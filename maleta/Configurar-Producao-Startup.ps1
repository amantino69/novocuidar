# ============================================================
# TELECUIDAR - Configurar Inicialização Automática PRODUÇÃO
# ============================================================
# Execute este script NO COMPUTADOR DA MALETA para fazer
# a maleta iniciar automaticamente conectada à PRODUÇÃO.
#
# COMO USAR:
# 1. Clique com botão direito neste arquivo
# 2. Selecione "Executar com PowerShell"
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   TELECUIDAR - CONFIGURAR INICIALIZAÇÃO PRODUÇÃO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Caminhos
$MaletaPath = "C:\telecuidar\maleta"
$TargetBat = Join-Path $MaletaPath "Iniciar Maleta PRODUCAO.bat"
$StartupPath = [Environment]::GetFolderPath('Startup')
$ShortcutPath = Join-Path $StartupPath "TeleCuidar Maleta PRODUCAO.lnk"

# Verificar se o arquivo .bat existe
if (-not (Test-Path $TargetBat)) {
    Write-Host "ERRO: Arquivo não encontrado!" -ForegroundColor Red
    Write-Host "   $TargetBat" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Verifique se a pasta C:\telecuidar\maleta está correta." -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Remover atalhos antigos da maleta na Startup
Write-Host "Removendo atalhos antigos..." -ForegroundColor Gray
Get-ChildItem $StartupPath -Filter "TeleCuidar*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem $StartupPath -Filter "*Maleta*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Criar novo atalho
Write-Host "Criando atalho na pasta Startup..." -ForegroundColor Gray
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $TargetBat
$Shortcut.WorkingDirectory = $MaletaPath
$Shortcut.Description = "TeleCuidar Maleta - Producao (telecuidar.com.br)"
$Shortcut.WindowStyle = 1
$Shortcut.Save()

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   SUCESSO!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Atalho criado em:" -ForegroundColor White
Write-Host "   $ShortcutPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Destino:" -ForegroundColor White
Write-Host "   $TargetBat" -ForegroundColor Cyan
Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Quando o Windows iniciar, a maleta vai:" -ForegroundColor Yellow
Write-Host "   1. Abrir janela BLE (balança, Omron, termômetro)" -ForegroundColor White
Write-Host "   2. Abrir janela Ausculta (estetoscópio USB)" -ForegroundColor White
Write-Host "   3. Conectar automaticamente a telecuidar.com.br" -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Read-Host "Pressione Enter para sair"
