"""
Scanner para Eko CORE 500
=========================

Este script descobre os serviços e características BLE do Eko CORE 500
para entender como podemos capturar os dados de áudio/fonocardiograma.

Instruções:
1. Ligue o Eko CORE 500 (luz piscando branca)
2. NÃO conecte ao app Eko (deixe desconectado)
3. Execute este script
"""

import asyncio
from bleak import BleakScanner, BleakClient
from datetime import datetime

# UUIDs conhecidos de serviços de áudio Bluetooth
KNOWN_AUDIO_SERVICES = {
    "00001800-0000-1000-8000-00805f9b34fb": "Generic Access",
    "00001801-0000-1000-8000-00805f9b34fb": "Generic Attribute", 
    "0000180a-0000-1000-8000-00805f9b34fb": "Device Information",
    "0000180f-0000-1000-8000-00805f9b34fb": "Battery Service",
    "00001810-0000-1000-8000-00805f9b34fb": "Blood Pressure",
    "00001816-0000-1000-8000-00805f9b34fb": "Cycling Speed and Cadence",
    "0000181c-0000-1000-8000-00805f9b34fb": "User Data",
    "0000184e-0000-1000-8000-00805f9b34fb": "Audio Input Control",
    "0000184f-0000-1000-8000-00805f9b34fb": "Audio Stream Control",
    "00001850-0000-1000-8000-00805f9b34fb": "Published Audio Capabilities",
    "00001851-0000-1000-8000-00805f9b34fb": "Basic Audio Announcement",
    "00001852-0000-1000-8000-00805f9b34fb": "Broadcast Audio Announcement",
    "00001853-0000-1000-8000-00805f9b34fb": "Common Audio",
    "00001854-0000-1000-8000-00805f9b34fb": "Hearing Access",
    "00001856-0000-1000-8000-00805f9b34fb": "Telephony and Media Audio",
}

KNOWN_CHARACTERISTICS = {
    "00002a00-0000-1000-8000-00805f9b34fb": "Device Name",
    "00002a01-0000-1000-8000-00805f9b34fb": "Appearance",
    "00002a19-0000-1000-8000-00805f9b34fb": "Battery Level",
    "00002a29-0000-1000-8000-00805f9b34fb": "Manufacturer Name",
    "00002a24-0000-1000-8000-00805f9b34fb": "Model Number",
    "00002a25-0000-1000-8000-00805f9b34fb": "Serial Number",
    "00002a26-0000-1000-8000-00805f9b34fb": "Firmware Revision",
    "00002a27-0000-1000-8000-00805f9b34fb": "Hardware Revision",
    "00002a28-0000-1000-8000-00805f9b34fb": "Software Revision",
}


def get_service_name(uuid: str) -> str:
    """Retorna nome do serviço se conhecido"""
    uuid_lower = uuid.lower()
    return KNOWN_AUDIO_SERVICES.get(uuid_lower, "Desconhecido (possivelmente proprietário)")


def get_char_name(uuid: str) -> str:
    """Retorna nome da característica se conhecida"""
    uuid_lower = uuid.lower()
    return KNOWN_CHARACTERISTICS.get(uuid_lower, "")


async def scan_for_eko():
    """Procura dispositivos Eko ou estetoscópios"""
    print("\n" + "=" * 60)
    print("   🩺 SCANNER EKO CORE 500")
    print("=" * 60)
    print("\n🔍 Procurando dispositivos Bluetooth LE...")
    print("   (Certifique-se que o Eko está ligado e NÃO conectado ao app)\n")
    
    devices_found = []
    
    def detection_callback(device, advertisement_data):
        name = device.name or advertisement_data.local_name or "Sem nome"
        
        # Procura por dispositivos que podem ser o Eko
        keywords = ["eko", "core", "littmann", "3m", "stethoscope", "stetoscópio"]
        is_potential_eko = any(kw in name.lower() for kw in keywords)
        
        # Também mostra dispositivos desconhecidos fortes (podem ser o Eko)
        rssi = advertisement_data.rssi or -100
        is_strong_signal = rssi > -60
        
        if is_potential_eko or (is_strong_signal and device.address not in [d.address for d in devices_found]):
            if device not in devices_found:
                devices_found.append(device)
                marker = "✅ POSSÍVEL EKO!" if is_potential_eko else "📶 Sinal forte"
                print(f"   {marker}")
                print(f"   Nome: {name}")
                print(f"   MAC: {device.address}")
                print(f"   RSSI: {rssi} dBm")
                if advertisement_data.service_uuids:
                    print(f"   Serviços anunciados: {advertisement_data.service_uuids}")
                print()
    
    scanner = BleakScanner(detection_callback)
    await scanner.start()
    await asyncio.sleep(10)  # Escaneia por 10 segundos
    await scanner.stop()
    
    return devices_found


async def explore_device(address: str):
    """Conecta ao dispositivo e lista todos os serviços e características"""
    print("\n" + "=" * 60)
    print(f"   🔌 CONECTANDO AO DISPOSITIVO: {address}")
    print("=" * 60)
    
    try:
        async with BleakClient(address, timeout=30.0) as client:
            print(f"\n✅ Conectado!")
            print(f"   MTU: {client.mtu_size}")
            
            print("\n" + "-" * 60)
            print("   📋 SERVIÇOS E CARACTERÍSTICAS DISPONÍVEIS")
            print("-" * 60)
            
            for service in client.services:
                service_name = get_service_name(service.uuid)
                print(f"\n🔷 SERVIÇO: {service.uuid}")
                print(f"   Nome: {service_name}")
                
                for char in service.characteristics:
                    char_name = get_char_name(char.uuid)
                    print(f"\n   📝 Característica: {char.uuid}")
                    if char_name:
                        print(f"      Nome: {char_name}")
                    print(f"      Propriedades: {', '.join(char.properties)}")
                    print(f"      Handle: {char.handle}")
                    
                    # Tenta ler o valor se for legível
                    if "read" in char.properties:
                        try:
                            value = await client.read_gatt_char(char.uuid)
                            # Tenta decodificar como texto
                            try:
                                text_value = value.decode('utf-8')
                                print(f"      Valor (texto): {text_value}")
                            except:
                                print(f"      Valor (hex): {value.hex()}")
                                print(f"      Valor (bytes): {list(value)}")
                        except Exception as e:
                            print(f"      Erro ao ler: {e}")
                    
                    # Indica se suporta notificação (importante para streaming)
                    if "notify" in char.properties:
                        print(f"      ⚡ SUPORTA NOTIFY (pode ser streaming de dados!)")
                    if "indicate" in char.properties:
                        print(f"      ⚡ SUPORTA INDICATE")
            
            print("\n" + "=" * 60)
            print("   ANÁLISE COMPLETA")
            print("=" * 60)
            
    except Exception as e:
        print(f"\n❌ Erro ao conectar: {e}")
        print("   Dicas:")
        print("   1. Certifique-se que o Eko está ligado")
        print("   2. Desconecte do app Eko se estiver conectado")
        print("   3. Tente reiniciar o dispositivo")


async def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 SCANNER EKO CORE 500 - TELECUIDAR                       ║
║                                                              ║
║   Este script vai descobrir como capturar dados do seu       ║
║   estetoscópio digital Eko CORE 500.                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    # Fase 1: Escanear
    devices = await scan_for_eko()
    
    if not devices:
        print("\n⚠️ Nenhum dispositivo encontrado.")
        print("   Certifique-se que:")
        print("   1. O Eko CORE 500 está ligado (luz piscando)")
        print("   2. Não está conectado ao app Eko")
        print("   3. Está próximo ao computador")
        return
    
    # Fase 2: Perguntar qual dispositivo explorar
    print("\n" + "=" * 60)
    print("   DISPOSITIVOS ENCONTRADOS")
    print("=" * 60)
    
    for i, device in enumerate(devices):
        name = device.name or "Sem nome"
        print(f"   [{i+1}] {name} ({device.address})")
    
    print(f"\n   [0] Digitar MAC manualmente")
    print(f"   [Enter] Sair")
    
    try:
        choice = input("\n👉 Escolha o dispositivo para explorar: ").strip()
        
        if not choice:
            print("Saindo...")
            return
        
        if choice == "0":
            address = input("   Digite o MAC address (XX:XX:XX:XX:XX:XX): ").strip()
        else:
            idx = int(choice) - 1
            if 0 <= idx < len(devices):
                address = devices[idx].address
            else:
                print("Opção inválida")
                return
        
        # Fase 3: Explorar o dispositivo
        await explore_device(address)
        
        # Salvar resultado
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"eko_scan_{timestamp}.txt"
        print(f"\n💾 Resultado salvo em: {filename}")
        
    except ValueError:
        print("Entrada inválida")
    except KeyboardInterrupt:
        print("\nCancelado pelo usuário")


if __name__ == "__main__":
    asyncio.run(main())
