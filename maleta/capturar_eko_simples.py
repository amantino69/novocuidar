#!/usr/bin/env python3
"""
Script simplificado para capturar e enviar fonocardiograma do Eko CORE 500
Uso: python capturar_eko_simples.py [--local]
"""

import asyncio
import struct
import base64
import argparse
import aiohttp
import numpy as np
from bleak import BleakClient

# Configuração
EKO_MAC = "88:D2:11:C8:20:31"
EKO_CHAR_UUID = "c320d257-d7be-46ac-9a37-7a4edfa84bce"
DURATION = 15  # segundos

# Argumentos
parser = argparse.ArgumentParser()
parser.add_argument('--local', '-l', action='store_true', help='Usar localhost:5239')
args = parser.parse_args()

API_URL = "http://localhost:5239/api" if args.local else "https://www.telecuidar.com.br/api"

# Buffer de áudio
audio_buffer = bytearray()
packet_count = 0

def decode_ima_adpcm(data: bytes) -> list:
    """Decodifica IMA ADPCM para PCM 16-bit"""
    IMA_INDEX_TABLE = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]
    IMA_STEP_TABLE = [
        7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
        34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
        157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
        724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024,
        3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
        15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
    ]
    
    samples = []
    predictor = 0
    step_index = 0
    
    for byte in data:
        for nibble in [byte & 0x0F, (byte >> 4) & 0x0F]:
            step = IMA_STEP_TABLE[step_index]
            diff = step >> 3
            if nibble & 1: diff += step >> 2
            if nibble & 2: diff += step >> 1
            if nibble & 4: diff += step
            if nibble & 8: diff = -diff
            
            predictor = max(-32768, min(32767, predictor + diff))
            samples.append(predictor)
            
            step_index = max(0, min(88, step_index + IMA_INDEX_TABLE[nibble]))
    
    return samples

def analyze_heartbeat(samples: list, sample_rate: int = 8000) -> dict:
    """Analisa frequência cardíaca"""
    samples_np = np.array(samples, dtype=np.float32)
    samples_np = samples_np - np.mean(samples_np)
    
    # Autocorrelação
    corr = np.correlate(samples_np, samples_np, mode='full')
    corr = corr[len(corr)//2:]
    
    # Encontra picos
    min_samples = int(sample_rate * 0.4)  # 150 BPM max
    max_samples = int(sample_rate * 1.5)  # 40 BPM min
    
    if len(corr) > max_samples:
        search_region = corr[min_samples:max_samples]
        peak_idx = np.argmax(search_region) + min_samples
        
        if peak_idx > 0:
            period_seconds = peak_idx / sample_rate
            bpm = int(60 / period_seconds)
            if 40 <= bpm <= 150:
                return {"heartRate": bpm}
    
    return {"heartRate": None}


async def get_active_appointment() -> str:
    """Busca consulta ativa"""
    async with aiohttp.ClientSession() as session:
        async with session.get(f"{API_URL}/biometrics/active-appointment") as resp:
            if resp.status == 200:
                data = await resp.json()
                return data.get("appointmentId")
    return None


async def capture_and_send():
    global audio_buffer, packet_count
    
    print(f"\n{'='*60}")
    print(f"🩺 CAPTURA SIMPLIFICADA - EKO CORE 500")
    print(f"{'='*60}")
    print(f"API: {API_URL}")
    
    # Busca consulta ativa
    print("\n📡 Verificando consulta ativa...")
    appointment_id = await get_active_appointment()
    
    if not appointment_id:
        print("❌ Nenhuma consulta ativa encontrada!")
        print("   Inicie uma teleconsulta primeiro.")
        return
    
    print(f"   ✅ Consulta: {appointment_id}")
    
    # Callback para notificações
    def notification_handler(sender, data):
        global audio_buffer, packet_count
        audio_buffer.extend(data)
        packet_count += 1
        if packet_count % 50 == 0:
            print(f"   📦 {packet_count} pacotes ({len(audio_buffer)} bytes)")
    
    # Conecta ao Eko
    print(f"\n🔗 Conectando ao Eko ({EKO_MAC})...")
    
    try:
        async with BleakClient(EKO_MAC, timeout=30.0) as client:
            if not client.is_connected:
                print("❌ Falha ao conectar!")
                return
            
            print("   ✅ Conectado!")
            
            # Inicia captura
            print(f"\n🎵 Capturando áudio por {DURATION} segundos...")
            print("   (Coloque o estetoscópio no peito)")
            
            await client.start_notify(EKO_CHAR_UUID, notification_handler)
            
            # Aguarda
            for i in range(DURATION, 0, -1):
                print(f"\r   ⏱️ {i}s restantes...", end="", flush=True)
                await asyncio.sleep(1)
            
            await client.stop_notify(EKO_CHAR_UUID)
            print(f"\n\n🛑 Captura finalizada: {packet_count} pacotes, {len(audio_buffer)} bytes")
            
            if len(audio_buffer) == 0:
                print("❌ Nenhum dado capturado!")
                return
            
            # Processa áudio
            print("\n🔧 Processando áudio...")
            
            # Remove headers (1 byte por pacote de 238 bytes)
            raw_data = bytes(audio_buffer)
            packet_size = 238
            num_packets = len(raw_data) // packet_size
            
            clean_data = bytearray()
            for i in range(num_packets):
                packet = raw_data[i * packet_size : (i + 1) * packet_size]
                clean_data.extend(packet[1:])  # Skip header
            
            # Decodifica
            samples = decode_ima_adpcm(bytes(clean_data))
            print(f"   ✅ {len(samples)} amostras decodificadas")
            
            # Analisa BPM
            analysis = analyze_heartbeat(samples)
            if analysis.get("heartRate"):
                print(f"   ❤️ Frequência cardíaca: {analysis['heartRate']} BPM")
            
            # Converte para base64
            pcm_bytes = struct.pack(f'<{len(samples)}h', *samples)
            audio_base64 = base64.b64encode(pcm_bytes).decode('utf-8')
            
            # Envia para backend
            print(f"\n📤 Enviando para backend...")
            
            payload = {
                "appointmentId": appointment_id,
                "deviceType": "stethoscope",
                "values": {"heartRate": analysis.get("heartRate")},
                "audioData": audio_base64,
                "sampleRate": 8000,
                "format": "pcm_s16le"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(f"{API_URL}/biometrics/phonocardiogram", json=payload) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        print(f"   ✅ Sucesso!")
                        print(f"   📁 Áudio: {result.get('audioUrl')}")
                    else:
                        text = await resp.text()
                        print(f"   ❌ Erro {resp.status}: {text}")
            
            print(f"\n{'='*60}")
            print("✅ CAPTURA CONCLUÍDA!")
            print("   Verifique a tela do médico - o fonocardiograma deve aparecer.")
            print(f"{'='*60}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")


if __name__ == "__main__":
    asyncio.run(capture_and_send())
