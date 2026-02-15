#!/usr/bin/env python3
"""
TeleCuidar - Gateway BLE para Tablet Android
=============================================

Script otimizado para rodar em tablet Android via Termux.
Captura sinais BLE dos dispositivos médicos e envia para o servidor.

REQUISITOS:
- Termux instalado pelo F-Droid (NÃO usar Play Store!)
- Python 3.8+ 
- Permissões: Bluetooth, Localização, Internet

INSTALAÇÃO (no Termux):
  pkg update && pkg upgrade -y
  pkg install python -y
  pip install bleak aiohttp

USO:
  python tablet_gateway.py              # Produção
  python tablet_gateway.py --local      # Homologação local
  python tablet_gateway.py --test       # Modo teste (simula dispositivos)
"""

from __future__ import annotations  # Compatibilidade Python 3.8+

import asyncio
import argparse
import json
import struct
import sys
import time
from datetime import datetime
from typing import Optional, Dict, Any

# Tenta importar bleak, com fallback para modo offline
try:
    from bleak import BleakScanner, BleakClient
    BLEAK_AVAILABLE = True
except ImportError:
    BLEAK_AVAILABLE = False
    print("[AVISO] bleak não instalado. Execute: pip install bleak")

try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False
    print("[AVISO] aiohttp não instalado. Execute: pip install aiohttp")


# ============ CONFIGURAÇÃO ============

# URLs do servidor
URL_PROD = "https://www.telecuidar.com.br"
URL_LOCAL = "http://localhost:5239"

# Dispositivos médicos conhecidos (MAC -> configuração)
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
        "service_uuid": "00001809-0000-1000-8000-00805f9b34fb",
        "char_uuid": "00002a1c-0000-1000-8000-00805f9b34fb"
    }
}

# Prefixos para descoberta automática de dispositivos
DEVICE_PREFIXES = {
    "BLESmart_": "blood_pressure",  # Omron
    "OKOK": "scale",
    "QN-Scale": "scale",
    "MOBI": "thermometer",
    "Eko": "stethoscope"
}


# ============ ESTADO GLOBAL ============

class GatewayState:
    def __init__(self):
        self.base_url = URL_PROD
        self.appointment_id = None
        self.last_appointment_check = 0
        self.check_interval = 3  # segundos
        
        # Estado da balança (confirma peso estável)
        self.scale_value = 0
        self.scale_count = 0
        self.scale_confirmed = False
        
        # Controle de cooldown para evitar spam
        self.last_readings = {}  # device_type -> timestamp
        self.cooldown_seconds = 10  # Entre leituras do mesmo tipo
        
        # Estatísticas
        self.stats = {
            "detected": 0,
            "sent": 0,
            "errors": 0,
            "start_time": time.time()
        }

state = GatewayState()


# ============ FUNÇÕES AUXILIARES ============

def log(msg: str, level: str = "INFO"):
    """Log com timestamp"""
    ts = datetime.now().strftime("%H:%M:%S")
    icons = {"INFO": "ℹ️", "OK": "✅", "WARN": "⚠️", "ERR": "❌", "BLE": "📶"}
    icon = icons.get(level, "•")
    print(f"[{ts}] {icon} {msg}")


def sfloat_to_float(raw: int) -> float:
    """Converte IEEE 11073 SFLOAT para float"""
    if raw in (0x07FF, 0x0800):
        return float('nan')
    if raw == 0x07FE:
        return float('inf')
    if raw == 0x0802:
        return float('-inf')
    
    mantissa = raw & 0x0FFF
    if mantissa >= 0x0800:
        mantissa -= 0x1000
    exponent = (raw >> 12) & 0x0F
    if exponent >= 0x08:
        exponent -= 0x10
    return mantissa * (10 ** exponent)


def parse_blood_pressure(data: bytes) -> Optional[Dict]:
    """Parse Blood Pressure Measurement (BLE standard)"""
    if len(data) < 7:
        return None
    
    flags = data[0]
    offset = 1
    
    sys_raw = struct.unpack_from('<H', data, offset)[0]
    dia_raw = struct.unpack_from('<H', data, offset + 2)[0]
    
    result = {
        "systolic": round(sfloat_to_float(sys_raw)),
        "diastolic": round(sfloat_to_float(dia_raw))
    }
    
    offset = 7
    
    # Timestamp (flag 0x02)
    if flags & 0x02 and len(data) >= offset + 7:
        offset += 7
    
    # Pulse rate (flag 0x04)
    if flags & 0x04 and len(data) >= offset + 2:
        pulse_raw = struct.unpack_from('<H', data, offset)[0]
        result["heartRate"] = round(sfloat_to_float(pulse_raw))
    
    return result


def parse_scale_advertisement(manufacturer_data: Dict) -> Optional[Dict]:
    """Parse dados do advertisement da balança OKOK"""
    for data in manufacturer_data.values():
        if not data or len(data) < 2:
            continue
        
        raw = (data[0] << 8) | data[1]
        if raw == 0:
            # Balança zerada - reset estado
            if state.scale_confirmed:
                log("Balança zerada - pronto para próxima medição", "INFO")
            state.scale_value = 0
            state.scale_count = 0
            state.scale_confirmed = False
            return None
        
        peso = round(raw / 100, 2)
        
        if raw == state.scale_value:
            state.scale_count += 1
        else:
            state.scale_value = raw
            state.scale_count = 1
            state.scale_confirmed = False
        
        # Confirma peso após 5 leituras iguais
        if state.scale_count >= 5 and not state.scale_confirmed:
            state.scale_confirmed = True
            log(f"PESO CONFIRMADO: {peso} kg", "OK")
            return {"weight": peso}
    
    return None


def parse_temperature(data: bytes) -> Optional[Dict]:
    """Parse Health Thermometer Measurement (IEEE 11073)"""
    if len(data) < 5:
        return None
    
    flags = data[0]
    
    # IEEE 11073 FLOAT: mantissa (3 bytes) + exponent (1 byte)
    mantissa = data[1] | (data[2] << 8) | (data[3] << 16)
    if mantissa >= 0x800000:
        mantissa -= 0x1000000
    exponent = data[4]
    if exponent >= 0x80:
        exponent -= 0x100
    
    temp = mantissa * (10 ** exponent)
    
    # Converte se Fahrenheit
    if flags & 0x01:
        temp = (temp - 32) * 5 / 9
    
    temp = round(temp, 1)
    
    # Valida range humano
    if 32.0 <= temp <= 43.0:
        return {"temperature": temp}
    
    return None


# ============ API ============

async def get_active_appointment() -> Optional[str]:
    """Busca consulta ativa no servidor"""
    if not AIOHTTP_AVAILABLE:
        return None
    
    now = time.time()
    if state.appointment_id and (now - state.last_appointment_check) < state.check_interval:
        return state.appointment_id
    
    state.last_appointment_check = now
    
    try:
        url = f"{state.base_url}/api/biometrics/active-appointment"
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    if isinstance(data, dict) and data.get("id"):
                        if data["id"] != state.appointment_id:
                            log(f"Consulta ativa: {data['id'][:8]}...", "OK")
                        state.appointment_id = data["id"]
                        return state.appointment_id
    except Exception as e:
        pass
    
    return state.appointment_id


async def send_reading(device_type: str, values: Dict) -> bool:
    """Envia leitura para o servidor"""
    if not AIOHTTP_AVAILABLE:
        log(f"Simulado: {device_type} = {values}", "WARN")
        return True
    
    appointment_id = await get_active_appointment()
    if not appointment_id:
        log("Nenhuma consulta ativa - aguardando...", "WARN")
        return False
    
    # Verifica cooldown
    last = state.last_readings.get(device_type, 0)
    if time.time() - last < state.cooldown_seconds:
        return False
    
    payload = {
        "appointmentId": appointment_id,
        "deviceType": device_type,
        "values": values,
        "timestamp": datetime.now().isoformat()
    }
    
    try:
        url = f"{state.base_url}/api/biometrics/ble-reading"
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=10)) as resp:
                if resp.status in (200, 201):
                    state.last_readings[device_type] = time.time()
                    state.stats["sent"] += 1
                    log(f"Enviado: {device_type} = {values}", "OK")
                    return True
                else:
                    state.stats["errors"] += 1
                    log(f"Erro HTTP {resp.status}", "ERR")
    except Exception as e:
        state.stats["errors"] += 1
        log(f"Erro ao enviar: {e}", "ERR")
    
    return False


# ============ BLE SCANNER ============

def identify_device(address: str, name: str) -> Optional[Dict]:
    """Identifica dispositivo por MAC ou nome"""
    address = address.upper()
    
    # Primeiro tenta MAC conhecido
    if address in DEVICES:
        return DEVICES[address]
    
    # Depois tenta prefixo do nome
    if name:
        for prefix, device_type in DEVICE_PREFIXES.items():
            if name.startswith(prefix):
                return {"type": device_type, "name": name, "method": "advertisement"}
    
    return None


async def handle_device_detection(device, advertisement_data):
    """Callback para dispositivo BLE detectado"""
    state.stats["detected"] += 1
    
    address = device.address.upper()
    name = device.name or advertisement_data.local_name or ""
    
    device_info = identify_device(address, name)
    if not device_info:
        return
    
    device_type = device_info["type"]
    method = device_info.get("method", "advertisement")
    
    values = None
    
    if device_type == "scale":
        # Balança envia dados via manufacturer_data
        values = parse_scale_advertisement(dict(advertisement_data.manufacturer_data or {}))
    
    elif device_type == "blood_pressure" and method == "gatt":
        # Omron precisa de conexão GATT
        try:
            async with BleakClient(device) as client:
                if client.is_connected:
                    char_uuid = device_info.get("char_uuid")
                    if char_uuid:
                        data = await client.read_gatt_char(char_uuid)
                        values = parse_blood_pressure(data)
        except Exception as e:
            log(f"Erro GATT {name}: {e}", "ERR")
    
    elif device_type == "thermometer" and method == "gatt":
        # Termômetro também precisa de conexão GATT
        try:
            async with BleakClient(device) as client:
                if client.is_connected:
                    char_uuid = device_info.get("char_uuid")
                    if char_uuid:
                        data = await client.read_gatt_char(char_uuid)
                        values = parse_temperature(data)
        except Exception as e:
            log(f"Erro GATT {name}: {e}", "ERR")
    
    if values:
        await send_reading(device_type, values)


async def run_scanner():
    """Loop principal do scanner BLE"""
    if not BLEAK_AVAILABLE:
        log("bleak não disponível - modo offline", "ERR")
        return
    
    log("Iniciando scanner BLE...", "INFO")
    log(f"Servidor: {state.base_url}", "INFO")
    log(f"Dispositivos configurados: {len(DEVICES)}", "INFO")
    
    scanner = BleakScanner(detection_callback=handle_device_detection)
    
    try:
        await scanner.start()
        log("Scanner BLE ativo - aguardando dispositivos...", "OK")
        
        while True:
            await asyncio.sleep(10)
            
            # Log de status
            uptime = int(time.time() - state.stats["start_time"])
            appt = state.appointment_id[:8] + "..." if state.appointment_id else "nenhuma"
            log(f"Status: up={uptime}s det={state.stats['detected']} sent={state.stats['sent']} err={state.stats['errors']} consulta={appt}", "INFO")
    
    except KeyboardInterrupt:
        log("Encerrando...", "INFO")
    finally:
        await scanner.stop()


# ============ MODO TESTE ============

async def run_test_mode():
    """Modo teste - simula dispositivos para validar API"""
    log("=== MODO TESTE ===", "INFO")
    log(f"Servidor: {state.base_url}", "INFO")
    
    # Testa conexão com servidor
    appointment = await get_active_appointment()
    if not appointment:
        log("Nenhuma consulta ativa encontrada!", "ERR")
        log("Inicie uma teleconsulta no navegador primeiro.", "INFO")
        return
    
    log(f"Consulta ativa: {appointment}", "OK")
    
    # Simula leituras
    test_readings = [
        ("scale", {"weight": 72.5}),
        ("blood_pressure", {"systolic": 120, "diastolic": 80, "heartRate": 72}),
        ("thermometer", {"temperature": 36.5})
    ]
    
    for device_type, values in test_readings:
        log(f"Simulando {device_type}: {values}", "INFO")
        success = await send_reading(device_type, values)
        if success:
            log(f"{device_type} enviado com sucesso!", "OK")
        else:
            log(f"Falha ao enviar {device_type}", "ERR")
        await asyncio.sleep(2)
    
    log("=== TESTE CONCLUÍDO ===", "INFO")


# ============ MAIN ============

def main():
    parser = argparse.ArgumentParser(
        description="TeleCuidar - Gateway BLE para Tablet Android",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  python tablet_gateway.py              # Produção (telecuidar.com.br)
  python tablet_gateway.py --local      # Homologação (localhost:5239)
  python tablet_gateway.py --test       # Modo teste (simula dispositivos)
  python tablet_gateway.py --url http://192.168.1.100:5239  # URL custom
        """
    )
    parser.add_argument("--local", "-l", action="store_true", help="Usar localhost:5239")
    parser.add_argument("--url", "-u", type=str, help="URL customizada")
    parser.add_argument("--test", "-t", action="store_true", help="Modo teste (simula dispositivos)")
    
    args = parser.parse_args()
    
    # Configura URL
    if args.url:
        state.base_url = args.url.rstrip('/')
    elif args.local:
        state.base_url = URL_LOCAL
    else:
        state.base_url = URL_PROD
    
    print()
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║           TELECUIDAR - GATEWAY BLE TABLET                    ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print()
    
    if args.test:
        asyncio.run(run_test_mode())
    else:
        asyncio.run(run_scanner())


if __name__ == "__main__":
    main()
