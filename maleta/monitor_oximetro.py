#!/usr/bin/env python3
"""
Monitor contínuo do oxímetro
VID: 0x28e9 | PID: 0x028a
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    MONITOR CONTÍNUO - OXÍMETRO USB")
print("=" * 60)
print()
print("📌 INSTRUÇÕES:")
print("   1. Conecte o oxímetro via USB")
print("   2. Coloque o dedo no oxímetro")
print("   3. Aguarde o display mostrar SpO2 e Pulso")
print("   4. Observe se os dados aqui mudam")
print()
print("   Pressione Ctrl+C para sair")
print()

try:
    device = hid.device()
    device.open(VID, PID)
    device.set_nonblocking(True)
    
    print("✅ Conectado ao oxímetro!")
    print("-" * 60)
    
    # Envia comando de streaming inicial
    cmd = bytes([0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80])
    try:
        device.write(bytes([0x00]) + cmd)
    except:
        device.write(cmd)
    
    last_data = None
    packet_count = 0
    start = time.time()
    
    print("📊 Monitorando... (60 segundos)")
    print()
    
    while time.time() - start < 60:
        data = device.read(64, timeout_ms=100)
        
        if data:
            # Só mostra se for diferente do anterior
            data_tuple = tuple(data)
            if data_tuple != last_data:
                last_data = data_tuple
                packet_count += 1
                
                hex_str = ' '.join(f'{b:02x}' for b in data[:20])
                elapsed = time.time() - start
                
                print(f"[{elapsed:5.1f}s] #{packet_count:3d}: {hex_str}")
                
                # Tenta decodificar
                # Bytes diferentes de f0/70/00 podem ser dados
                interesting = [b for b in data if b not in [0x00, 0xf0, 0x70]]
                if interesting:
                    print(f"         Bytes interessantes: {interesting}")
                    for i, b in enumerate(interesting):
                        if 85 <= b <= 100:
                            print(f"         → Possível SpO2: {b}%")
                        if 50 <= b <= 120:
                            print(f"         → Possível Pulso: {b} bpm")
        
        # Reenvia comando periodicamente
        if int(time.time()) % 5 == 0:
            try:
                device.write(bytes([0x00]) + cmd)
            except:
                pass
        
        time.sleep(0.05)
    
    device.close()
    print("\n✅ Monitoramento concluído")
    
except KeyboardInterrupt:
    print("\n\n👋 Interrompido pelo usuário")
except Exception as e:
    print(f"\n❌ Erro: {e}")
