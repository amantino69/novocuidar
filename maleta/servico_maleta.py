"""
Serviço Maleta TeleCuidar - AUTOMÁTICO
======================================

Este script roda automaticamente com o Windows e:
1. Detecta consultas ativas automaticamente
2. Monitora dispositivos BLE (balança, pressão, etc)
3. Envia dados em tempo real para o TeleCuidar

INSTALAÇÃO:
  python servico_maleta.py --install

EXECUÇÃO MANUAL:
  python servico_maleta.py [--local]

O script roda em loop infinito, verificando a cada 5 segundos
se há consulta ativa para enviar os dados.
"""

import asyncio
import aiohttp
import struct
import sys
import os
import time
from datetime import datetime
from pathlib import Path
import argparse
import ctypes

# Tenta importar bleak (BLE)
try:
    from bleak import BleakScanner, BleakClient
    BLE_DISPONIVEL = True
except ImportError:
    BLE_DISPONIVEL = False
    print("⚠️  Bleak não instalado. Execute: pip install bleak")

# === CONFIGURAÇÃO ===
BASE_URL_LOCAL = "http://localhost:5239"
BASE_URL_PROD = "https://www.telecuidar.com.br"
BASE_URL = BASE_URL_PROD  # Default: produção

# Dispositivos conhecidos (MAC addresses)
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

# Estado global
appointment_id = None
estado_balanca = {"valor": 0, "contador": 0, "confirmado": False}
omron_conectando = False
ultima_verificacao_consulta = 0
INTERVALO_VERIFICACAO = 5  # segundos
scanner_global = None  # Referência ao scanner para pausar durante conexão GATT


def sfloat_to_float(raw: int) -> float:
    """Converte IEEE 11073 SFLOAT para float"""
    mantissa = raw & 0x0FFF
    if mantissa >= 0x0800:
        mantissa -= 0x1000
    exponent = (raw >> 12) & 0x0F
    if exponent >= 0x08:
        exponent -= 0x10
    return mantissa * (10 ** exponent)


async def buscar_consulta_ativa():
    """Busca consulta ativa no TeleCuidar"""
    global appointment_id
    url = f"{BASE_URL}/api/biometrics/active-appointment"
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=10) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    new_id = data.get('id')
                    if new_id and new_id != appointment_id:
                        appointment_id = new_id
                        print(f"\n🟢 CONSULTA ATIVA: {appointment_id[:8]}...")
                    return new_id
                elif resp.status == 404:
                    if appointment_id:
                        print("\n⚪ Consulta encerrada. Aguardando próxima...")
                    appointment_id = None
    except Exception as e:
        pass  # Silencia erros de conexão
    
    return appointment_id


async def enviar_leitura(tipo: str, valores: dict):
    """Envia leitura para o backend TeleCuidar"""
    global appointment_id, ultima_verificacao_consulta
    
    # Verifica consulta ativa se necessário
    agora = time.time()
    if agora - ultima_verificacao_consulta > INTERVALO_VERIFICACAO:
        await buscar_consulta_ativa()
        ultima_verificacao_consulta = agora
    
    if not appointment_id:
        print(f"⚠️  Sem consulta ativa - dados não enviados")
        return False
    
    url = f"{BASE_URL}/api/biometrics/ble-reading"
    payload = {
        "appointmentId": appointment_id,
        "deviceType": tipo,
        "timestamp": datetime.now().isoformat(),
        "values": valores
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                if resp.status == 200:
                    print(f"✅ Enviado para TeleCuidar!")
                    return True
                else:
                    text = await resp.text()
                    print(f"❌ Erro: {resp.status}")
                    return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False


def processar_balanca(data: bytes):
    """Processa dados da balança OKOK"""
    global estado_balanca
    
    if len(data) < 2:
        return None
    
    raw = (data[0] << 8) | data[1]
    peso = round(raw / 100, 2)
    
    if raw == 0:
        if estado_balanca["confirmado"]:
            print("\n🔄 Balança zerada - pronta para nova medição")
        estado_balanca = {"valor": 0, "contador": 0, "confirmado": False}
        return None
    
    print(f"⚖️  {peso} kg", end="\r")
    
    if raw == estado_balanca["valor"]:
        estado_balanca["contador"] += 1
    else:
        estado_balanca["valor"] = raw
        estado_balanca["contador"] = 1
        estado_balanca["confirmado"] = False
    
    if estado_balanca["contador"] >= 5 and not estado_balanca["confirmado"]:
        estado_balanca["confirmado"] = True
        print(f"\n{'='*50}")
        print(f"⚖️  PESO CONFIRMADO: {peso} kg")
        print(f"{'='*50}\n")
        return {"weight": peso}
    
    return None


def processar_pressao(data: bytes) -> dict:
    """Processa dados do Omron Blood Pressure"""
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
        "diastolic": round(diastolica)
    }
    
    if flags & 0x04 and len(data) >= offset + 2:
        if flags & 0x02:
            offset += 7
        if len(data) >= offset + 2:
            pulse = sfloat_to_float(struct.unpack_from('<H', data, offset)[0])
            resultado["heartRate"] = round(pulse)
    
    return resultado


async def conectar_omron():
    """Conecta ao Omron e lê medição de pressão"""
    global omron_conectando, scanner_global
    
    if omron_conectando:
        return None
    
    omron_conectando = True
    device = DEVICES["blood_pressure"]
    
    print(f"\n🔗 Conectando ao {device['name']}...")
    
    # IMPORTANTE: Parar o scanner durante conexão GATT
    # Isso evita conflitos no adapter Bluetooth
    scanner_parado = False
    if scanner_global:
        try:
            await scanner_global.stop()
            scanner_parado = True
            print("🔇 Scanner pausado para conexão GATT")
            await asyncio.sleep(0.5)  # Pequena pausa para liberar o adapter
        except Exception as e:
            print(f"⚠️  Erro ao pausar scanner: {e}")
    
    dados_pressao = None
    pressao_recebida = asyncio.Event()
    
    def notification_handler(sender, data):
        nonlocal dados_pressao
        print(f"📩 Dados recebidos: {len(data)} bytes")
        resultado = processar_pressao(data)
        if resultado:
            dados_pressao = resultado
            pressao_recebida.set()
    
    try:
        async with BleakClient(device["mac"], timeout=15.0) as client:
            if client.is_connected:
                print(f"✅ Conectado ao {device['name']}")
                
                await client.start_notify(device["char_uuid"], notification_handler)
                print("📊 Aguardando medição... (pressione botão Bluetooth no Omron)")
                
                try:
                    await asyncio.wait_for(pressao_recebida.wait(), timeout=60.0)
                    
                    if dados_pressao:
                        print(f"\n{'='*50}")
                        print(f"💓 PRESSÃO ARTERIAL:")
                        print(f"   Sistólica:  {dados_pressao['systolic']} mmHg")
                        print(f"   Diastólica: {dados_pressao['diastolic']} mmHg")
                        if 'heartRate' in dados_pressao:
                            print(f"   Pulso:      {dados_pressao['heartRate']} bpm")
                        print(f"{'='*50}\n")
                        
                        await enviar_leitura("blood_pressure", dados_pressao)
                        
                except asyncio.TimeoutError:
                    print("\n⏱️  Timeout - nenhuma medição recebida")
                    print("   Dica: Faça a medição e depois pressione o botão Bluetooth")
                
                await client.stop_notify(device["char_uuid"])
                
    except Exception as e:
        print(f"❌ Erro ao conectar ao Omron: {e}")
    finally:
        omron_conectando = False
        # Reiniciar o scanner
        if scanner_parado and scanner_global:
            try:
                await scanner_global.start()
                print("🔊 Scanner reiniciado")
            except Exception as e:
                print(f"⚠️  Erro ao reiniciar scanner: {e}")
    
    return None


def detection_callback(device, advertisement_data):
    """Callback para dispositivos detectados via BLE scan"""
    mac = device.address.upper()
    scale_mac = DEVICES["scale"]["mac"].upper()
    omron_mac = DEVICES["blood_pressure"]["mac"].upper()
    
    if mac == scale_mac:
        for _, data in advertisement_data.manufacturer_data.items():
            resultado = processar_balanca(data)
            if resultado:
                asyncio.create_task(enviar_leitura("scale", resultado))
    
    elif mac == omron_mac and not omron_conectando:
        print(f"\n📡 Omron detectado!")
        asyncio.create_task(conectar_omron())


def instalar_inicializacao():
    """Instala o script para iniciar com Windows"""
    import winreg
    
    script_path = os.path.abspath(__file__)
    python_path = sys.executable
    
    # Comando a ser executado
    comando = f'"{python_path}" "{script_path}"'
    
    try:
        # Adiciona ao registro do Windows (Run)
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0,
            winreg.KEY_SET_VALUE
        )
        winreg.SetValueEx(key, "TeleCuidar Maleta", 0, winreg.REG_SZ, comando)
        winreg.CloseKey(key)
        
        print("=" * 60)
        print("✅ INSTALADO COM SUCESSO!")
        print("=" * 60)
        print("\nO serviço da maleta será iniciado automaticamente")
        print("quando o Windows iniciar.")
        print("\nPara remover, execute:")
        print("  python servico_maleta.py --uninstall")
        print("")
        
    except Exception as e:
        print(f"❌ Erro ao instalar: {e}")
        print("\nTente executar como Administrador")


def desinstalar_inicializacao():
    """Remove o script da inicialização do Windows"""
    import winreg
    
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0,
            winreg.KEY_SET_VALUE
        )
        winreg.DeleteValue(key, "TeleCuidar Maleta")
        winreg.CloseKey(key)
        
        print("✅ Removido da inicialização do Windows")
        
    except FileNotFoundError:
        print("⚠️  Não estava instalado")
    except Exception as e:
        print(f"❌ Erro ao desinstalar: {e}")


async def main():
    global BASE_URL, scanner_global
    
    parser = argparse.ArgumentParser(description='Serviço Maleta TeleCuidar')
    parser.add_argument('--local', '-l', action='store_true', help='Usar localhost')
    parser.add_argument('--install', '-i', action='store_true', help='Instalar para iniciar com Windows')
    parser.add_argument('--uninstall', '-u', action='store_true', help='Remover da inicialização')
    args = parser.parse_args()
    
    if args.install:
        instalar_inicializacao()
        return
    
    if args.uninstall:
        desinstalar_inicializacao()
        return
    
    if args.local:
        BASE_URL = BASE_URL_LOCAL
        print("\n🏠 MODO LOCAL: localhost:5239")
    else:
        BASE_URL = BASE_URL_PROD
        print("\n🌐 MODO PRODUÇÃO: telecuidar.com.br")
    
    if not BLE_DISPONIVEL:
        print("❌ Bleak não disponível. Execute: pip install bleak aiohttp")
        return
    
    print("=" * 60)
    print("   🏥 SERVIÇO MALETA TELECUIDAR")
    print("   Captura automática de sinais vitais")
    print("=" * 60)
    
    print("\nDispositivos monitorados:")
    for key, device in DEVICES.items():
        print(f"  • {device['name']} ({device['mac']})")
    
    # Busca consulta inicial
    print("\n🔍 Verificando consulta ativa...")
    await buscar_consulta_ativa()
    
    print("\n" + "-" * 60)
    print("🔊 ESCUTANDO DISPOSITIVOS...")
    print("   - Suba na balança para medir peso")
    print("   - Ligue o Omron e faça a medição de pressão")
    print("   - IMPORTANTE: Após medir no Omron, pressione o botão Bluetooth!")
    print("-" * 60)
    print("\nPressione Ctrl+C para sair\n")
    
    scanner_global = BleakScanner(detection_callback)
    await scanner_global.start()
    
    try:
        while True:
            # Verifica consulta a cada 5 segundos
            await buscar_consulta_ativa()
            await asyncio.sleep(INTERVALO_VERIFICACAO)
    except KeyboardInterrupt:
        print("\n\n👋 Encerrando serviço...")
    finally:
        await scanner_global.stop()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n👋 Encerrado pelo usuário")
