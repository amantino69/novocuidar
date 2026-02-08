# ============================================================================
# TeleCuidar Maleta - Configurar Inicialização Automática
# ============================================================================
# Este script cria um atalho na pasta Startup do Windows para iniciar
# automaticamente a maleta quando o computador ligar.
# ============================================================================

param(
    [Parameter()]
    [ValidateSet("producao", "homologacao", "menu", "remover")]
    [string]$Ambiente = "menu"
)

$ErrorActionPreference = "Stop"
$MaletaPath = Split-Path -Parent $PSScriptRoot
if (-not $MaletaPath) { $MaletaPath = "C:\telecuidar\maleta" }

# Determinar pasta de Startup do usuário
$StartupFolder = [Environment]::GetFolderPath('Startup')
$ShortcutName = "TeleCuidar Maleta.lnk"
$ShortcutPath = Join-Path $StartupFolder $ShortcutName

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   TELECUIDAR MALETA - Configurar Inicialização Automática ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Selecione uma opção:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Iniciar com Windows → PRODUÇÃO (telecuidar.com.br)" -ForegroundColor Green
    Write-Host "  [2] Iniciar com Windows → HOMOLOGAÇÃO (192.168.18.31)" -ForegroundColor Yellow
    Write-Host "  [3] Iniciar com Windows → MENU (escolher na hora)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [R] REMOVER inicialização automática" -ForegroundColor Red
    Write-Host "  [Q] Sair sem alterar" -ForegroundColor Gray
    Write-Host ""
    
    $escolha = Read-Host "  Escolha (1/2/3/R/Q)"
    
    switch ($escolha.ToUpper()) {
        "1" { return "producao" }
        "2" { return "homologacao" }
        "3" { return "menu" }
        "R" { return "remover" }
        "Q" { return "sair" }
        default { return "menu" }
    }
}

function Create-Shortcut {
    param(
        [string]$TargetBat,
        [string]$Description
    )
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetBat
    $Shortcut.WorkingDirectory = $MaletaPath
    $Shortcut.Description = $Description
    $Shortcut.WindowStyle = 1  # Normal window
    $Shortcut.Save()
    
    Write-Host ""
    Write-Host "  ✅ Atalho criado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Localização: $ShortcutPath" -ForegroundColor Gray
    Write-Host "  Destino: $TargetBat" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Na próxima vez que o Windows iniciar, a maleta" -ForegroundColor Cyan
    Write-Host "  será ativada automaticamente." -ForegroundColor Cyan
    Write-Host ""
}

function Remove-Shortcut {
    if (Test-Path $ShortcutPath) {
        Remove-Item $ShortcutPath -Force
        Write-Host ""
        Write-Host "  ✅ Inicialização automática REMOVIDA" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "  ℹ️  Não havia inicialização automática configurada" -ForegroundColor Gray
        Write-Host ""
    }
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================

# Se não passou parâmetro, mostrar menu
if ($Ambiente -eq "menu" -and $args.Count -eq 0) {
    $Ambiente = Show-Menu
}

switch ($Ambiente) {
    "producao" {
        $TargetBat = Join-Path $MaletaPath "Maleta-PRODUCAO.bat"
        if (-not (Test-Path $TargetBat)) {
            Write-Host "  ❌ Arquivo não encontrado: $TargetBat" -ForegroundColor Red
            exit 1
        }
        Create-Shortcut -TargetBat $TargetBat -Description "TeleCuidar Maleta - Produção"
    }
    "homologacao" {
        $TargetBat = Join-Path $MaletaPath "Maleta-HOMOLOGACAO.bat"
        if (-not (Test-Path $TargetBat)) {
            Write-Host "  ❌ Arquivo não encontrado: $TargetBat" -ForegroundColor Red
            exit 1
        }
        Create-Shortcut -TargetBat $TargetBat -Description "TeleCuidar Maleta - Homologação"
    }
    "menu" {
        $TargetBat = Join-Path $MaletaPath "IniciarMaletaTeleCuidar.bat"
        if (-not (Test-Path $TargetBat)) {
            Write-Host "  ❌ Arquivo não encontrado: $TargetBat" -ForegroundColor Red
            exit 1
        }
        Create-Shortcut -TargetBat $TargetBat -Description "TeleCuidar Maleta - Menu"
    }
    "remover" {
        Remove-Shortcut
    }
    "sair" {
        Write-Host ""
        Write-Host "  Nenhuma alteração feita." -ForegroundColor Gray
        Write-Host ""
        exit 0
    }
}

# Verificar status atual
Write-Host "  ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
if (Test-Path $ShortcutPath) {
    $existingShortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($ShortcutPath)
    Write-Host "  📋 STATUS ATUAL:" -ForegroundColor Cyan
    Write-Host "     Inicialização automática: ATIVADA" -ForegroundColor Green
    Write-Host "     Script: $($existingShortcut.TargetPath)" -ForegroundColor Gray
} else {
    Write-Host "  📋 STATUS ATUAL:" -ForegroundColor Cyan
    Write-Host "     Inicialização automática: DESATIVADA" -ForegroundColor Yellow
}
Write-Host ""

Read-Host "  Pressione Enter para sair"
