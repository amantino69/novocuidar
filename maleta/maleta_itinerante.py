"""
TeleCuidar BLE Service - Maleta Itinerante
==========================================

Serviço para MALETA ITINERANTE de telemedicina.
Detecta automaticamente qual consulta está ativa no navegador.

FLUXO:
1. Técnico leva maleta para comunidade remota
2. Paciente faz login no telecuidar.com
3. Paciente entra na teleconsulta com o médico
4. Serviço DETECTA automaticamente a consulta ativa
5. Dispositivos BLE enviam dados para ESSA consulta
6. Próximo paciente → Nova consulta → Detecta automaticamente

O técnico não precisa configurar NADA entre pacientes!
"""

import asyncio
import aiohttp
import struct
import json
import os
import sys
import logging
import re
from datetime import datetime
from pathlib import Path
from bleak import BleakScanner, BleakClient

# === CONFIGURAÇÃO ===
BASE_URL = os.environ.get("TELECUIDAR_URL", "https://www.telecuidar.com.br")
API_URL = f"{BASE_URL}/api"

# Arquivo de log
LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(exist_ok=True)
LOG_FILE = LOG_DIR / "ble_service.log"

# Configurar logging
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
    },
    "DC:23:4E:DA:E9:DD": {
        "type": "thermometer",
        "name": "MOBI m3ja",
        "method": "gatt",
        "service_uuid": "00001809-0000-1000-8000-00805f9b34fb",  # Health Thermometer
        "char_uuid": "00002a1c-0000-1000-8000-00805f9b34fb"      # Temperature Measurement
    }
}

# === ESTADO GLOBAL ===
class ServiceState:
    def __init__(self):
        self.current_appointment_id = None
        self.last_check = None
        self.check_interval = 3  # Verifica a cada 3 segundos
        
        # Estado da balança
        self.scale_state = {"valor": 0, "contador": 0, "confirmado": False}
        
        # Controle do Omron
        self.omron_connecting = False
        
        # Controle do Termômetro
        self.thermometer_connecting = False

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
    """Processa dados do Blood Pressure Measurement"""
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
    
    if flags & 0x04 and len(data) >= offset + 2:
        if flags & 0x02:
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
    
    if raw == 0:
        if state.scale_state["confirmado"]:
            logger.info("⚖️ Balança zerada - pronto para próxima medição")
        state.scale_state = {"valor": 0, "contador": 0, "confirmado": False}
        return None
    
    if raw == state.scale_state["valor"]:
        state.scale_state["contador"] += 1
    else:
        state.scale_state["valor"] = raw
        state.scale_state["contador"] = 1
        state.scale_state["confirmado"] = False
    
    if state.scale_state["contador"] >= 5 and not state.scale_state["confirmado"]:
        state.scale_state["confirmado"] = True
        logger.info(f"✅ PESO CONFIRMADO: {peso} kg")
        return {"weight": peso}
    
    return None


def processar_temperatura(data: bytes) -> dict:
    """Processa dados do Health Thermometer Measurement (IEEE 11073)"""
    if len(data) < 5:
        return None
    
    flags = data[0]
    
    # Temperatura em IEEE 11073 FLOAT (4 bytes)
    # Formato: mantissa (3 bytes) + exponent (1 byte)
    mantissa = data[1] | (data[2] << 8) | (data[3] << 16)
    if mantissa >= 0x800000:
        mantissa -= 0x1000000
    exponent = data[4]
    if exponent >= 0x80:
        exponent -= 0x100
    
    temperatura = mantissa * (10 ** exponent)
    
    # Verifica se é Fahrenheit (bit 0 do flags)
    if flags & 0x01:
        # Converte de Fahrenheit para Celsius
        temperatura = (temperatura - 32) * 5 / 9
    
    # Arredonda para 1 casa decimal
    temperatura = round(temperatura, 1)
    
    # Valida range (32°C a 43°C é range humano típico)
    if 32.0 <= temperatura <= 43.0:
        return {"temperature": temperatura}
    
    return None


# === DETECÇÃO DE CONSULTA ATIVA ===

async def get_active_appointment_from_api() -> str:
    """
    Busca consultas em andamento no backend.
    Retorna o ID da consulta mais recente com status "Em Andamento".
    """
    try:
        async with aiohttp.ClientSession() as session:
            # Endpoint específico para maleta itinerante
            url = f"{API_URL}/biometrics/active-appointment"
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    if data and isinstance(data, dict) and data.get("id"):
                        return data["id"]
                    elif data and isinstance(data, list) and len(data) > 0:
                        return data[0].get("id")
    except Exception as e:
        # Silencioso - vai tentar novamente
        pass
    
    return None


async def detect_active_appointment() -> str:
    """
    Detecta qual consulta está ativa.
    Usa múltiplas estratégias:
    1. API do backend (consultas em andamento)
    2. Arquivo temporário (escrito pelo frontend)
    """
    now = datetime.now()
    
    # Verifica intervalo
    if state.last_check:
        elapsed = (now - state.last_check).total_seconds()
        if elapsed < state.check_interval and state.current_appointment_id:
            return state.current_appointment_id
    
    state.last_check = now
    
    # Estratégia 1: Arquivo de sessão (escrito pelo frontend quando entra na teleconsulta)
    session_file = Path(__file__).parent / "current_session.json"
    if session_file.exists():
        try:
            with open(session_file, 'r') as f:
                session = json.load(f)
                appointment_id = session.get("appointmentId")
                if appointment_id:
                    if appointment_id != state.current_appointment_id:
                        logger.info(f"📡 Nova consulta detectada: {appointment_id}")
                        state.current_appointment_id = appointment_id
                    return appointment_id
        except:
            pass
    
    # Estratégia 2: API do backend
    appointment_id = await get_active_appointment_from_api()
    if appointment_id:
        if appointment_id != state.current_appointment_id:
            logger.info(f"📡 Consulta ativa (API): {appointment_id}")
            state.current_appointment_id = appointment_id
        return appointment_id
    
    return state.current_appointment_id


# === COMUNICAÇÃO COM BACKEND ===

async def enviar_para_cache(tipo: str, valores: dict):
    """Envia leitura para o cache do backend (sempre, independente de consulta ativa)"""
    payload = {
        "deviceType": tipo,
        "timestamp": datetime.now().isoformat(),
        "values": valores
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            url = f"{API_URL}/biometrics/ble-cache"
            async with session.post(url, json=payload) as resp:
                if resp.status == 200:
                    logger.info(f"📦 Cache: {tipo} = {valores}")
                    return True
    except Exception as e:
        pass  # Silencioso - cache é secundário
    return False


async def enviar_leitura(tipo: str, valores: dict):
    """Envia leitura para o backend TeleCuidar"""
    # SEMPRE envia para o cache (para botão "Capturar Sinais")
    await enviar_para_cache(tipo, valores)
    
    appointment_id = await detect_active_appointment()
    
    if not appointment_id:
        logger.warning(f"⚠️ Nenhuma consulta ativa - {tipo} não enviado")
        logger.info("   Aguardando paciente entrar na teleconsulta...")
        return False
    
    payload = {
        "appointmentId": appointment_id,
        "deviceType": tipo,
        "timestamp": datetime.now().isoformat(),
        "values": valores
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            url = f"{API_URL}/biometrics/ble-reading"
            async with session.post(url, json=payload) as resp:
                if resp.status == 200:
                    logger.info(f"✅ {tipo}: {valores} → Médico recebeu!")
                    return True
                else:
                    text = await resp.text()
                    logger.error(f"❌ Erro: {resp.status} - {text}")
                    return False
    except Exception as e:
        logger.error(f"❌ Erro de conexão: {e}")
        return False


# === CONEXÃO OMRON ===

async def conectar_omron():
    """Conecta ao Omron via GATT"""
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
                logger.info(f"✅ Conectado ao Omron")
                
                await client.start_notify(char_uuid, notification_handler)
                
                try:
                    await asyncio.wait_for(pressao_recebida.wait(), timeout=60.0)
                    
                    if dados_pressao:
                        pulse_info = f", Pulso: {dados_pressao['pulse']} bpm" if 'pulse' in dados_pressao else ""
                        logger.info(f"💓 PRESSÃO: {dados_pressao['systolic']}/{dados_pressao['diastolic']} mmHg{pulse_info}")
                        await enviar_leitura("blood_pressure", dados_pressao)
                        return dados_pressao
                        
                except asyncio.TimeoutError:
                    logger.warning("⏱️ Timeout - faça a medição no aparelho")
                
                await client.stop_notify(char_uuid)
                
    except Exception as e:
        logger.error(f"❌ Erro Omron: {e}")
    finally:
        state.omron_connecting = False
    
    return None


# === CONEXÃO TERMÔMETRO MOBI ===

async def conectar_termometro():
    """Conecta ao termômetro MOBI via GATT"""
    if state.thermometer_connecting:
        return None
    
    state.thermometer_connecting = True
    device_info = DEVICES.get("DC:23:4E:DA:E9:DD")
    mac = "DC:23:4E:DA:E9:DD"
    char_uuid = device_info["char_uuid"]
    
    logger.info(f"🔗 Conectando ao {device_info['name']}...")
    
    dados_temp = None
    temp_recebida = asyncio.Event()
    
    def notification_handler(sender, data):
        nonlocal dados_temp
        logger.debug(f"🌡️ Dados recebidos: {data.hex()}")
        resultado = processar_temperatura(data)
        if resultado:
            dados_temp = resultado
            temp_recebida.set()
    
    try:
        async with BleakClient(mac, timeout=15.0) as client:
            if client.is_connected:
                logger.info(f"✅ Conectado ao Termômetro")
                
                # Tenta encontrar a característica de temperatura
                try:
                    await client.start_notify(char_uuid, notification_handler)
                except Exception as e:
                    # Alguns termômetros usam characteristic diferente
                    logger.debug(f"Tentando características alternativas...")
                    for service in client.services:
                        for char in service.characteristics:
                            if "notify" in char.properties or "indicate" in char.properties:
                                try:
                                    await client.start_notify(char.uuid, notification_handler)
                                    logger.debug(f"Usando característica: {char.uuid}")
                                    break
                                except:
                                    pass
                
                try:
                    await asyncio.wait_for(temp_recebida.wait(), timeout=30.0)
                    
                    if dados_temp:
                        logger.info(f"🌡️ TEMPERATURA: {dados_temp['temperature']}°C")
                        await enviar_leitura("thermometer", dados_temp)
                        return dados_temp
                        
                except asyncio.TimeoutError:
                    logger.warning("⏱️ Timeout - faça a medição no termômetro")
                
    except Exception as e:
        logger.error(f"❌ Erro Termômetro: {e}")
    finally:
        state.thermometer_connecting = False
    
    return None


# === SCANNER BLE ===

def detection_callback(device, advertisement_data):
    """Callback para dispositivos BLE detectados"""
    mac = device.address.upper()
    
    if mac == "F8:8F:C8:3A:B7:92":
        for _, data in advertisement_data.manufacturer_data.items():
            resultado = processar_balanca(data)
            if resultado:
                asyncio.create_task(enviar_leitura("scale", resultado))
    
    elif mac == "00:5F:BF:9A:64:DF" and not state.omron_connecting:
        logger.info(f"📡 Omron detectado!")
        asyncio.create_task(conectar_omron())
    
    elif mac == "DC:23:4E:DA:E9:DD" and not state.thermometer_connecting:
        logger.info(f"🌡️ Termômetro MOBI detectado!")
        asyncio.create_task(conectar_termometro())


# === INTERFACE SIMPLES PARA TÉCNICO ===

def mostrar_status():
    """Mostra status atual"""
    print("\n" + "=" * 50)
    print("   🏥 MALETA ITINERANTE - STATUS")
    print("=" * 50)
    if state.current_appointment_id:
        print(f"   📡 Consulta ativa: {state.current_appointment_id[:8]}...")
    else:
        print("   ⏳ Aguardando paciente entrar na teleconsulta")
    print("=" * 50 + "\n")


# === LOOP PRINCIPAL ===

async def main():
    logger.info("=" * 60)
    logger.info("   🚐 TELECUIDAR - MALETA ITINERANTE")
    logger.info("=" * 60)
    logger.info(f"Backend: {BASE_URL}")
    
    logger.info("\n📋 DISPOSITIVOS CONFIGURADOS:")
    for mac, device in DEVICES.items():
        logger.info(f"   • {device['name']} ({mac})")
    
    logger.info("\n" + "-" * 60)
    logger.info("🔊 MODO ITINERANTE ATIVO")
    logger.info("   O serviço detecta automaticamente a consulta")
    logger.info("   quando o paciente entra na teleconsulta.")
    logger.info("-" * 60)
    logger.info("\n⏳ Aguardando consulta ativa...\n")
    
    scanner = BleakScanner(detection_callback)
    await scanner.start()
    
    last_status_check = None
    
    try:
        while True:
            # Atualiza detecção de consulta
            await detect_active_appointment()
            
            # Mostra status periodicamente
            now = datetime.now()
            if not last_status_check or (now - last_status_check).total_seconds() > 30:
                if state.current_appointment_id:
                    logger.info(f"📡 Consulta ativa: {state.current_appointment_id}")
                else:
                    logger.info("⏳ Aguardando paciente entrar na teleconsulta...")
                last_status_check = now
            
            await asyncio.sleep(3)
            
    except asyncio.CancelledError:
        pass
    finally:
        await scanner.stop()
        logger.info("Scanner BLE parado")


if __name__ == "__main__":
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚐 TELECUIDAR - MALETA ITINERANTE DE TELEMEDICINA          ║
║                                                              ║
║   Este serviço detecta AUTOMATICAMENTE qual paciente         ║
║   está em teleconsulta e envia os dados dos dispositivos.    ║
║                                                              ║
║   O técnico NÃO precisa configurar nada entre pacientes!     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n👋 Serviço encerrado")
