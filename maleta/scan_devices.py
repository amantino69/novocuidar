#!/usr/bin/env python3
"""
Scanner de dispositivos BLE para encontrar termômetros, oxímetros, etc.
"""

import asyncio
from bleak import BleakScanner

async def scan():
    print("=" * 60)
    print("  SCANNER DE DISPOSITIVOS BLE")
    print("=" * 60)
    print()
    print("Escaneando por 20 segundos...")
    print(">>> LIGUE O TERMÔMETRO MOBI AGORA! <<<")
    print()
    
    devices = await BleakScanner.discover(timeout=20)
    
    print(f"{len(devices)} dispositivos encontrados:")
    print()
    print(f"{'Nome':<35} | {'MAC Address':<20}")
    print("-" * 60)
    
    for d in sorted(devices, key=lambda x: (x.name or 'zzz').lower()):
        name = d.name or "(Sem nome)"
        print(f"{name:<35} | {d.address}")
    
    print()
    print("=" * 60)
    print("Procure por: MOBI, Thermo, ThermoScan, ou similar")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(scan())
