#!/usr/bin/env python3
"""
Teste de handshake completo - enviando a resposta de volta
O f0 70 pode ser uma requisição de handshake
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    TESTE DE HANDSHAKE - OXÍMETRO")
print("=" * 60)
print()

try:
    device = hid.device()
    device.open(VID, PID)
    device.set_nonblocking(True)
    
    print("✅ Conectado!")
    
    # A resposta f0 70 pode ser um pedido de handshake
    # Vamos responder com diferentes variações
    
    handshakes = [
        # Eco da resposta
        bytes([0x00, 0xf0, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        bytes([0x00, 0x70, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        
        # ACK típicos
        bytes([0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),  # ACK
        bytes([0x00, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),  # NAK
        
        # Comandos de início baseados no f0
        bytes([0x00, 0xf0, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        bytes([0x00, 0xf0, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        bytes([0x00, 0xf0, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        bytes([0x00, 0xf0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        
        # Comandos com checksum
        bytes([0x00, 0xf0, 0x70, 0x01, 0x61, 0x00, 0x00, 0x00, 0x00]),  # 0xf0+0x70+0x01 = 0x161
        
        # Start commands
        bytes([0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        bytes([0x00, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        
        # Query commands
        bytes([0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        bytes([0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    ]
    
    print("\n🔧 Enviando handshakes e observando respostas...")
    print("-" * 60)
    
    for hs in handshakes:
        # Limpa buffer
        for _ in range(3):
            device.read(64, timeout_ms=50)
        
        # Envia handshake
        try:
            device.write(hs)
        except:
            continue
            
        print(f"\n📤 Enviado: {hs.hex()}")
        
        # Lê respostas por 1 segundo
        time.sleep(0.2)
        responses = []
        start = time.time()
        while time.time() - start < 1:
            data = device.read(64, timeout_ms=100)
            if data:
                responses.append(data)
        
        if responses:
            for r in responses:
                hex_str = ' '.join(f'{b:02x}' for b in r[:20])
                # Verifica se é diferente do padrão f0 70 00...
                unique = sum(1 for b in r if b not in [0x00, 0xf0, 0x70])
                if unique > 0:
                    print(f"   📥 🎯 NOVO: {hex_str}")
                    for i, b in enumerate(r):
                        if b not in [0x00, 0xf0, 0x70]:
                            print(f"       Byte {i}: {b} (0x{b:02x})")
                else:
                    print(f"   📥 Padrão: {hex_str[:30]}...")
        else:
            print("   ❌ Sem resposta")
    
    device.close()
    
except Exception as e:
    print(f"❌ Erro: {e}")

print("\n" + "=" * 60)
print("📋 Se nenhum dado novo apareceu, este oxímetro:")
print("   1. Não suporta streaming USB")
print("   2. O cabo USB é apenas para um software proprietário")
print("   3. Ou o firmware está incompleto/defeituoso")
print("=" * 60)
