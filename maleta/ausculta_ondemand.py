"""
Captura de Fonocardiograma ON-DEMAND
====================================

Fica aguardando requisições do servidor para capturar áudio.
Não gera arquivos .wav continuamente - só captura quando solicitado.

Uso:
  python ausculta_ondemand.py           # Servidor local
  python ausculta_ondemand.py --prod    # Servidor de produção
"""

import numpy as np
import wave
import time
import asyncio
import aiohttp
import base64
import argparse
import os
from datetime import datetime
from pathlib import Path

try:
    import sounddevice as sd
    SOUNDDEVICE_AVAILABLE = True
except ImportError:
    SOUNDDEVICE_AVAILABLE = False
    print("❌ Execute: pip install sounddevice")

# Configuração
SAMPLE_RATE = 44100
CHANNELS = 1
POLL_INTERVAL = 2  # segundos entre verificações

# URLs da API
API_URL_LOCAL = "http://localhost:5239"
API_URL_PROD = "https://www.telecuidar.com.br"

USE_PRODUCTION = False


def get_api_url():
    return API_URL_PROD if USE_PRODUCTION else API_URL_LOCAL


def find_default_microphone():
    """Encontra o microfone padrão do sistema"""
    if not SOUNDDEVICE_AVAILABLE:
        return None, None
    
    devices = sd.query_devices()
    mic_candidates = []
    
    search_terms = ['realtek', 'microfone', 'microphone', 'grupo de microfones', 'mic array']
    
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] > 0:
            name = dev['name'].lower()
            sr = int(dev['default_samplerate'])
            
            if 'mixagem' in name or 'stereo mix' in name or 'loopback' in name:
                continue
            
            priority = 0
            for idx, term in enumerate(search_terms):
                if term in name:
                    priority = len(search_terms) - idx
                    break
            
            if sr == 44100:
                priority += 10
            
            mic_candidates.append((i, dev, sr, priority))
    
    if not mic_candidates:
        return None, None
    
    mic_candidates.sort(key=lambda x: x[3], reverse=True)
    return mic_candidates[0][0], mic_candidates[0][1]


def capture_audio(device_id: int, duration: int = 10, sample_rate: int = None):
    """Captura áudio do dispositivo"""
    if sample_rate is None:
        dev_info = sd.query_devices(device_id)
        sample_rate = int(dev_info['default_samplerate'])
    
    print(f"\n🎤 Capturando {duration}s de áudio...")
    print(f"   🔴 GRAVANDO...")
    
    try:
        recording = sd.rec(
            int(duration * sample_rate),
            samplerate=sample_rate,
            channels=1,
            dtype='int16',
            device=device_id
        )
        
        start_time = time.time()
        while time.time() - start_time < duration:
            elapsed = time.time() - start_time
            progress = elapsed / duration
            bar = '█' * int(progress * 30) + '░' * (30 - int(progress * 30))
            print(f"   [{bar}] {int(elapsed)}/{duration}s", end='\r')
            time.sleep(0.2)
        
        sd.wait()
        print(f"\n   ✅ Captura concluída!")
        
        return recording.flatten(), sample_rate
        
    except Exception as e:
        print(f"\n   ❌ Erro: {e}")
        return None, 0


def process_audio(samples: np.ndarray, sample_rate: int):
    """Processa o áudio para melhorar qualidade"""
    samples_float = samples.astype(np.float64)
    samples_float = samples_float - np.mean(samples_float)
    
    # Filtro passa-alta (remove < 20Hz)
    alpha = 0.01
    filtered = np.zeros_like(samples_float)
    prev_in, prev_out = 0.0, 0.0
    for i in range(len(samples_float)):
        filtered[i] = alpha * prev_out + alpha * (samples_float[i] - prev_in)
        prev_in = samples_float[i]
        prev_out = filtered[i]
    
    # Filtro passa-baixa (remove > 500Hz para sons cardíacos)
    alpha_low = 500.0 / (sample_rate / 2.0)
    result = np.zeros_like(filtered)
    prev = 0.0
    for i in range(len(filtered)):
        result[i] = prev + alpha_low * (filtered[i] - prev)
        prev = result[i]
    
    # Normaliza
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
    
    rms = np.sqrt(np.mean(samples_float ** 2))
    
    envelope = np.abs(samples_float)
    window = int(sample_rate * 0.03)
    if window > 1:
        envelope = np.convolve(envelope, np.ones(window)/window, mode='same')
    
    threshold = np.mean(envelope) + 0.4 * np.std(envelope)
    peaks = []
    in_peak = False
    min_gap = int(sample_rate * 0.25)
    last_peak = -min_gap
    
    for i, val in enumerate(envelope):
        if val > threshold and not in_peak and (i - last_peak) > min_gap:
            in_peak = True
            peaks.append(i)
            last_peak = i
        elif val < threshold * 0.6:
            in_peak = False
    
    bpm = None
    if len(peaks) >= 2:
        intervals = np.diff(peaks) / sample_rate
        avg_interval = np.median(intervals)
        if 0.3 < avg_interval < 2.0:
            bpm = int(60 / avg_interval)
    
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
        max_v, min_v = np.max(block), np.min(block)
        waveform.append(float(max_v if abs(max_v) > abs(min_v) else min_v))
    
    return waveform[:num_points]


async def check_for_request():
    """Verifica se há solicitação de captura pendente"""
    url = f"{get_api_url()}/api/biometrics/ausculta-request"
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=5) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    if data and data.get('appointmentId'):
                        return data
                return None
    except Exception as e:
        # Silently ignore connection errors during polling
        return None


async def send_phonocardiogram(appointment_id: str, samples: np.ndarray, 
                               sample_rate: int, analysis: dict, waveform: list):
    """Envia o fonocardiograma para o servidor"""
    url = f"{get_api_url()}/api/biometrics/phonocardiogram"
    
    # Converte para bytes PCM
    pcm_bytes = samples.tobytes()
    audio_base64 = base64.b64encode(pcm_bytes).decode('utf-8')
    duration = len(samples) / sample_rate
    
    payload = {
        "appointmentId": appointment_id,
        "deviceType": "stethoscope",
        "audioData": audio_base64,
        "sampleRate": sample_rate,
        "format": "pcm_s16le",
        "durationSeconds": duration,
        "waveform": waveform,
        "values": {
            "heartRate": analysis.get('bpm'),
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
        print(f"   ❌ Erro ao enviar: {e}")
        return False


async def process_request(device_id: int, request: dict):
    """Processa uma solicitação de captura"""
    appointment_id = request.get('appointmentId')
    duration = request.get('durationSeconds', 10)
    position = request.get('position', 'cardiac')
    
    print(f"\n" + "=" * 50)
    print(f"📥 SOLICITAÇÃO RECEBIDA!")
    print(f"   Consulta: {appointment_id[:8]}...")
    print(f"   Duração: {duration}s")
    print(f"   Posição: {position}")
    print("=" * 50)
    
    # Captura
    samples, sr = capture_audio(device_id, duration)
    if samples is None:
        print("   ❌ Falha na captura")
        return False
    
    # Processa
    samples = process_audio(samples, sr)
    
    # Analisa
    analysis = analyze_audio(samples, sr)
    print(f"\n📊 Análise:")
    print(f"   • BPM: {analysis['bpm'] or 'N/A'}")
    print(f"   • Qualidade: {analysis['quality']}%")
    
    # Waveform
    waveform = generate_waveform(samples)
    
    # Envia
    print("\n📤 Enviando para servidor...")
    success = await send_phonocardiogram(appointment_id, samples, sr, analysis, waveform)
    
    return success


async def polling_loop(device_id: int):
    """Loop principal de polling"""
    print(f"\n🔄 Aguardando solicitações de captura...")
    print(f"   Polling a cada {POLL_INTERVAL}s")
    print(f"   Pressione Ctrl+C para encerrar\n")
    
    last_status_time = time.time()
    
    while True:
        try:
            # Verifica se há solicitação
            request = await check_for_request()
            
            if request:
                # Processa a solicitação
                await process_request(device_id, request)
                print(f"\n🔄 Aguardando próxima solicitação...")
            else:
                # Status periódico (a cada 30s)
                if time.time() - last_status_time > 30:
                    print(f"   ⏳ [{datetime.now().strftime('%H:%M:%S')}] Aguardando...")
                    last_status_time = time.time()
            
            # Aguarda antes de verificar novamente
            await asyncio.sleep(POLL_INTERVAL)
            
        except asyncio.CancelledError:
            break
        except Exception as e:
            print(f"   ⚠️ Erro: {e}")
            await asyncio.sleep(POLL_INTERVAL)


async def main():
    global USE_PRODUCTION
    
    parser = argparse.ArgumentParser(description='Ausculta ON-DEMAND - Captura só quando solicitado')
    parser.add_argument('--prod', action='store_true', help='Usar servidor de produção')
    parser.add_argument('--device', type=int, help='ID do dispositivo de áudio')
    
    args = parser.parse_args()
    USE_PRODUCTION = args.prod
    
    print("\n" + "=" * 55)
    print("   🩺 AUSCULTA ON-DEMAND - ESTETOSCÓPIO DIGITAL")
    print("=" * 55)
    
    if not SOUNDDEVICE_AVAILABLE:
        print("\n❌ Instale: pip install sounddevice")
        return
    
    # Encontra microfone
    device_id, device_info = find_default_microphone()
    
    if args.device is not None:
        device_id = args.device
    
    if device_id is None:
        print("\n❌ Nenhum microfone encontrado!")
        return
    
    print(f"\n🎤 Microfone: [{device_id}] {sd.query_devices(device_id)['name']}")
    print(f"📡 Servidor: {'PRODUÇÃO' if USE_PRODUCTION else 'LOCAL'} ({get_api_url()})")
    
    try:
        await polling_loop(device_id)
    except KeyboardInterrupt:
        print("\n\n👋 Encerrado pelo usuário")
    
    print("\n✅ Finalizado!")


if __name__ == "__main__":
    asyncio.run(main())
