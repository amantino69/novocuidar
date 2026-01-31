#!/usr/bin/env python3
"""
Última tentativa de captura via USB do oxímetro Contec
"""

import hid
import time

print("=" * 60)
print("  ÚLTIMA TENTATIVA - CAPTURA USB DO OXÍMETRO")
print("=" * 60)
print()

# Verificar dispositivos
print("🔍 Procurando oxímetro USB...")
oximetro = None

for d in hid.enumerate():
    product = d.get('product_string', '').lower()
    if 'pulse' in product or 'oxim' in product or d['vendor_id'] == 0x28e9:
        print(f"   ✅ Encontrado: {d.get('product_string', 'N/A')}")
        print(f"      VID: 0x{d['vendor_id']:04x}, PID: 0x{d['product_id']:04x}")
        oximetro = d
        break

if not oximetro:
    print("❌ Oxímetro não encontrado via USB!")
    print("   Conecte o cabo USB e tente novamente.")
    exit(1)

print()
print("📌 Coloque o dedo no oxímetro e aguarde leitura estável...")
print("   Monitorando por 20 segundos...")
print()

# Conectar
device = hid.device()
try:
    device.open_path(oximetro['path'])
except Exception as e:
    print(f"❌ Erro ao abrir dispositivo: {e}")
    exit(1)

device.set_nonblocking(True)

# Tentar diferentes comandos de inicialização
init_commands = [
    # CMS50D standard
    bytes([0x7d, 0x81, 0xa1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),
    # Alternate
    bytes([0xa7, 0x00, 0x02, 0x00, 0x84, 0x1c, 0x00, 0x00]),
    # Request data
    bytes([0x7d, 0x81, 0xa7, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),
]

for cmd in init_commands:
    try:
        device.write(list(cmd))
        time.sleep(0.1)
    except:
        pass

# Monitorar
start = time.time()
unique_patterns = {}
dados_validos = []

print("Dados recebidos:")
print("-" * 60)

while time.time() - start < 20:
    data = device.read(64)
    if data:
        # Ignorar padrões só de zeros
        if all(b == 0 for b in data):
            continue
            
        hex_data = bytes(data).hex()
        
        # Agrupar por primeiro byte
        first_byte = data[0]
        if first_byte not in unique_patterns:
            unique_patterns[first_byte] = 0
            print(f"Padrão 0x{first_byte:02x}: {hex_data[:40]}...")
        unique_patterns[first_byte] += 1
        
        # Tentar decodificar formatos conhecidos
        
        # Formato 1: 0x01 SpO2 Pulse ...
        if data[0] == 0x01 and len(data) >= 5:
            spo2 = data[1]
            pulse = data[2]
            if 70 <= spo2 <= 100 and 30 <= pulse <= 200:
                dados_validos.append((spo2, pulse))
                print(f"   >>> SpO2: {spo2}% | Pulso: {pulse} bpm")
        
        # Formato 2: CMS50 wave packet
        if data[0] & 0x80 and len(data) >= 5:
            # Bit 7 set = sync byte
            spo2 = data[4] if len(data) > 4 else 0
            pulse = data[3] | ((data[2] & 0x40) << 1)
            if 70 <= spo2 <= 100 and 30 <= pulse <= 200:
                dados_validos.append((spo2, pulse))
                print(f"   >>> SpO2: {spo2}% | Pulso: {pulse} bpm (formato 2)")
        
        # Formato 3: Bytes 3-4 = SpO2, Pulse
        if len(data) >= 5:
            spo2 = data[3]
            pulse = data[4]
            if 85 <= spo2 <= 100 and 50 <= pulse <= 120:
                if (spo2, pulse) not in dados_validos[-5:] if dados_validos else True:
                    # print(f"   Possível: SpO2={spo2}% Pulso={pulse}")
                    pass
    
    time.sleep(0.05)

device.close()

print()
print("=" * 60)
print("RESULTADO:")
print("=" * 60)

if dados_validos:
    print(f"✅ SUCESSO! {len(dados_validos)} leituras válidas")
    # Média das últimas leituras
    if len(dados_validos) >= 5:
        ultimas = dados_validos[-5:]
        avg_spo2 = sum(d[0] for d in ultimas) // 5
        avg_pulse = sum(d[1] for d in ultimas) // 5
        print(f"   Média: SpO2 = {avg_spo2}% | Pulso = {avg_pulse} bpm")
else:
    print("❌ NENHUM DADO VÁLIDO RECEBIDO VIA USB")
    print()
    print("Padrões recebidos:")
    for byte, count in unique_patterns.items():
        print(f"   0x{byte:02x}: {count} vezes")
    print()
    print("CONCLUSÃO: Este oxímetro NÃO transmite dados via USB.")
    print("           O cabo USB provavelmente é apenas para alimentação")
    print("           ou para uso com software específico da Contec.")
