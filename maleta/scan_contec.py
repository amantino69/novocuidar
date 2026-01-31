#!/usr/bin/env python3
"""
Scanner específico para Contec CMS50D-BT
"""

import asyncio
from bleak import BleakScanner

print("=" * 60)
print("    SCANNER PARA CONTEC CMS50D-BT")
print("=" * 60)
print()
print("📌 INSTRUÇÕES:")
print("   1. Desconecte o cabo USB do oxímetro")
print("   2. Coloque o dedo no oxímetro")
print("   3. Pressione o botão para ligar")
print("   4. Aguarde o scan (30 segundos)")
print()

async def scan():
    print("🔍 Escaneando dispositivos BLE por 30 segundos...\n")
    
    devices = await BleakScanner.discover(timeout=30, return_adv=True)
    
    print(f"📱 Total de dispositivos encontrados: {len(devices)}\n")
    
    contec_candidates = []
    
    for device, adv_data in devices.values():
        name = device.name or adv_data.local_name or ""
        mac = device.address
        rssi = adv_data.rssi
        services = adv_data.service_uuids or []
        manufacturer = adv_data.manufacturer_data
        
        # Verifica se pode ser o Contec
        is_contec = False
        reason = ""
        
        # Por nome
        if name:
            name_lower = name.lower()
            if any(kw in name_lower for kw in ['contec', 'cms', 'oxi', 'spo2', 'pulse', 'po']):
                is_contec = True
                reason = "Nome"
        
        # Por serviço de oxímetro (0x1822)
        for s in services:
            if '1822' in s.lower():
                is_contec = True
                reason = "Serviço Oxímetro"
            # Ou serviço de pulso (0x180d)
            if '180d' in s.lower():
                is_contec = True
                reason = "Serviço Heart Rate"
        
        # Mostra todos os dispositivos com detalhes
        if name or services or manufacturer:
            print(f"📶 {name or '(sem nome)'}")
            print(f"   MAC: {mac} | RSSI: {rssi} dBm")
            if services:
                print(f"   Serviços: {services}")
            if manufacturer:
                for mid, data in manufacturer.items():
                    print(f"   Fabricante ID: 0x{mid:04x} | Data: {data.hex()}")
            if is_contec:
                print(f"   🎯 POSSÍVEL CONTEC! ({reason})")
                contec_candidates.append((device, adv_data, reason))
            print()
    
    # Mostra também dispositivos sem nome mas com sinal forte
    print("-" * 60)
    print("Dispositivos próximos (RSSI > -70):")
    for device, adv_data in devices.values():
        name = device.name or adv_data.local_name or ""
        if not name and adv_data.rssi and adv_data.rssi > -70:
            print(f"   {device.address} | RSSI: {adv_data.rssi} dBm")
    
    print("\n" + "=" * 60)
    if contec_candidates:
        print("🎯 CANDIDATOS A CONTEC:")
        for dev, adv, reason in contec_candidates:
            print(f"   • {dev.name or dev.address} ({reason})")
    else:
        print("❌ Nenhum dispositivo Contec identificado")
        print()
        print("💡 SUGESTÕES:")
        print("   1. O Bluetooth pode precisar ser ativado no oxímetro")
        print("   2. Tente pressionar e SEGURAR o botão por 3-5 segundos")
        print("   3. Verifique se há algum ícone de Bluetooth no display")
    print("=" * 60)

asyncio.run(scan())
