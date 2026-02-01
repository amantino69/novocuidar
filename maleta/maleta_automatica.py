"""
TeleCuidar - Maleta Automática
==============================

Sistema TOTALMENTE AUTOMÁTICO para a enfermeira.
Ela só precisa:
1. Abrir esta janela no início do dia (duplo-clique)
2. Usar o TeleCuidar normalmente no navegador
3. Usar os equipamentos - TUDO é automático!

O estetoscópio detecta quando está sendo usado e captura sozinho.
"""

import asyncio
import numpy as np
import wave
import time
import base64
import aiohttp
import threading
import queue
from datetime import datetime
from pathlib import Path
import sys

# Tenta importar bleak para BLE
try:
    from bleak import BleakScanner
    BLEAK_AVAILABLE = True
except ImportError:
    BLEAK_AVAILABLE = False

# Tenta importar sounddevice para áudio
try:
    import sounddevice as sd
    SOUNDDEVICE_AVAILABLE = True
except ImportError:
    SOUNDDEVICE_AVAILABLE = False
    print("⚠️  Instale: pip install sounddevice numpy aiohttp")
    sys.exit(1)

# ============================================================
# CONFIGURAÇÃO
# ============================================================

API_URL = "https://www.telecuidar.com.br"

# Dispositivos BLE
DEVICES = {
    "F8:8F:C8:3A:B7:92": {"type": "scale", "name": "Balança"},
    "00:5F:BF:9A:64:DF": {"type": "blood_pressure", "name": "Omron"},
    "DC:23:4E:DA:E9:DD": {"type": "thermometer", "name": "Termômetro"}
}

# Configuração do estetoscópio AUTOMÁTICO
STETHOSCOPE_DEVICE_NAME = "Ausculta"
AUDIO_THRESHOLD = 500          # Nível mínimo para detectar uso
CAPTURE_DURATION = 10          # Segundos de captura
SILENCE_BEFORE_CAPTURE = 1.5   # Segundos de silêncio antes de considerar "fim"
MIN_INTERVAL_BETWEEN = 15      # Mínimo de segundos entre capturas


class AutomaticStethoscope:
    """Estetoscópio que detecta e captura automaticamente"""
    
    def __init__(self):
        self.device_id = None
        self.sample_rate = 44100
        self.is_capturing = False
        self.last_capture_time = 0
        self.audio_buffer = []
        self.silence_counter = 0
        self.capture_start_time = 0
        
    def find_device(self):
        """Encontra o dispositivo de áudio"""
        devices = sd.query_devices()
        for i, dev in enumerate(devices):
            if dev['max_input_channels'] > 0:
                if STETHOSCOPE_DEVICE_NAME.lower() in dev['name'].lower():
                    self.device_id = i
                    self.sample_rate = int(dev['default_samplerate'])
                    return True
        # Fallback - primeiro dispositivo de entrada
        for i, dev in enumerate(devices):
            if dev['max_input_channels'] > 0:
                self.device_id = i
                self.sample_rate = int(dev['default_samplerate'])
                return True
        return False
    
    def audio_callback(self, indata, frames, time_info, status):
        """Callback chamado continuamente com dados de áudio"""
        level = np.abs(indata).mean() * 32768
        
        now = time.time()
        
        # Se estamos capturando
        if self.is_capturing:
            self.audio_buffer.append(indata.copy())
            
            # Verifica se atingiu duração máxima
            elapsed = now - self.capture_start_time
            if elapsed >= CAPTURE_DURATION:
                self.finish_capture()
            # Ou se está em silêncio por muito tempo
            elif level < AUDIO_THRESHOLD / 2:
                self.silence_counter += frames / self.sample_rate
                if self.silence_counter > SILENCE_BEFORE_CAPTURE and elapsed > 3:
                    self.finish_capture()
            else:
                self.silence_counter = 0
        else:
            # Detecta início de uso
            if level > AUDIO_THRESHOLD:
                time_since_last = now - self.last_capture_time
                if time_since_last > MIN_INTERVAL_BETWEEN:
                    self.start_capture()
    
    def start_capture(self):
        """Inicia captura automática"""
        self.is_capturing = True
        self.audio_buffer = []
        self.silence_counter = 0
        self.capture_start_time = time.time()
        print(f"\n🎤 [{datetime.now().strftime('%H:%M:%S')}] Estetoscópio detectado - capturando...")
    
    def finish_capture(self):
        """Finaliza captura e envia"""
        self.is_capturing = False
        self.last_capture_time = time.time()
        
        if len(self.audio_buffer) < 10:
            print("   ⚠️  Captura muito curta, ignorando")
            return
        
        # Concatena buffer
        audio_data = np.concatenate(self.audio_buffer)
        duration = len(audio_data) / self.sample_rate
        
        print(f"   ✅ Captura finalizada ({duration:.1f}s)")
        
        # Processa em thread separada para não bloquear
        threading.Thread(
            target=self.process_and_send,
            args=(audio_data.flatten(), self.sample_rate),
            daemon=True
        ).start()
    
    def process_and_send(self, samples, sample_rate):
        """Processa e envia o áudio"""
        try:
            # Converte para int16
            samples_float = samples.astype(np.float64)
            samples_float = samples_float - np.mean(samples_float)
            
            # Normaliza
            max_val = np.max(np.abs(samples_float))
            if max_val > 0:
                samples_float = samples_float * (30000.0 / max_val)
            
            processed = samples_float.astype(np.int16)
            
            # Análise
            bpm, quality = self.analyze(processed, sample_rate)
            print(f"   📊 BPM: {bpm or 'N/A'} | Qualidade: {quality}%")
            
            # Waveform
            waveform = self.generate_waveform(processed)
            
            # Salva WAV
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"fono_{timestamp}.wav"
            with wave.open(filename, 'w') as f:
                f.setnchannels(1)
                f.setsampwidth(2)
                f.setframerate(sample_rate)
                f.writeframes(processed.tobytes())
            
            # Envia
            asyncio.run(self.send_to_server(filename, sample_rate, bpm, quality, waveform))
            
        except Exception as e:
            print(f"   ❌ Erro: {e}")
    
    def analyze(self, samples, sample_rate):
        """Analisa o áudio"""
        samples_float = samples.astype(np.float64)
        samples_float = samples_float - np.mean(samples_float)
        max_val = np.max(np.abs(samples_float))
        if max_val > 0:
            samples_float = samples_float / max_val
        
        rms = np.sqrt(np.mean(samples_float ** 2))
        
        # Envelope
        envelope = np.abs(samples_float)
        window = int(sample_rate * 0.03)
        if window > 1:
            envelope = np.convolve(envelope, np.ones(window)/window, mode='same')
        
        # Detecta picos
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
        
        # BPM
        bpm = None
        if len(peaks) >= 2:
            intervals = np.diff(peaks) / sample_rate
            avg = np.median(intervals)
            if 0.3 < avg < 2.0:
                bpm = int(60 / avg)
        
        quality = min(100, int(rms * 400))
        return bpm, quality
    
    def generate_waveform(self, samples, num_points=500):
        """Gera waveform para visualização"""
        samples_float = samples.astype(np.float64)
        max_val = np.max(np.abs(samples_float))
        if max_val > 0:
            samples_float = samples_float / max_val
        
        block_size = max(1, len(samples_float) // num_points)
        waveform = []
        
        for i in range(0, min(len(samples_float), num_points * block_size), block_size):
            block = samples_float[i:i + block_size]
            peak = max(np.max(block), -np.min(block), key=abs)
            waveform.append(float(peak))
        
        return waveform[:num_points]
    
    async def send_to_server(self, filename, sample_rate, bpm, quality, waveform):
        """Envia para o servidor"""
        # Busca consulta ativa
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{API_URL}/api/biometrics/acontecendo", timeout=10) as resp:
                    if resp.status != 200:
                        print("   ⚠️  Sem consulta ativa")
                        return
                    data = await resp.json()
                    appointment_id = data.get('appointmentId')
                    if not appointment_id:
                        print("   ⚠️  Sem consulta ativa")
                        return
        except Exception as e:
            print(f"   ⚠️  Erro ao buscar consulta: {e}")
            return
        
        # Envia fonocardiograma
        try:
            with open(filename, 'rb') as f:
                wav_data = f.read()
            
            pcm_data = wav_data[44:] if len(wav_data) > 44 else wav_data
            audio_base64 = base64.b64encode(pcm_data).decode('utf-8')
            duration = len(pcm_data) / (sample_rate * 2)
            
            payload = {
                "appointmentId": appointment_id,
                "deviceType": "stethoscope",
                "audioData": audio_base64,
                "sampleRate": sample_rate,
                "format": "pcm_s16le",
                "durationSeconds": duration,
                "waveform": waveform,
                "values": {"heartRate": bpm, "quality": quality}
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{API_URL}/api/biometrics/phonocardiogram",
                    json=payload, timeout=30
                ) as resp:
                    if resp.status == 200:
                        print(f"   📤 Enviado para consulta!")
                    else:
                        print(f"   ❌ Erro ao enviar: {resp.status}")
        except Exception as e:
            print(f"   ❌ Erro: {e}")


async def ble_monitor():
    """Monitora dispositivos BLE"""
    if not BLEAK_AVAILABLE:
        return
    
    last_readings = {}
    
    def callback(device, advertisement_data):
        if device.address.upper() not in DEVICES:
            return
        
        dev_info = DEVICES[device.address.upper()]
        
        # Parse de dados aqui (simplificado)
        for uuid, data in (advertisement_data.service_data or {}).items():
            if dev_info["type"] == "scale" and len(data) >= 5:
                weight = ((data[4] << 8) | data[3]) / 100.0
                if 10 < weight < 300:
                    key = f"scale_{weight}"
                    now = time.time()
                    if key not in last_readings or now - last_readings[key] > 30:
                        last_readings[key] = now
                        print(f"\n⚖️  [{datetime.now().strftime('%H:%M:%S')}] Peso: {weight:.1f} kg")
                        asyncio.create_task(send_vital(dev_info["type"], {"weight": weight}))
    
    try:
        scanner = BleakScanner(callback)
        await scanner.start()
        while True:
            await asyncio.sleep(1)
    except Exception as e:
        print(f"⚠️  BLE: {e}")


async def send_vital(device_type, values):
    """Envia sinal vital"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{API_URL}/api/biometrics/acontecendo", timeout=10) as resp:
                if resp.status != 200:
                    print("   ⚠️  Sem consulta ativa")
                    return
                data = await resp.json()
                appointment_id = data.get('appointmentId')
        
        if not appointment_id:
            return
        
        payload = {
            "appointmentId": appointment_id,
            "deviceType": device_type,
            "values": values,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{API_URL}/api/biometrics/ble-reading",
                json=payload, timeout=30
            ) as resp:
                if resp.status == 200:
                    print(f"   📤 Enviado!")
    except Exception as e:
        print(f"   ❌ Erro: {e}")


async def status_monitor():
    """Mostra status periodicamente"""
    while True:
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{API_URL}/api/biometrics/acontecendo", timeout=10) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        if data.get('appointmentId'):
                            status = "🟢 CONSULTA ATIVA"
                        else:
                            status = "⚪ Aguardando consulta"
                    else:
                        status = "⚪ Aguardando consulta"
        except:
            status = "🔴 Sem conexão"
        
        print(f"\r[{datetime.now().strftime('%H:%M:%S')}] {status}         ", end='', flush=True)
        await asyncio.sleep(5)


def main():
    print("\n" + "=" * 60)
    print("   🩺 TELECUIDAR - MALETA AUTOMÁTICA")
    print("=" * 60)
    print()
    print("   Este sistema é TOTALMENTE AUTOMÁTICO!")
    print()
    print("   A enfermeira só precisa:")
    print("   • Fazer login no TeleCuidar (navegador)")
    print("   • Usar os equipamentos normalmente")
    print()
    print("   ✅ Balança → detecta peso automaticamente")
    print("   ✅ Omron → detecta pressão automaticamente")
    print("   ✅ Termômetro → detecta temperatura automaticamente")
    print("   ✅ Estetoscópio → detecta uso e captura sozinho!")
    print()
    print("   NÃO FECHE ESTA JANELA!")
    print()
    print("=" * 60)
    print()
    
    # Inicializa estetoscópio
    stethoscope = AutomaticStethoscope()
    if stethoscope.find_device():
        print(f"🎤 Estetoscópio encontrado (device {stethoscope.device_id})")
    else:
        print("⚠️  Estetoscópio não encontrado - conecte na entrada P2")
    
    # Inicia stream de áudio em thread separada
    def audio_thread():
        try:
            with sd.InputStream(
                device=stethoscope.device_id,
                channels=1,
                samplerate=stethoscope.sample_rate,
                dtype='float32',
                blocksize=int(stethoscope.sample_rate * 0.1),  # 100ms blocks
                callback=stethoscope.audio_callback
            ):
                while True:
                    time.sleep(1)
        except Exception as e:
            print(f"❌ Erro de áudio: {e}")
    
    threading.Thread(target=audio_thread, daemon=True).start()
    
    print()
    print("-" * 60)
    
    # Event loop principal - só status (BLE roda em outro processo)
    async def run():
        await status_monitor()
    
    try:
        if sys.platform == 'win32':
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(run())
    except KeyboardInterrupt:
        print("\n\n👋 Encerrando...")


if __name__ == "__main__":
    main()
