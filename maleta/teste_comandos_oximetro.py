#!/usr/bin/env python3
"""
Teste extensivo de comandos para oxímetro USB
VID: 0x28e9 | PID: 0x028a
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

# Lista de comandos conhecidos de diferentes oxímetros
COMMANDS = [
    # CMS50D/CMS50E standard
    (bytes([0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "CMS50D Start"),
    (bytes([0x7D, 0x81, 0xAF, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "CMS50D Info"),
    (bytes([0x7D, 0x81, 0xB0, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "CMS50D GetData"),
    
    # Berry/BerryMed
    (bytes([0xA7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "Berry Start"),
    (bytes([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Berry Alt"),
    
    # Protocolo YK-80x (comum em genéricos chineses)
    (bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "YK80 Zeros"),
    (bytes([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "YK80 Start"),
    (bytes([0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), "YK80 Read"),
    
    # Report IDs comuns
    (bytes([0x00] + [0x00] * 7), "Report 0"),
    (bytes([0x01] + [0x00] * 7), "Report 1"),
    (bytes([0x02] + [0x00] * 7), "Report 2"),
    (bytes([0x09] + [0x00] * 7), "Report 9"),
    
    # Comandos alternativos
    (bytes([0xF0, 0x70] + [0x00] * 6), "Based on response"),
    (bytes([0x70, 0xF0] + [0x00] * 6), "Reverse"),
    (bytes([0xFF] * 8), "All FF"),
    (bytes([0xAA] * 8), "All AA"),
    (bytes([0x55] * 8), "All 55"),
    
    # Contec específicos
    (bytes([0x7D, 0x81, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Contec A"),
    (bytes([0x7D, 0x82, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), "Contec B"),
]

def test_commands():
    print("=" * 60)
    print("    TESTE DE COMANDOS - OXÍMETRO USB")
    print("    VID: 0x28e9 | PID: 0x028a")
    print("=" * 60)
    print()
    print("⚠️  MANTENHA O DEDO NO OXÍMETRO DURANTE TODO O TESTE!")
    print()
    
    try:
        device = hid.device()
        device.open(VID, PID)
        device.set_nonblocking(True)
        
        print("✅ Conectado ao oxímetro!\n")
        
        # Primeiro, lê o que vem antes de qualquer comando
        print("📥 Lendo dados iniciais (3 segundos)...")
        start = time.time()
        initial_data = []
        while time.time() - start < 3:
            data = device.read(64, timeout_ms=100)
            if data:
                initial_data.append(data)
        print(f"   Pacotes iniciais recebidos: {len(initial_data)}")
        if initial_data:
            for d in initial_data[:3]:
                print(f"   → {' '.join(f'{b:02x}' for b in d[:20])}")
        
        print("\n" + "-" * 60)
        print("🔧 TESTANDO COMANDOS...")
        print("-" * 60)
        
        for cmd, name in COMMANDS:
            print(f"\n📤 [{name}]: {cmd.hex()}")
            
            # Limpa buffer
            while device.read(64, timeout_ms=50):
                pass
            
            # Envia comando
            try:
                # Tenta com report ID 0
                device.write(bytes([0x00]) + cmd)
            except:
                try:
                    # Tenta sem report ID
                    device.write(cmd)
                except Exception as e:
                    print(f"   ⚠️ Falha ao enviar: {e}")
                    continue
            
            # Aguarda resposta
            time.sleep(0.5)
            
            responses = []
            for _ in range(10):
                data = device.read(64, timeout_ms=100)
                if data and any(b != 0 for b in data):
                    responses.append(data)
            
            if responses:
                print(f"   ✅ Recebeu {len(responses)} respostas!")
                for r in responses[:3]:
                    hex_str = ' '.join(f'{b:02x}' for b in r[:20])
                    print(f"   📥 {hex_str}")
                    
                    # Tenta identificar SpO2/Pulso
                    for i in range(len(r) - 1):
                        b1, b2 = r[i], r[i+1]
                        if 90 <= b1 <= 100 and 50 <= b2 <= 120:
                            print(f"      🎯 Possível SpO2={b1}%, Pulso={b2}")
                        if 50 <= b1 <= 120 and 90 <= b2 <= 100:
                            print(f"      🎯 Possível Pulso={b1}, SpO2={b2}%")
            else:
                print(f"   ❌ Sem resposta")
        
        device.close()
        
        print("\n" + "=" * 60)
        print("✅ Teste concluído!")
        print("=" * 60)
        
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    test_commands()
