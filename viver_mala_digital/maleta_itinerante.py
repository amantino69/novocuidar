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
import argparse
from datetime import datetime
from pathlib import Path
from bleak import BleakScanner, BleakClient

# === ARGUMENTOS DE LINHA DE COMANDO ===
def parse_args():
    parser = argparse.ArgumentParser(
        description="TeleCuidar BLE Service - Maleta Itinerante",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  python maleta_itinerante.py              # Usa produção (telecuidar.com.br)
  python maleta_itinerante.py --local      # Usa localhost:5239 (homologação)
  python maleta_itinerante.py --url http://192.168.1.100:5239  # URL customizada
  python maleta_itinerante.py --appointment 62734ef5-c2af-40f1-8726-099932da0240  # ID fixo
        """
    )
    parser.add_argument(
        "--local", "-l",
        action="store_true",
        help="Usar ambiente local (http://localhost:5239)"
    )
    parser.add_argument(
        "--url", "-u",
        type=str,
        help="URL base customizada (ex: http://192.168.1.100:5239)"
    )
    parser.add_argument(
        "--appointment", "-a",
        type=str,
        help="ID da consulta (GUID). Se informado, ignora detecção automática."
    )
    return parser.parse_args()

# Parse argumentos
args = parse_args()

# === CONFIGURAÇÃO ===
if args.url:
    BASE_URL = args.url.rstrip('/')
elif args.local:
    BASE_URL = "http://localhost:5239"
else:
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
    },
    "88:D2:11:C8:20:31": {
        "type": "stethoscope",
        "name": "Eko CORE 500",
        "method": "gatt_stream",
        "char_uuid": "c320d257-d7be-46ac-9a37-7a4edfa84bce",    # Audio streaming
        "sample_rate": 8000,
        "codec": "ima_adpcm",
        "capture_duration": 15  # segundos
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
        self.omron_last_attempt = None  # Cooldown para não conectar repetidamente
        self.omron_cooldown = 30  # Espera 30 segundos entre tentativas
        
        # Controle do Termômetro
        self.thermometer_connecting = False
        
        # Controle do Eko (estetoscópio)
        self.eko_connecting = False
        self.eko_capturing = False
        self.eko_audio_buffer = bytearray()
        self.eko_packet_count = 0
        self.eko_last_capture = None  # Cooldown para não capturar repetidamente
        self.eko_cooldown = 60  # Espera 60 segundos entre capturas
        
        # Referência ao scanner BLE (para pausar durante conexão GATT)
        self.scanner = None

state = ServiceState()


# === FUNÇÕES AUXILIARES ===

def sfloat_to_float(raw: int) -> float:
    """Converte IEEE 11073 SFLOAT para float"""
    # Valores especiais
    if raw == 0x07FF:  # NaN
        return float('nan')
    if raw == 0x0800:  # NRes (not at this resolution)
        return float('nan')
    if raw == 0x07FE:  # +INFINITY
        return float('inf')
    if raw == 0x0802:  # -INFINITY
        return float('-inf')
    
    mantissa = raw & 0x0FFF
    if mantissa >= 0x0800:
        mantissa -= 0x1000  # Complemento de 2 para 12 bits
    exponent = (raw >> 12) & 0x0F
    if exponent >= 0x08:
        exponent -= 0x10  # Complemento de 2 para 4 bits
    return mantissa * (10 ** exponent)


def processar_pressao(data: bytes) -> dict:
    """Processa dados do Blood Pressure Measurement (BLE spec)"""
    if len(data) < 7:
        return None
    
    flags = data[0]
    offset = 1
    
    # Lê os valores raw (SFLOAT - 2 bytes cada)
    sys_raw = struct.unpack_from('<H', data, offset)[0]
    offset += 2
    dia_raw = struct.unpack_from('<H', data, offset)[0]
    offset += 2
    map_raw = struct.unpack_from('<H', data, offset)[0]
    offset += 2
    
    # Converte de SFLOAT para float
    sistolica = sfloat_to_float(sys_raw)
    diastolica = sfloat_to_float(dia_raw)
    map_value = sfloat_to_float(map_raw)
    
    resultado = {
        "systolic": round(sistolica),
        "diastolic": round(diastolica),
        "map": round(map_value),
        "timestamp": None  # Para comparação
    }
    
    # ORDEM DOS CAMPOS segundo BLE Blood Pressure Measurement spec:
    # 1. Timestamp (se flag bit 1 = 0x02)
    # 2. Pulse Rate (se flag bit 2 = 0x04)
    # 3. User ID (se flag bit 3 = 0x08)
    # 4. Measurement Status (se flag bit 4 = 0x10)
    
    # 1. Extrai timestamp se presente (flag bit 1 = 0x02)
    if flags & 0x02 and len(data) >= offset + 7:
        year = struct.unpack_from('<H', data, offset)[0]
        month = data[offset + 2]
        day = data[offset + 3]
        hour = data[offset + 4]
        minute = data[offset + 5]
        second = data[offset + 6]
        offset += 7
        
        try:
            from datetime import datetime as dt
            resultado["timestamp"] = dt(year, month, day, hour, minute, second)
            logger.debug(f"   Timestamp: {year}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:{second:02d}")
        except Exception as e:
            logger.debug(f"   Timestamp inválido: {e}")
    
    # 2. Pulse Rate (flag bit 2 = 0x04) - VEM LOGO APÓS TIMESTAMP!
    if flags & 0x04 and len(data) >= offset + 2:
        pulse_raw = struct.unpack_from('<H', data, offset)[0]
        pulse = sfloat_to_float(pulse_raw)
        resultado["pulse"] = round(pulse)
        offset += 2
    
    # 3. User ID (flag bit 3 = 0x08) - ignoramos
    if flags & 0x08 and len(data) >= offset + 1:
        offset += 1
    
    # 4. Measurement Status (flag bit 4 = 0x10) - ignoramos
    if flags & 0x10 and len(data) >= offset + 2:
        offset += 2
    
    # Log resumido
    ts_str = resultado["timestamp"].strftime("%d/%m %H:%M") if resultado.get("timestamp") else "sem data"
    pulse_str = f", Pulso: {resultado['pulse']}" if resultado.get('pulse') else ""
    logger.info(f"📊 Medição: {resultado['systolic']}/{resultado['diastolic']} mmHg{pulse_str} | {ts_str}")
    
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
    0. Parâmetro de linha de comando (--appointment)
    1. API do backend (consultas em andamento)
    2. Arquivo temporário (escrito pelo frontend)
    """
    # Estratégia 0: Parâmetro de linha de comando (prioridade máxima)
    if args.appointment:
        if args.appointment != state.current_appointment_id:
            logger.info(f"📡 Usando consulta fixa (--appointment): {args.appointment}")
            state.current_appointment_id = args.appointment
        return args.appointment
    
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
    """Conecta ao Omron via GATT - usando técnica do pressao.py que funciona"""
    # Verifica cooldown
    if state.omron_last_attempt:
        elapsed = (datetime.now() - state.omron_last_attempt).total_seconds()
        if elapsed < state.omron_cooldown:
            return None  # Ainda em cooldown, ignora
    
    if state.omron_connecting:
        return None
    
    state.omron_connecting = True
    state.omron_last_attempt = datetime.now()
    device_info = DEVICES.get("00:5F:BF:9A:64:DF")
    mac = "00:5F:BF:9A:64:DF"
    char_uuid = device_info["char_uuid"]
    
    logger.info(f"🔗 Conectando ao {device_info['name']}...")
    
    # IMPORTANTE: Parar o scanner durante conexão GATT
    scanner_parado = False
    if state.scanner:
        try:
            await state.scanner.stop()
            scanner_parado = True
            logger.info("🔇 Scanner pausado para conexão GATT")
            await asyncio.sleep(0.3)
        except Exception as e:
            logger.warning(f"⚠️ Erro ao pausar scanner: {e}")
    
    dados_pressao = None
    todas_medicoes = []  # Coleta TODAS as medições
    pressao_recebida = asyncio.Event()
    ultima_notificacao = [None]  # Mutable para closure
    
    def notification_handler(sender, data):
        nonlocal dados_pressao
        logger.info(f"📩 Dados recebidos: {len(data)} bytes - {data.hex()}")
        resultado = processar_pressao(data)
        if resultado:
            todas_medicoes.append(resultado)
            dados_pressao = resultado
            ultima_notificacao[0] = asyncio.get_event_loop().time()
            pressao_recebida.set()
    
    try:
        # Técnica do pressao.py: scan dedicado primeiro
        logger.info("🔍 Buscando Omron...")
        devices = await BleakScanner.discover(timeout=10.0)
        target = next((d for d in devices if d.address.upper() == mac.upper()), None)
        
        if not target:
            logger.warning("⚠️ Omron não encontrado no scan")
            return None
        
        logger.info(f"✅ Encontrado: {target.name}")
        
        # Conecta usando objeto device - timeout de 90s para dar tempo da medição
        async with BleakClient(target, timeout=90.0) as client:
            if client.is_connected:
                logger.info(f"✅ Conectado ao Omron!")
                
                await client.start_notify(char_uuid, notification_handler)
                logger.info("📊 Aguardando medição... (3 minutos)")
                logger.info("   → Faça a medição normalmente no aparelho")
                logger.info("   → Após medir, APERTE O BOTÃO BLUETOOTH no Omron para sincronizar")
                
                # Loop de 3 minutos - tempo suficiente para medição completa (~50s)
                for i in range(180):  # 3 minutos
                    if not client.is_connected:
                        logger.warning("❌ Conexão perdida!")
                        break
                    
                    # Se recebeu alguma medição, aguarda mais 3 segundos para coletar todas
                    if pressao_recebida.is_set():
                        if ultima_notificacao[0]:
                            tempo_desde_ultima = asyncio.get_event_loop().time() - ultima_notificacao[0]
                            if tempo_desde_ultima >= 3.0:  # 3s sem novas notificações
                                logger.info(f"📦 Recebidas {len(todas_medicoes)} medição(ões) da memória")
                                break
                    await asyncio.sleep(1)
                
                # Seleciona a medição MAIS RECENTE pelo timestamp
                if todas_medicoes:
                    # Filtra medições com timestamp válido
                    com_timestamp = [m for m in todas_medicoes if m.get('timestamp')]
                    
                    if com_timestamp:
                        # Ordena por timestamp (mais recente primeiro)
                        com_timestamp.sort(key=lambda x: x['timestamp'], reverse=True)
                        dados_pressao = com_timestamp[0]
                        logger.info(f"✅ Selecionada medição mais recente: {dados_pressao['timestamp']}")
                    else:
                        # Sem timestamp, pega a última recebida
                        dados_pressao = todas_medicoes[-1]
                        logger.info(f"⚠️ Sem timestamps, usando última medição recebida")
                    
                    pulse_info = f", Pulso: {dados_pressao['pulse']} bpm" if 'pulse' in dados_pressao else ""
                    logger.info(f"💓 PRESSÃO FINAL: {dados_pressao['systolic']}/{dados_pressao['diastolic']} mmHg{pulse_info}")
                    
                    # Remove timestamp antes de enviar (não é necessário no backend)
                    envio = {k: v for k, v in dados_pressao.items() if k != 'timestamp'}
                    await enviar_leitura("blood_pressure", envio)
                    state.omron_last_attempt = None  # Reseta cooldown após sucesso
                    return envio
                else:
                    logger.warning("⏱️ Timeout - nenhuma medição recebida")
                    logger.info(f"⏳ Aguardando {state.omron_cooldown}s antes de tentar novamente...")
                
                if client.is_connected:
                    try:
                        await client.stop_notify(char_uuid)
                    except:
                        pass
                
    except Exception as e:
        logger.error(f"❌ Erro Omron: {e}")
        logger.info(f"⏳ Aguardando {state.omron_cooldown}s antes de tentar novamente...")
    finally:
        state.omron_connecting = False
        # Reiniciar o scanner com retry
        if scanner_parado:
            for attempt in range(3):
                try:
                    await asyncio.sleep(0.5)  # Aguarda estado estabilizar
                    state.scanner = BleakScanner(detection_callback)
                    await state.scanner.start()
                    logger.info("🔊 Scanner reiniciado")
                    break
                except Exception as e:
                    logger.warning(f"⚠️ Tentativa {attempt+1}/3 de reiniciar scanner: {e}")
                    await asyncio.sleep(1)
    
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
    
    # IMPORTANTE: Parar o scanner durante conexão GATT
    scanner_parado = False
    if state.scanner:
        try:
            await state.scanner.stop()
            scanner_parado = True
            logger.info("🔇 Scanner pausado para conexão GATT")
            await asyncio.sleep(0.5)
        except Exception as e:
            logger.warning(f"⚠️ Erro ao pausar scanner: {e}")
    
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
        # Reiniciar o scanner com retry
        if scanner_parado:
            for attempt in range(3):
                try:
                    await asyncio.sleep(0.5)
                    state.scanner = BleakScanner(detection_callback)
                    await state.scanner.start()
                    logger.info("🔊 Scanner reiniciado")
                    break
                except Exception as e:
                    logger.warning(f"⚠️ Tentativa {attempt+1}/3 de reiniciar scanner: {e}")
                    await asyncio.sleep(1)
    
    return None


# === CONEXÃO EKO CORE 500 (ESTETOSCÓPIO) ===

# Tabelas IMA ADPCM para decodificação
EKO_STEP_TABLE = [
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
    157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
    724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024,
    3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
]
EKO_INDEX_TABLE = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]


def decode_ima_adpcm(data: bytes) -> list:
    """Decodifica IMA ADPCM para PCM 16-bit"""
    samples = []
    predictor = 0
    step_index = 0
    
    for byte in data:
        for nibble in [byte & 0x0F, (byte >> 4) & 0x0F]:
            step = EKO_STEP_TABLE[step_index]
            diff = step >> 3
            if nibble & 1:
                diff += step >> 2
            if nibble & 2:
                diff += step >> 1
            if nibble & 4:
                diff += step
            if nibble & 8:
                predictor -= diff
            else:
                predictor += diff
            predictor = max(-32768, min(32767, predictor))
            samples.append(predictor)
            step_index += EKO_INDEX_TABLE[nibble]
            step_index = max(0, min(88, step_index))
    
    return samples


def analyze_heartbeat(samples: list, sample_rate: int = 8000) -> dict:
    """Analisa sinal para detectar frequência cardíaca"""
    import numpy as np
    
    samples_float = np.array(samples, dtype=float)
    samples_float = samples_float - np.mean(samples_float)
    
    if np.max(np.abs(samples_float)) > 0:
        samples_float = samples_float / np.max(np.abs(samples_float))
    
    envelope = np.abs(samples_float)
    window_size = int(sample_rate * 0.05)
    if window_size > 0 and len(envelope) > window_size:
        envelope = np.convolve(envelope, np.ones(window_size)/window_size, mode='same')
    
    threshold = np.mean(envelope) + 0.5 * np.std(envelope)
    peaks = []
    in_peak = False
    peak_start = 0
    
    for i, val in enumerate(envelope):
        if val > threshold and not in_peak:
            in_peak = True
            peak_start = i
        elif val < threshold and in_peak:
            in_peak = False
            peaks.append((peak_start + i) // 2)
    
    if len(peaks) > 1:
        intervals = np.diff(peaks) / sample_rate
        valid = intervals[(intervals > 0.3) & (intervals < 2.0)]
        if len(valid) > 0:
            return {"heartRate": round(60 / np.mean(valid))}
    
    return {"heartRate": None}


async def capturar_fonocardiograma(duration: int = 15) -> dict:
    """Captura fonocardiograma do Eko CORE 500"""
    if state.eko_capturing:
        logger.warning("⚠️ Captura Eko já em andamento")
        return None
    
    state.eko_capturing = True
    state.eko_audio_buffer = bytearray()
    state.eko_packet_count = 0
    
    device_info = DEVICES.get("88:D2:11:C8:20:31")
    mac = "88:D2:11:C8:20:31"
    char_uuid = device_info["char_uuid"]
    
    logger.info(f"🩺 Iniciando captura do {device_info['name']} ({duration}s)...")
    
    def notification_handler(sender, data):
        state.eko_audio_buffer.extend(data)
        state.eko_packet_count += 1
        if state.eko_packet_count % 50 == 0:
            logger.debug(f"📦 {state.eko_packet_count} pacotes ({len(state.eko_audio_buffer)} bytes)")
    
    try:
        logger.info(f"🔗 Conectando ao Eko ({mac})...")
        async with BleakClient(mac, timeout=30.0) as client:
            if client.is_connected:
                logger.info(f"✅ Conectado ao Eko CORE 500")
                
                await client.start_notify(char_uuid, notification_handler)
                logger.info(f"🎵 Notify ativado - capturando por {duration}s...")
                
                # Captura por N segundos
                for i in range(duration):
                    await asyncio.sleep(1)
                    if i % 5 == 0:
                        logger.info(f"⏱️ {duration - i}s restantes... ({state.eko_packet_count} pacotes)")
                
                await client.stop_notify(char_uuid)
                
                logger.info(f"🛑 Captura finalizada: {state.eko_packet_count} pacotes, {len(state.eko_audio_buffer)} bytes")
                
                if len(state.eko_audio_buffer) > 0:
                    # Remove headers dos pacotes (1 byte por pacote de 238 bytes)
                    raw_data = bytes(state.eko_audio_buffer)
                    packet_size = 238
                    num_packets = len(raw_data) // packet_size
                    
                    clean_data = bytearray()
                    for i in range(num_packets):
                        packet = raw_data[i * packet_size : (i + 1) * packet_size]
                        clean_data.extend(packet[1:])  # Skip header
                    
                    # Decodifica IMA ADPCM
                    samples = decode_ima_adpcm(bytes(clean_data))
                    
                    # Analisa frequência cardíaca
                    analysis = analyze_heartbeat(samples)
                    
                    # Converte para base64 para envio
                    import base64
                    import struct as st
                    pcm_bytes = st.pack(f'<{len(samples)}h', *samples)
                    audio_base64 = base64.b64encode(pcm_bytes).decode('utf-8')
                    
                    resultado = {
                        "audioBase64": audio_base64,
                        "sampleRate": device_info["sample_rate"],
                        "durationSeconds": len(samples) / device_info["sample_rate"],
                        "heartRate": analysis.get("heartRate"),
                        "format": "pcm_s16le"
                    }
                    
                    if analysis.get("heartRate"):
                        logger.info(f"❤️ Frequência cardíaca: {analysis['heartRate']} BPM")
                    
                    return resultado
                    
    except Exception as e:
        logger.error(f"❌ Erro Eko: {e}")
    finally:
        state.eko_capturing = False
    
    return None


async def enviar_fonocardiograma():
    """Captura e envia fonocardiograma para o backend"""
    resultado = await capturar_fonocardiograma()
    
    if resultado:
        appointment_id = await detect_active_appointment()
        
        if not appointment_id:
            logger.warning("⚠️ Nenhuma consulta ativa - fonocardiograma não enviado")
            return False
        
        payload = {
            "appointmentId": appointment_id,
            "deviceType": "stethoscope",
            "timestamp": datetime.now().isoformat(),
            "values": {
                "heartRate": resultado.get("heartRate")
            },
            "audioData": resultado.get("audioBase64"),
            "sampleRate": resultado.get("sampleRate"),
            "format": resultado.get("format")
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{API_URL}/biometrics/phonocardiogram"
                async with session.post(url, json=payload) as resp:
                    if resp.status == 200:
                        logger.info(f"✅ Fonocardiograma enviado → Médico pode ouvir!")
                        return True
                    else:
                        text = await resp.text()
                        logger.error(f"❌ Erro: {resp.status} - {text}")
        except Exception as e:
            logger.error(f"❌ Erro de conexão: {e}")
    
    return False


async def conectar_eko():
    """Conecta ao Eko e inicia captura de fonocardiograma"""
    if state.eko_connecting or state.eko_capturing:
        return None
    
    state.eko_connecting = True
    try:
        resultado = await enviar_fonocardiograma()
        return resultado
    except Exception as e:
        logger.error(f"❌ Erro ao capturar Eko: {e}")
        return None
    finally:
        state.eko_connecting = False
        state.eko_capturing = False


# === SCANNER BLE ===

async def safe_task(coro, name: str):
    """Executa uma coroutine com tratamento de exceção"""
    try:
        await coro
    except Exception as e:
        logger.error(f"❌ Erro em {name}: {e}")

def detection_callback(device, advertisement_data):
    """Callback para dispositivos BLE detectados"""
    mac = device.address.upper()
    
    if mac == "F8:8F:C8:3A:B7:92":
        for _, data in advertisement_data.manufacturer_data.items():
            resultado = processar_balanca(data)
            if resultado:
                asyncio.create_task(safe_task(enviar_leitura("scale", resultado), "balança"))
    
    elif mac == "00:5F:BF:9A:64:DF" and not state.omron_connecting:
        logger.info(f"📡 Omron detectado!")
        asyncio.create_task(safe_task(conectar_omron(), "omron"))
    
    elif mac == "DC:23:4E:DA:E9:DD" and not state.thermometer_connecting:
        logger.info(f"🌡️ Termômetro MOBI detectado!")
        asyncio.create_task(safe_task(conectar_termometro(), "termômetro"))
    
    elif mac == "88:D2:11:C8:20:31" and not state.eko_connecting and not state.eko_capturing:
        # Eko CORE 500 - estetoscópio digital
        # Verifica cooldown (60s entre capturas)
        now = datetime.now()
        if state.eko_last_capture and (now - state.eko_last_capture).total_seconds() < state.eko_cooldown:
            return  # Ainda em cooldown, ignora
        
        # Só captura se houver consulta ativa
        if not state.current_appointment_id:
            return  # Sem consulta ativa, ignora
            
        # Captura automática quando detectado (15s de áudio)
        logger.info(f"🩺 Eko CORE 500 detectado!")
        state.eko_last_capture = now
        asyncio.create_task(safe_task(conectar_eko(), "eko"))


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
    
    # Cria scanner com retry em caso de erro de estado
    scanner = None
    for attempt in range(3):
        try:
            scanner = BleakScanner(detection_callback)
            state.scanner = scanner
            await scanner.start()
            break
        except Exception as e:
            logger.warning(f"⚠️ Erro ao iniciar scanner (tentativa {attempt+1}/3): {e}")
            await asyncio.sleep(2)
            if attempt == 2:
                raise
    
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
    # Determina ambiente para exibição
    if args.local:
        ambiente = "🧪 HOMOLOGAÇÃO (localhost:5239)"
    elif args.url:
        ambiente = f"🔧 CUSTOMIZADO ({args.url})"
    else:
        ambiente = "🌐 PRODUÇÃO (telecuidar.com.br)"
    
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚐 TELECUIDAR - MALETA ITINERANTE DE TELEMEDICINA          ║
║                                                              ║
║   Este serviço detecta AUTOMATICAMENTE qual paciente         ║
║   está em teleconsulta e envia os dados dos dispositivos.    ║
║                                                              ║
║   O técnico NÃO precisa configurar nada entre pacientes!     ║
║                                                              ║
║   Ambiente: {ambiente:<47} ║
║   API: {API_URL:<52} ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

   Uso: python maleta_itinerante.py [--local | --url URL]
        --local, -l     Usar localhost:5239 (homologação)
        --url, -u URL   Usar URL customizada
    """)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n👋 Serviço encerrado pelo usuário")
    except Exception as e:
        logger.error(f"❌ Erro fatal: {e}")
        import traceback
        traceback.print_exc()
        input("Pressione ENTER para fechar...")
