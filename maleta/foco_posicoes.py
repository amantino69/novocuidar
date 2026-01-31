#!/usr/bin/env python3
"""
Foco nas posições 2 e 3 que variam!
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    ANÁLISE DAS POSIÇÕES 2 E 3")
print("    SpO2 esperado: 94 | Pulso esperado: 61")
print("=" * 60)
print()

device = hid.device()
device.open(VID, PID)
device.set_nonblocking(True)

# Envia comando de streaming
cmd = bytes([0x00, 0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80])
device.write(cmd)

print("📊 Monitorando posições 2 e 3 por 30 segundos...\n")

start = time.time()
readings = []

while time.time() - start < 30:
    try:
        data = device.read(64, timeout_ms=500)
        if data and len(data) > 3:
            elapsed = time.time() - start
            byte2 = data[2]
            byte3 = data[3]
            
            # Interpreta os dados
            # f0 = 240 = 0xF0
            # 70 = 112 = 0x70
            
            # Verifica se byte2 ou byte3 mudaram de 0
            if byte2 != 0 or byte3 != 0:
                hex_all = ' '.join(f'{b:02x}' for b in data[:10])
                print(f"[{elapsed:5.1f}s] {hex_all}")
                print(f"         Byte 2: {byte2} (0x{byte2:02x})")
                print(f"         Byte 3: {byte3} (0x{byte3:02x})")
                
                # O formato pode ser:
                # [f0] [70] [??] [??] ... onde ?? são dados
                # Ou os bytes podem estar codificados
                
                # Tenta diferentes interpretações
                if byte2 == 0xf0:
                    print(f"         → Byte 2 é sync (0xF0)")
                if byte3 == 0x70:
                    print(f"         → Byte 3 é sync (0x70)")
                
                # Verifica se há SpO2/Pulso em qualquer posição
                for i, b in enumerate(data[:15]):
                    if b == 94:
                        print(f"         🎯 SpO2 (94) encontrado na posição {i}!")
                    if b == 61:
                        print(f"         🎯 Pulso (61) encontrado na posição {i}!")
                    if 90 <= b <= 100 and b not in [0xf0]:
                        print(f"         ❓ Possível SpO2 na pos {i}: {b}%")
                    if 50 <= b <= 80 and b not in [0x70]:
                        print(f"         ❓ Possível Pulso na pos {i}: {b} bpm")
                
                readings.append(data[:10])
                print()
    except Exception as e:
        if "read error" in str(e).lower():
            device.close()
            device = hid.device()
            device.open(VID, PID)
            device.set_nonblocking(True)

device.close()

print(f"\n📊 Total de leituras com dados: {len(readings)}")

if readings:
    print("\n📋 Todas as leituras:")
    for i, r in enumerate(readings):
        print(f"   [{i+1}] {' '.join(f'{b:02x}' for b in r)}")
