#!/usr/bin/env python3
"""
Protocolo PC-60FW / Berry BM1000
VID: 0x28e9 | PID: 0x028a
"""

import hid
import time
import struct

VID = 0x28e9
PID = 0x028a

print("=" * 60)
print("    PROTOCOLO PC-60FW - OXÍMETRO USB")
print("    SpO2: 94% | Pulso: 61 bpm (valores do display)")
print("=" * 60)
print()

# Comandos do protocolo PC-60FW / Berry
PC60_COMMANDS = [
    # Formato: [Length, Type, Op, Data...]
    bytes([0x7D, 0x81, 0xA7, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),  # PC-60 real-time
    bytes([0x7D, 0x81, 0xA2, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),  # PC-60 waveform
    bytes([0x7D, 0x81, 0xA6, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),  # PC-60 device info
    bytes([0x7D, 0x81, 0xAD, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]),  # Stop
    
    # ChoiceMMed / Berry específico
    bytes([0x02, 0x70, 0x01, 0x01, 0x74]),  # Start measurement
    bytes([0x02, 0x70, 0x02, 0x01, 0x75]),  # Get data
    bytes([0x02, 0x70, 0x00, 0x00, 0x72]),  # Status
    
    # Feature reports
    bytes([0x00, 0x01]),  # Feature report get
    bytes([0x00, 0x02]),
    bytes([0x00, 0x70]),
    
    # Output reports alternativos
    bytes([0x70, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    bytes([0x70, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    bytes([0x70, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
]

def try_feature_report(device):
    """Tenta ler feature reports"""
    print("\n📋 Tentando Feature Reports...")
    for report_id in range(10):
        try:
            data = device.get_feature_report(report_id, 64)
            if data and any(b != 0 for b in data):
                print(f"   Feature Report {report_id}: {' '.join(f'{b:02x}' for b in data[:20])}")
        except:
            pass

def try_input_reports(device):
    """Tenta ler diferentes tipos de input"""
    print("\n📥 Lendo Input Reports por 10 segundos...")
    print("   (Mantenha o dedo no oxímetro!)")
    
    start = time.time()
    seen = set()
    
    while time.time() - start < 10:
        try:
            data = device.read(64, timeout_ms=200)
            if data:
                key = tuple(data)
                if key not in seen:
                    seen.add(key)
                    hex_str = ' '.join(f'{b:02x}' for b in data[:20])
                    print(f"   📥 {hex_str}")
                    
                    # Procura por 94 (0x5E) e 61 (0x3D) nos dados
                    if 0x5E in data or 0x3D in data:
                        print(f"      🎯 Encontrado 0x5E(94) ou 0x3D(61)!")
                        for i, b in enumerate(data):
                            if b == 0x5E:
                                print(f"         Byte {i} = 0x5E (94 = SpO2?)")
                            if b == 0x3D:
                                print(f"         Byte {i} = 0x3D (61 = Pulso?)")
        except:
            pass
    
    print(f"   Padrões únicos vistos: {len(seen)}")

def send_and_receive(device, cmd, name):
    """Envia comando e lê resposta"""
    print(f"\n📤 [{name}]: {cmd.hex()}")
    
    # Limpa buffer
    try:
        while device.read(64, timeout_ms=50):
            pass
    except:
        pass
    
    # Tenta diferentes formas de enviar
    sent = False
    for method in ['with_report_id', 'direct', 'feature']:
        try:
            if method == 'with_report_id':
                device.write(bytes([0x00]) + cmd)
            elif method == 'direct':
                device.write(cmd)
            elif method == 'feature':
                device.send_feature_report(bytes([0x00]) + cmd)
            sent = True
            break
        except:
            pass
    
    if not sent:
        print(f"   ⚠️ Não conseguiu enviar")
        return
    
    # Lê respostas
    time.sleep(0.3)
    responses = []
    for _ in range(5):
        try:
            data = device.read(64, timeout_ms=200)
            if data and any(b != 0 for b in data):
                responses.append(data)
        except:
            break
    
    if responses:
        for r in responses:
            hex_str = ' '.join(f'{b:02x}' for b in r[:25])
            print(f"   📥 {hex_str}")
            
            # Procura valores
            non_zero = [(i, b) for i, b in enumerate(r) if b not in [0x00, 0xf0, 0x70]]
            if non_zero:
                print(f"      Bytes com dados: {non_zero[:10]}")
    else:
        print(f"   ❌ Sem resposta significativa")

def main():
    try:
        device = hid.device()
        device.open(VID, PID)
        device.set_nonblocking(True)
        
        print("✅ Conectado ao oxímetro!")
        
        # Tenta feature reports primeiro
        try_feature_report(device)
        
        # Lê inputs iniciais
        try_input_reports(device)
        
        # Testa comandos
        print("\n" + "=" * 60)
        print("🔧 TESTANDO COMANDOS ESPECÍFICOS...")
        print("=" * 60)
        
        for cmd in PC60_COMMANDS:
            name = f"Cmd {cmd[:3].hex()}"
            send_and_receive(device, cmd, name)
            time.sleep(0.2)
        
        # Tenta leitura contínua após comandos
        print("\n" + "=" * 60)
        print("📊 LEITURA CONTÍNUA PÓS-COMANDOS (15 segundos)...")
        print("=" * 60)
        
        start = time.time()
        unique_packets = set()
        
        while time.time() - start < 15:
            try:
                data = device.read(64, timeout_ms=100)
                if data:
                    key = tuple(data)
                    if key not in unique_packets:
                        unique_packets.add(key)
                        hex_str = ' '.join(f'{b:02x}' for b in data[:30])
                        print(f"📥 {hex_str}")
                        
                        # Análise específica para SpO2=94, Pulso=61
                        for i in range(len(data) - 1):
                            if data[i] == 94 or data[i] == 61:
                                print(f"   🎯 Byte {i} = {data[i]} (SpO2 ou Pulso?)")
            except Exception as e:
                if "read error" in str(e):
                    device.close()
                    device = hid.device()
                    device.open(VID, PID)
                    device.set_nonblocking(True)
                    print("   ⟳ Reconectado")
        
        print(f"\n📊 Total de padrões únicos: {len(unique_packets)}")
        
        device.close()
        
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    main()
