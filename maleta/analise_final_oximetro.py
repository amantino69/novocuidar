#!/usr/bin/env python3
"""
Tentativa final - Protocolo alternativo
Procura por qualquer padrão nos dados
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    ANÁLISE FINAL - OXÍMETRO USB")
print("=" * 60)

# Tenta encontrar TODOS os endpoints/interfaces do dispositivo
print("\n📋 Listando TODOS os dispositivos HID com VID 0x28e9:")

for dev in hid.enumerate(VID, 0):
    print(f"\n   PID: 0x{dev['product_id']:04x}")
    print(f"   Path: {dev['path']}")
    print(f"   Produto: {dev.get('product_string', 'N/A')}")
    print(f"   Interface: {dev.get('interface_number', 'N/A')}")
    print(f"   Usage Page: 0x{dev.get('usage_page', 0):04x}")
    print(f"   Usage: 0x{dev.get('usage', 0):04x}")

print("\n" + "=" * 60)

# Abre e tenta todas as variações
try:
    device = hid.device()
    device.open(VID, PID)
    
    # Tenta ler o manufacturer e product string diretamente
    print(f"\n📱 Fabricante: {device.get_manufacturer_string()}")
    print(f"📱 Produto: {device.get_product_string()}")
    print(f"📱 Serial: {device.get_serial_number_string()}")
    
    # Envia sequência de inicialização completa
    print("\n🔧 Enviando sequência de inicialização...")
    
    init_sequence = [
        bytes([0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),
        bytes([0x7D, 0x81, 0xA7, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),
        bytes([0x7D, 0x81, 0xAC, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),
    ]
    
    device.set_nonblocking(False)
    
    for cmd in init_sequence:
        try:
            device.write(bytes([0x00]) + cmd)
            time.sleep(0.1)
        except:
            pass
    
    device.set_nonblocking(True)
    
    # Lê por 30 segundos com análise detalhada
    print("\n📊 MONITORANDO POR 30 SEGUNDOS...")
    print("   Valores esperados: SpO2=94 (0x5E), Pulso=61 (0x3D)")
    print("-" * 60)
    
    start = time.time()
    all_data = []
    
    while time.time() - start < 30:
        try:
            data = device.read(64, timeout_ms=100)
            if data:
                all_data.append((time.time() - start, list(data)))
                
                # Mostra apenas se tiver dados diferentes de f0 70 00
                if any(b not in [0x00, 0xf0, 0x70] for b in data):
                    hex_str = ' '.join(f'{b:02x}' for b in data[:20])
                    print(f"[{time.time()-start:5.1f}s] 🎯 DADOS: {hex_str}")
                
                # Procura pelos valores específicos
                if 94 in data:
                    print(f"         ✅ Encontrado 94 (SpO2) na posição {data.index(94)}")
                if 61 in data:
                    print(f"         ✅ Encontrado 61 (Pulso) na posição {data.index(61)}")
                    
        except Exception as e:
            if "read error" in str(e).lower():
                # Reconecta
                try:
                    device.close()
                except:
                    pass
                device = hid.device()
                device.open(VID, PID)
                device.set_nonblocking(True)
                print("   ⟳ Reconectado")
    
    device.close()
    
    print(f"\n📊 Total de leituras: {len(all_data)}")
    
    # Análise estatística
    if all_data:
        print("\n📈 ANÁLISE DOS DADOS:")
        
        # Encontra bytes que variam
        first = all_data[0][1]
        varying_positions = set()
        
        for _, data in all_data[:50]:
            for i in range(min(len(data), len(first))):
                if data[i] != first[i]:
                    varying_positions.add(i)
        
        if varying_positions:
            print(f"   Posições com variação: {sorted(varying_positions)}")
        else:
            print("   ⚠️ Nenhuma variação detectada nos dados")
            print("   → O oxímetro NÃO está transmitindo dados de medição via USB")
    
except Exception as e:
    print(f"\n❌ Erro: {e}")

print("\n" + "=" * 60)
print("📋 CONCLUSÃO:")
print("=" * 60)
print("""
Se o oxímetro mostra SpO2/Pulso no display mas não envia dados USB:

1. Este modelo pode NÃO suportar streaming USB
   - Alguns oxímetros só transmitem via Bluetooth
   - Outros precisam de software proprietário

2. Opções:
   a) Verificar se há modo Bluetooth (pressione botões)
   b) Procurar pelo software do fabricante
   c) Usar outro oxímetro com protocolo documentado

Modelos compatíveis conhecidos:
   - Contec CMS50D (original, não clones)
   - ChoiceMMed MD300C208
   - BerryMed BM1000A
""")
