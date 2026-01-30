"""
TeleCuidar BLE Service - Serviço Windows para Maleta de Telemedicina
=====================================================================

Este serviço roda automaticamente no Windows e:
1. Escuta TODOS os dispositivos BLE configurados
2. Detecta automaticamente a consulta ativa do paciente
3. Envia dados instantaneamente para o backend (médico vê em tempo real)

O paciente só precisa ligar os aparelhos e usar!
"""

import asyncio
import aiohttp
import struct
import json
import os
import sys
import logging
from datetime import datetime, timedelta
from pathlib import Path
from bleak import BleakScanner, BleakClient

# === CONFIGURAÇÃO ===
# Em produção: https://www.telecuidar.com.br
# Em homologação: http://localhost:5239
BASE_URL = os.environ.get("TELECUIDAR_URL", "http://localhost:5239")
API_URL = f"{BASE_URL}/api"

# Arquivo de configuração do paciente (criado no setup da maleta)
CONFIG_FILE = Path(__file__).parent / "config.json"
LOG_FILE = Path(__file__).parent / "logs" / "ble_service.log"

# Configurar logging
LOG_FILE.parent.mkdir(exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# === DISPOSITIVOS SUPORTADOS ===
DEVICES = {
    "F8:8F:C8:3A:B7:92": {
        "type": "scale",
        "name": "Balança OKOK",
        "method": "advertisement"
    },
    "00:5F:BF:9A:64:DF": {
        "type": "blood_pressure",
        "name": "Omron HEM-7156T",
        "method": "gatt",
        "service_uuid": "00001810-0000-1000-8000-00805f9b34fb",
        "char_uuid": "00002a35-0000-1000-8000-00805f9b34fb"
    }
    # Adicione mais dispositivos aqui conforme necessário
}

# === ESTADO GLOBAL ===
class ServiceState:
    def __init__(self):
        self.patient_id = None
        self.patient_email = None
        self.auth_token = None
        self.current_appointment_id = None
        self.last_appointment_check = None
        self.appointment_check_interval = 10  # segundos
        
        # Estado da balança
        self.scale_state = {"valor": 0, "contador": 0, "confirmado": False}
        
        # Controle do Omron
        self.omron_connecting = False
        self.omron_last_reading = None
        
        # Carregar configuração
        self.load_config()
    
    def load_config(self):
        """Carrega configuração do paciente da maleta"""
        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE, 'r') as f:
                    config = json.load(f)
                    self.patient_id = config.get("patient_id")
                    self.patient_email = config.get("patient_email")
                    self.auth_token = config.get("auth_token")
                    logger.info(f"Configuração carregada: {self.patient_email}")
            except Exception as e:
                logger.error(f"Erro ao carregar configuração: {e}")
        else:
            logger.warning(f"Arquivo de configuração não encontrado: {CONFIG_FILE}")

state = ServiceState()


# === FUNÇÕES AUXILIARES ===

def sfloat_to_float(raw: int) -> float:
    """Converte IEEE 11073 SFLOAT para float"""
    mantissa = raw & 0x0FFF
    if mantissa >= 0x0800:
        mantissa -= 0x1000
    exponent = (raw >> 12) & 0x0F
    if exponent >= 0x08:
        exponent -= 0x10
    return mantissa * (10 ** exponent)


def processar_pressao(data: bytes) -> dict:
    """Processa dados do Blood Pressure Measurement (UUID 0x2A35)"""
    if len(data) < 7:
        return None
    
    flags = data[0]
    offset = 1
    
    sistolica = sfloat_to_float(struct.unpack_from('<H', data, offset)[0])
    offset += 2
    diastolica = sfloat_to_float(struct.unpack_from('<H', data, offset)[0])
    offset += 2
    map_value = sfloat_to_float(struct.unpack_from('<H', data, offset)[0])
    offset += 2
    
    resultado = {
        "systolic": round(sistolica),
        "diastolic": round(diastolica),
        "map": round(map_value)
    }
    
    # Pulso (se presente)
    if flags & 0x04 and len(data) >= offset + 2:
        if flags & 0x02:  # Timestamp presente
            offset += 7
        if len(data) >= offset + 2:
            pulse = sfloat_to_float(struct.unpack_from('<H', data, offset)[0])
            resultado["pulse"] = round(pulse)
    
    return resultado


def processar_balanca(data: bytes) -> dict:
    """Processa dados da balança OKOK"""
    if len(data) < 2:
        return None
    
    raw = (data[0] << 8) | data[1]
    peso = round(raw / 100, 2)
    
    # Se zerou, reseta
    if raw == 0:
        if state.scale_state["confirmado"]:
            logger.info("Balança zerada - pronto para nova medição")
        state.scale_state = {"valor": 0, "contador": 0, "confirmado": False}
        return None
    
    # Conta estabilidade
    if raw == state.scale_state["valor"]:
        state.scale_state["contador"] += 1
    else:
        state.scale_state["valor"] = raw
        state.scale_state["contador"] = 1
        state.scale_state["confirmado"] = False
    
    # Confirma após 5 leituras iguais
    if state.scale_state["contador"] >= 5 and not state.scale_state["confirmado"]:
        state.scale_state["confirmado"] = True
        logger.info(f"✅ PESO CONFIRMADO: {peso} kg")
        return {"weight": peso}
    
    return None


# === COMUNICAÇÃO COM BACKEND ===

async def get_active_appointment() -> str:
    """Busca a consulta ativa do paciente"""
    if not state.patient_id:
        return None
    
    # Verifica se já checou recentemente
    now = datetime.now()
    if state.last_appointment_check:
        elapsed = (now - state.last_appointment_check).total_seconds()
        if elapsed < state.appointment_check_interval and state.current_appointment_id:
            return state.current_appointment_id
    
    try:
        headers = {}
        if state.auth_token:
            headers["Authorization"] = f"Bearer {state.auth_token}"
        
        async with aiohttp.ClientSession() as session:
            # Busca consultas do paciente com status "Em Andamento"
            url = f"{API_URL}/appointments?patientId={state.patient_id}&status=2"
            async with session.get(url, headers=headers) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    appointments = data.get("items", data) if isinstance(data, dict) else data
                    
                    if appointments and len(appointments) > 0:
                        # Pega a primeira consulta ativa
                        appointment = appointments[0]
                        appointment_id = appointment.get("id")
                        
                        if appointment_id != state.current_appointment_id:
                            logger.info(f"📡 Nova consulta ativa: {appointment_id}")
                            state.current_appointment_id = appointment_id
                        
                        state.last_appointment_check = now
                        return appointment_id
                    else:
                        if state.current_appointment_id:
                            logger.info("Consulta encerrada")
                        state.current_appointment_id = None
                else:
                    logger.warning(f"Erro ao buscar consultas: {resp.status}")
                    
    except Exception as e:
        logger.error(f"Erro ao verificar consulta ativa: {e}")
    
    state.last_appointment_check = now
    return state.current_appointment_id


async def enviar_leitura(tipo: str, valores: dict):
    """Envia leitura para o backend TeleCuidar"""
    appointment_id = await get_active_appointment()
    
    if not appointment_id:
        logger.warning(f"⚠️ Sem consulta ativa - dados de {tipo} não enviados")
        return False
    
    payload = {
        "appointmentId": appointment_id,
        "deviceType": tipo,
        "timestamp": datetime.now().isoformat(),
        "values": valores
    }
    
    try:
        headers = {"Content-Type": "application/json"}
        if state.auth_token:
            headers["Authorization"] = f"Bearer {state.auth_token}"
        
        async with aiohttp.ClientSession() as session:
            url = f"{API_URL}/biometrics/ble-reading"
            async with session.post(url, json=payload, headers=headers) as resp:
                if resp.status == 200:
                    logger.info(f"✅ {tipo}: {valores} → Enviado para o médico!")
                    return True
                else:
                    text = await resp.text()
                    logger.error(f"❌ Erro ao enviar {tipo}: {resp.status} - {text}")
                    return False
    except Exception as e:
        logger.error(f"❌ Erro de conexão: {e}")
        return False


# === CONEXÃO OMRON (GATT) ===

async def conectar_omron():
    """Conecta ao Omron e lê medição de pressão via GATT"""
    if state.omron_connecting:
        return None
    
    state.omron_connecting = True
    device_info = DEVICES.get("00:5F:BF:9A:64:DF")
    mac = "00:5F:BF:9A:64:DF"
    char_uuid = device_info["char_uuid"]
    
    logger.info(f"🔗 Conectando ao {device_info['name']}...")
    
    dados_pressao = None
    pressao_recebida = asyncio.Event()
    
    def notification_handler(sender, data):
        nonlocal dados_pressao
        resultado = processar_pressao(data)
        if resultado:
            dados_pressao = resultado
            pressao_recebida.set()
    
    try:
        async with BleakClient(mac, timeout=15.0) as client:
            if client.is_connected:
                logger.info(f"✅ Conectado ao {device_info['name']}")
                
                await client.start_notify(char_uuid, notification_handler)
                
                try:
                    await asyncio.wait_for(pressao_recebida.wait(), timeout=60.0)
                    
                    if dados_pressao:
                        logger.info(f"💓 PRESSÃO: {dados_pressao['systolic']}/{dados_pressao['diastolic']} mmHg")
                        await enviar_leitura("blood_pressure", dados_pressao)
                        state.omron_last_reading = datetime.now()
                        return dados_pressao
                        
                except asyncio.TimeoutError:
                    logger.warning("Timeout - nenhuma medição recebida do Omron")
                
                await client.stop_notify(char_uuid)
                
    except Exception as e:
        logger.error(f"Erro ao conectar ao Omron: {e}")
    finally:
        state.omron_connecting = False
    
    return None


# === SCANNER BLE ===

def detection_callback(device, advertisement_data):
    """Callback para dispositivos detectados via BLE scan"""
    mac = device.address.upper()
    
    # Processa balança via advertisement
    if mac == "F8:8F:C8:3A:B7:92":
        for _, data in advertisement_data.manufacturer_data.items():
            resultado = processar_balanca(data)
            if resultado:
                asyncio.create_task(enviar_leitura("scale", resultado))
    
    # Detecta Omron e tenta conectar
    elif mac == "00:5F:BF:9A:64:DF" and not state.omron_connecting:
        logger.info(f"📡 Omron detectado!")
        asyncio.create_task(conectar_omron())


# === LOOP PRINCIPAL ===

async def main():
    logger.info("=" * 60)
    logger.info("   🏥 TeleCuidar BLE Service - Maleta de Telemedicina")
    logger.info("=" * 60)
    logger.info(f"Backend: {BASE_URL}")
    
    if state.patient_email:
        logger.info(f"Paciente: {state.patient_email}")
    else:
        logger.warning("⚠️ Nenhum paciente configurado!")
        logger.info(f"Configure o arquivo: {CONFIG_FILE}")
    
    logger.info("\nDispositivos monitorados:")
    for mac, device in DEVICES.items():
        logger.info(f"  • {device['name']} ({mac})")
    
    logger.info("\n" + "-" * 60)
    logger.info("🔊 SERVIÇO ATIVO - Escutando dispositivos...")
    logger.info("-" * 60)
    
    scanner = BleakScanner(detection_callback)
    await scanner.start()
    
    try:
        while True:
            # Verifica periodicamente se há consulta ativa
            await get_active_appointment()
            await asyncio.sleep(5)
    except asyncio.CancelledError:
        logger.info("Serviço cancelado")
    finally:
        await scanner.stop()
        logger.info("Scanner BLE parado")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n👋 Serviço encerrado pelo usuário")
    except Exception as e:
        logger.error(f"Erro fatal: {e}")
        sys.exit(1)
