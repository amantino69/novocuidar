#!/usr/bin/env python3
"""
Diagnóstico de Oxímetro USB (Contec CMS50D)
Lê dados via protocolo HID USB
"""

import hid
import time

# Vendor/Product IDs conhecidos do Contec CMS50D
CONTEC_VENDOR_IDS = [0x0c45, 0x28e9, 0x4b3c]  # Possíveis VIDs
CONTEC_PRODUCT_IDS = [0x7500, 0x7000]  # Possíveis PIDs

def list_hid_devices():
    """Lista todos os dispositivos HID conectados"""
    print("=" * 60)
    print("    DISPOSITIVOS HID USB DETECTADOS")
    print("=" * 60)
    
    devices = hid.enumerate()
    oximeter_candidates = []
    
    for d in devices:
        vid = d['vendor_id']
        pid = d['product_id']
        manufacturer = d.get('manufacturer_string', '') or ''
        product = d.get('product_string', '') or ''
        path = d['path']
        
        # Verifica se pode ser o oxímetro
        is_candidate = False
        if any(kw in product.lower() for kw in ['pulse', 'oximeter', 'spo2', 'contec', 'cms']):
            is_candidate = True
        if any(kw in manufacturer.lower() for kw in ['contec', 'medical']):
            is_candidate = True
        if vid in CONTEC_VENDOR_IDS:
            is_candidate = True
            
        if is_candidate:
            oximeter_candidates.append(d)
            print(f"🎯 POSSÍVEL OXÍMETRO:")
        else:
            print(f"   Dispositivo HID:")
            
        print(f"      VID: 0x{vid:04x} | PID: 0x{pid:04x}")
        print(f"      Fabricante: {manufacturer}")
        print(f"      Produto: {product}")
        print(f"      Path: {path.decode() if isinstance(path, bytes) else path}")
        print()
    
    return oximeter_candidates, devices

def try_read_oximeter(device_info):
    """Tenta ler dados do oxímetro"""
    print("=" * 60)
    print(f"🔬 TENTANDO LER: {device_info.get('product_string', 'Desconhecido')}")
    print("=" * 60)
    
    try:
        device = hid.device()
        device.open_path(device_info['path'])
        device.set_nonblocking(True)
        
        print("✅ Dispositivo aberto com sucesso!")
        print("\n📊 Lendo dados por 15 segundos...")
        print("   (Certifique-se que o oxímetro está no dedo e medindo)")
        print("-" * 50)
        
        # Alguns oxímetros precisam de um comando para iniciar streaming
        # Comando comum do CMS50D: 0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
        try:
            cmd = bytes([0x7D, 0x81, 0xA1, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80])
            device.write(cmd)
            print("   → Comando de streaming enviado")
        except Exception as e:
            print(f"   → Não foi possível enviar comando: {e}")
        
        packets_received = 0
        start_time = time.time()
        last_spo2 = None
        last_pulse = None
        
        while time.time() - start_time < 15:
            try:
                data = device.read(64, timeout_ms=100)
                if data:
                    packets_received += 1
                    hex_data = ' '.join(f'{b:02x}' for b in data)
                    
                    # Tenta decodificar dados do CMS50D
                    # Formato típico: sync byte, status, SpO2, pulse...
                    if len(data) >= 5:
                        # Formato CMS50D típico
                        if data[0] == 0x01:  # Sync byte comum
                            spo2 = data[4] if len(data) > 4 else 0
                            pulse = data[3] if len(data) > 3 else 0
                            
                            if 70 <= spo2 <= 100 and 40 <= pulse <= 200:
                                last_spo2 = spo2
                                last_pulse = pulse
                                print(f"\r   📥 SpO2: {spo2}% | Pulso: {pulse} bpm    ", end='', flush=True)
                        else:
                            # Tenta outros formatos
                            for i in range(len(data) - 1):
                                possible_spo2 = data[i]
                                possible_pulse = data[i + 1] if i + 1 < len(data) else 0
                                
                                if 90 <= possible_spo2 <= 100 and 50 <= possible_pulse <= 120:
                                    print(f"\n   ❓ Possíveis valores em offset {i}: SpO2={possible_spo2}%, Pulso={possible_pulse}")
                    
                    if packets_received <= 5 or packets_received % 20 == 0:
                        print(f"\n   Raw [{packets_received}]: {hex_data[:50]}...")
                        
            except Exception as e:
                pass
            
            time.sleep(0.05)
        
        print(f"\n\n{'='*60}")
        print("📊 RESULTADO:")
        print("=" * 60)
        
        if packets_received > 0:
            print(f"✅ Recebidos {packets_received} pacotes de dados!")
            if last_spo2 and last_pulse:
                print(f"   📈 Última leitura: SpO2 = {last_spo2}%, Pulso = {last_pulse} bpm")
                print("\n🎉 OXÍMETRO COMPATÍVEL! Podemos integrar no TeleCuidar!")
                return True, device_info
            else:
                print("   ⚠️ Dados recebidos mas formato não reconhecido")
                print("   → Pode precisar de análise adicional do protocolo")
                return True, device_info
        else:
            print("❌ Nenhum dado recebido")
            print("   → Verifique se o oxímetro está medindo (dedo inserido)")
            return False, None
            
        device.close()
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False, None

def main():
    print("=" * 60)
    print("    DIAGNÓSTICO DE OXÍMETRO USB - TeleCuidar")
    print("    (Contec CMS50D e similares)")
    print("=" * 60)
    print()
    print("📌 Instruções:")
    print("   1. Conecte o oxímetro via USB")
    print("   2. Ligue o oxímetro")
    print("   3. Coloque-o no dedo")
    print("   4. Aguarde a leitura estabilizar")
    print()
    
    candidates, all_devices = list_hid_devices()
    
    if not all_devices:
        print("❌ Nenhum dispositivo HID encontrado!")
        return
    
    print(f"\n📱 Total de dispositivos HID: {len(all_devices)}")
    print(f"🎯 Possíveis oxímetros: {len(candidates)}")
    
    if candidates:
        for c in candidates:
            success, device = try_read_oximeter(c)
            if success:
                print(f"\n📋 Informações para configuração:")
                print(f"   VID: 0x{c['vendor_id']:04x}")
                print(f"   PID: 0x{c['product_id']:04x}")
                break
    else:
        print("\n⚠️ Nenhum oxímetro identificado automaticamente.")
        print("   Vamos tentar todos os dispositivos HID...")
        
        for d in all_devices:
            if d.get('product_string'):
                print(f"\n   Tentando: {d.get('product_string', 'Unknown')}")
                success, device = try_read_oximeter(d)
                if success:
                    break

if __name__ == "__main__":
    main()
