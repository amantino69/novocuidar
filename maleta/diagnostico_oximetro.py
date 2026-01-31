#!/usr/bin/env python3
"""
Diagnóstico de Oxímetro BLE
Verifica se o oxímetro usa protocolo padrão BLE (Pulse Oximeter Service 0x1822)
"""

import asyncio
from bleak import BleakScanner, BleakClient

# UUIDs padrão BLE para oxímetros
PULSE_OXIMETER_SERVICE = "00001822-0000-1000-8000-00805f9b34fb"  # Pulse Oximeter Service
PLX_CONTINUOUS = "00002a5f-0000-1000-8000-00805f9b34fb"  # PLX Continuous Measurement
PLX_SPOT_CHECK = "00002a5e-0000-1000-8000-00805f9b34fb"  # PLX Spot-Check Measurement
PLX_FEATURES = "00002a60-0000-1000-8000-00805f9b34fb"  # PLX Features

# Nomes comuns de oxímetros
OXIMETER_KEYWORDS = ["oxi", "spo2", "pulse", "po", "berry", "contec", "cms", "fingertip", "o2"]

async def scan_for_oximeters():
    """Escaneia por dispositivos que parecem ser oxímetros"""
    print("🔍 Escaneando dispositivos BLE por 15 segundos...")
    print("   (Coloque o oxímetro no dedo e ligue-o)\n")
    
    devices = await BleakScanner.discover(timeout=15, return_adv=True)
    
    oximeters = []
    all_devices = []
    
    for device, adv_data in devices.values():
        name = device.name or adv_data.local_name or "Desconhecido"
        all_devices.append((device, name, adv_data))
        
        # Verifica se parece ser oxímetro pelo nome
        name_lower = name.lower()
        if any(kw in name_lower for kw in OXIMETER_KEYWORDS):
            oximeters.append((device, name, adv_data))
        
        # Verifica se tem o serviço de oxímetro nos dados de advertising
        if adv_data.service_uuids:
            for uuid in adv_data.service_uuids:
                if "1822" in uuid.lower():
                    if (device, name, adv_data) not in oximeters:
                        oximeters.append((device, name, adv_data))
    
    print(f"📱 Total de dispositivos encontrados: {len(all_devices)}\n")
    
    # Mostra todos os dispositivos
    print("=" * 60)
    print("TODOS OS DISPOSITIVOS ENCONTRADOS:")
    print("=" * 60)
    for device, name, adv_data in sorted(all_devices, key=lambda x: x[2].rssi or -100, reverse=True):
        rssi = adv_data.rssi or "?"
        services = adv_data.service_uuids or []
        print(f"  📶 {name}")
        print(f"     MAC: {device.address} | RSSI: {rssi} dBm")
        if services:
            print(f"     Serviços: {services}")
        print()
    
    if oximeters:
        print("=" * 60)
        print("🎯 POSSÍVEIS OXÍMETROS DETECTADOS:")
        print("=" * 60)
        for device, name, adv_data in oximeters:
            print(f"  ✅ {name} - {device.address}")
    
    return oximeters, all_devices

async def analyze_device(address: str, name: str):
    """Conecta ao dispositivo e analisa os serviços"""
    print(f"\n{'='*60}")
    print(f"🔬 ANALISANDO: {name}")
    print(f"   MAC: {address}")
    print("=" * 60)
    
    try:
        async with BleakClient(address, timeout=20) as client:
            print(f"✅ Conectado!")
            
            services = client.services
            has_standard_oximeter = False
            notify_chars = []
            
            print(f"\n📋 SERVIÇOS ENCONTRADOS ({len(list(services))} total):")
            print("-" * 50)
            
            for service in services:
                uuid = service.uuid
                
                # Identifica o tipo de serviço
                if "1822" in uuid:
                    service_name = "🎯 PULSE OXIMETER SERVICE (PADRÃO!)"
                    has_standard_oximeter = True
                elif "1800" in uuid:
                    service_name = "Generic Access"
                elif "1801" in uuid:
                    service_name = "Generic Attribute"
                elif "180a" in uuid:
                    service_name = "Device Information"
                elif "180f" in uuid:
                    service_name = "Battery Service"
                elif "1810" in uuid:
                    service_name = "Blood Pressure (interessante!)"
                else:
                    service_name = "Vendor Specific / Desconhecido"
                
                print(f"\n  📦 {uuid}")
                print(f"     → {service_name}")
                
                for char in service.characteristics:
                    props = ", ".join(char.properties)
                    char_name = ""
                    
                    if "2a5f" in char.uuid:
                        char_name = " ← PLX Continuous Measurement!"
                    elif "2a5e" in char.uuid:
                        char_name = " ← PLX Spot-Check!"
                    elif "2a60" in char.uuid:
                        char_name = " ← PLX Features"
                    
                    print(f"       • {char.uuid}")
                    print(f"         Props: [{props}]{char_name}")
                    
                    if "notify" in char.properties or "indicate" in char.properties:
                        notify_chars.append((service.uuid, char.uuid, char.properties))
            
            # Resultado
            print("\n" + "=" * 60)
            print("📊 RESULTADO DA ANÁLISE:")
            print("=" * 60)
            
            if has_standard_oximeter:
                print("✅ COMPATÍVEL! Usa protocolo padrão BLE Pulse Oximeter (0x1822)")
                print("   → Podemos integrar este oxímetro!")
                return True
            else:
                print("⚠️  NÃO usa protocolo padrão de oxímetro")
                print(f"   → Encontrados {len(notify_chars)} características com notify/indicate")
                
                if notify_chars:
                    print("\n   Vamos tentar capturar dados dessas características...")
                    await try_capture_data(client, notify_chars)
                
                return False
                
    except Exception as e:
        print(f"❌ Erro ao conectar: {e}")
        return False

async def try_capture_data(client, notify_chars):
    """Tenta capturar dados das características com notify"""
    print("\n" + "-" * 50)
    print("🔊 Tentando capturar dados (30 segundos)...")
    print("   → Coloque o oxímetro no dedo e aguarde a leitura")
    print("-" * 50)
    
    received_data = []
    
    def notification_handler(sender, data):
        hex_data = data.hex()
        print(f"\n   📥 DADOS RECEBIDOS de {sender}:")
        print(f"      Hex: {hex_data}")
        print(f"      Bytes: {list(data)}")
        
        # Tenta interpretar como SpO2 e Pulso
        if len(data) >= 4:
            # Formato comum: [flags, SpO2, Pulse_LSB, Pulse_MSB]
            possible_spo2 = data[1] if len(data) > 1 else None
            possible_pulse = data[2] if len(data) > 2 else None
            
            if possible_spo2 and 70 <= possible_spo2 <= 100:
                print(f"      ❓ Possível SpO2: {possible_spo2}%")
            if possible_pulse and 40 <= possible_pulse <= 200:
                print(f"      ❓ Possível Pulso: {possible_pulse} bpm")
        
        received_data.append(data)
    
    # Habilita notificações em todas as características
    for service_uuid, char_uuid, props in notify_chars:
        try:
            print(f"   → Habilitando notificações em {char_uuid[:8]}...")
            await client.start_notify(char_uuid, notification_handler)
        except Exception as e:
            print(f"      ⚠️ Falhou: {e}")
    
    # Aguarda dados
    await asyncio.sleep(30)
    
    # Para notificações
    for service_uuid, char_uuid, props in notify_chars:
        try:
            await client.stop_notify(char_uuid)
        except:
            pass
    
    if received_data:
        print(f"\n✅ Recebidos {len(received_data)} pacotes de dados!")
        print("   → Este oxímetro pode ser integrável (protocolo proprietário)")
    else:
        print("\n❌ Nenhum dado recebido")
        print("   → O oxímetro pode precisar de comandos especiais para enviar dados")

async def main():
    print("=" * 60)
    print("    DIAGNÓSTICO DE OXÍMETRO BLE - TeleCuidar")
    print("=" * 60)
    print()
    print("📌 Instruções:")
    print("   1. Ligue o oxímetro")
    print("   2. Coloque-o no dedo")
    print("   3. Aguarde a leitura estabilizar")
    print()
    
    # Escaneia
    oximeters, all_devices = await scan_for_oximeters()
    
    if not all_devices:
        print("❌ Nenhum dispositivo BLE encontrado!")
        print("   Verifique se o Bluetooth está ligado")
        return
    
    # Se encontrou possíveis oxímetros, analisa automaticamente
    if oximeters:
        for device, name, adv_data in oximeters:
            await analyze_device(device.address, name)
    else:
        # Pergunta qual dispositivo analisar
        print("\n" + "=" * 60)
        print("Nenhum oxímetro identificado automaticamente.")
        print("Qual dispositivo você quer analisar?")
        print("=" * 60)
        
        for i, (device, name, adv_data) in enumerate(all_devices):
            print(f"  [{i+1}] {name} - {device.address}")
        
        try:
            choice = input("\nDigite o número (ou Enter para o primeiro): ").strip()
            idx = int(choice) - 1 if choice else 0
            if 0 <= idx < len(all_devices):
                device, name, adv_data = all_devices[idx]
                await analyze_device(device.address, name)
        except (ValueError, KeyboardInterrupt):
            print("Cancelado")

if __name__ == "__main__":
    asyncio.run(main())
