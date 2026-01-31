"""
Configurador de Nova Maleta TeleCuidar
======================================

Este script automatiza a configuração de uma nova maleta itinerante.
Execute como Administrador!

Uso:
  python configurar_nova_maleta.py

O script irá:
1. Verificar pré-requisitos
2. Instalar dependências
3. Escanear dispositivos Bluetooth
4. Configurar MACs
5. Criar atalhos
6. Testar conexão
"""

import subprocess
import sys
import os
import json
from pathlib import Path

def print_header(texto):
    print("\n" + "=" * 60)
    print(f"  {texto}")
    print("=" * 60)

def print_ok(texto):
    print(f"  ✅ {texto}")

def print_erro(texto):
    print(f"  ❌ {texto}")

def print_aviso(texto):
    print(f"  ⚠️  {texto}")

def verificar_python():
    """Verifica versão do Python"""
    print("\n📋 Verificando Python...")
    versao = sys.version_info
    if versao.major >= 3 and versao.minor >= 10:
        print_ok(f"Python {versao.major}.{versao.minor}.{versao.micro}")
        return True
    else:
        print_erro(f"Python {versao.major}.{versao.minor} - Requer 3.10+")
        return False

def instalar_dependencias():
    """Instala dependências Python"""
    print("\n📦 Instalando dependências...")
    
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-q", "bleak", "aiohttp"], 
                      check=True, capture_output=True)
        print_ok("bleak instalado")
        print_ok("aiohttp instalado")
        return True
    except subprocess.CalledProcessError as e:
        print_erro(f"Erro ao instalar: {e}")
        return False

def verificar_bluetooth():
    """Verifica se Bluetooth está disponível"""
    print("\n📡 Verificando Bluetooth...")
    
    try:
        import asyncio
        from bleak import BleakScanner
        
        async def scan_rapido():
            scanner = BleakScanner()
            await scanner.start()
            await asyncio.sleep(2)
            await scanner.stop()
            return True
        
        asyncio.run(scan_rapido())
        print_ok("Bluetooth funcionando")
        return True
    except Exception as e:
        print_erro(f"Bluetooth não disponível: {e}")
        return False

def escanear_dispositivos():
    """Escaneia dispositivos BLE próximos"""
    print("\n🔍 Escaneando dispositivos Bluetooth...")
    print("   Liga os dispositivos agora (balança, Omron, etc.)")
    print("   Aguarde 15 segundos...")
    
    import asyncio
    from bleak import BleakScanner
    
    dispositivos_encontrados = []
    
    async def scan():
        devices = await BleakScanner.discover(timeout=15.0)
        for d in devices:
            nome = d.name or "Desconhecido"
            if any(x in nome.upper() for x in ["OKOK", "OMRON", "HEM", "MOBI", "SCALE", "BP"]):
                dispositivos_encontrados.append({
                    "mac": d.address,
                    "nome": nome,
                    "rssi": d.rssi
                })
        return devices
    
    asyncio.run(scan())
    
    if dispositivos_encontrados:
        print("\n   📱 Dispositivos médicos encontrados:")
        for d in dispositivos_encontrados:
            print(f"      • {d['nome']} ({d['mac']}) - Sinal: {d['rssi']} dBm")
    else:
        print_aviso("Nenhum dispositivo médico encontrado")
        print("   Certifique-se de que os dispositivos estão ligados e próximos")
    
    return dispositivos_encontrados

def configurar_macs(dispositivos):
    """Configura MACs no arquivo de configuração"""
    print("\n⚙️  Configurando dispositivos...")
    
    config = {
        "scale": {"mac": None, "name": "Balança"},
        "blood_pressure": {"mac": None, "name": "Monitor de Pressão"},
        "thermometer": {"mac": None, "name": "Termômetro"}
    }
    
    for d in dispositivos:
        nome_upper = d['nome'].upper()
        if "OKOK" in nome_upper or "SCALE" in nome_upper:
            config["scale"]["mac"] = d['mac']
            config["scale"]["name"] = d['nome']
        elif "OMRON" in nome_upper or "HEM" in nome_upper or "BP" in nome_upper:
            config["blood_pressure"]["mac"] = d['mac']
            config["blood_pressure"]["name"] = d['nome']
        elif "MOBI" in nome_upper or "THERM" in nome_upper:
            config["thermometer"]["mac"] = d['mac']
            config["thermometer"]["name"] = d['nome']
    
    # Mostra configuração
    for tipo, info in config.items():
        if info["mac"]:
            print_ok(f"{info['name']}: {info['mac']}")
        else:
            print_aviso(f"{info['name']}: Não encontrado")
    
    # Permite configuração manual
    print("\n   Deseja configurar manualmente? (s/N): ", end="")
    resposta = input().strip().lower()
    
    if resposta == 's':
        print("\n   Digite o MAC da Balança (ou Enter para pular): ", end="")
        mac = input().strip()
        if mac:
            config["scale"]["mac"] = mac
        
        print("   Digite o MAC do Omron (ou Enter para pular): ", end="")
        mac = input().strip()
        if mac:
            config["blood_pressure"]["mac"] = mac
        
        print("   Digite o MAC do Termômetro (ou Enter para pular): ", end="")
        mac = input().strip()
        if mac:
            config["thermometer"]["mac"] = mac
    
    return config

def atualizar_script(config):
    """Atualiza o maleta_itinerante.py com os MACs"""
    print("\n📝 Atualizando script...")
    
    script_path = Path(__file__).parent / "maleta_itinerante.py"
    
    # Por enquanto, apenas informa - edição manual mais segura
    print("   Edite o arquivo maleta_itinerante.py:")
    print(f"   Caminho: {script_path}")
    print("\n   Altere os MACs na seção DEVICES (~linha 50):")
    
    for tipo, info in config.items():
        if info["mac"]:
            print(f'      "{info["mac"]}": {{ "type": "{tipo}", ... }}')
    
    return True

def criar_atalhos():
    """Cria atalhos no Desktop e Inicialização"""
    print("\n🔗 Criando atalhos...")
    
    try:
        # PowerShell para criar atalhos
        script = '''
$WScriptShell = New-Object -ComObject WScript.Shell

# Desktop
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$Shortcut = $WScriptShell.CreateShortcut("$DesktopPath\\TeleCuidar Maleta.lnk")
$Shortcut.TargetPath = 'C:\\telecuidar\\maleta\\Iniciar Maleta.bat'
$Shortcut.WorkingDirectory = 'C:\\telecuidar\\maleta'
$Shortcut.IconLocation = 'C:\\Windows\\System32\\shell32.dll,22'
$Shortcut.Save()

# Startup
$StartupPath = [Environment]::GetFolderPath('Startup')
$Shortcut2 = $WScriptShell.CreateShortcut("$StartupPath\\TeleCuidar Maleta.lnk")
$Shortcut2.TargetPath = 'C:\\telecuidar\\maleta\\Iniciar Maleta.bat'
$Shortcut2.WorkingDirectory = 'C:\\telecuidar\\maleta'
$Shortcut2.Save()

Write-Host "OK"
'''
        result = subprocess.run(["powershell", "-Command", script], 
                               capture_output=True, text=True)
        
        if "OK" in result.stdout:
            print_ok("Atalho no Desktop criado")
            print_ok("Atalho na Inicialização criado")
            return True
        else:
            print_erro("Falha ao criar atalhos")
            return False
            
    except Exception as e:
        print_erro(f"Erro: {e}")
        return False

def testar_conexao():
    """Testa conexão com o servidor"""
    print("\n🌐 Testando conexão com servidor...")
    
    import asyncio
    import aiohttp
    
    async def test():
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get("https://www.telecuidar.com.br/api/health", 
                                       timeout=aiohttp.ClientTimeout(total=10)) as resp:
                    if resp.status == 200:
                        return True
        except:
            pass
        return False
    
    if asyncio.run(test()):
        print_ok("Conexão com telecuidar.com.br OK")
        return True
    else:
        print_erro("Não foi possível conectar ao servidor")
        print("   Verifique a conexão com internet")
        return False

def main():
    print_header("CONFIGURADOR DE MALETA TELECUIDAR")
    print("\n   Este assistente irá configurar esta maleta para")
    print("   funcionar com o sistema TeleCuidar.\n")
    
    # Verificações
    if not verificar_python():
        print("\n❌ Instale Python 3.10 ou superior e tente novamente.")
        return
    
    instalar_dependencias()
    
    if not verificar_bluetooth():
        print("\n⚠️  Ative o Bluetooth e tente novamente.")
        input("Pressione Enter para continuar mesmo assim...")
    
    # Escanear dispositivos
    dispositivos = escanear_dispositivos()
    
    # Configurar MACs
    config = configurar_macs(dispositivos)
    
    # Atualizar script
    atualizar_script(config)
    
    # Criar atalhos
    criar_atalhos()
    
    # Testar conexão
    testar_conexao()
    
    # Resumo
    print_header("CONFIGURAÇÃO CONCLUÍDA!")
    print("""
   Próximos passos:
   
   1. Edite o arquivo maleta_itinerante.py com os MACs corretos
      (se não foram detectados automaticamente)
   
   2. Reinicie o computador
   
   3. A janela "TeleCuidar Maleta" deve abrir automaticamente
   
   4. Faça login em telecuidar.com.br e teste uma medição
   
   📖 Consulte o arquivo "GUIA RAPIDO.txt" para instruções de uso
""")
    
    input("\nPressione Enter para sair...")

if __name__ == "__main__":
    main()
