"""
Teste Rápido do Serviço BLE
============================

Executa o serviço em modo de teste para verificar se está funcionando.
Não requer configuração prévia - usa o ID da consulta passado como argumento.

Uso:
  python testar_servico.py <appointment_id>
  
Exemplo:
  python testar_servico.py f97ee19e-9e84-4509-8acf-0099f83d9514
"""

import asyncio
import sys
import os

# Configura o ambiente para teste local
os.environ["TELECUIDAR_URL"] = "http://localhost:5239"

# Importa o módulo do serviço
from telecuidar_ble_service import (
    state, DEVICES, detection_callback, enviar_leitura, logger
)
from bleak import BleakScanner


async def main():
    if len(sys.argv) < 2:
        print("❌ Uso: python testar_servico.py <appointment_id>")
        print("   Exemplo: python testar_servico.py f97ee19e-9e84-4509-8acf-0099f83d9514")
        sys.exit(1)
    
    appointment_id = sys.argv[1]
    
    # Força o ID da consulta (sem precisar de login)
    state.current_appointment_id = appointment_id
    
    print("=" * 60)
    print("   🧪 TESTE DO SERVIÇO BLE TELECUIDAR")
    print("=" * 60)
    print(f"\nConsulta: {appointment_id}")
    print(f"Backend: {os.environ['TELECUIDAR_URL']}")
    
    print("\nDispositivos monitorados:")
    for mac, device in DEVICES.items():
        print(f"  • {device['name']} ({mac})")
    
    print("\n" + "-" * 60)
    print("🔊 ESCUTANDO DISPOSITIVOS...")
    print("   - Suba na balança para medir peso")
    print("   - Ligue o Omron e faça a medição de pressão")
    print("-" * 60)
    print("\nPressione Ctrl+C para sair\n")
    
    scanner = BleakScanner(detection_callback)
    await scanner.start()
    
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        print("\n\n👋 Teste encerrado")
    finally:
        await scanner.stop()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
