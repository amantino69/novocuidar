#!/usr/bin/env python3
"""
Análise detalhada do protocolo do Oxímetro USB
VID: 0x28e9, PID: 0x028a
"""

import hid
import time

VID = 0x28e9
PID = 0x028a

def analyze_oximeter():
    print("=" * 60)
    print("    ANÁLISE DE PROTOCOLO - OXÍMETRO USB")
    print("    VID: 0x28e9 | PID: 0x028a")
    print("=" * 60)
    print()
    print("📌 COLOQUE O OXÍMETRO NO DEDO E AGUARDE A LEITURA")
    print("   O oxímetro deve estar mostrando valores no display")
    print()
    
    try:
        device = hid.device()
        device.open(VID, PID)
        device.set_nonblocking(False)  # Bloqueia até receber dados
        
        print("✅ Conectado ao oxímetro!")
        print()
        
        # Tenta diferentes comandos de inicialização
        commands = [
            bytes([0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),  # CMS50D padrão
            bytes([0xA7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),        # Alternativo 1
            bytes([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),        # Alternativo 2
            bytes([0x00] * 8),  # Zeros
            bytes([0xF0, 0x70]),  # Baseado na resposta recebida
        ]
        
        print("🔧 Testando comandos de inicialização...")
        for i, cmd in enumerate(commands):
            try:
                device.write(cmd)
                print(f"   Comando {i+1} enviado: {cmd.hex()}")
                time.sleep(0.1)
            except:
                pass
        
        print()
        print("-" * 60)
        print("📊 CAPTURANDO DADOS (30 segundos)...")
        print("   Formatos conhecidos:")
        print("   - CMS50D: [sync, signal, pleth, pulse, spo2]")
        print("   - Berry: [0x01, flags, pulse, spo2, pleth]")
        print("-" * 60)
        print()
        
        packets = []
        start_time = time.time()
        last_display = 0
        
        while time.time() - start_time < 30:
            try:
                # Lê com timeout de 500ms
                data = device.read(64, timeout_ms=500)
                
                if data and len(data) > 0:
                    packets.append(data)
                    hex_str = ' '.join(f'{b:02x}' for b in data)
                    
                    # Análise dos dados
                    now = time.time()
                    if now - last_display > 0.5:  # Mostra a cada 0.5s
                        last_display = now
                        print(f"📥 Pacote #{len(packets):3d}: {hex_str[:50]}...")
                        
                        # Tenta identificar SpO2 e Pulso em diferentes posições
                        valid_spo2 = []
                        valid_pulse = []
                        
                        for i, byte in enumerate(data):
                            if 85 <= byte <= 100:
                                valid_spo2.append((i, byte))
                            if 50 <= byte <= 120:
                                valid_pulse.append((i, byte))
                        
                        if valid_spo2:
                            print(f"   Possível SpO2: {valid_spo2}")
                        if valid_pulse:
                            print(f"   Possível Pulso: {valid_pulse}")
                        
                        # Verifica padrões específicos
                        if len(data) >= 5:
                            # Padrão CMS50D
                            if data[0] & 0x80:  # Bit 7 set = sync
                                spo2 = data[4] & 0x7F
                                pulse = data[3] & 0x7F
                                if 70 <= spo2 <= 100 and 40 <= pulse <= 200:
                                    print(f"   ✅ Formato CMS50D: SpO2={spo2}%, Pulso={pulse} bpm")
                            
                            # Outro padrão comum
                            if data[0] == 0x01:
                                spo2 = data[4]
                                pulse = data[3]
                                if 70 <= spo2 <= 100 and 40 <= pulse <= 200:
                                    print(f"   ✅ Formato Alt: SpO2={spo2}%, Pulso={pulse} bpm")
                    
            except Exception as e:
                print(f"   Erro: {e}")
        
        device.close()
        
        print()
        print("=" * 60)
        print("📊 RESUMO DA ANÁLISE")
        print("=" * 60)
        print(f"   Pacotes recebidos: {len(packets)}")
        
        if packets:
            # Analisa padrões
            print("\n   Primeiros 10 pacotes:")
            for i, p in enumerate(packets[:10]):
                hex_str = ' '.join(f'{b:02x}' for b in p)
                print(f"   [{i+1}] {hex_str}")
            
            # Identifica bytes que mudam (provavelmente dados)
            if len(packets) > 5:
                print("\n   Análise de variação dos bytes:")
                first = packets[0]
                variations = [set() for _ in range(len(first))]
                
                for p in packets[:20]:
                    for i in range(min(len(p), len(first))):
                        variations[i].add(p[i])
                
                for i, v in enumerate(variations[:15]):
                    if len(v) > 1:
                        print(f"   Byte {i}: Varia! Valores: {sorted(v)}")
                    else:
                        print(f"   Byte {i}: Fixo = {list(v)[0]:02x}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

if __name__ == "__main__":
    analyze_oximeter()
