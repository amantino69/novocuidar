#!/usr/bin/env python3
"""
Leitura simples do oxímetro - com dedo inserido!
"""

import hid
import time
import sys

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    LEITURA DO OXÍMETRO USB")
print("=" * 60)
print()
print("⚠️  IMPORTANTE: O DEDO DEVE ESTAR NO OXÍMETRO!")
print("   O display deve estar mostrando SpO2 e Pulso")
print()
input("Pressione ENTER quando o oxímetro estiver medindo...")

try:
    device = hid.device()
    device.open(VID, PID)
    device.set_nonblocking(True)
    
    print("\n✅ Conectado! Lendo por 20 segundos...\n")
    
    start = time.time()
    packets = 0
    
    while time.time() - start < 20:
        data = device.read(64, timeout_ms=100)
        if data and any(b != 0 for b in data):  # Ignora pacotes só de zeros
            packets += 1
            hex_str = ' '.join(f'{b:02x}' for b in data[:20])
            print(f"[{packets:3d}] {hex_str}")
            
            # Tenta interpretar
            for i in range(len(data) - 1):
                b1, b2 = data[i], data[i+1]
                if 90 <= b1 <= 100 and 50 <= b2 <= 120:
                    print(f"      ❓ Offset {i}: SpO2={b1}%, Pulso={b2} bpm")
                if 50 <= b1 <= 120 and 90 <= b2 <= 100:
                    print(f"      ❓ Offset {i}: Pulso={b1} bpm, SpO2={b2}%")
        
        time.sleep(0.05)
    
    device.close()
    print(f"\nTotal: {packets} pacotes com dados")
    
except Exception as e:
    print(f"❌ Erro: {e}")
