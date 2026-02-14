#!/usr/bin/env python3
"""
Serviço de Análise de Fonocardiograma - TeleCuidar
Executa como API HTTP para o backend .NET chamar

Endpoint: POST /analyze
Body: { "wav_path": "/app/wwwroot/phonocardiograms/xxx.wav" }
Response: { "estimated_bpm": 72, "quality": "good", "rms": 0.08, ... }
"""

from flask import Flask, request, jsonify
import wave
import numpy as np
from scipy import signal
from scipy.signal import find_peaks
import os
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

def analyze_wav(wav_path):
    """Analisa arquivo WAV e retorna métricas"""
    result = {
        "success": False,
        "error": None,
        "duration_seconds": 0,
        "sample_rate": 0,
        "rms": 0,
        "peak": 0,
        "estimated_bpm": None,
        "quality": "unknown",
        "peaks_detected": 0,
        "hrv_ms": None
    }
    
    try:
        with wave.open(wav_path, 'rb') as wf:
            frame_rate = wf.getframerate()
            n_frames = wf.getnframes()
            duration = n_frames / frame_rate
            
            result["sample_rate"] = frame_rate
            result["duration_seconds"] = round(duration, 2)
            
            raw_data = wf.readframes(n_frames)
            audio = np.frombuffer(raw_data, dtype=np.int16).astype(np.float32)
            audio = audio / 32768.0
            
    except Exception as e:
        result["error"] = f"Erro ao abrir arquivo: {str(e)}"
        return result
    
    # Análise de amplitude
    rms = float(np.sqrt(np.mean(audio**2)))
    peak = float(np.max(np.abs(audio)))
    result["rms"] = round(rms, 4)
    result["peak"] = round(peak, 4)
    
    # Qualidade baseada em RMS
    if rms < 0.01:
        result["quality"] = "very_low"
    elif rms < 0.03:
        result["quality"] = "low"
    elif rms < 0.15:
        result["quality"] = "good"
    else:
        result["quality"] = "high"
    
    # Detecção de batimentos
    try:
        nyquist = frame_rate / 2
        low_cutoff = 5
        b, a = signal.butter(4, low_cutoff / nyquist, btype='low')
        filtered = signal.filtfilt(b, a, audio)
        
        envelope = np.abs(filtered)
        kernel_size = int(frame_rate * 0.05)
        if kernel_size % 2 == 0:
            kernel_size += 1
        envelope_smooth = signal.medfilt(envelope, kernel_size=kernel_size)
        
        min_distance = int(frame_rate * 0.3)
        height_threshold = np.mean(envelope_smooth) + 0.5 * np.std(envelope_smooth)
        
        peaks, _ = find_peaks(envelope_smooth, distance=min_distance, height=height_threshold)
        
        result["peaks_detected"] = len(peaks)
        
        if len(peaks) >= 2:
            peak_times = peaks / frame_rate
            intervals = np.diff(peak_times)
            
            avg_interval = float(np.mean(intervals))
            std_interval = float(np.std(intervals))
            
            estimated_bpm = 60 / avg_interval
            hrv = std_interval * 1000
            
            result["estimated_bpm"] = round(estimated_bpm) if 30 < estimated_bpm < 200 else None
            result["hrv_ms"] = round(hrv, 1)
            
    except Exception as e:
        result["error"] = f"Erro na análise: {str(e)}"
    
    result["success"] = True
    return result


@app.route('/analyze', methods=['POST'])
def analyze():
    """Endpoint para análise de fonocardiograma"""
    data = request.get_json()
    
    if not data or 'wav_path' not in data:
        return jsonify({"error": "wav_path required"}), 400
    
    wav_path = data['wav_path']
    
    if not os.path.exists(wav_path):
        return jsonify({"error": f"File not found: {wav_path}"}), 404
    
    result = analyze_wav(wav_path)
    return jsonify(result)


@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({"status": "ok", "service": "phonocardiogram-analyzer"})


if __name__ == '__main__':
    # Para teste local
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == '--test':
        # Testa com arquivo
        test_dir = r"C:\telecuidar\backend\WebAPI\wwwroot\phonocardiograms"
        import glob
        wavs = glob.glob(os.path.join(test_dir, "*.wav"))
        if wavs:
            latest = max(wavs, key=os.path.getmtime)
            print(f"Testando: {latest}")
            result = analyze_wav(latest)
            import json
            print(json.dumps(result, indent=2))
    else:
        # Roda como servidor
        app.run(host='0.0.0.0', port=5050, debug=False)
