cd """
Decodificação Avançada do Eko CORE 500
======================================

Tenta diferentes codecs e formatos de áudio para decodificar
os dados do Eko CORE 500.
"""

import struct
import wave
import numpy as np
from pathlib import Path


# Tabelas para decodificação µ-law e A-law
def _build_ulaw_table():
    """Constrói tabela de decodificação µ-law"""
    table = []
    for i in range(256):
        val = ~i
        sign = val & 0x80
        exponent = (val >> 4) & 0x07
        mantissa = val & 0x0F
        sample = ((mantissa << 3) + 0x84) << exponent
        sample -= 0x84
        if sign:
            sample = -sample
        table.append(sample)
    return table

def _build_alaw_table():
    """Constrói tabela de decodificação A-law"""
    table = []
    for i in range(256):
        val = i ^ 0x55
        sign = val & 0x80
        exponent = (val >> 4) & 0x07
        mantissa = val & 0x0F
        if exponent == 0:
            sample = (mantissa << 4) + 8
        else:
            sample = ((mantissa << 4) + 0x108) << (exponent - 1)
        if sign:
            sample = -sample
        table.append(sample)
    return table

ULAW_TABLE = _build_ulaw_table()
ALAW_TABLE = _build_alaw_table()


def decode_ulaw(data: bytes) -> np.ndarray:
    """Decodifica µ-law (comum em telefonia)"""
    samples = [ULAW_TABLE[b] for b in data]
    return np.array(samples, dtype=np.int16)


def decode_alaw(data: bytes) -> np.ndarray:
    """Decodifica A-law (comum em telefonia europeia)"""
    samples = [ALAW_TABLE[b] for b in data]
    return np.array(samples, dtype=np.int16)


def decode_adpcm_ima(data: bytes) -> np.ndarray:
    """
    Decodifica IMA ADPCM (4-bit)
    Muito comum em dispositivos embarcados e Bluetooth
    """
    # Tabela de passos IMA ADPCM
    step_table = [
        7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
        34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
        157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
        724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024,
        3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
        15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
    ]
    
    # Tabela de índice
    index_table = [
        -1, -1, -1, -1, 2, 4, 6, 8,
        -1, -1, -1, -1, 2, 4, 6, 8
    ]
    
    samples = []
    predictor = 0
    step_index = 0
    
    for byte in data:
        # Cada byte contém 2 samples de 4 bits
        for nibble in [byte & 0x0F, (byte >> 4) & 0x0F]:
            step = step_table[step_index]
            
            # Calcula diferença
            diff = step >> 3
            if nibble & 1:
                diff += step >> 2
            if nibble & 2:
                diff += step >> 1
            if nibble & 4:
                diff += step
            
            # Aplica sinal
            if nibble & 8:
                predictor -= diff
            else:
                predictor += diff
            
            # Clamp
            predictor = max(-32768, min(32767, predictor))
            samples.append(predictor)
            
            # Atualiza índice
            step_index += index_table[nibble]
            step_index = max(0, min(88, step_index))
    
    return np.array(samples, dtype=np.int16)


def decode_adpcm_ms(data: bytes) -> np.ndarray:
    """
    Decodifica Microsoft ADPCM
    """
    # Coeficientes padrão MS ADPCM
    coef1 = [256, 512, 0, 192, 240, 460, 392]
    coef2 = [0, -256, 0, 64, 0, -208, -232]
    
    samples = []
    
    # Estado inicial
    predictor = 0
    delta = 16
    sample1 = 0
    sample2 = 0
    
    for byte in data:
        for nibble in [byte >> 4, byte & 0x0F]:
            # Signed nibble
            if nibble >= 8:
                nibble -= 16
            
            predictor = ((sample1 * coef1[0]) + (sample2 * coef2[0])) // 256
            predictor += nibble * delta
            predictor = max(-32768, min(32767, predictor))
            
            sample2 = sample1
            sample1 = predictor
            samples.append(predictor)
            
            # Atualiza delta
            delta = max(16, (delta * [230, 230, 230, 230, 307, 409, 512, 614, 
                                       230, 230, 230, 230, 307, 409, 512, 614][nibble & 0x0F]) // 256)
    
    return np.array(samples, dtype=np.int16)


def try_nibble_formats(data: bytes) -> dict:
    """
    Tenta diferentes interpretações dos dados como nibbles (4 bits)
    O Eko pode usar formato comprimido de 4 bits por sample
    """
    results = {}
    
    # Remove header de cada pacote
    packet_size = 238
    num_packets = len(data) // packet_size
    
    clean_data = bytearray()
    for i in range(num_packets):
        packet = data[i * packet_size : (i + 1) * packet_size]
        clean_data.extend(packet[1:])  # Skip primeiro byte (contador)
    
    data = bytes(clean_data)
    
    # 1. Nibbles como valores diretos (0-15 escalado)
    samples1 = []
    for byte in data:
        samples1.append(((byte & 0x0F) - 8) * 4096)
        samples1.append((((byte >> 4) & 0x0F) - 8) * 4096)
    results['nibble_direct'] = np.array(samples1, dtype=np.int16)
    
    # 2. Nibbles invertidos
    samples2 = []
    for byte in data:
        samples2.append((((byte >> 4) & 0x0F) - 8) * 4096)
        samples2.append(((byte & 0x0F) - 8) * 4096)
    results['nibble_swapped'] = np.array(samples2, dtype=np.int16)
    
    # 3. IMA ADPCM
    results['ima_adpcm'] = decode_adpcm_ima(data)
    
    return results


def analyze_packet_structure(data: bytes):
    """Analisa a estrutura detalhada dos pacotes"""
    print("\n🔬 ANÁLISE DETALHADA DOS PACOTES")
    print("=" * 60)
    
    packet_size = 238
    num_packets = len(data) // packet_size
    
    # Analisa os primeiros 5 pacotes
    for i in range(min(5, num_packets)):
        packet = data[i * packet_size : (i + 1) * packet_size]
        
        print(f"\n📦 Pacote {i+1}:")
        print(f"   Header (byte 0): {packet[0]} (0x{packet[0]:02X})")
        print(f"   Bytes 1-4: {list(packet[1:5])} = {packet[1:5].hex()}")
        print(f"   Bytes 5-8: {list(packet[5:9])} = {packet[5:9].hex()}")
        
        # Verifica se os primeiros bytes podem ser header adicional
        # Procura por padrões
        payload = packet[1:]
        
        # Conta valores únicos
        unique = len(set(payload))
        print(f"   Valores únicos no payload: {unique}")
        
        # Verifica distribuição
        zeros = sum(1 for b in payload if b < 16)
        mid = sum(1 for b in payload if 100 <= b <= 160)
        high = sum(1 for b in payload if b > 200)
        print(f"   Distribuição: baixos(<16)={zeros}, médios(100-160)={mid}, altos(>200)={high}")


def save_wav(samples: np.ndarray, filename: str, sample_rate: int):
    """Salva array de samples como WAV"""
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(samples.tobytes())


def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 DECODIFICAÇÃO AVANÇADA - EKO CORE 500                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    # Encontra o arquivo mais recente
    bin_files = list(Path(".").glob("eko_raw_*.bin"))
    if not bin_files:
        print("❌ Nenhum arquivo .bin encontrado!")
        return
    
    latest = max(bin_files, key=lambda f: f.stat().st_mtime)
    print(f"📂 Analisando: {latest.name}")
    
    with open(latest, 'rb') as f:
        data = f.read()
    
    print(f"   Tamanho: {len(data)} bytes")
    
    # Análise detalhada
    analyze_packet_structure(data)
    
    # Remove headers dos pacotes
    packet_size = 238
    num_packets = len(data) // packet_size
    
    clean_data = bytearray()
    for i in range(num_packets):
        packet = data[i * packet_size : (i + 1) * packet_size]
        clean_data.extend(packet[1:])
    
    print(f"\n📊 Dados limpos (sem headers): {len(clean_data)} bytes")
    
    # Tenta diferentes decodificações
    print("\n🔊 TENTANDO DECODIFICAÇÕES AVANÇADAS:")
    print("=" * 60)
    
    files_created = []
    
    # 1. µ-law
    try:
        samples = decode_ulaw(bytes(clean_data))
        for rate in [4000, 8000]:
            filename = f"eko_ulaw_{rate}hz.wav"
            save_wav(samples, filename, rate)
            print(f"   ✅ {filename} - µ-law, {rate}Hz")
            files_created.append(filename)
    except Exception as e:
        print(f"   ❌ µ-law: {e}")
    
    # 2. A-law
    try:
        samples = decode_alaw(bytes(clean_data))
        for rate in [4000, 8000]:
            filename = f"eko_alaw_{rate}hz.wav"
            save_wav(samples, filename, rate)
            print(f"   ✅ {filename} - A-law, {rate}Hz")
            files_created.append(filename)
    except Exception as e:
        print(f"   ❌ A-law: {e}")
    
    # 3. IMA ADPCM
    try:
        samples = decode_adpcm_ima(bytes(clean_data))
        for rate in [4000, 8000, 2000]:
            filename = f"eko_ima_adpcm_{rate}hz.wav"
            save_wav(samples, filename, rate)
            duration = len(samples) / rate
            print(f"   ✅ {filename} - IMA ADPCM, {rate}Hz, {duration:.1f}s")
            files_created.append(filename)
    except Exception as e:
        print(f"   ❌ IMA ADPCM: {e}")
    
    # 4. Nibble formats
    try:
        nibble_results = try_nibble_formats(data)
        for name, samples in nibble_results.items():
            for rate in [4000, 8000]:
                filename = f"eko_{name}_{rate}hz.wav"
                save_wav(samples, filename, rate)
                duration = len(samples) / rate
                print(f"   ✅ {filename} - {name}, {rate}Hz, {duration:.1f}s")
                files_created.append(filename)
    except Exception as e:
        print(f"   ❌ Nibble formats: {e}")
    
    # 5. Tenta interpretar como dados já filtrados/processados
    # Os valores 0x00, 0x01, 0x09, 0x10, 0x11, 0x19, 0x91, 0x99 aparecem muito
    # Isso pode ser um formato BCD ou codificação especial
    print("\n🔍 Análise de valores frequentes:")
    value_counts = {}
    for b in clean_data:
        value_counts[b] = value_counts.get(b, 0) + 1
    
    top_values = sorted(value_counts.items(), key=lambda x: -x[1])[:15]
    print("   Top 15 valores mais frequentes:")
    for val, count in top_values:
        pct = count * 100 / len(clean_data)
        print(f"   0x{val:02X} ({val:3d}): {count:5d} ({pct:.1f}%)")
    
    print(f"\n" + "=" * 60)
    print(f"✅ {len(files_created)} arquivos criados!")
    print("=" * 60)
    print("\n🎧 Ouça os arquivos, especialmente:")
    print("   - eko_ima_adpcm_4000hz.wav (ADPCM é muito comum)")
    print("   - eko_ulaw_8000hz.wav (µ-law é padrão telefonia)")
    print("   - eko_alaw_8000hz.wav (A-law alternativo)")


if __name__ == "__main__":
    main()
