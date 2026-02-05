"""
BLE Bridge - Ponte entre dispositivos Bluetooth e TeleCuidar
Escuta automaticamente dispositivos médicos e envia dados para o backend

DISPOSITIVOS SUPORTADOS:
- Balança OKOK: Escuta via BLE Advertisement (automático)
- Omron HEM-7156T: Conecta via GATT quando detectado (automático)

USO:
  python ble_bridge.py --prod          # Produção (detecta consulta automaticamente)
  python ble_bridge.py                  # Local (detecta consulta automaticamente)
  python ble_bridge.py ID --prod        # Com ID específico

O sistema fica escutando continuamente. Quando:
- Balança: Detecta peso estável automaticamente
- Omron: Conecta quando o aparelho é ligado e envia a medição

Os dados são enviados para o backend e distribuídos via SignalR para
a tela de Sinais Vitais do paciente e do médico.
"""
import asyncio
import aiohttp
import struct
import sys
from bleak import BleakScanner, BleakClient
from datetime import datetime
import argparse

# === CONFIGURAÇÃO ===
BACKEND_URL_LOCAL = "http://localhost:5239/api/biometrics/ble-reading"
BACKEND_URL_PROD = "https://www.telecuidar.com.br/api/biometrics/ble-reading"
ACTIVE_APPOINTMENT_LOCAL = "http://localhost:5239/api/biometrics/active-appointment"
ACTIVE_APPOINTMENT_PROD = "https://www.telecuidar.com.br/api/biometrics/active-appointment"
BACKEND_URL = BACKEND_URL_LOCAL  # Será alterado se --prod
ACTIVE_APPOINTMENT_URL = ACTIVE_APPOINTMENT_LOCAL
APPOINTMENT_ID = None  # Definido via argumento ou buscado automaticamente

# Dispositivos conhecidos
DEVICES = {
    "scale": {
        "mac": "F8:8F:C8:3A:B7:92",
        "name": "Balança OKOK",
        "method": "advertisement"
    },
    "blood_pressure": {
        "mac": "00:5F:BF:9A:64:DF",
        "name": "Omron HEM-7156T",
        "method": "gatt",
        "service_uuid": "00001810-0000-1000-8000-00805f9b34fb",
        "char_uuid": "00002a35-0000-1000-8000-00805f9b34fb"
    }
}

# Estado da balança
estado_balanca = {
    "valor": 0, 
    "contador": 0, 
    "confirmado": False
}

# Controle de conexão do Omron
omron_conectando = False
omron_ultima_leitura = None


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
    
    # Valores de pressão (SFLOAT - 2 bytes cada)
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
    
    # Verifica se tem pulso (bit 2 do flags)
    if flags & 0x04 and len(data) >= offset + 2:
        # Pula timestamp se presente (bit 1)
        if flags & 0x02:
            offset += 7
        if len(data) >= offset + 2:
            pulse = sfloat_to_float(struct.unpack_from('<H', data, offset)[0])
            resultado["pulse"] = round(pulse)
    
    return resultado


async def enviar_leitura(tipo: str, valores: dict):
    """Envia leitura para o backend TeleCuidar"""
    global APPOINTMENT_ID
    
    # Se não tem ID, tenta buscar automaticamente
    if not APPOINTMENT_ID:
        APPOINTMENT_ID = await buscar_consulta_ativa()
    
    if not APPOINTMENT_ID:
        print(f"⚠️  Sem consulta ativa - dados NÃO enviados ao backend")
        print(f"    Certifique-se que há uma consulta 'Em Andamento' no sistema")
        return False
        
    payload = {
        "appointmentId": APPOINTMENT_ID,
        "deviceType": tipo,
        "timestamp": datetime.now().isoformat(),
        "values": valores
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(BACKEND_URL, json=payload) as resp:
                if resp.status == 200:
                    print(f"✅ Enviado para TeleCuidar via SignalR!")
                    return True
                else:
                    text = await resp.text()
                    print(f"❌ Erro ao enviar: {resp.status} - {text}")
                    return False
    except Exception as e:
        print(f"❌ Erro de conexão com backend: {e}")
        return False


async def buscar_consulta_ativa():
    """Busca consulta ativa automaticamente no backend"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(ACTIVE_APPOINTMENT_URL) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    appointment_id = data.get('id')
                    if appointment_id:
                        print(f"🔍 Consulta ativa encontrada: {appointment_id}")
                        return appointment_id
                elif resp.status == 404:
                    print("⚠️  Nenhuma consulta ativa no momento")
                else:
                    print(f"⚠️  Erro ao buscar consulta: {resp.status}")
    except Exception as e:
        print(f"❌ Erro ao buscar consulta ativa: {e}")
    return None


def processar_balanca(data: bytes):
    """Processa dados da balança OKOK"""
    global estado_balanca
    
    if len(data) < 2:
        return None
    
    raw = (data[0] << 8) | data[1]
    peso = round(raw / 100, 2)
    
    # Se zerou, reseta
    if raw == 0:
        if estado_balanca["confirmado"]:
            print("🔄 Balança zerada - pronto para nova medição\n")
        estado_balanca = {"valor": 0, "contador": 0, "confirmado": False}
        return None
    
    # Mostra em tempo real
    print(f"⚖️  {peso} kg", end="\r")
    
    # Conta estabilidade
    if raw == estado_balanca["valor"]:
        estado_balanca["contador"] += 1
    else:
        estado_balanca["valor"] = raw
        estado_balanca["contador"] = 1
        estado_balanca["confirmado"] = False
    
    # Confirma após 5 leituras iguais
    if estado_balanca["contador"] >= 5 and not estado_balanca["confirmado"]:
        estado_balanca["confirmado"] = True
        print(f"\n{'='*40}")
        print(f"⚖️  PESO CONFIRMADO: {peso} kg")
        print(f"{'='*40}\n")
        return {"weight": peso}
    
    return None


async def conectar_omron():
    """Conecta ao Omron e lê medição de pressão via GATT"""
    global omron_conectando, omron_ultima_leitura
    
    if omron_conectando:
        return None
    
    omron_conectando = True
    device = DEVICES["blood_pressure"]
    mac = device["mac"]
    char_uuid = device["char_uuid"]
    
    print(f"\n🔗 Conectando ao {device['name']}...")
    
    dados_pressao = None
    pressao_recebida = asyncio.Event()
    
    def notification_handler(sender, data):
        """Callback quando recebe notification do Omron"""
        nonlocal dados_pressao
        resultado = processar_pressao(data)
        if resultado:
            dados_pressao = resultado
            pressao_recebida.set()
    
    try:
        async with BleakClient(mac, timeout=15.0) as client:
            if client.is_connected:
                print(f"✅ Conectado ao {device['name']}")
                print("📊 Aguardando medição do aparelho...")
                
                # Ativa notificações
                await client.start_notify(char_uuid, notification_handler)
                
                # Aguarda dados por até 60 segundos
                try:
                    await asyncio.wait_for(pressao_recebida.wait(), timeout=60.0)
                    
                    if dados_pressao:
                        print(f"\n{'='*40}")
                        print(f"💓 PRESSÃO ARTERIAL:")
                        print(f"   Sistólica:  {dados_pressao['systolic']} mmHg")
                        print(f"   Diastólica: {dados_pressao['diastolic']} mmHg")
                        if 'pulse' in dados_pressao:
                            print(f"   Pulso:      {dados_pressao['pulse']} bpm")
                        print(f"{'='*40}\n")
                        
                        await enviar_leitura("blood_pressure", dados_pressao)
                        omron_ultima_leitura = datetime.now()
                        return dados_pressao
                        
                except asyncio.TimeoutError:
                    print("\n⏱️  Timeout - nenhuma medição recebida")
                
                await client.stop_notify(char_uuid)
                
    except Exception as e:
        print(f"❌ Erro ao conectar ao Omron: {e}")
    finally:
        omron_conectando = False
    
    return None


def detection_callback(device, advertisement_data):
    """Callback para dispositivos detectados via BLE scan"""
    mac = device.address.upper()
    scale_mac = DEVICES["scale"]["mac"].upper()
    omron_mac = DEVICES["blood_pressure"]["mac"].upper()
    
    # Processa balança via advertisement
    if mac == scale_mac:
        for _, data in advertisement_data.manufacturer_data.items():
            resultado = processar_balanca(data)
            if resultado:
                asyncio.create_task(enviar_leitura("scale", resultado))
    
    # Detecta Omron e tenta conectar
    elif mac == omron_mac and not omron_conectando:
        # Omron detectado - tenta conectar
        print(f"\n📡 Omron detectado! Tentando conectar...")
        asyncio.create_task(conectar_omron())


async def main():
    global APPOINTMENT_ID, BACKEND_URL, ACTIVE_APPOINTMENT_URL
    
    # Parse argumentos
    parser = argparse.ArgumentParser(description='BLE Bridge - TeleCuidar')
    parser.add_argument('appointment_id', nargs='?', help='ID da consulta (opcional - busca automaticamente)')
    parser.add_argument('--prod', action='store_true', help='Usar servidor de produção')
    args = parser.parse_args()
    
    if args.prod:
        BACKEND_URL = BACKEND_URL_PROD
        ACTIVE_APPOINTMENT_URL = ACTIVE_APPOINTMENT_PROD
        print("\n🌐 MODO PRODUÇÃO: telecuidar.com.br")
    else:
        BACKEND_URL = BACKEND_URL_LOCAL
        ACTIVE_APPOINTMENT_URL = ACTIVE_APPOINTMENT_LOCAL
        print("\n🏠 MODO LOCAL: localhost:5239")
    
    print("=" * 50)
    print("   🏥 BLE BRIDGE - TeleCuidar (AUTOMÁTICO)")
    print("=" * 50)
    
    # Pega appointment_id 
    if args.appointment_id:
        APPOINTMENT_ID = args.appointment_id
        print(f"\n📡 Consulta fixa: {APPOINTMENT_ID}")
    else:
        print("\n🔍 Buscando consulta ativa automaticamente...")
        APPOINTMENT_ID = await buscar_consulta_ativa()
        if not APPOINTMENT_ID:
            print("⚠️  Nenhuma consulta ativa encontrada.")
            print("   O script vai continuar escutando e tentará novamente")
            print("   quando um dispositivo for detectado.")
    
    print("\nDispositivos monitorados:")
    for key, device in DEVICES.items():
        print(f"  • {device['name']} ({device['mac']})")
    
    print("\n" + "-" * 50)
    print("🔊 ESCUTANDO DISPOSITIVOS...")
    print("   - Suba na balança para medir peso")
    print("   - Ligue o Omron e faça a medição de pressão")
    print("-" * 50)
    print("\nPressione Ctrl+C para sair\n")
    
    scanner = BleakScanner(detection_callback)
    await scanner.start()
    
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        print("\n\n👋 Encerrando BLE Bridge...")
    finally:
        await scanner.stop()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n👋 Encerrado pelo usuário")
