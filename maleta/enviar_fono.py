"""
Enviar Fonocardiograma - Script Simples
========================================
Este script envia o último fonocardiograma capturado para uma consulta específica.
"""

import base64
import aiohttp
import asyncio
import glob
import os
from pathlib import Path

API_URL = "https://www.telecuidar.com.br"

async def enviar_fonocardiograma():
    # Encontra o arquivo WAV mais recente
    wav_files = glob.glob("fonocardiograma_*.wav")
    if not wav_files:
        print("❌ Nenhum arquivo fonocardiograma_*.wav encontrado!")
        print("   Execute primeiro o eko_fonocardiograma.py para capturar")
        return
    
    wav_files.sort(key=os.path.getmtime, reverse=True)
    latest_wav = wav_files[0]
    
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║   📤 ENVIAR FONOCARDIOGRAMA PARA CONSULTA                    ║
╚══════════════════════════════════════════════════════════════╝

   Arquivo: {latest_wav}
   Tamanho: {os.path.getsize(latest_wav) / 1024:.1f} KB
""")
    
    # Pede o ID da consulta
    print("   Cole o ID da consulta da URL do navegador.")
    print("   Exemplo: 62734ef5-c2af-40f1-8726-099932da0240")
    print()
    appointment_id = input("👉 ID da consulta: ").strip()
    
    if not appointment_id or len(appointment_id) < 30:
        print("❌ ID inválido!")
        return
    
    print(f"\n📡 Enviando para {API_URL}...")
    
    # Lê o arquivo
    with open(latest_wav, 'rb') as f:
        wav_data = f.read()
    
    audio_b64 = base64.b64encode(wav_data).decode()
    
    payload = {
        'appointmentId': appointment_id,
        'values': {'heartRate': None},
        'audioData': audio_b64,
        'sampleRate': 8000
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            url = f"{API_URL}/api/biometrics/phonocardiogram"
            async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=30)) as resp:
                if resp.status == 200:
                    result = await resp.json()
                    print(f"""
✅ FONOCARDIOGRAMA ENVIADO COM SUCESSO!

   📁 Arquivo no servidor: {result.get('audioUrl')}
   
   O médico agora pode clicar no botão ▶ para ouvir!
""")
                else:
                    text = await resp.text()
                    print(f"❌ Erro {resp.status}: {text}")
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")


if __name__ == "__main__":
    asyncio.run(enviar_fonocardiograma())
