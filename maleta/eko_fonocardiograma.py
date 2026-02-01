"""
Captura e Visualização do Fonocardiograma - Eko CORE 500
========================================================

Este script captura áudio do Eko CORE 500, decodifica como IMA ADPCM
e exibe uma visualização do fonocardiograma para confirmar batimentos cardíacos.
"""

import asyncio
import numpy as np
import wave
from datetime import datetime
from pathlib import Path
from bleak import BleakClient

# Configuração do Eko CORE 500
EKO_MAC = "88:D2:11:C8:20:31"
AUDIO_CHARACTERISTIC = "c320d257-d7be-46ac-9a37-7a4edfa84bce"
SAMPLE_RATE = 8000  # Hz - confirmado como melhor taxa

# Buffer para dados
audio_buffer = bytearray()
packet_count = 0


# Tabela de passos IMA ADPCM
STEP_TABLE = [
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
    157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
    724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024,
    3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
]

INDEX_TABLE = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]


def decode_ima_adpcm(data: bytes) -> np.ndarray:
    """Decodifica IMA ADPCM para PCM 16-bit"""
    samples = []
    predictor = 0
    step_index = 0
    
    for byte in data:
        for nibble in [byte & 0x0F, (byte >> 4) & 0x0F]:
            step = STEP_TABLE[step_index]
            
            diff = step >> 3
            if nibble & 1:
                diff += step >> 2
            if nibble & 2:
                diff += step >> 1
            if nibble & 4:
                diff += step
            
            if nibble & 8:
                predictor -= diff
            else:
                predictor += diff
            
            predictor = max(-32768, min(32767, predictor))
            samples.append(predictor)
            
            step_index += INDEX_TABLE[nibble]
            step_index = max(0, min(88, step_index))
    
    return np.array(samples, dtype=np.int16)


def remove_packet_headers(data: bytes, packet_size: int = 238) -> bytes:
    """Remove o primeiro byte (header/contador) de cada pacote"""
    num_packets = len(data) // packet_size
    clean_data = bytearray()
    
    for i in range(num_packets):
        packet = data[i * packet_size : (i + 1) * packet_size]
        clean_data.extend(packet[1:])  # Skip primeiro byte
    
    # Adiciona bytes restantes se houver
    remainder = len(data) % packet_size
    if remainder > 1:
        clean_data.extend(data[-remainder + 1:])
    
    return bytes(clean_data)


def save_wav(samples: np.ndarray, filename: str, sample_rate: int = SAMPLE_RATE):
    """Salva samples como arquivo WAV"""
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(samples.tobytes())


def analyze_heartbeat(samples: np.ndarray, sample_rate: int = SAMPLE_RATE):
    """
    Analisa o sinal para detectar batimentos cardíacos.
    Retorna estimativa de BPM e qualidade do sinal.
    """
    # Normaliza o sinal
    samples_float = samples.astype(float)
    samples_float = samples_float - np.mean(samples_float)
    
    if np.max(np.abs(samples_float)) > 0:
        samples_float = samples_float / np.max(np.abs(samples_float))
    
    # Calcula envelope do sinal (valor absoluto suavizado)
    envelope = np.abs(samples_float)
    
    # Suaviza com média móvel
    window_size = int(sample_rate * 0.05)  # 50ms
    if window_size > 0 and len(envelope) > window_size:
        envelope = np.convolve(envelope, np.ones(window_size)/window_size, mode='same')
    
    # Encontra picos (potenciais batimentos S1/S2)
    threshold = np.mean(envelope) + 0.5 * np.std(envelope)
    peaks = []
    in_peak = False
    peak_start = 0
    
    for i, val in enumerate(envelope):
        if val > threshold and not in_peak:
            in_peak = True
            peak_start = i
        elif val < threshold and in_peak:
            in_peak = False
            peak_center = (peak_start + i) // 2
            peaks.append(peak_center)
    
    # Calcula intervalos entre picos
    if len(peaks) > 1:
        intervals = np.diff(peaks) / sample_rate  # em segundos
        
        # Filtra intervalos plausíveis (entre 0.3s e 2s = 30-200 BPM)
        valid_intervals = intervals[(intervals > 0.3) & (intervals < 2.0)]
        
        if len(valid_intervals) > 0:
            avg_interval = np.mean(valid_intervals)
            bpm = 60 / avg_interval
            
            # Qualidade baseada na consistência dos intervalos
            if len(valid_intervals) > 1:
                std_interval = np.std(valid_intervals)
                quality = max(0, min(100, 100 - (std_interval / avg_interval * 200)))
            else:
                quality = 50
            
            return {
                'bpm': round(bpm),
                'quality': round(quality),
                'peaks_detected': len(peaks),
                'duration_seconds': len(samples) / sample_rate
            }
    
    return {
        'bpm': None,
        'quality': 0,
        'peaks_detected': len(peaks),
        'duration_seconds': len(samples) / sample_rate
    }


def create_text_visualization(samples: np.ndarray, width: int = 60, height: int = 15):
    """Cria uma visualização ASCII do sinal de áudio"""
    # Downsample para caber na largura
    step = max(1, len(samples) // width)
    downsampled = samples[::step][:width]
    
    # Normaliza para altura
    min_val = np.min(downsampled)
    max_val = np.max(downsampled)
    
    if max_val - min_val > 0:
        normalized = ((downsampled - min_val) / (max_val - min_val) * (height - 1)).astype(int)
    else:
        normalized = np.zeros(len(downsampled), dtype=int)
    
    # Cria grid
    lines = []
    for row in range(height - 1, -1, -1):
        line = ""
        for col in range(len(normalized)):
            if normalized[col] == row:
                line += "█"
            elif row == height // 2:
                line += "─"
            else:
                line += " "
        lines.append(line)
    
    return "\n".join(lines)


def notification_handler(sender, data):
    """Handler para notificações BLE"""
    global audio_buffer, packet_count
    audio_buffer.extend(data)
    packet_count += 1
    
    if packet_count % 50 == 0:
        print(f"   📦 {packet_count} pacotes recebidos ({len(audio_buffer)} bytes)")


async def capture_and_analyze(duration_seconds: int = 15):
    """Captura áudio do Eko e analisa"""
    global audio_buffer, packet_count
    audio_buffer = bytearray()
    packet_count = 0
    
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 CAPTURA DE FONOCARDIOGRAMA - EKO CORE 500               ║
║                                                              ║
║   Formato: IMA ADPCM @ 8000Hz                                ║
║   Duração: {duration_seconds} segundos                                        ║
║                                                              ║
║   INSTRUÇÕES:                                                ║
║   1. Coloque o estetoscópio no peito (lado esquerdo)         ║
║   2. Mantenha parado durante a captura                       ║
║   3. Evite falar ou fazer barulho                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    input("Pressione ENTER quando estiver pronto para iniciar...")
    
    print(f"\n🔍 Conectando ao Eko CORE 500 ({EKO_MAC})...")
    
    try:
        async with BleakClient(EKO_MAC, timeout=30.0) as client:
            print(f"✅ Conectado!")
            
            print(f"\n🎤 CAPTURANDO POR {duration_seconds} SEGUNDOS...")
            print("   Mantenha o estetoscópio no peito\n")
            
            await client.start_notify(AUDIO_CHARACTERISTIC, notification_handler)
            
            # Countdown visual
            for remaining in range(duration_seconds, 0, -1):
                print(f"   ⏱️ {remaining:2d} segundos restantes...", end="\r")
                await asyncio.sleep(1)
            
            await client.stop_notify(AUDIO_CHARACTERISTIC)
            print("\n\n🛑 Captura finalizada!")
            
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        return None
    
    if len(audio_buffer) == 0:
        print("❌ Nenhum dado capturado!")
        return None
    
    # Processa os dados
    print(f"\n📊 PROCESSANDO DADOS...")
    print(f"   Bytes capturados: {len(audio_buffer)}")
    print(f"   Pacotes recebidos: {packet_count}")
    
    # Remove headers dos pacotes
    clean_data = remove_packet_headers(bytes(audio_buffer))
    print(f"   Bytes de áudio: {len(clean_data)}")
    
    # Decodifica IMA ADPCM
    samples = decode_ima_adpcm(clean_data)
    duration = len(samples) / SAMPLE_RATE
    print(f"   Samples decodificados: {len(samples)}")
    print(f"   Duração do áudio: {duration:.1f} segundos")
    
    # Salva arquivo WAV
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    wav_filename = f"fonocardiograma_{timestamp}.wav"
    save_wav(samples, wav_filename)
    print(f"\n💾 Arquivo salvo: {wav_filename}")
    
    # Análise de batimentos
    print(f"\n" + "=" * 60)
    print("   🫀 ANÁLISE DO FONOCARDIOGRAMA")
    print("=" * 60)
    
    analysis = analyze_heartbeat(samples)
    
    if analysis['bpm']:
        print(f"\n   ❤️ Frequência Cardíaca Estimada: {analysis['bpm']} BPM")
        print(f"   📊 Qualidade do sinal: {analysis['quality']}%")
        print(f"   🔍 Picos detectados: {analysis['peaks_detected']}")
    else:
        print(f"\n   ⚠️ Não foi possível estimar a frequência cardíaca")
        print(f"   🔍 Picos detectados: {analysis['peaks_detected']}")
        print(f"   💡 Tente posicionar melhor o estetoscópio")
    
    # Visualização ASCII
    print(f"\n📈 FORMA DE ONDA (primeiros 3 segundos):")
    print("-" * 62)
    
    # Pega primeiros 3 segundos
    samples_3s = samples[:int(SAMPLE_RATE * 3)]
    visualization = create_text_visualization(samples_3s, width=60, height=12)
    print(visualization)
    print("-" * 62)
    
    print(f"\n✅ Fonocardiograma capturado com sucesso!")
    print(f"   Ouça o arquivo: {wav_filename}")
    
    return {
        'filename': wav_filename,
        'samples': samples,
        'analysis': analysis
    }


async def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 EKO CORE 500 - FONOCARDIOGRAMA                          ║
║                                                              ║
║   Sistema de captura e análise de sons cardíacos             ║
║   Formato confirmado: IMA ADPCM @ 8000Hz                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Escolha a duração da captura:
   [1] 10 segundos (teste rápido)
   [2] 15 segundos (recomendado)
   [3] 30 segundos (análise completa)
   [4] 60 segundos (gravação longa)
   [0] Sair
    """)
    
    try:
        choice = input("👉 Opção: ").strip()
        
        durations = {"1": 10, "2": 15, "3": 30, "4": 60}
        
        if choice in durations:
            await capture_and_analyze(durations[choice])
        elif choice == "0":
            print("Saindo...")
        else:
            print("Opção inválida")
            
    except KeyboardInterrupt:
        print("\n👋 Cancelado")


if __name__ == "__main__":
    asyncio.run(main())
