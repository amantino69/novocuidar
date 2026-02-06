# ============================================================
# ADICIONAR MALETA A INICIALIZACAO DO WINDOWS
# ============================================================
# Execute este script UMA VEZ como Administrador para fazer
# a maleta iniciar automaticamente com o Windows.
#
# COMO USAR:
# 1. Clique com botao direito neste arquivo
# 2. Selecione "Executar com PowerShell"
# 3. Se pedir permissao, clique "Sim"
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   TELECUIDAR - CONFIGURAR INICIALIZACAO AUTOMATICA" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Perguntar qual versao
Write-Host "Qual versao deseja iniciar automaticamente com o Windows?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] LOCAL      - Para desenvolvimento (localhost:5239)"
Write-Host "  [2] PRODUCAO   - Para uso em campo (telecuidar.com.br)"
Write-Host "  [3] CANCELAR"
Write-Host ""
$opcao = Read-Host "Digite 1, 2 ou 3"

if ($opcao -eq "3") {
    Write-Host "Operacao cancelada." -ForegroundColor Red
    exit
}

# Definir arquivo de origem
$sourcePath = "C:\telecuidar\maleta"
if ($opcao -eq "1") {
    $batFile = "INICIAR MALETA COMPLETA.bat"
    $shortcutName = "TeleCuidar Maleta LOCAL"
} else {
    $batFile = "INICIAR MALETA PRODUCAO.bat"
    $shortcutName = "TeleCuidar Maleta PRODUCAO"
}

$batPath = Join-Path $sourcePath $batFile

# Verificar se arquivo existe
if (-not (Test-Path $batPath)) {
    Write-Host "ERRO: Arquivo nao encontrado: $batPath" -ForegroundColor Red
    pause
    exit 1
}

# Caminho da pasta Startup
$startupPath = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupPath "$shortcutName.lnk"

# Criar atalho
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $batPath
$Shortcut.WorkingDirectory = $sourcePath
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,22"
$Shortcut.Description = "TeleCuidar - Maleta de Telemedicina"
$Shortcut.Save()

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   SUCESSO!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Atalho criado em: $shortcutPath" -ForegroundColor White
Write-Host ""
Write-Host "A maleta iniciara automaticamente quando voce ligar o computador." -ForegroundColor Yellow
Write-Host ""

# Perguntar se quer criar atalho na area de trabalho tambem
$desktop = Read-Host "Deseja criar atalho na Area de Trabalho tambem? (S/N)"
if ($desktop -eq "S" -or $desktop -eq "s") {
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $desktopShortcut = Join-Path $desktopPath "$shortcutName.lnk"
    
    $Shortcut2 = $WScriptShell.CreateShortcut($desktopShortcut)
    $Shortcut2.TargetPath = $batPath
    $Shortcut2.WorkingDirectory = $sourcePath
    $Shortcut2.IconLocation = "C:\Windows\System32\shell32.dll,22"
    $Shortcut2.Description = "TeleCuidar - Maleta de Telemedicina"
    $Shortcut2.Save()
    
    Write-Host "Atalho criado na Area de Trabalho!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Pressione qualquer tecla para fechar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
