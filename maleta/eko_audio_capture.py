"""
Captura de Áudio do Eko CORE 500 via Interface de Áudio do Windows
===================================================================

O Eko CORE 500 se conecta como dispositivo de áudio Bluetooth (A2DP).
Este script captura o áudio diretamente da entrada de áudio do Windows.

PASSO 1: Parear o Eko como dispositivo de áudio no Windows
PASSO 2: Executar este script
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

# Tenta importar sounddevice
try:
    import sounddevice as sd
    SOUNDDEVICE_AVAILABLE = True
except ImportError:
    SOUNDDEVICE_AVAILABLE = False
    print("⚠️  sounddevice não instalado. Execute: pip install sounddevice")

# URLs da API
API_URL_LOCAL = "http://localhost:5239"
API_URL_PROD = "https://www.telecuidar.com.br"
APPOINTMENT_ID_FIXO = "62734ef5-c2af-40f1-8726-099932da0240"

USE_PRODUCTION = False


def get_api_url():
    return API_URL_PROD if USE_PRODUCTION else API_URL_LOCAL


def list_audio_devices():
    """Lista todos os dispositivos de áudio disponíveis"""
    if not SOUNDDEVICE_AVAILABLE:
        return []
    
    print("\n" + "=" * 60)
    print("   🎤 DISPOSITIVOS DE ÁUDIO DISPONÍVEIS")
    print("=" * 60)
    
    devices = sd.query_devices()
    eko_candidates = []
    
    for i, dev in enumerate(devices):
        # Mostra apenas dispositivos de entrada
        if dev['max_input_channels'] > 0:
            name = dev['name']
            sr = int(dev['default_samplerate'])
            channels = dev['max_input_channels']
            
            # Procura por nomes que podem ser o Eko
            is_eko = any(kw in name.lower() for kw in ['eko', 'core', 'stethoscope', 'littmann'])
            is_bluetooth = 'bluetooth' in name.lower() or 'bt' in name.lower()
            
            marker = ""
            if is_eko:
                marker = " 🩺 EKO!"
                eko_candidates.append((i, name, sr))
            elif is_bluetooth:
                marker = " 📶 BT"
                eko_candidates.append((i, name, sr))
            
            print(f"   [{i:2d}] {name[:50]:50s} | {sr}Hz | {channels}ch{marker}")
    
    print("=" * 60)
    return eko_candidates


def find_eko_device():
    """Encontra automaticamente o dispositivo Eko"""
    if not SOUNDDEVICE_AVAILABLE:
        return None, None
    
    devices = sd.query_devices()
    
    # Primeiro, procura por "Eko" no nome
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] > 0:
            name = dev['name'].lower()
            if 'eko' in name or 'core 500' in name:
                return i, dev
    
    # Depois, procura por dispositivos Bluetooth
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] > 0:
            name = dev['name'].lower()
            if 'bluetooth' in name or 'bt' in name:
                return i, dev
    
    return None, None


def capture_audio(device_id=None, duration=10, sample_rate=None):
    """Captura áudio do dispositivo especificado"""
    if not SOUNDDEVICE_AVAILABLE:
        print("❌ sounddevice não disponível!")
        return None, 0
    
    # Se não especificou dispositivo, tenta encontrar o Eko
    if device_id is None:
        device_id, dev_info = find_eko_device()
        if device_id is None:
            print("❌ Eko não encontrado! Use --device <id> para especificar.")
            return None, 0
        print(f"✅ Encontrado: {dev_info['name']}")
        if sample_rate is None:
            sample_rate = int(dev_info['default_samplerate'])
    
    if sample_rate is None:
        sample_rate = 44100
    
    print(f"\n🎤 Capturando {duration}s de áudio do dispositivo [{device_id}]...")
    print(f"   Taxa de amostragem: {sample_rate} Hz")
    print(f"   Canais: 1 (mono)")
    print()
    
    # Countdown
    for i in range(3, 0, -1):
        print(f"   Iniciando em {i}...", end='\r')
        time.sleep(1)
    print("   🔴 GRAVANDO...          ")
    
    try:
        # Captura o áudio
        recording = sd.rec(
            int(duration * sample_rate),
            samplerate=sample_rate,
            channels=1,
            dtype='int16',
            device=device_id
        )
        
        # Barra de progresso
        for i in range(duration):
            progress = (i + 1) / duration
            bar = '█' * int(progress * 30) + '░' * (30 - int(progress * 30))
            print(f"   [{bar}] {i+1}/{duration}s", end='\r')
            time.sleep(1)
        
        sd.wait()
        print(f"\n   ✅ Captura concluída! {len(recording)} amostras")
        
        return recording, sample_rate
        
    except Exception as e:
        print(f"\n   ❌ Erro na captura: {e}")
        return None, 0


def analyze_audio(samples: np.ndarray, sample_rate: int):
    """Analisa o áudio capturado para detectar batimentos"""
    if samples is None or len(samples) == 0:
        return {}
    
    # Flatten se necessário
    if len(samples.shape) > 1:
        samples = samples.flatten()
    
    # Normaliza
    samples_float = samples.astype(np.float64)
    samples_float = samples_float - np.mean(samples_float)
    
    max_val = np.max(np.abs(samples_float))
    if max_val > 0:
        samples_float = samples_float / max_val
    
    # Calcula RMS (volume)
    rms = np.sqrt(np.mean(samples_float ** 2))
    
    # Detecta picos para estimar BPM
    envelope = np.abs(samples_float)
    window_size = int(sample_rate * 0.05)
    if window_size > 1:
        envelope = np.convolve(envelope, np.ones(window_size)/window_size, mode='same')
    
    threshold = np.mean(envelope) + 0.5 * np.std(envelope)
    peaks = []
    in_peak = False
    
    for i, val in enumerate(envelope):
        if val > threshold and not in_peak:
            in_peak = True
            peaks.append(i)
        elif val < threshold * 0.7:
            in_peak = False
    
    # Calcula BPM aproximado
    bpm = None
    if len(peaks) >= 2:
        intervals = np.diff(peaks) / sample_rate
        avg_interval = np.median(intervals)
        if 0.3 < avg_interval < 2.0:  # Entre 30 e 200 BPM
            bpm = int(60 / avg_interval)
    
    # Qualidade do sinal (0-100)
    quality = min(100, int(rms * 500))  # Baseado no volume
    
    return {
        'bpm': bpm,
        'quality': quality,
        'rms': float(rms),
        'peaks': len(peaks),
        'duration': len(samples) / sample_rate
    }


def generate_waveform(samples: np.ndarray, num_points: int = 500) -> list:
    """Gera dados do waveform para visualização"""
    if samples is None or len(samples) == 0:
        return []
    
    if len(samples.shape) > 1:
        samples = samples.flatten()
    
    samples_float = samples.astype(np.float64)
    max_val = np.max(np.abs(samples_float))
    if max_val > 0:
        samples_float = samples_float / max_val
    
    block_size = max(1, len(samples_float) // num_points)
    waveform = []
    
    for i in range(0, len(samples_float) - block_size, block_size):
        block = samples_float[i:i + block_size]
        peak = max(np.max(block), -np.min(block), key=abs)
        waveform.append(float(peak))
    
    return waveform[:num_points]


def save_wav(samples: np.ndarray, filename: str, sample_rate: int):
    """Salva como WAV"""
    if len(samples.shape) > 1:
        samples = samples.flatten()
    
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)  # 16-bit
        f.setframerate(sample_rate)
        f.writeframes(samples.tobytes())
    
    print(f"   💾 Salvo: {filename}")


async def send_to_api(wav_filename: str, sample_rate: int, analysis: dict, waveform: list):
    """Envia para a API do TeleCuidar"""
    url = f"{get_api_url()}/api/biometrics/phonocardiogram"
    appointment_id = APPOINTMENT_ID_FIXO
    
    with open(wav_filename, 'rb') as f:
        wav_data = f.read()
    
    # Extrai PCM do WAV
    pcm_data = wav_data[44:] if len(wav_data) > 44 else wav_data
    audio_base64 = base64.b64encode(pcm_data).decode('utf-8')
    duration_seconds = len(pcm_data) / (sample_rate * 2)
    
    payload = {
        "appointmentId": appointment_id,
        "deviceType": "stethoscope",
        "audioData": audio_base64,
        "sampleRate": sample_rate,
        "format": "pcm_s16le",
        "durationSeconds": duration_seconds,
        "waveform": waveform,
        "values": {
            "heartRate": analysis.get('bpm'),
            "quality": analysis.get('quality', 0)
        }
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, timeout=30) as response:
                if response.status == 200:
                    result = await response.json()
                    print(f"   ✅ Enviado com sucesso!")
                    if result.get('audioUrl'):
                        print(f"   🔊 URL: {get_api_url().replace('/api', '')}{result['audioUrl']}")
                    return True
                else:
                    text = await response.text()
                    print(f"   ❌ Erro: {response.status} - {text[:100]}")
                    return False
    except Exception as e:
        print(f"   ❌ Erro de conexão: {e}")
        return False


async def main():
    global USE_PRODUCTION
    
    parser = argparse.ArgumentParser(description='Captura áudio do Eko CORE 500')
    parser.add_argument('--list', '-l', action='store_true', help='Lista dispositivos de áudio')
    parser.add_argument('--device', '-d', type=int, help='ID do dispositivo de áudio')
    parser.add_argument('--duration', '-t', type=int, default=10, help='Duração em segundos (padrão: 10)')
    parser.add_argument('--rate', '-r', type=int, help='Taxa de amostragem (Hz)')
    parser.add_argument('--prod', action='store_true', help='Usa servidor de produção')
    parser.add_argument('--nosend', action='store_true', help='Não envia para API (apenas salva local)')
    
    args = parser.parse_args()
    USE_PRODUCTION = args.prod
    
    print("\n" + "=" * 60)
    print("   🩺 CAPTURA DE ÁUDIO - EKO CORE 500")
    print("=" * 60)
    
    if not SOUNDDEVICE_AVAILABLE:
        print("\n❌ Módulo 'sounddevice' não instalado!")
        print("   Execute: pip install sounddevice")
        return
    
    if args.list:
        list_audio_devices()
        return
    
    # Lista dispositivos e encontra o Eko
    candidates = list_audio_devices()
    
    if not candidates and args.device is None:
        print("\n⚠️  Nenhum dispositivo Bluetooth/Eko encontrado.")
        print("   Certifique-se de que o Eko está pareado como dispositivo de áudio.")
        print("   Ou use --device <id> para especificar manualmente.")
        return
    
    # Captura
    samples, sr = capture_audio(
        device_id=args.device,
        duration=args.duration,
        sample_rate=args.rate
    )
    
    if samples is None:
        return
    
    # Análise
    print("\n📊 Analisando áudio...")
    analysis = analyze_audio(samples, sr)
    print(f"   • Duração: {analysis.get('duration', 0):.1f}s")
    print(f"   • Picos detectados: {analysis.get('peaks', 0)}")
    print(f"   • BPM estimado: {analysis.get('bpm', 'N/A')}")
    print(f"   • Qualidade: {analysis.get('quality', 0)}%")
    print(f"   • RMS (volume): {analysis.get('rms', 0):.4f}")
    
    # Waveform
    waveform = generate_waveform(samples)
    
    # Salva arquivo
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"eko_audio_{timestamp}.wav"
    save_wav(samples, filename, sr)
    
    # Envia para API
    if not args.nosend:
        print("\n📤 Enviando para servidor...")
        await send_to_api(filename, sr, analysis, waveform)
    
    print("\n✅ Concluído!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
