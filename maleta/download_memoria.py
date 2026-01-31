#!/usr/bin/env python3
"""
Teste de download de memória - Oxímetro USB
O oxímetro pode armazenar dados e precisar de comando de download
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    DOWNLOAD DE MEMÓRIA - OXÍMETRO USB")
print("=" * 60)
print()
print("📌 INSTRUÇÕES:")
print("   1. Desligue o oxímetro")
print("   2. Segure o botão e conecte o USB")
print("   3. Ou tente: Conecte USB, depois ligue o oxímetro")
print()

# Comandos de download de memória conhecidos
DOWNLOAD_COMMANDS = [
    # CMS50D download commands
    (bytes([0x7D, 0x81, 0xA5, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Download stored data"),
    (bytes([0x7D, 0x81, 0xA6, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Get device info"),
    (bytes([0x7D, 0x81, 0xA7, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Get stored count"),
    (bytes([0x7D, 0x81, 0xA8, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Get memory block"),
    (bytes([0x7D, 0x81, 0xAA, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Read record"),
    (bytes([0x7D, 0x81, 0xAB, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Read next"),
    (bytes([0x7D, 0x81, 0xAC, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Read all"),
    
    # Comandos com diferentes prefixos
    (bytes([0x7D, 0x82, 0xA5, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Alt download 1"),
    (bytes([0x7D, 0x83, 0xA5, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Alt download 2"),
    
    # Comandos simples
    (bytes([0xA5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Simple A5"),
    (bytes([0xAA, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "AA 55 sync"),
    (bytes([0x55, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "55 AA sync"),
    
    # Request data
    (bytes([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Request 01"),
    (bytes([0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Request 02"),
    (bytes([0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Request 03"),
    (bytes([0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Request 10"),
    (bytes([0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Request 20"),
    
    # Comandos baseados na resposta f0 70
    (bytes([0xF0, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "F0 01"),
    (bytes([0xF0, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "F0 02"),
    (bytes([0xF0, 0x70, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]), "F0 70 01"),
]

def test_command(device, cmd, name):
    """Envia comando e analisa resposta"""
    # Limpa buffer
    for _ in range(5):
        try:
            device.read(64, timeout_ms=50)
        except:
            pass
    
    # Envia
    try:
        device.write(bytes([0x00]) + cmd)
    except:
        try:
            device.write(cmd)
        except:
            return None
    
    # Lê respostas por 1 segundo
    time.sleep(0.2)
    responses = []
    start = time.time()
    while time.time() - start < 1:
        try:
            data = device.read(64, timeout_ms=100)
            if data:
                responses.append(data)
        except:
            pass
    
    return responses

def main():
    try:
        device = hid.device()
        device.open(VID, PID)
        device.set_nonblocking(True)
        
        print("✅ Conectado ao oxímetro!")
        print()
        
        # Primeiro lê o que vem espontaneamente
        print("📥 Verificando dados espontâneos (5s)...")
        start = time.time()
        spontaneous = []
        while time.time() - start < 5:
            try:
                data = device.read(64, timeout_ms=100)
                if data and any(b not in [0x00, 0xf0, 0x70] for b in data):
                    spontaneous.append(data)
                    hex_str = ' '.join(f'{b:02x}' for b in data[:20])
                    print(f"   🎯 {hex_str}")
            except:
                pass
        
        if not spontaneous:
            print("   Nenhum dado espontâneo")
        
        print()
        print("-" * 60)
        print("🔧 TESTANDO COMANDOS DE DOWNLOAD...")
        print("-" * 60)
        
        interesting_responses = []
        
        for cmd, name in DOWNLOAD_COMMANDS:
            responses = test_command(device, cmd, name)
            
            if responses:
                # Verifica se a resposta é diferente de f0 70 00...
                for r in responses:
                    # Conta bytes diferentes de f0, 70, 00
                    different = sum(1 for b in r if b not in [0x00, 0xf0, 0x70])
                    
                    if different > 2:  # Resposta interessante!
                        print(f"\n🎯 [{name}]:")
                        hex_str = ' '.join(f'{b:02x}' for b in r[:30])
                        print(f"   📥 {hex_str}")
                        interesting_responses.append((name, cmd, r))
                        
                        # Analisa bytes
                        for i, b in enumerate(r):
                            if b not in [0x00, 0xf0, 0x70]:
                                if 85 <= b <= 100:
                                    print(f"   → Byte {i}: {b} (possível SpO2)")
                                elif 40 <= b <= 120:
                                    print(f"   → Byte {i}: {b} (possível Pulso)")
                                else:
                                    print(f"   → Byte {i}: {b} (0x{b:02x})")
        
        device.close()
        
        print()
        print("=" * 60)
        print("📊 RESUMO")
        print("=" * 60)
        
        if interesting_responses:
            print(f"✅ Encontradas {len(interesting_responses)} respostas interessantes!")
            for name, cmd, _ in interesting_responses:
                print(f"   • {name}: {cmd.hex()}")
        else:
            print("❌ Nenhuma resposta com dados significativos")
            print()
            print("💡 SUGESTÕES:")
            print("   1. Tente ligar o oxímetro APÓS conectar o USB")
            print("   2. Pressione e segure o botão ao conectar")
            print("   3. Verifique se há algum menu no oxímetro")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    main()
