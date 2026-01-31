#!/usr/bin/env python3
"""
Scanner detalhado - mostra serviços BLE de cada dispositivo
"""

import asyncio
from bleak import BleakScanner

async def scan():
    print("=" * 70)
    print("  SCANNER DETALHADO DE DISPOSITIVOS BLE")
    print("=" * 70)
    print()
    print("Escaneando por 15 segundos...")
    print()
    
    devices = await BleakScanner.discover(timeout=15, return_adv=True)
    
    print(f"{len(devices)} dispositivos encontrados:")
    print()
    
    for address, (device, adv_data) in devices.items():
        name = device.name or adv_data.local_name or "(Sem nome)"
        print(f"📱 {name}")
        print(f"   MAC: {address}")
        print(f"   RSSI: {adv_data.rssi} dBm")
        
        if adv_data.service_uuids:
            print(f"   Serviços: {', '.join(adv_data.service_uuids[:3])}")
        
        if adv_data.manufacturer_data:
            for mfr_id, data in adv_data.manufacturer_data.items():
                print(f"   Fabricante ID: {mfr_id} (0x{mfr_id:04X})")
        
        print()
    
    print("=" * 70)
    print("Termômetros geralmente têm:")
    print("  - Health Thermometer Service: 00001809-0000-1000-8000-00805f9b34fb")
    print("=" * 70)

if __name__ == "__main__":
    asyncio.run(scan())
