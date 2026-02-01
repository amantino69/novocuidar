"""
TeleCuidar - Maleta Itinerante Unificada
========================================

Sistema unificado para captura de todos os sinais vitais:
- Balança OKOK (peso) - via Bluetooth LE
- Omron HEM-7156T (pressão arterial) - via Bluetooth LE  
- Termômetro MOBI (temperatura) - via Bluetooth LE
- Estetoscópio Digital (fonocardiograma) - via entrada de áudio P2

INSTRUÇÕES PARA O OPERADOR:
---------------------------
1. Ligue os dispositivos Bluetooth e conecte o estetoscópio na entrada P2
2. Execute: python maleta_unificada.py --prod
3. Faça login no TeleCuidar e entre na teleconsulta
4. Clique em "Acontecendo" para ativar a captura
5. Use os dispositivos normalmente - os dados serão enviados automaticamente
6. Para capturar som do estetoscópio: pressione ENTER

Pressione Ctrl+C para encerrar.
"""

import asyncio
import numpy as np
import wave
import time
import base64
import aiohttp
import argparse
import threading
from datetime import datetime
from pathlib import Path

# Tenta importar bleak para BLE
try:
    from bleak import BleakScanner, BleakClient
    BLEAK_AVAILABLE = True
except ImportError:
    BLEAK_AVAILABLE = False
    print("⚠️  bleak não instalado - dispositivos BLE não funcionarão")

# Tenta importar sounddevice para áudio
try:
    import sounddevice as sd
    SOUNDDEVICE_AVAILABLE = True
except ImportError:
    SOUNDDEVICE_AVAILABLE = False
    print("⚠️  sounddevice não instalado - estetoscópio não funcionará")

# ============================================================
# CONFIGURAÇÃO
# ============================================================

# URLs da API
API_URL_LOCAL = "http://localhost:5239"
API_URL_PROD = "https://www.telecuidar.com.br"

USE_PRODUCTION = False

# Dispositivos BLE conhecidos
DEVICES = {
    # Balança OKOK
    "F8:8F:C8:3A:B7:92": {
        "type": "scale",
        "name": "Balança OKOK",
        "method": "advertisement"
    },
    # Omron HEM-7156T
    "00:5F:BF:9A:64:DF": {
        "type": "blood_pressure",
        "name": "Omron HEM-7156T", 
        "method": "gatt"
    },
    # Termômetro MOBI
    "DC:23:4E:DA:E9:DD": {
        "type": "thermometer",
        "name": "Termômetro MOBI",
        "method": "gatt"
    }
}

# Configuração do estetoscópio
STETHOSCOPE_DEVICE_NAME = "Ausculta"
STETHOSCOPE_DURATION = 10  # segundos
STETHOSCOPE_SAMPLE_RATE = 48000

# Tabelas IMA ADPCM para decodificação
STEP_TABLE = [
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
    157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
    724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024,
    3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
]
INDEX_TABLE = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]


def get_api_url():
    return API_URL_PROD if USE_PRODUCTION else API_URL_LOCAL


# ============================================================
# API FUNCTIONS
# ============================================================

async def get_active_appointment():
    """Busca consulta ativa via endpoint 'acontecendo'"""
    url = f"{get_api_url()}/api/biometrics/acontecendo"
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=10) as response:
                if response.status == 200:
                    data = await response.json()
                    return data.get('appointmentId')
                return None
    except:
        return None


async def send_vital_signs(appointment_id: str, device_type: str, values: dict):
    """Envia sinais vitais para a API"""
    url = f"{get_api_url()}/api/biometrics/ble-reading"
    
    payload = {
        "appointmentId": appointment_id,
        "deviceType": device_type,
        "values": values,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, timeout=30) as response:
                return response.status == 200
    except Exception as e:
        print(f"   ❌ Erro ao enviar: {e}")
        return False


async def send_phonocardiogram(appointment_id: str, wav_data: bytes, sample_rate: int, 
                                bpm: int = None, waveform: list = None, quality: int = 0):
    """Envia fonocardiograma para a API"""
    url = f"{get_api_url()}/api/biometrics/phonocardiogram"
    
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
        "values": {
            "heartRate": bpm,
            "quality": quality
        }
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, timeout=30) as response:
                if response.status == 200:
                    result = await response.json()
                    if result.get('audioUrl'):
                        print(f"   🔊 {get_api_url().replace('/api', '')}{result['audioUrl']}")
                    return True
                return False
    except Exception as e:
        print(f"   ❌ Erro: {e}")
        return False


# ============================================================
# BLE DEVICE HANDLERS
# ============================================================

def parse_scale_data(data: bytes) -> dict:
    """Parseia dados da balança OKOK"""
    if len(data) < 10:
        return None
    
    # Formato típico: peso em kg * 100 nos bytes 3-4
    weight_raw = (data[4] << 8) | data[3]
    weight = weight_raw / 100.0
    
    if 10 < weight < 300:  # Peso válido
        return {"weight": weight}
    return None


def parse_blood_pressure_data(data: bytes) -> dict:
    """Parseia dados do Omron"""
    if len(data) < 7:
        return None
    
    systolic = data[1]
    diastolic = data[3]
    pulse = data[5]
    
    if 60 < systolic < 250 and 40 < diastolic < 150:
        return {
            "systolic": systolic,
            "diastolic": diastolic,
            "pulseRate": pulse
        }
    return None


def parse_thermometer_data(data: bytes) -> dict:
    """Parseia dados do termômetro"""
    if len(data) < 4:
        return None
    
    temp_raw = (data[1] << 8) | data[0]
    temperature = temp_raw / 100.0
    
    if 34 < temperature < 42:  # Temperatura corporal válida
        return {"temperature": temperature}
    return None


# ============================================================
# BLE SCANNER
# ============================================================

class BLEMonitor:
    def __init__(self):
        self.running = False
        self.last_readings = {}
        
    async def scan_advertisements(self):
        """Monitora advertisements BLE (para balança)"""
        print("📡 Monitorando dispositivos BLE...")
        
        def callback(device, advertisement_data):
            if device.address.upper() in DEVICES:
                dev_info = DEVICES[device.address.upper()]
                if dev_info["method"] == "advertisement":
                    # Processa dados do advertisement
                    for uuid, data in (advertisement_data.service_data or {}).items():
                        if dev_info["type"] == "scale":
                            values = parse_scale_data(data)
                            if values:
                                self.handle_reading(dev_info, values)
        
        scanner = BleakScanner(callback)
        await scanner.start()
        
        while self.running:
            await asyncio.sleep(1)
        
        await scanner.stop()
    
    def handle_reading(self, device_info: dict, values: dict):
        """Processa uma leitura de dispositivo"""
        key = device_info["type"]
        
        # Evita duplicatas (mesmo valor em 10s)
        now = time.time()
        if key in self.last_readings:
            last_time, last_values = self.last_readings[key]
            if now - last_time < 10 and values == last_values:
                return
        
        self.last_readings[key] = (now, values)
        
        print(f"\n✅ {device_info['name']}: {values}")
        
        # Envia para API em background
        asyncio.create_task(self.send_reading(device_info["type"], values))
    
    async def send_reading(self, device_type: str, values: dict):
        """Envia leitura para a API"""
        appointment_id = await get_active_appointment()
        if appointment_id:
            success = await send_vital_signs(appointment_id, device_type, values)
            if success:
                print(f"   📤 Enviado para consulta {appointment_id[:8]}...")
        else:
            print("   ⚠️  Sem consulta ativa - clique em 'Acontecendo' no TeleCuidar")


# ============================================================
# STETHOSCOPE CAPTURE
# ============================================================

class StethoscopeCapture:
    def __init__(self):
        self.device_id = None
        self.sample_rate = STETHOSCOPE_SAMPLE_RATE
        
    def find_device(self):
        """Encontra o dispositivo de áudio do estetoscópio"""
        if not SOUNDDEVICE_AVAILABLE:
            return False
        
        devices = sd.query_devices()
        for i, dev in enumerate(devices):
            if dev['max_input_channels'] > 0:
                if STETHOSCOPE_DEVICE_NAME.lower() in dev['name'].lower():
                    self.device_id = i
                    self.sample_rate = int(dev['default_samplerate'])
                    return True
        return False
    
    def capture(self, duration: int = STETHOSCOPE_DURATION):
        """Captura áudio do estetoscópio"""
        if self.device_id is None:
            if not self.find_device():
                print("❌ Estetoscópio não encontrado!")
                return None, 0
        
        print(f"\n🎤 Capturando {duration}s de áudio do estetoscópio...")
        print("   Posicione o estetoscópio e aguarde...")
        
        try:
            recording = sd.rec(
                int(duration * self.sample_rate),
                samplerate=self.sample_rate,
                channels=1,
                dtype='int16',
                device=self.device_id
            )
            
            # Progresso
            for i in range(duration):
                progress = (i + 1) / duration
                bar = '█' * int(progress * 30) + '░' * (30 - int(progress * 30))
                print(f"   [{bar}] {i+1}/{duration}s", end='\r')
                time.sleep(1)
            
            sd.wait()
            print(f"\n   ✅ Captura concluída!")
            
            return recording.flatten(), self.sample_rate
            
        except Exception as e:
            print(f"\n   ❌ Erro: {e}")
            return None, 0
    
    def process_and_send(self, samples: np.ndarray, sample_rate: int):
        """Processa e envia o áudio"""
        # Processamento básico
        samples_float = samples.astype(np.float64)
        samples_float = samples_float - np.mean(samples_float)
        
        # Normaliza
        max_val = np.max(np.abs(samples_float))
        if max_val > 0:
            samples_float = samples_float * (30000.0 / max_val)
        
        processed = samples_float.astype(np.int16)
        
        # Análise
        analysis = self.analyze(processed, sample_rate)
        print(f"   📊 BPM: {analysis.get('bpm', 'N/A')} | Qualidade: {analysis.get('quality', 0)}%")
        
        # Waveform para visualização
        waveform = self.generate_waveform(processed)
        
        # Salva WAV
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"fonocardiograma_{timestamp}.wav"
        with wave.open(filename, 'w') as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(sample_rate)
            f.writeframes(processed.tobytes())
        print(f"   💾 Salvo: {filename}")
        
        # Envia
        return filename, analysis, waveform
    
    def analyze(self, samples: np.ndarray, sample_rate: int) -> dict:
        """Analisa o áudio para detectar batimentos"""
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
        
        return {
            'bpm': bpm,
            'quality': min(100, int(rms * 400)),
            'peaks': len(peaks)
        }
    
    def generate_waveform(self, samples: np.ndarray, num_points: int = 500) -> list:
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


# ============================================================
# MAIN
# ============================================================

async def stethoscope_capture_task(stethoscope: StethoscopeCapture):
    """Task para captura do estetoscópio quando ENTER é pressionado"""
    while True:
        # Aguarda input do usuário em thread separada
        await asyncio.get_event_loop().run_in_executor(None, input)
        
        print("\n" + "=" * 50)
        print("🩺 CAPTURA DO ESTETOSCÓPIO")
        print("=" * 50)
        
        # Captura
        samples, sr = stethoscope.capture(STETHOSCOPE_DURATION)
        if samples is None:
            continue
        
        # Processa
        filename, analysis, waveform = stethoscope.process_and_send(samples, sr)
        
        # Envia
        appointment_id = await get_active_appointment()
        if appointment_id:
            print("   📤 Enviando para servidor...")
            with open(filename, 'rb') as f:
                wav_data = f.read()
            success = await send_phonocardiogram(
                appointment_id, wav_data, sr,
                analysis.get('bpm'), waveform, analysis.get('quality', 0)
            )
            if success:
                print("   ✅ Fonocardiograma enviado!")
        else:
            print("   ⚠️  Sem consulta ativa - clique em 'Acontecendo'")
        
        print("\n💡 Pressione ENTER para nova captura do estetoscópio")
        print("-" * 50)


async def main():
    global USE_PRODUCTION
    
    parser = argparse.ArgumentParser(description='TeleCuidar - Maleta Itinerante Unificada')
    parser.add_argument('--prod', action='store_true', help='Servidor de produção')
    parser.add_argument('--no-ble', action='store_true', help='Desativa BLE')
    parser.add_argument('--no-audio', action='store_true', help='Desativa estetoscópio')
    
    args = parser.parse_args()
    USE_PRODUCTION = args.prod
    
    print("\n" + "=" * 60)
    print("   🩺 TELECUIDAR - MALETA ITINERANTE UNIFICADA")
    print("=" * 60)
    print(f"\n📡 Servidor: {'PRODUÇÃO' if USE_PRODUCTION else 'LOCAL'}")
    print()
    
    # Verifica dispositivos
    print("📋 DISPOSITIVOS CONFIGURADOS:")
    print("-" * 40)
    
    if not args.no_ble and BLEAK_AVAILABLE:
        for mac, info in DEVICES.items():
            print(f"   • {info['name']:20s} [{mac}]")
    else:
        print("   ⚠️  BLE desativado")
    
    if not args.no_audio and SOUNDDEVICE_AVAILABLE:
        stethoscope = StethoscopeCapture()
        if stethoscope.find_device():
            print(f"   • Estetoscópio Digital   [Entrada P2 - {stethoscope.sample_rate}Hz]")
        else:
            print(f"   ⚠️  Estetoscópio não encontrado (conecte na entrada P2)")
    else:
        print("   ⚠️  Estetoscópio desativado")
    
    print("-" * 40)
    print()
    
    # Instruções
    print("📝 INSTRUÇÕES:")
    print("   1. Faça login no TeleCuidar e entre na teleconsulta")
    print("   2. Clique em 'Acontecendo' para ativar a captura")
    print("   3. Use os dispositivos - dados enviados automaticamente")
    print("   4. Para estetoscópio: pressione ENTER para capturar")
    print()
    print("   Pressione Ctrl+C para encerrar")
    print()
    print("=" * 60)
    print()
    
    tasks = []
    
    # Inicia monitor BLE
    if not args.no_ble and BLEAK_AVAILABLE:
        ble_monitor = BLEMonitor()
        ble_monitor.running = True
        tasks.append(asyncio.create_task(ble_monitor.scan_advertisements()))
    
    # Inicia captura de estetoscópio
    if not args.no_audio and SOUNDDEVICE_AVAILABLE:
        stethoscope = StethoscopeCapture()
        if stethoscope.find_device():
            print("💡 Pressione ENTER para capturar som do estetoscópio")
            print("-" * 50)
            tasks.append(asyncio.create_task(stethoscope_capture_task(stethoscope)))
    
    # Status loop
    async def status_loop():
        while True:
            appointment_id = await get_active_appointment()
            status = "🟢 ATIVA" if appointment_id else "⚪ Aguardando 'Acontecendo'"
            print(f"\r[{datetime.now().strftime('%H:%M:%S')}] Consulta: {status}     ", end='')
            await asyncio.sleep(5)
    
    tasks.append(asyncio.create_task(status_loop()))
    
    try:
        await asyncio.gather(*tasks)
    except KeyboardInterrupt:
        print("\n\n👋 Encerrando...")
        if 'ble_monitor' in dir():
            ble_monitor.running = False


if __name__ == "__main__":
    # Correção para Windows - usar SelectorEventLoop para evitar conflitos com bleak
    import sys
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
