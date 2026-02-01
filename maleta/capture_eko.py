"""
Captura de Áudio do Eko CORE 500
================================

Este script tenta capturar dados de streaming do Eko CORE 500
através das características que suportam NOTIFY.

MAC do dispositivo: 88:D2:11:C8:20:31
"""

import asyncio
import struct
import wave
import numpy as np
from datetime import datetime
from pathlib import Path
from bleak import BleakClient, BleakScanner

# Configuração do Eko CORE 500
EKO_MAC = "88:D2:11:C8:20:31"

# Características que suportam NOTIFY (possíveis canais de áudio)
NOTIFY_CHARACTERISTICS = [
    # Serviço 5bf6e500-9999-11e3-a116-0002a5d5c51b
    "ba9c5360-9999-11e3-966f-0002a5d5c51b",
    
    # Serviço f1de0ef3-6e8f-4fa6-b538-5bd318bdbccb
    "c320d257-d7be-46ac-9a37-7a4edfa84bce",
    "c2148e84-cb1f-4a05-9ed0-832a1e9fb336",
]

# Buffer para armazenar dados recebidos
audio_buffers = {char: bytearray() for char in NOTIFY_CHARACTERISTICS}
packet_counts = {char: 0 for char in NOTIFY_CHARACTERISTICS}


def create_notification_handler(char_uuid: str):
    """Cria um handler de notificação para uma característica específica"""
    def handler(sender, data):
        audio_buffers[char_uuid].extend(data)
        packet_counts[char_uuid] += 1
        
        # Mostra os primeiros bytes para análise
        if packet_counts[char_uuid] <= 5:
            print(f"\n📦 [{char_uuid[:8]}...] Pacote #{packet_counts[char_uuid]}")
            print(f"   Tamanho: {len(data)} bytes")
            print(f"   Hex: {data[:20].hex()}{'...' if len(data) > 20 else ''}")
            print(f"   Bytes: {list(data[:20])}{'...' if len(data) > 20 else ''}")
            
            # Tenta interpretar como diferentes formatos
            if len(data) >= 2:
                # Tenta PCM 16-bit little-endian
                try:
                    samples = struct.unpack(f'<{len(data)//2}h', data[:len(data)//2*2])
                    print(f"   Como PCM 16-bit: {samples[:5]}...")
                except:
                    pass
        elif packet_counts[char_uuid] % 100 == 0:
            total_bytes = len(audio_buffers[char_uuid])
            print(f"   [{char_uuid[:8]}...] {packet_counts[char_uuid]} pacotes, {total_bytes} bytes total")
    
    return handler


async def capture_eko_data(duration_seconds: int = 10):
    """Captura dados do Eko por um período especificado"""
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 CAPTURA DE DADOS - EKO CORE 500                         ║
║                                                              ║
║   Duração: {duration_seconds} segundos                                       ║
║   Pressione Ctrl+C para parar antes                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    print(f"🔍 Conectando ao Eko CORE 500 ({EKO_MAC})...")
    
    try:
        async with BleakClient(EKO_MAC, timeout=30.0) as client:
            print(f"✅ Conectado! MTU: {client.mtu_size}")
            
            # Ativa notificações em todas as características
            print("\n📡 Ativando streaming de dados...")
            active_chars = []
            
            for char_uuid in NOTIFY_CHARACTERISTICS:
                try:
                    await client.start_notify(char_uuid, create_notification_handler(char_uuid))
                    print(f"   ✅ {char_uuid[:8]}... ativado")
                    active_chars.append(char_uuid)
                except Exception as e:
                    print(f"   ❌ {char_uuid[:8]}... falhou: {e}")
            
            if not active_chars:
                print("\n❌ Nenhuma característica conseguiu ser ativada")
                return
            
            print(f"\n🎤 CAPTURANDO POR {duration_seconds} SEGUNDOS...")
            print("   Coloque o estetoscópio no peito para testar")
            print("   (ou bata levemente no diafragma)\n")
            
            # Aguarda o tempo de captura
            try:
                await asyncio.sleep(duration_seconds)
            except asyncio.CancelledError:
                print("\n⏹️ Captura interrompida pelo usuário")
            
            # Desativa notificações
            print("\n🛑 Parando captura...")
            for char_uuid in active_chars:
                try:
                    await client.stop_notify(char_uuid)
                except:
                    pass
            
            # Análise dos dados capturados
            print("\n" + "=" * 60)
            print("   📊 ANÁLISE DOS DADOS CAPTURADOS")
            print("=" * 60)
            
            for char_uuid in NOTIFY_CHARACTERISTICS:
                data = audio_buffers[char_uuid]
                packets = packet_counts[char_uuid]
                
                if packets > 0:
                    print(f"\n🔷 Característica: {char_uuid[:20]}...")
                    print(f"   Pacotes recebidos: {packets}")
                    print(f"   Total de bytes: {len(data)}")
                    print(f"   Média por pacote: {len(data)/packets:.1f} bytes")
                    
                    if len(data) > 0:
                        # Salva os dados brutos
                        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                        filename = f"eko_raw_{char_uuid[:8]}_{timestamp}.bin"
                        with open(filename, 'wb') as f:
                            f.write(data)
                        print(f"   💾 Dados salvos em: {filename}")
                        
                        # Tenta converter para WAV assumindo PCM 16-bit
                        try:
                            wav_filename = f"eko_audio_{char_uuid[:8]}_{timestamp}.wav"
                            save_as_wav(data, wav_filename)
                            print(f"   🔊 Áudio WAV salvo em: {wav_filename}")
                        except Exception as e:
                            print(f"   ⚠️ Não foi possível converter para WAV: {e}")
            
            # Resumo
            total_data = sum(len(buf) for buf in audio_buffers.values())
            total_packets = sum(packet_counts.values())
            print(f"\n📈 TOTAL: {total_packets} pacotes, {total_data} bytes")
            
            if total_data == 0:
                print("\n⚠️ Nenhum dado recebido!")
                print("   Possíveis causas:")
                print("   1. O Eko precisa estar em modo de gravação")
                print("   2. Pode ser necessário enviar comando de início")
                print("   3. O áudio pode usar outra característica")
            
    except Exception as e:
        print(f"\n❌ Erro: {e}")


def save_as_wav(data: bytes, filename: str, sample_rate: int = 4000):
    """
    Salva dados brutos como arquivo WAV.
    Tenta diferentes interpretações dos dados.
    """
    # Remove padding se houver
    if len(data) % 2 != 0:
        data = data[:-1]
    
    if len(data) < 10:
        raise ValueError("Dados insuficientes")
    
    # Interpreta como PCM 16-bit signed little-endian
    samples = struct.unpack(f'<{len(data)//2}h', data)
    
    # Normaliza
    samples_array = np.array(samples, dtype=np.int16)
    
    # Salva como WAV
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)  # Taxa de amostragem (ajustar conforme necessário)
        wav_file.writeframes(samples_array.tobytes())


async def try_start_commands():
    """Tenta enviar comandos de início para o Eko"""
    print("🔧 Tentando enviar comandos de início...")
    
    # Características que aceitam write
    WRITE_CHARACTERISTICS = [
        "ba9c5360-9999-11e3-966f-0002a5d5c51b",  # write-without-response
        "c320d257-d7be-46ac-9a37-7a4edfa84bce",  # write-without-response
        "31ddcab1-2788-4af0-b019-9307cebfaf53",  # write
    ]
    
    # Comandos comuns para iniciar streaming
    START_COMMANDS = [
        bytes([0x01]),           # Simples start
        bytes([0x01, 0x00]),     # Start com parâmetro
        bytes([0x00, 0x01]),     # Alternativo
        bytes([0x53, 0x54]),     # "ST" ASCII
        b"start",                 # Texto
    ]
    
    try:
        async with BleakClient(EKO_MAC, timeout=30.0) as client:
            print(f"✅ Conectado!")
            
            for char_uuid in WRITE_CHARACTERISTICS:
                for cmd in START_COMMANDS:
                    try:
                        await client.write_gatt_char(char_uuid, cmd, response=False)
                        print(f"   ✅ Enviado {cmd.hex()} para {char_uuid[:8]}...")
                    except Exception as e:
                        pass
            
            print("\n   Comandos enviados. Execute a captura novamente.")
            
    except Exception as e:
        print(f"❌ Erro: {e}")


async def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🩺 EKO CORE 500 - CAPTURA DE FONOCARDIOGRAMA               ║
║                                                              ║
║   MAC: 88:D2:11:C8:20:31                                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Escolha uma opção:
   [1] Capturar dados por 10 segundos
   [2] Capturar dados por 30 segundos  
   [3] Capturar dados por 60 segundos
   [4] Tentar enviar comandos de início
   [0] Sair
    """)
    
    try:
        choice = input("👉 Opção: ").strip()
        
        if choice == "1":
            await capture_eko_data(10)
        elif choice == "2":
            await capture_eko_data(30)
        elif choice == "3":
            await capture_eko_data(60)
        elif choice == "4":
            await try_start_commands()
        elif choice == "0":
            print("Saindo...")
        else:
            print("Opção inválida")
            
    except KeyboardInterrupt:
        print("\n👋 Cancelado")


if __name__ == "__main__":
    asyncio.run(main())
