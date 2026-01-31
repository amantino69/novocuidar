#!/usr/bin/env python3
"""
Monitor de conexão - detecta quando oxímetro conecta/desconecta
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    MONITOR DE CONEXÃO - OXÍMETRO")
print("=" * 60)
print()
print("📌 INSTRUÇÕES:")
print("   1. Desconecte o USB do oxímetro")
print("   2. Aguarde este script detectar a desconexão")
print("   3. Conecte o USB novamente")
print("   4. Ligue o oxímetro (se não ligar automaticamente)")
print()
print("⏳ Aguardando 60 segundos...")
print("-" * 60)

device = None
was_connected = False
start = time.time()
all_data = []

while time.time() - start < 60:
    # Verifica se dispositivo está presente
    devices = hid.enumerate(VID, PID)
    is_present = len(devices) > 0
    
    if is_present and not was_connected:
        print(f"\n[{time.time()-start:5.1f}s] 🔌 OXÍMETRO CONECTADO!")
        try:
            device = hid.device()
            device.open(VID, PID)
            device.set_nonblocking(True)
            was_connected = True
            print("         ✅ Porta aberta - monitorando dados...")
            
            # Não envia nenhum comando - só escuta
        except Exception as e:
            print(f"         ⚠️ Erro ao abrir: {e}")
    
    elif not is_present and was_connected:
        print(f"\n[{time.time()-start:5.1f}s] ❌ OXÍMETRO DESCONECTADO!")
        was_connected = False
        if device:
            try:
                device.close()
            except:
                pass
            device = None
    
    # Se conectado, lê dados
    if device and was_connected:
        try:
            data = device.read(64, timeout_ms=100)
            if data:
                all_data.append((time.time() - start, data))
                hex_str = ' '.join(f'{b:02x}' for b in data[:25])
                
                # Destaca se há dados diferentes de f0 70 00
                has_data = any(b not in [0x00, 0xf0, 0x70] for b in data)
                
                if has_data:
                    print(f"[{time.time()-start:5.1f}s] 🎯 DADOS: {hex_str}")
                    
                    # Analisa
                    for i, b in enumerate(data[:15]):
                        if b not in [0x00, 0xf0, 0x70]:
                            desc = ""
                            if 85 <= b <= 100:
                                desc = f" (SpO2?)"
                            elif 40 <= b <= 120:
                                desc = f" (Pulso?)"
                            print(f"         Byte {i}: {b}{desc}")
                else:
                    # Mostra só o primeiro de cada tipo
                    key = tuple(data[:5])
                    print(f"[{time.time()-start:5.1f}s] Status: {hex_str[:20]}", end='\r')
                    
        except Exception as e:
            if "read error" in str(e).lower():
                was_connected = False
                device = None
    
    time.sleep(0.05)

print("\n")
print("=" * 60)
print("📊 RESUMO")
print("=" * 60)
print(f"Total de leituras: {len(all_data)}")

# Mostra leituras únicas
unique = {}
for t, data in all_data:
    key = tuple(data[:10])
    if key not in unique:
        unique[key] = (t, data)

print(f"Padrões únicos: {len(unique)}")
for (t, data) in unique.values():
    hex_str = ' '.join(f'{b:02x}' for b in data[:20])
    print(f"   {hex_str}")
