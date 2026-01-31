#!/usr/bin/env python3
"""
Diagnóstico do termômetro MOBI - descobre serviços e características
"""

import asyncio
from bleak import BleakClient, BleakScanner

MOBI_MAC = "DC:23:4E:DA:E9:DD"

async def diagnostico():
    print("=" * 70)
    print("  DIAGNÓSTICO DO TERMÔMETRO MOBI")
    print("=" * 70)
    print()
    print(f"Conectando ao {MOBI_MAC}...")
    print(">>> Mantenha o termômetro ligado! <<<")
    print()
    
    try:
        async with BleakClient(MOBI_MAC, timeout=20.0) as client:
            if client.is_connected:
                print("✅ Conectado!")
                print()
                print("=" * 70)
                print("  SERVIÇOS E CARACTERÍSTICAS DISPONÍVEIS")
                print("=" * 70)
                
                for service in client.services:
                    print(f"\n📦 Serviço: {service.uuid}")
                    print(f"   Descrição: {service.description}")
                    
                    for char in service.characteristics:
                        props = ", ".join(char.properties)
                        print(f"   ├── Característica: {char.uuid}")
                        print(f"   │   Propriedades: {props}")
                        
                        # Tenta ler se for readable
                        if "read" in char.properties:
                            try:
                                value = await client.read_gatt_char(char.uuid)
                                print(f"   │   Valor: {value.hex()} ({value})")
                            except Exception as e:
                                print(f"   │   Valor: (erro ao ler: {e})")
                
                print()
                print("=" * 70)
                print("  ESCUTANDO NOTIFICAÇÕES (30 segundos)")
                print("  >>> Faça uma medição agora! <<<")
                print("=" * 70)
                
                # Escuta todas as características com notify/indicate
                received_data = []
                
                def make_handler(char_uuid):
                    def handler(sender, data):
                        print(f"\n🔔 NOTIFICAÇÃO de {char_uuid}:")
                        print(f"   Dados (hex): {data.hex()}")
                        print(f"   Dados (bytes): {list(data)}")
                        received_data.append((char_uuid, data))
                    return handler
                
                notify_chars = []
                for service in client.services:
                    for char in service.characteristics:
                        if "notify" in char.properties or "indicate" in char.properties:
                            try:
                                await client.start_notify(char.uuid, make_handler(char.uuid))
                                notify_chars.append(char.uuid)
                                print(f"👂 Escutando: {char.uuid}")
                            except Exception as e:
                                print(f"❌ Erro ao escutar {char.uuid}: {e}")
                
                print(f"\nEscutando {len(notify_chars)} características...")
                print("Faça a medição de temperatura agora!\n")
                
                await asyncio.sleep(30)
                
                # Para notificações
                for char_uuid in notify_chars:
                    try:
                        await client.stop_notify(char_uuid)
                    except:
                        pass
                
                print()
                if received_data:
                    print(f"✅ Recebidas {len(received_data)} notificações!")
                else:
                    print("❌ Nenhuma notificação recebida")
                    
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    asyncio.run(diagnostico())
