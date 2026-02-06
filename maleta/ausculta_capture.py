"""
Captura de Fonocardiograma - Estetoscópio Digital (P2)
======================================================

Captura áudio do estetoscópio conectado via entrada P2 (3.5mm).
Envia para o TeleCuidar em tempo real.

Dispositivo: Estetoscópio com saída de áudio P2 (ex: Ausculta)
Entrada: Realtek Audio - "Ausculta"

Uso:
  python ausculta_capture.py              # Captura 10s e envia para servidor local
  python ausculta_capture.py --prod       # Envia para produção
  python ausculta_capture.py --duration 15  # Captura 15 segundos
  python ausculta_capture.py --continuous   # Modo contínuo (captura a cada 10s)
"""

import numpy as np
import wave
import time
import asyncio
import aiohttp
import base64
import argparse
from datetime import datetime
from pathlib import Path

try:
    import sounddevice as sd
    SOUNDDEVICE_AVAILABLE = True
except ImportError:
    SOUNDDEVICE_AVAILABLE = False
    print("❌ Execute: pip install sounddevice")

# Configuração
# O estetoscópio é conectado na entrada de microfone padrão do computador (P2/3.5mm)
SAMPLE_RATE = 44100       # Hz - qualidade CD
CHANNELS = 1              # Mono

# URLs da API
API_URL_LOCAL = "http://localhost:5239"
API_URL_PROD = "https://www.telecuidar.com.br"

# ID fixo para testes
APPOINTMENT_ID_FIXO = "62734ef5-c2af-40f1-8726-099932da0240"

USE_PRODUCTION = False


def get_api_url():
    return API_URL_PROD if USE_PRODUCTION else API_URL_LOCAL


def find_default_microphone():
    """Encontra o microfone padrão do sistema (para estetoscópio conectado via P2)"""
    if not SOUNDDEVICE_AVAILABLE:
        return None, None
    
    devices = sd.query_devices()
    mic_candidates = []
    
    # Prioridade de busca: Realtek > Microfone > Qualquer entrada
    search_terms = ['realtek', 'microfone', 'microphone', 'grupo de microfones', 'mic array']
    
    # Coleta todos os dispositivos de entrada
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] > 0:
            name = dev['name'].lower()
            sr = int(dev['default_samplerate'])
            
            # Ignora dispositivos de mixagem/estéreo (são saídas virtuais)
            if 'mixagem' in name or 'stereo mix' in name or 'loopback' in name:
                continue
            
            # Prioriza 44100Hz para qualidade
            priority = 0
            for idx, term in enumerate(search_terms):
                if term in name:
                    priority = len(search_terms) - idx  # Maior prioridade para primeiros termos
                    break
            
            if sr == 44100:
                priority += 10  # Bônus para 44100Hz
            
            mic_candidates.append((i, dev, sr, priority))
    
    if not mic_candidates:
        return None, None
    
    # Ordena por prioridade (maior primeiro)
    mic_candidates.sort(key=lambda x: x[3], reverse=True)
    
    return mic_candidates[0][0], mic_candidates[0][1]


def list_devices():
    """Lista dispositivos de entrada disponíveis"""
    print("\n📋 DISPOSITIVOS DE ENTRADA:")
    print("-" * 50)
    
    devices = sd.query_devices()
    recommended_id, _ = find_default_microphone()
    
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] > 0:
            name = dev['name']
            sr = int(dev['default_samplerate'])
            is_recommended = (i == recommended_id)
            marker = " ✅ RECOMENDADO" if is_recommended else ""
            print(f"  [{i:2d}] {name[:40]:40s} {sr}Hz{marker}")
    
    print("-" * 50)
    return recommended_id


def capture_audio(device_id: int, duration: int = 10, sample_rate: int = None):
    """Captura áudio do dispositivo"""
    
    # Obtém taxa de amostragem nativa do dispositivo se não especificada
    if sample_rate is None:
        dev_info = sd.query_devices(device_id)
        sample_rate = int(dev_info['default_samplerate'])
    
    print(f"\n🎤 Capturando {duration}s de áudio...")
    print(f"   Dispositivo: [{device_id}]")
    print(f"   Taxa: {sample_rate} Hz | Mono")
    
    # Countdown
    for i in range(3, 0, -1):
        print(f"   Iniciando em {i}...", end='\r')
        time.sleep(1)
    
    print("   🔴 GRAVANDO...              ")
    
    try:
        recording = sd.rec(
            int(duration * sample_rate),
            samplerate=sample_rate,
            channels=1,
            dtype='int16',
            device=device_id
        )
        
        # Barra de progresso
        start_time = time.time()
        while time.time() - start_time < duration:
            elapsed = time.time() - start_time
            progress = elapsed / duration
            bar = '█' * int(progress * 30) + '░' * (30 - int(progress * 30))
            print(f"   [{bar}] {int(elapsed)}/{duration}s", end='\r')
            time.sleep(0.2)
        
        sd.wait()
        print(f"\n   ✅ Captura concluída! {len(recording)} amostras")
        
        return recording.flatten(), sample_rate
        
    except Exception as e:
        print(f"\n   ❌ Erro: {e}")
        return None, 0


def process_audio(samples: np.ndarray, sample_rate: int):
    """Processa o áudio para melhorar qualidade"""
    print("   🔊 Processando áudio...")
    
    samples_float = samples.astype(np.float64)
    
    # 1. Remove DC offset
    samples_float = samples_float - np.mean(samples_float)
    
    # 2. Filtro passa-alta simples (remove ruído < 20Hz)
    alpha = 0.01
    filtered = np.zeros_like(samples_float)
    prev_in, prev_out = 0.0, 0.0
    for i in range(len(samples_float)):
        filtered[i] = alpha * prev_out + alpha * (samples_float[i] - prev_in)
        prev_in = samples_float[i]
        prev_out = filtered[i]
    
    # 3. Filtro passa-baixa (remove ruído > 500Hz para sons cardíacos)
    alpha_low = 500.0 / (sample_rate / 2.0)
    result = np.zeros_like(filtered)
    prev = 0.0
    for i in range(len(filtered)):
        result[i] = prev + alpha_low * (filtered[i] - prev)
        prev = result[i]
    
    # 4. Normaliza
    max_val = np.max(np.abs(result))
    if max_val > 0:
        result = result * (30000.0 / max_val)
    
    return result.astype(np.int16)


def analyze_audio(samples: np.ndarray, sample_rate: int):
    """Analisa o áudio para detectar batimentos"""
    samples_float = samples.astype(np.float64)
    samples_float = samples_float - np.mean(samples_float)
    
    max_val = np.max(np.abs(samples_float))
    if max_val > 0:
        samples_float = samples_float / max_val
    
    # RMS (volume)
    rms = np.sqrt(np.mean(samples_float ** 2))
    
    # Envelope para detectar picos
    envelope = np.abs(samples_float)
    window = int(sample_rate * 0.03)  # 30ms
    if window > 1:
        envelope = np.convolve(envelope, np.ones(window)/window, mode='same')
    
    # Detecta picos
    threshold = np.mean(envelope) + 0.4 * np.std(envelope)
    peaks = []
    in_peak = False
    min_gap = int(sample_rate * 0.25)  # Mínimo 250ms entre batimentos (240 BPM max)
    last_peak = -min_gap
    
    for i, val in enumerate(envelope):
        if val > threshold and not in_peak and (i - last_peak) > min_gap:
            in_peak = True
            peaks.append(i)
            last_peak = i
        elif val < threshold * 0.6:
            in_peak = False
    
    # Calcula BPM
    bpm = None
    if len(peaks) >= 2:
        intervals = np.diff(peaks) / sample_rate
        avg_interval = np.median(intervals)
        if 0.3 < avg_interval < 2.0:
            bpm = int(60 / avg_interval)
    
    # Qualidade (0-100)
    quality = min(100, int(rms * 400))
    
    return {
        'bpm': bpm,
        'quality': quality,
        'rms': float(rms),
        'peaks': len(peaks),
        'duration': len(samples) / sample_rate
    }


def generate_waveform(samples: np.ndarray, num_points: int = 500) -> list:
    """Gera waveform para visualização"""
    samples_float = samples.astype(np.float64)
    max_val = np.max(np.abs(samples_float))
    if max_val > 0:
        samples_float = samples_float / max_val
    
    block_size = max(1, len(samples_float) // num_points)
    waveform = []
    
    for i in range(0, min(len(samples_float), num_points * block_size), block_size):
        block = samples_float[i:i + block_size]
        # Pega pico do bloco
        max_v, min_v = np.max(block), np.min(block)
        waveform.append(float(max_v if abs(max_v) > abs(min_v) else min_v))
    
    return waveform[:num_points]


def save_wav(samples: np.ndarray, filename: str, sample_rate: int):
    """Salva como WAV"""
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(samples.tobytes())
    print(f"   💾 Salvo: {filename}")
    return filename


async def send_to_server(wav_file: str, sample_rate: int, analysis: dict, waveform: list):
    """Envia para o TeleCuidar"""
    url = f"{get_api_url()}/api/biometrics/phonocardiogram"
    
    with open(wav_file, 'rb') as f:
        wav_data = f.read()
    
    pcm_data = wav_data[44:]
    audio_base64 = base64.b64encode(pcm_data).decode('utf-8')
    duration = len(pcm_data) / (sample_rate * 2)
    
    payload = {
        "appointmentId": APPOINTMENT_ID_FIXO,
        "deviceType": "stethoscope",
        "audioData": audio_base64,
        "sampleRate": sample_rate,
        "format": "pcm_s16le",
        "durationSeconds": duration,
        "waveform": waveform,
        "values": {
            # SEGURANÇA: heartRate REMOVIDO - cálculo por áudio não é confiável!
            # FC deve vir APENAS de dispositivos médicos certificados (Omron, oxímetro)
            "quality": analysis.get('quality', 0)
        }
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, timeout=30) as resp:
                if resp.status == 200:
                    result = await resp.json()
                    print(f"   ✅ Enviado para servidor!")
                    if result.get('audioUrl'):
                        base_url = get_api_url().replace('/api', '')
                        print(f"   🔊 {base_url}{result['audioUrl']}")
                    return True
                else:
                    text = await resp.text()
                    print(f"   ❌ Erro {resp.status}: {text[:100]}")
                    return False
    except Exception as e:
        print(f"   ❌ Erro: {e}")
        return False


async def capture_and_send(device_id: int, duration: int, process: bool = True):
    """Captura, processa e envia"""
    # Captura
    samples, sr = capture_audio(device_id, duration)
    if samples is None:
        return False
    
    # Processa (opcional)
    if process:
        samples = process_audio(samples, sr)
    
    # Analisa
    print("\n📊 Análise:")
    analysis = analyze_audio(samples, sr)
    print(f"   • Duração: {analysis['duration']:.1f}s")
    print(f"   • Batimentos: {analysis['peaks']}")
    print(f"   • BPM: {analysis['bpm'] or 'N/A'}")
    print(f"   • Qualidade: {analysis['quality']}%")
    
    # Waveform
    waveform = generate_waveform(samples)
    
    # Salva
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"ausculta_{timestamp}.wav"
    save_wav(samples, filename, sr)
    
    # Envia
    print("\n📤 Enviando...")
    await send_to_server(filename, sr, analysis, waveform)
    
    return True


async def main():
    global USE_PRODUCTION
    
    parser = argparse.ArgumentParser(description='Captura fonocardiograma do estetoscópio via microfone P2')
    parser.add_argument('--prod', action='store_true', help='Servidor de produção')
    parser.add_argument('--duration', '-d', type=int, default=10, help='Duração (s)')
    parser.add_argument('--device', type=int, help='ID do dispositivo')
    parser.add_argument('--continuous', '-c', action='store_true', help='Modo contínuo')
    parser.add_argument('--raw', action='store_true', help='Sem processamento')
    parser.add_argument('--list', '-l', action='store_true', help='Lista dispositivos')
    
    args = parser.parse_args()
    USE_PRODUCTION = args.prod
    
    print("\n" + "=" * 55)
    print("   🩺 FONOCARDIOGRAMA - ESTETOSCÓPIO (MICROFONE P2)")
    print("=" * 55)
    
    if not SOUNDDEVICE_AVAILABLE:
        print("\n❌ Instale: pip install sounddevice")
        return
    
    # Lista dispositivos
    ausculta_id = list_devices()
    
    if args.list:
        return
    
    # Determina dispositivo
    device_id = args.device if args.device is not None else ausculta_id
    
    if device_id is None:
        print("\n❌ Nenhum microfone encontrado! Use --device <id>")
        return
    
    print(f"\n🎯 Usando dispositivo [{device_id}]")
    print(f"📡 Servidor: {'PRODUÇÃO' if USE_PRODUCTION else 'LOCAL'}")
    
    if args.continuous:
        print("\n🔄 MODO CONTÍNUO - Ctrl+C para parar")
        print("-" * 55)
        try:
            while True:
                await capture_and_send(device_id, args.duration, not args.raw)
                print("\n⏳ Próxima captura em 3s...")
                await asyncio.sleep(3)
        except KeyboardInterrupt:
            print("\n\n👋 Encerrado pelo usuário")
    else:
        await capture_and_send(device_id, args.duration, not args.raw)
    
    print("\n✅ Concluído!")
    print("=" * 55)


if __name__ == "__main__":
    asyncio.run(main())
