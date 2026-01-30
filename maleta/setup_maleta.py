"""
Setup da Maleta TeleCuidar
===========================

Este script configura a maleta para um paciente específico.
Execute uma vez ao preparar a maleta para enviar ao paciente.

Uso:
  python setup_maleta.py --email pac_maria@telecuidar.com --senha 123
"""

import argparse
import json
import sys
import os
from pathlib import Path

# Adiciona o diretório atual ao path
sys.path.insert(0, str(Path(__file__).parent))

try:
    import aiohttp
    import asyncio
except ImportError:
    print("❌ Dependências não instaladas!")
    print("   Execute: pip install aiohttp bleak")
    sys.exit(1)

CONFIG_FILE = Path(__file__).parent / "config.json"
DEFAULT_BACKEND = "http://localhost:5239"  # Mude para produção quando necessário


async def fazer_login(email: str, senha: str, backend_url: str) -> dict:
    """Faz login e retorna dados do paciente"""
    async with aiohttp.ClientSession() as session:
        url = f"{backend_url}/api/auth/login"
        payload = {"email": email, "password": senha}
        
        async with session.post(url, json=payload) as resp:
            if resp.status == 200:
                return await resp.json()
            else:
                text = await resp.text()
                raise Exception(f"Erro no login: {resp.status} - {text}")


async def main():
    parser = argparse.ArgumentParser(description="Setup da Maleta TeleCuidar")
    parser.add_argument("--email", required=True, help="Email do paciente")
    parser.add_argument("--senha", required=True, help="Senha do paciente")
    parser.add_argument("--backend", default=DEFAULT_BACKEND, help="URL do backend")
    parser.add_argument("--producao", action="store_true", help="Usar servidor de produção")
    
    args = parser.parse_args()
    
    backend_url = "https://www.telecuidar.com.br" if args.producao else args.backend
    
    print("=" * 60)
    print("   🎒 SETUP DA MALETA TELECUIDAR")
    print("=" * 60)
    print(f"\nPaciente: {args.email}")
    print(f"Backend: {backend_url}")
    print()
    
    try:
        # Faz login para obter token e ID
        print("🔐 Fazendo login...")
        login_data = fazer_login(args.email, args.senha, backend_url)
        login_result = asyncio.get_event_loop().run_until_complete(
            fazer_login(args.email, args.senha, backend_url)
        )
        
        # Extrai dados
        token = login_result.get("token")
        user = login_result.get("user", {})
        patient_id = user.get("id")
        patient_name = user.get("fullName", user.get("name", args.email))
        
        if not token or not patient_id:
            raise Exception("Resposta de login inválida")
        
        print(f"✅ Login OK: {patient_name}")
        print(f"   ID: {patient_id}")
        
        # Carrega configuração existente
        config = {}
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
        
        # Atualiza com dados do paciente
        config["patient_id"] = patient_id
        config["patient_email"] = args.email
        config["auth_token"] = token
        config["backend_url"] = backend_url
        config["patient_name"] = patient_name
        config["setup_date"] = str(__import__('datetime').datetime.now())
        
        # Salva
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=4, ensure_ascii=False)
        
        print(f"\n✅ Configuração salva em: {CONFIG_FILE}")
        
        print("\n" + "-" * 60)
        print("📋 PRÓXIMOS PASSOS:")
        print("-" * 60)
        print("1. Instale o serviço Windows:")
        print("   python instalar_servico.py")
        print()
        print("2. Ou execute manualmente para testar:")
        print("   python telecuidar_ble_service.py")
        print()
        print("3. Configure o Chrome para abrir telecuidar.com.br")
        print("   automaticamente ao iniciar o Windows")
        print("-" * 60)
        
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
