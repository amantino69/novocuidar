"""
Análise e Conversão dos Dados do Eko CORE 500
=============================================

Este script analisa os dados brutos capturados do Eko e tenta
diferentes configurações para encontrar o formato correto do áudio.
"""

import struct
import wave
import numpy as np
from pathlib import Path
import os

def analyze_raw_data(filename: str):
    """Analisa os dados brutos do Eko"""
    print(f"\n📊 ANÁLISE DE: {filename}")
    print("=" * 60)
    
    with open(filename, 'rb') as f:
        data = f.read()
    
    print(f"Tamanho total: {len(data)} bytes")
    
    # Análise estatística
    bytes_array = np.frombuffer(data, dtype=np.uint8)
    print(f"Valor mínimo (byte): {bytes_array.min()}")
    print(f"Valor máximo (byte): {bytes_array.max()}")
    print(f"Média: {bytes_array.mean():.2f}")
    print(f"Desvio padrão: {bytes_array.std():.2f}")
    
    # Histograma simplificado
    print("\n📈 Distribuição de valores:")
    hist, bins = np.histogram(bytes_array, bins=10)
    for i, (count, bin_start) in enumerate(zip(hist, bins[:-1])):
        bar = "█" * (count * 40 // max(hist))
        print(f"   {int(bin_start):3d}-{int(bins[i+1]):3d}: {bar} ({count})")
    
    # Mostra primeiros bytes
    print(f"\nPrimeiros 50 bytes (hex): {data[:50].hex()}")
    print(f"Primeiros 50 bytes (dec): {list(data[:50])}")
    
    # Tenta detectar padrões
    print("\n🔍 ANÁLISE DE PADRÕES:")
    
    # Verifica se os dados têm estrutura de pacotes
    # O Eko envia pacotes de 238 bytes
    packet_size = 238
    num_packets = len(data) // packet_size
    print(f"   Possíveis pacotes de {packet_size} bytes: {num_packets}")
    
    if num_packets > 0:
        # Analisa estrutura do pacote
        first_packet = data[:packet_size]
        print(f"\n   Estrutura do primeiro pacote:")
        print(f"   Byte 0 (possível header/contador): {first_packet[0]}")
        print(f"   Bytes 1-10: {list(first_packet[1:11])}")
        
        # Verifica se o primeiro byte é um contador
        counters = [data[i * packet_size] for i in range(min(10, num_packets))]
        print(f"   Primeiros bytes de cada pacote: {counters}")
        
        # Se os valores incrementam, é provavelmente um contador
        if all(counters[i] < counters[i+1] or counters[i] - counters[i+1] > 200 for i in range(len(counters)-1)):
            print("   ✅ Parece ser um contador de pacotes no primeiro byte!")
    
    return data


def try_audio_conversion(data: bytes, output_prefix: str):
    """Tenta várias configurações de conversão para áudio"""
    print("\n🔊 TENTANDO CONVERSÕES DE ÁUDIO:")
    print("=" * 60)
    
    # Configurações para tentar
    configs = [
        # (sample_rate, bits, skip_bytes, description)
        (4000, 16, 0, "PCM 16-bit, 4kHz, sem header"),
        (4000, 16, 1, "PCM 16-bit, 4kHz, skip 1 byte header"),
        (8000, 16, 0, "PCM 16-bit, 8kHz, sem header"),
        (8000, 16, 1, "PCM 16-bit, 8kHz, skip 1 byte header"),
        (16000, 16, 0, "PCM 16-bit, 16kHz, sem header"),
        (4000, 8, 0, "PCM 8-bit, 4kHz"),
        (4000, 8, 1, "PCM 8-bit, 4kHz, skip 1 byte"),
        (8000, 8, 0, "PCM 8-bit, 8kHz"),
        (8000, 8, 1, "PCM 8-bit, 8kHz, skip 1 byte"),
        # Fonocardiograma típico é 1000-2000 Hz
        (2000, 16, 1, "PCM 16-bit, 2kHz (típico fonocardio)"),
        (1000, 16, 1, "PCM 16-bit, 1kHz"),
    ]
    
    # Remove header de cada pacote se houver
    packet_size = 238
    num_packets = len(data) // packet_size
    
    # Dados sem o primeiro byte de cada pacote (possível contador)
    data_no_header = bytearray()
    for i in range(num_packets):
        packet = data[i * packet_size : (i + 1) * packet_size]
        data_no_header.extend(packet[1:])  # Skip primeiro byte
    
    files_created = []
    
    for sample_rate, bits, skip, desc in configs:
        try:
            if skip > 0:
                audio_data = bytes(data_no_header)
            else:
                audio_data = data
            
            # Ajusta tamanho para ser par (16-bit)
            if bits == 16 and len(audio_data) % 2 != 0:
                audio_data = audio_data[:-1]
            
            if bits == 16:
                samples = np.frombuffer(audio_data, dtype=np.int16)
            else:
                # 8-bit unsigned para signed
                samples = np.frombuffer(audio_data, dtype=np.uint8).astype(np.int16) - 128
                samples = (samples * 256).astype(np.int16)
            
            # Normaliza para usar toda a faixa dinâmica
            if samples.max() > samples.min():
                samples = ((samples - samples.min()) / (samples.max() - samples.min()) * 65534 - 32767).astype(np.int16)
            
            filename = f"{output_prefix}_{sample_rate}hz_{bits}bit_skip{skip}.wav"
            
            with wave.open(filename, 'w') as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)  # Sempre salva como 16-bit
                wav_file.setframerate(sample_rate)
                wav_file.writeframes(samples.tobytes())
            
            duration = len(samples) / sample_rate
            print(f"   ✅ {filename}")
            print(f"      {desc}")
            print(f"      Duração: {duration:.2f}s, Samples: {len(samples)}")
            files_created.append(filename)
            
        except Exception as e:
            print(f"   ❌ {desc}: {e}")
    
    return files_created


def extract_packet_payload(data: bytes, header_size: int = 1):
    """Extrai apenas o payload de cada pacote, removendo headers"""
    packet_size = 238
    num_packets = len(data) // packet_size
    
    payload = bytearray()
    for i in range(num_packets):
        packet = data[i * packet_size : (i + 1) * packet_size]
        payload.extend(packet[header_size:])
    
    return bytes(payload)


def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 ANÁLISE DE DADOS DO EKO CORE 500                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    # Encontra arquivos .bin
    bin_files = list(Path(".").glob("eko_raw_*.bin"))
    
    if not bin_files:
        print("❌ Nenhum arquivo eko_raw_*.bin encontrado!")
        print("   Execute primeiro o capture_eko.py")
        return
    
    print(f"📁 Arquivos encontrados: {len(bin_files)}")
    for i, f in enumerate(bin_files):
        print(f"   [{i+1}] {f.name} ({f.stat().st_size} bytes)")
    
    # Usa o mais recente
    latest = max(bin_files, key=lambda f: f.stat().st_mtime)
    print(f"\n📂 Analisando arquivo mais recente: {latest.name}")
    
    # Analisa
    data = analyze_raw_data(str(latest))
    
    # Tenta conversões
    output_prefix = latest.stem.replace("raw", "converted")
    files = try_audio_conversion(data, output_prefix)
    
    print(f"\n" + "=" * 60)
    print(f"✅ {len(files)} arquivos de áudio criados!")
    print("=" * 60)
    print("\n🎧 Ouça cada arquivo para identificar qual soa melhor.")
    print("   Arquivos com taxa de amostragem maior = áudio mais rápido")
    print("   Arquivos com taxa menor = áudio mais lento")
    print("\n   O fonocardiograma típico usa 1000-4000 Hz")
    
    # Abre pasta
    os.startfile(".")


if __name__ == "__main__":
    main()
