#!/usr/bin/env python3
"""
Teste de comandos para o termômetro MOBI
"""

import asyncio
from bleak import BleakClient

MOBI_MAC = "DC:23:4E:DA:E9:DD"

# Características do MOBI
WRITE_CHAR_1 = "00000001-0000-1001-8001-00805f9b07d0"
NOTIFY_CHAR_1 = "00000002-0000-1001-8001-00805f9b07d0"
WRITE_CHAR_2 = "5833ff02-9b8b-5191-6142-22a4536ef123"
NOTIFY_CHAR_2 = "5833ff03-9b8b-5191-6142-22a4536ef123"

# Comandos comuns para tentar
COMMANDS = [
    (bytes([0x01]), "Comando 0x01"),
    (bytes([0x02]), "Comando 0x02"),
    (bytes([0x10]), "Comando 0x10"),
    (bytes([0x11]), "Comando 0x11"),
    (bytes([0x20]), "Comando 0x20"),
    (bytes([0x51]), "Comando 0x51"),
    (bytes([0x52]), "Comando 0x52"),
    (bytes([0xA1]), "Comando 0xA1"),
    (bytes([0xFE]), "Comando 0xFE"),
    (bytes([0xFF]), "Comando 0xFF"),
    (bytes([0x00, 0x01]), "Comando 0x00 0x01"),
    (bytes([0x01, 0x00]), "Comando 0x01 0x00"),
    (bytes([0x55, 0xAA]), "Comando sync 0x55 0xAA"),
]

async def teste_comandos():
    print("=" * 70)
    print("  TESTE DE COMANDOS - TERMÔMETRO MOBI")
    print("=" * 70)
    print()
    print(f"Conectando ao {MOBI_MAC}...")
    print()
    
    received = []
    
    def notification_handler(sender, data):
        print(f"\n  🔔 RESPOSTA RECEBIDA!")
        print(f"     Sender: {sender}")
        print(f"     Dados (hex): {data.hex()}")
        print(f"     Dados (bytes): {list(data)}")
        received.append(data)
    
    try:
        async with BleakClient(MOBI_MAC, timeout=20.0) as client:
            if client.is_connected:
                print("✅ Conectado!")
                print()
                
                # Escutar ambas características de notify
                await client.start_notify(NOTIFY_CHAR_1, notification_handler)
                await client.start_notify(NOTIFY_CHAR_2, notification_handler)
                print("👂 Escutando notificações...")
                print()
                
                # Tentar cada comando
                for cmd, desc in COMMANDS:
                    print(f"📤 Enviando {desc} para característica 1...")
                    try:
                        await client.write_gatt_char(WRITE_CHAR_1, cmd, response=False)
                        await asyncio.sleep(1)
                    except Exception as e:
                        print(f"   ❌ Erro: {e}")
                    
                    if received:
                        print(f"   ✅ Recebeu resposta!")
                        break
                
                if not received:
                    print()
                    print("Tentando característica 2...")
                    for cmd, desc in COMMANDS[:5]:
                        print(f"📤 Enviando {desc} para característica 2...")
                        try:
                            await client.write_gatt_char(WRITE_CHAR_2, cmd)
                            await asyncio.sleep(1)
                        except Exception as e:
                            print(f"   ❌ Erro: {e}")
                        
                        if received:
                            print(f"   ✅ Recebeu resposta!")
                            break
                
                print()
                print("=" * 70)
                if received:
                    print(f"✅ Total de respostas recebidas: {len(received)}")
                    for i, data in enumerate(received):
                        print(f"   {i+1}. {data.hex()} = {list(data)}")
                else:
                    print("❌ Nenhuma resposta recebida")
                    print()
                    print("O termômetro pode precisar de um protocolo específico.")
                    print("Verifique o manual ou app oficial do MOBI.")
                print("=" * 70)
                
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    asyncio.run(teste_comandos())
