#!/usr/bin/env python3
"""
Análise de Fonocardiograma - Detecção de Frequência Cardíaca
TeleCuidar POC - Fevereiro 2026
"""

import wave
import numpy as np
import sys
import os
from scipy import signal
from scipy.signal import find_peaks

def analyze_phonocardiogram(wav_path):
    """Analisa arquivo WAV de fonocardiograma e estima frequência cardíaca"""
    
    print(f"\n{'='*60}")
    print(f"ANÁLISE DE FONOCARDIOGRAMA")
    print(f"{'='*60}")
    print(f"Arquivo: {os.path.basename(wav_path)}")
    
    # 1. Carregar arquivo WAV
    try:
        with wave.open(wav_path, 'rb') as wf:
            n_channels = wf.getnchannels()
            sample_width = wf.getsampwidth()
            frame_rate = wf.getframerate()
            n_frames = wf.getnframes()
            duration = n_frames / frame_rate
            
            print(f"\n📁 METADADOS DO ARQUIVO:")
            print(f"   Canais: {n_channels}")
            print(f"   Bits: {sample_width * 8}")
            print(f"   Sample Rate: {frame_rate} Hz")
            print(f"   Frames: {n_frames}")
            print(f"   Duração: {duration:.2f} segundos")
            
            # Ler dados
            raw_data = wf.readframes(n_frames)
            audio = np.frombuffer(raw_data, dtype=np.int16).astype(np.float32)
            
            # Normalizar
            audio = audio / 32768.0
            
    except Exception as e:
        print(f"❌ Erro ao abrir arquivo: {e}")
        return None
    
    # 2. Análise de Amplitude
    rms = np.sqrt(np.mean(audio**2))
    peak = np.max(np.abs(audio))
    
    print(f"\n📊 ANÁLISE DE AMPLITUDE:")
    print(f"   RMS: {rms:.4f} ({rms*100:.1f}%)")
    print(f"   Pico: {peak:.4f} ({peak*100:.1f}%)")
    
    if rms < 0.01:
        print(f"   ⚠️  ÁUDIO MUITO BAIXO - pode ser silêncio ou microfone desconectado")
    elif rms < 0.05:
        print(f"   ✅ Nível baixo - normal para batimentos cardíacos")
    elif rms < 0.2:
        print(f"   ✅ Nível médio - bom para ausculta")
    else:
        print(f"   ⚠️  Nível alto - possível distorção ou ruído ambiente")
    
    # 3. Análise Espectral
    print(f"\n📈 ANÁLISE ESPECTRAL:")
    
    # FFT
    fft = np.fft.rfft(audio)
    freqs = np.fft.rfftfreq(len(audio), 1/frame_rate)
    magnitude = np.abs(fft)
    
    # Encontrar frequências dominantes
    # Batimentos cardíacos estão entre 0.5Hz (30 BPM) e 3.3Hz (200 BPM)
    heart_band_idx = np.where((freqs >= 0.5) & (freqs <= 3.5))[0]
    
    if len(heart_band_idx) > 0:
        heart_band_mag = magnitude[heart_band_idx]
        heart_band_freqs = freqs[heart_band_idx]
        
        # Top 3 frequências na banda cardíaca
        top_idx = np.argsort(heart_band_mag)[-3:][::-1]
        
        print(f"   Frequências dominantes (banda 0.5-3.5 Hz):")
        for i, idx in enumerate(top_idx):
            freq = heart_band_freqs[idx]
            bpm = freq * 60
            print(f"     #{i+1}: {freq:.2f} Hz = {bpm:.0f} BPM")
    
    # 4. Detecção de Picos (Batimentos)
    print(f"\n💓 DETECÇÃO DE BATIMENTOS:")
    
    # Filtro passa-baixa para isolar batimentos
    nyquist = frame_rate / 2
    low_cutoff = 5  # Hz - frequência de corte baixa
    b, a = signal.butter(4, low_cutoff / nyquist, btype='low')
    filtered = signal.filtfilt(b, a, audio)
    
    # Envelope do sinal (valor absoluto suavizado)
    envelope = np.abs(filtered)
    envelope_smooth = signal.medfilt(envelope, kernel_size=int(frame_rate * 0.05) | 1)
    
    # Encontrar picos
    min_distance = int(frame_rate * 0.3)  # Mínimo 0.3s entre batimentos (200 BPM max)
    height_threshold = np.mean(envelope_smooth) + 0.5 * np.std(envelope_smooth)
    
    peaks, properties = find_peaks(envelope_smooth, 
                                    distance=min_distance, 
                                    height=height_threshold)
    
    n_peaks = len(peaks)
    print(f"   Picos detectados: {n_peaks}")
    
    if n_peaks >= 2:
        # Calcular intervalos entre picos
        peak_times = peaks / frame_rate
        intervals = np.diff(peak_times)
        
        avg_interval = np.mean(intervals)
        std_interval = np.std(intervals)
        estimated_bpm = 60 / avg_interval
        
        print(f"   Intervalo médio: {avg_interval*1000:.0f} ms (±{std_interval*1000:.0f} ms)")
        print(f"\n   🫀 FREQUÊNCIA CARDÍACA ESTIMADA: {estimated_bpm:.0f} BPM")
        
        # Variabilidade da frequência cardíaca (HRV)
        hrv = std_interval * 1000  # em ms
        print(f"   📉 Variabilidade (HRV): {hrv:.1f} ms")
        
        if 60 <= estimated_bpm <= 100:
            print(f"   ✅ Frequência normal para adulto em repouso")
        elif 40 <= estimated_bpm < 60:
            print(f"   ⚠️  Bradicardia (frequência baixa)")
        elif 100 < estimated_bpm <= 150:
            print(f"   ⚠️  Taquicardia (frequência elevada)")
        else:
            print(f"   ⚠️  Frequência fora do esperado - pode ser ruído")
            
        return estimated_bpm
    else:
        print(f"   ⚠️  Poucos picos detectados - não foi possível calcular BPM")
        print(f"   Possíveis causas:")
        print(f"     - Microfone não captou bem os batimentos")
        print(f"     - Muito ruído ambiente")
        print(f"     - Estetoscópio mal posicionado")
        return None

    print(f"\n{'='*60}\n")


if __name__ == "__main__":
    # Diretório dos fonocardiogramas
    phono_dir = r"C:\telecuidar\backend\WebAPI\wwwroot\phonocardiograms"
    
    if len(sys.argv) > 1:
        # Arquivo específico
        wav_file = sys.argv[1]
    else:
        # Pegar o mais recente
        import glob
        wavs = glob.glob(os.path.join(phono_dir, "*.wav"))
        if not wavs:
            print("❌ Nenhum arquivo WAV encontrado")
            sys.exit(1)
        wav_file = max(wavs, key=os.path.getmtime)
    
    if os.path.exists(wav_file):
        analyze_phonocardiogram(wav_file)
    else:
        # Tentar no diretório padrão
        full_path = os.path.join(phono_dir, wav_file)
        if os.path.exists(full_path):
            analyze_phonocardiogram(full_path)
        else:
            print(f"❌ Arquivo não encontrado: {wav_file}")
