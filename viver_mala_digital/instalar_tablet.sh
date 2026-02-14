#!/data/data/com.termux/files/usr/bin/bash
#
# TeleCuidar - Script de Instalação para Tablet Android
# Execute no Termux: curl -sL URL | bash
#

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       TELECUIDAR - INSTALAÇÃO MALETA TELEMEDICINA            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok() { echo -e "${GREEN}✓${NC} $1"; }
log_err() { echo -e "${RED}✗${NC} $1"; }
log_warn() { echo -e "${YELLOW}!${NC} $1"; }
log_info() { echo -e "  $1"; }

# Verifica se está no Termux
if [ ! -d "/data/data/com.termux" ]; then
    log_err "Este script deve ser executado no Termux!"
    exit 1
fi

log_ok "Termux detectado"

# Atualiza pacotes
echo ""
echo "=== Atualizando pacotes ==="
pkg update -y 2>/dev/null
if [ $? -eq 0 ]; then
    log_ok "Pacotes atualizados"
else
    log_warn "Falha ao atualizar - tentando trocar mirror..."
    termux-change-repo
    pkg update -y
fi

# Instala Python
echo ""
echo "=== Instalando Python ==="
pkg install python -y 2>/dev/null
if command -v python &> /dev/null; then
    PYVER=$(python --version 2>&1)
    log_ok "Python instalado: $PYVER"
else
    log_err "Falha ao instalar Python!"
    exit 1
fi

# Atualiza pip
echo ""
echo "=== Atualizando pip ==="
python -m pip install --upgrade pip -q
log_ok "pip atualizado"

# Instala dependências
echo ""
echo "=== Instalando dependências Python ==="
pip install bleak aiohttp -q
if [ $? -eq 0 ]; then
    log_ok "bleak e aiohttp instalados"
else
    log_err "Falha ao instalar dependências!"
    exit 1
fi

# Cria pasta do projeto
echo ""
echo "=== Configurando projeto ==="
mkdir -p ~/telecuidar
cd ~/telecuidar

# Baixa o script principal
echo "Baixando tablet_gateway.py..."
SCRIPT_URL="https://raw.githubusercontent.com/amantino69/novocuidar/main/viver_mala_digital/tablet_gateway.py"

if command -v curl &> /dev/null; then
    curl -sO "$SCRIPT_URL" 2>/dev/null
elif command -v wget &> /dev/null; then
    wget -q "$SCRIPT_URL" 2>/dev/null
else
    log_warn "curl/wget não disponível - criando script localmente..."
fi

# Verifica se baixou
if [ -f ~/telecuidar/tablet_gateway.py ]; then
    log_ok "Script baixado em ~/telecuidar/tablet_gateway.py"
else
    log_warn "Não foi possível baixar - copie manualmente o tablet_gateway.py"
fi

# Cria script de inicialização
cat > ~/telecuidar/iniciar.sh << 'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/telecuidar
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           TELECUIDAR - MALETA TELEMEDICINA                   ║"
echo "║                                                              ║"
echo "║   Aguardando dispositivos BLE...                             ║"
echo "║   Pressione Ctrl+C para encerrar                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
python tablet_gateway.py "$@"
STARTEOF
chmod +x ~/telecuidar/iniciar.sh
log_ok "Script iniciar.sh criado"

# Configurações do bashrc
if ! grep -q "telecuidar" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# TeleCuidar - Maleta" >> ~/.bashrc
    echo 'alias maleta="cd ~/telecuidar && ./iniciar.sh"' >> ~/.bashrc
    echo 'alias maleta-test="cd ~/telecuidar && python tablet_gateway.py --test"' >> ~/.bashrc
    log_ok "Aliases configurados (maleta, maleta-test)"
fi

# Resumo final
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║               INSTALAÇÃO CONCLUÍDA!                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Próximos passos:"
echo ""
echo "  1. Teste a instalação:"
echo "     ${GREEN}python ~/telecuidar/tablet_gateway.py --test${NC}"
echo ""
echo "  2. Para iniciar a maleta:"
echo "     ${GREEN}maleta${NC}  ou  ${GREEN}./iniciar.sh${NC}"
echo ""
echo "  3. Verifique as permissões do Termux:"
echo "     - Bluetooth: ATIVADO"
echo "     - Localização: ATIVADO"
echo "     - Bateria: SEM RESTRIÇÕES"
echo ""
echo "Documentação completa: GUIA_TABLET_ANDROID.md"
echo ""
