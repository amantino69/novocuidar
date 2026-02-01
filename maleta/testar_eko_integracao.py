#!/usr/bin/env python3
"""
Teste de Integração do Eko CORE 500 com TeleCuidar
Simula uma captura de fonocardiograma e envia para o backend

Uso:
    python testar_eko_integracao.py                  # Local (localhost:5239)
    python testar_eko_integracao.py --prod           # Produção (telecuidar.com.br)
"""

import asyncio
import argparse
import base64
import struct
import aiohttp
from datetime import datetime

# URLs
LOCAL_URL = "http://localhost:5239/api"
PROD_URL = "https://www.telecuidar.com.br/api"

# Gera áudio de teste (tom senoidal simulando batimento cardíaco)
def gerar_audio_teste(duracao=5, sample_rate=8000, bpm=70):
    """Gera áudio PCM simulando batimentos cardíacos"""
    import math
    
    samples = []
    beat_interval = 60 / bpm  # segundos entre batimentos
    beat_duration = 0.15  # duração de cada batimento
    
    for i in range(int(duracao * sample_rate)):
        t = i / sample_rate
        time_in_beat_cycle = t % beat_interval
        
        # Simula batimento (S1-S2)
        if time_in_beat_cycle < beat_duration:
            # S1 (lub) - frequência mais baixa
            phase = time_in_beat_cycle / beat_duration
            envelope = math.sin(math.pi * phase)  # envelope suave
            s1 = math.sin(2 * math.pi * 50 * time_in_beat_cycle) * envelope * 0.8
            sample = int(s1 * 16000)
        elif time_in_beat_cycle < beat_duration * 2.5:
            # Pequena pausa
            sample = 0
        elif time_in_beat_cycle < beat_duration * 3.5:
            # S2 (dub) - frequência mais alta
            phase = (time_in_beat_cycle - beat_duration * 2.5) / beat_duration
            envelope = math.sin(math.pi * phase)
            s2 = math.sin(2 * math.pi * 80 * (time_in_beat_cycle - beat_duration * 2.5)) * envelope * 0.6
            sample = int(s2 * 12000)
        else:
            sample = 0
        
        # Adiciona ruído leve
        noise = int((hash(str(i)) % 100 - 50) * 5)
        sample = max(-32768, min(32767, sample + noise))
        samples.append(sample)
    
    return samples


async def testar_integracao(api_url, bpm=70):
    """Testa integração completa"""
    print("=" * 60)
    print("🩺 TESTE DE INTEGRAÇÃO - EKO CORE 500")
    print("=" * 60)
    print(f"🌐 URL: {api_url}")
    print()
    
    # 1. Verifica se há consulta ativa
    print("📡 Verificando consulta ativa...")
    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(f"{api_url}/biometrics/active-appointment") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    appointment_id = data.get("id")
                    print(f"   ✅ Consulta ativa: {appointment_id}")
                else:
                    print(f"   ⚠️ Nenhuma consulta ativa (status {resp.status})")
                    print("   Para testar, inicie uma teleconsulta no sistema")
                    return False
        except Exception as e:
            print(f"   ❌ Erro de conexão: {e}")
            return False
    
    # 2. Gera áudio de teste
    print()
    print(f"🎵 Gerando áudio de teste ({bpm} BPM, 5 segundos)...")
    samples = gerar_audio_teste(duracao=5, bpm=bpm)
    pcm_bytes = struct.pack(f'<{len(samples)}h', *samples)
    audio_base64 = base64.b64encode(pcm_bytes).decode('utf-8')
    print(f"   ✅ {len(samples)} amostras ({len(pcm_bytes)} bytes)")
    print(f"   ✅ Base64: {len(audio_base64)} caracteres")
    
    # 3. Envia para o backend
    print()
    print("📤 Enviando fonocardiograma...")
    payload = {
        "appointmentId": appointment_id,
        "deviceType": "stethoscope",
        "timestamp": datetime.now().isoformat(),
        "values": {
            "heartRate": bpm
        },
        "audioData": audio_base64,
        "sampleRate": 8000,
        "format": "pcm_s16le",
        "durationSeconds": 5.0
    }
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(f"{api_url}/biometrics/phonocardiogram", json=payload) as resp:
                if resp.status == 200:
                    result = await resp.json()
                    print(f"   ✅ Sucesso!")
                    print(f"   📁 Áudio salvo: {result.get('audioUrl', 'N/A')}")
                    print(f"   ❤️ BPM detectado: {result.get('heartRate', 'N/A')}")
                else:
                    text = await resp.text()
                    print(f"   ❌ Erro {resp.status}: {text}")
                    return False
        except Exception as e:
            print(f"   ❌ Erro: {e}")
            return False
    
    print()
    print("=" * 60)
    print("✅ TESTE CONCLUÍDO COM SUCESSO!")
    print()
    print("Verifique na tela do médico:")
    print("  - Seção 'Fonocardiograma' deve aparecer")
    print("  - Player de áudio com o som de teste")
    print(f"  - Frequência cardíaca: {bpm} BPM")
    print("=" * 60)
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Testar integração Eko CORE 500")
    parser.add_argument("--prod", action="store_true", help="Usar servidor de produção")
    parser.add_argument("--bpm", type=int, default=70, help="BPM simulado (default: 70)")
    args = parser.parse_args()
    
    api_url = PROD_URL if args.prod else LOCAL_URL
    asyncio.run(testar_integracao(api_url, args.bpm))
