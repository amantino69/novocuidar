"""
TeleCuidar BLE Service - Maleta Itinerante
==========================================

Servi├ºo para MALETA ITINERANTE de telemedicina.
Detecta automaticamente qual consulta est├í ativa no navegador.

FLUXO:
1. T├®cnico leva maleta para comunidade remota
2. Paciente faz login no telecuidar.com
3. Paciente entra na teleconsulta com o m├®dico
4. Servi├ºo DETECTA automaticamente a consulta ativa
5. Dispositivos BLE enviam dados para ESSA consulta
6. Pr├│ximo paciente ÔåÆ Nova consulta ÔåÆ Detecta automaticamente

O t├®cnico n├úo precisa configurar NADA entre pacientes!
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

# === CONFIGURA├ç├âO ===
BASE_URL = os.environ.get("TELECUIDAR_URL", "http://localhost:5239")
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
        "name": "Balan├ºa OKOK",
        "method": "advertisement"
    },
    "00:5F:BF:9A:64:DF": {
        "type": "blood_pressure",
        "name": "Omron HEM-7156T",
        "method": "gatt",
        "service_uuid": "00001810-0000-1000-8000-00805f9b34fb",
        "char_uuid": "00002a35-0000-1000-8000-00805f9b34fb"
    }
}

# === ESTADO GLOBAL ===
class ServiceState:
    def __init__(self):
        self.current_appointment_id = None
        self.last_check = None
        self.check_interval = 3  # Verifica a cada 3 segundos
        
        # Estado da balan├ºa
        self.scale_state = {"valor": 0, "contador": 0, "confirmado": False}
        
        # Controle do Omron
        self.omron_connecting = False

state = ServiceState()


# === FUN├ç├òES AUXILIARES ===

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
    """Processa dados da balan├ºa OKOK"""
    if len(data) < 2:
        return None
    
    raw = (data[0] << 8) | data[1]
    peso = round(raw / 100, 2)
    
    if raw == 0:
        if state.scale_state["confirmado"]:
            logger.info("ÔÜû´©Å Balan├ºa zerada - pronto para pr├│xima medi├º├úo")
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
        logger.info(f"Ô£à PESO CONFIRMADO: {peso} kg")
        return {"weight": peso}
    
    return None


# === DETEC├ç├âO DE CONSULTA ATIVA ===

async def get_active_appointment_from_api() -> str:
    """
    Busca consultas em andamento no backend.
    Retorna o ID da consulta mais recente com status "Em Andamento".
    """
    try:
        async with aiohttp.ClientSession() as session:
            # Endpoint espec├¡fico para maleta itinerante
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
    Detecta qual consulta est├í ativa.
    Usa m├║ltiplas estrat├®gias:
    1. API do backend (consultas em andamento)
    2. Arquivo tempor├írio (escrito pelo frontend)
    """
    now = datetime.now()
    
    # Verifica intervalo
    if state.last_check:
        elapsed = (now - state.last_check).total_seconds()
        if elapsed < state.check_interval and state.current_appointment_id:
            return state.current_appointment_id
    
    state.last_check = now
    
    # Estrat├®gia 1: Arquivo de sess├úo (escrito pelo frontend quando entra na teleconsulta)
    session_file = Path(__file__).parent / "current_session.json"
    if session_file.exists():
        try:
            with open(session_file, 'r') as f:
                session = json.load(f)
                appointment_id = session.get("appointmentId")
                if appointment_id:
                    if appointment_id != state.current_appointment_id:
                        logger.info(f"­ƒôí Nova consulta detectada: {appointment_id}")
                        state.current_appointment_id = appointment_id
                    return appointment_id
        except:
            pass
    
    # Estrat├®gia 2: API do backend
    appointment_id = await get_active_appointment_from_api()
    if appointment_id:
        if appointment_id != state.current_appointment_id:
            logger.info(f"­ƒôí Consulta ativa (API): {appointment_id}")
            state.current_appointment_id = appointment_id
        return appointment_id
    
    return state.current_appointment_id


# === COMUNICA├ç├âO COM BACKEND ===

async def enviar_leitura(tipo: str, valores: dict):
    """Envia leitura para o backend TeleCuidar"""
    appointment_id = await detect_active_appointment()
    
    if not appointment_id:
        logger.warning(f"ÔÜá´©Å Nenhuma consulta ativa - {tipo} n├úo enviado")
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
                    logger.info(f"Ô£à {tipo}: {valores} ÔåÆ M├®dico recebeu!")
                    return True
                else:
                    text = await resp.text()
                    logger.error(f"ÔØî Erro: {resp.status} - {text}")
                    return False
    except Exception as e:
        logger.error(f"ÔØî Erro de conex├úo: {e}")
        return False


# === CONEX├âO OMRON ===

async def conectar_omron():
    """Conecta ao Omron via GATT"""
    if state.omron_connecting:
        return None
    
    state.omron_connecting = True
    device_info = DEVICES.get("00:5F:BF:9A:64:DF")
    mac = "00:5F:BF:9A:64:DF"
    char_uuid = device_info["char_uuid"]
    
    logger.info(f"­ƒöù Conectando ao {device_info['name']}...")
    
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
                logger.info(f"Ô£à Conectado ao Omron")
                
                await client.start_notify(char_uuid, notification_handler)
                
                try:
                    await asyncio.wait_for(pressao_recebida.wait(), timeout=60.0)
                    
                    if dados_pressao:
                        pulse_info = f", Pulso: {dados_pressao['pulse']} bpm" if 'pulse' in dados_pressao else ""
                        logger.info(f"­ƒÆô PRESS├âO: {dados_pressao['systolic']}/{dados_pressao['diastolic']} mmHg{pulse_info}")
                        await enviar_leitura("blood_pressure", dados_pressao)
                        return dados_pressao
                        
                except asyncio.TimeoutError:
                    logger.warning("ÔÅ▒´©Å Timeout - fa├ºa a medi├º├úo no aparelho")
                
                await client.stop_notify(char_uuid)
                
    except Exception as e:
        logger.error(f"ÔØî Erro Omron: {e}")
    finally:
        state.omron_connecting = False
    
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
        logger.info(f"­ƒôí Omron detectado!")
        asyncio.create_task(conectar_omron())


# === INTERFACE SIMPLES PARA T├ëCNICO ===

def mostrar_status():
    """Mostra status atual"""
    print("\n" + "=" * 50)
    print("   ­ƒÅÑ MALETA ITINERANTE - STATUS")
    print("=" * 50)
    if state.current_appointment_id:
        print(f"   ­ƒôí Consulta ativa: {state.current_appointment_id[:8]}...")
    else:
        print("   ÔÅ│ Aguardando paciente entrar na teleconsulta")
    print("=" * 50 + "\n")


# === LOOP PRINCIPAL ===

async def main():
    logger.info("=" * 60)
    logger.info("   ­ƒÜÉ TELECUIDAR - MALETA ITINERANTE")
    logger.info("=" * 60)
    logger.info(f"Backend: {BASE_URL}")
    
    logger.info("\n­ƒôï DISPOSITIVOS CONFIGURADOS:")
    for mac, device in DEVICES.items():
        logger.info(f"   ÔÇó {device['name']} ({mac})")
    
    logger.info("\n" + "-" * 60)
    logger.info("­ƒöè MODO ITINERANTE ATIVO")
    logger.info("   O servi├ºo detecta automaticamente a consulta")
    logger.info("   quando o paciente entra na teleconsulta.")
    logger.info("-" * 60)
    logger.info("\nÔÅ│ Aguardando consulta ativa...\n")
    
    scanner = BleakScanner(detection_callback)
    await scanner.start()
    
    last_status_check = None
    
    try:
        while True:
            # Atualiza detec├º├úo de consulta
            await detect_active_appointment()
            
            # Mostra status periodicamente
            now = datetime.now()
            if not last_status_check or (now - last_status_check).total_seconds() > 30:
                if state.current_appointment_id:
                    logger.info(f"­ƒôí Consulta ativa: {state.current_appointment_id}")
                else:
                    logger.info("ÔÅ│ Aguardando paciente entrar na teleconsulta...")
                last_status_check = now
            
            await asyncio.sleep(3)
            
    except asyncio.CancelledError:
        pass
    finally:
        await scanner.stop()
        logger.info("Scanner BLE parado")


if __name__ == "__main__":
    print("""
ÔòöÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòù
Ôòæ                                                              Ôòæ
Ôòæ   ­ƒÜÉ TELECUIDAR - MALETA ITINERANTE DE TELEMEDICINA          Ôòæ
Ôòæ                                                              Ôòæ
Ôòæ   Este servi├ºo detecta AUTOMATICAMENTE qual paciente         Ôòæ
Ôòæ   est├í em teleconsulta e envia os dados dos dispositivos.    Ôòæ
Ôòæ                                                              Ôòæ
Ôòæ   O t├®cnico N├âO precisa configurar nada entre pacientes!     Ôòæ
Ôòæ                                                              Ôòæ
ÔòÜÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòØ
    """)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n­ƒæï Servi├ºo encerrado")
