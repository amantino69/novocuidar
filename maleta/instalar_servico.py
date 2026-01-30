"""
Instalador do Serviço Windows TeleCuidar BLE
=============================================

Instala o serviço BLE como um serviço Windows que inicia automaticamente.
Usa NSSM (Non-Sucking Service Manager) para gerenciar o serviço.

Requisitos:
- Python 3.10+
- NSSM instalado (https://nssm.cc/download)
- Executar como Administrador
"""

import subprocess
import sys
import os
from pathlib import Path

SERVICE_NAME = "TeleCuidarBLE"
SERVICE_DISPLAY_NAME = "TeleCuidar BLE Service"
SERVICE_DESCRIPTION = "Serviço de captura de dispositivos médicos Bluetooth para telemedicina"

SCRIPT_DIR = Path(__file__).parent
SERVICE_SCRIPT = SCRIPT_DIR / "telecuidar_ble_service.py"
LOGS_DIR = SCRIPT_DIR / "logs"


def is_admin():
    """Verifica se está rodando como administrador"""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def find_nssm():
    """Procura o NSSM no sistema"""
    # Tenta encontrar no PATH
    result = subprocess.run(["where", "nssm"], capture_output=True, text=True)
    if result.returncode == 0:
        return result.stdout.strip().split('\n')[0]
    
    # Tenta locais comuns
    common_paths = [
        r"C:\nssm\nssm.exe",
        r"C:\Program Files\nssm\nssm.exe",
        r"C:\tools\nssm\nssm.exe",
        SCRIPT_DIR / "nssm.exe"
    ]
    
    for path in common_paths:
        if Path(path).exists():
            return str(path)
    
    return None


def find_python():
    """Encontra o executável Python"""
    return sys.executable


def install_service():
    """Instala o serviço Windows"""
    
    if not is_admin():
        print("❌ Este script precisa ser executado como Administrador!")
        print("   Clique com botão direito → Executar como administrador")
        sys.exit(1)
    
    nssm = find_nssm()
    if not nssm:
        print("❌ NSSM não encontrado!")
        print()
        print("   Baixe em: https://nssm.cc/download")
        print("   Extraia nssm.exe para C:\\nssm\\ ou para esta pasta")
        sys.exit(1)
    
    python = find_python()
    
    print("=" * 60)
    print("   🔧 INSTALADOR DO SERVIÇO TELECUIDAR BLE")
    print("=" * 60)
    print(f"\nNSSM: {nssm}")
    print(f"Python: {python}")
    print(f"Script: {SERVICE_SCRIPT}")
    print()
    
    # Remove serviço existente (se houver)
    print("🔄 Removendo serviço antigo (se existir)...")
    subprocess.run([nssm, "stop", SERVICE_NAME], capture_output=True)
    subprocess.run([nssm, "remove", SERVICE_NAME, "confirm"], capture_output=True)
    
    # Cria diretório de logs
    LOGS_DIR.mkdir(exist_ok=True)
    
    # Instala o serviço
    print(f"📦 Instalando serviço '{SERVICE_NAME}'...")
    
    result = subprocess.run([
        nssm, "install", SERVICE_NAME, python, str(SERVICE_SCRIPT)
    ], capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ Erro ao instalar: {result.stderr}")
        sys.exit(1)
    
    # Configura o serviço
    print("⚙️  Configurando serviço...")
    
    # Nome de exibição
    subprocess.run([nssm, "set", SERVICE_NAME, "DisplayName", SERVICE_DISPLAY_NAME])
    
    # Descrição
    subprocess.run([nssm, "set", SERVICE_NAME, "Description", SERVICE_DESCRIPTION])
    
    # Diretório de trabalho
    subprocess.run([nssm, "set", SERVICE_NAME, "AppDirectory", str(SCRIPT_DIR)])
    
    # Logs
    stdout_log = LOGS_DIR / "service_stdout.log"
    stderr_log = LOGS_DIR / "service_stderr.log"
    subprocess.run([nssm, "set", SERVICE_NAME, "AppStdout", str(stdout_log)])
    subprocess.run([nssm, "set", SERVICE_NAME, "AppStderr", str(stderr_log)])
    subprocess.run([nssm, "set", SERVICE_NAME, "AppStdoutCreationDisposition", "4"])  # Append
    subprocess.run([nssm, "set", SERVICE_NAME, "AppStderrCreationDisposition", "4"])
    
    # Reinício automático em caso de falha
    subprocess.run([nssm, "set", SERVICE_NAME, "AppRestartDelay", "5000"])  # 5 segundos
    
    # Inicia automaticamente
    subprocess.run([nssm, "set", SERVICE_NAME, "Start", "SERVICE_AUTO_START"])
    
    # Inicia o serviço
    print("🚀 Iniciando serviço...")
    result = subprocess.run([nssm, "start", SERVICE_NAME], capture_output=True, text=True)
    
    if result.returncode == 0:
        print()
        print("=" * 60)
        print("   ✅ SERVIÇO INSTALADO COM SUCESSO!")
        print("=" * 60)
        print()
        print(f"   Nome: {SERVICE_NAME}")
        print(f"   Status: Iniciado")
        print(f"   Logs: {LOGS_DIR}")
        print()
        print("   Comandos úteis:")
        print(f"   - Parar:     nssm stop {SERVICE_NAME}")
        print(f"   - Iniciar:   nssm start {SERVICE_NAME}")
        print(f"   - Status:    nssm status {SERVICE_NAME}")
        print(f"   - Remover:   nssm remove {SERVICE_NAME}")
        print()
    else:
        print(f"⚠️  Serviço instalado mas não iniciou: {result.stderr}")
        print("   Verifique os logs em:", LOGS_DIR)


def uninstall_service():
    """Remove o serviço"""
    nssm = find_nssm()
    if not nssm:
        print("❌ NSSM não encontrado")
        return
    
    print(f"🗑️  Removendo serviço '{SERVICE_NAME}'...")
    subprocess.run([nssm, "stop", SERVICE_NAME], capture_output=True)
    result = subprocess.run([nssm, "remove", SERVICE_NAME, "confirm"], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ Serviço removido com sucesso!")
    else:
        print(f"❌ Erro: {result.stderr}")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uninstall":
        uninstall_service()
    else:
        install_service()
