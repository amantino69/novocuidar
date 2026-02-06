#!/usr/bin/env pwsh
<#
.SYNOPSIS
Script para iniciar o TeleCuidar em desenvolvimento local (localhost:4200)
.DESCRIPTION
- Mata processos nas portas 4200, 5239, 8443
- Inicia PostgreSQL local (Docker)
- Limpa temporários e cache
- Inicia Frontend HTTPS e Backend
#>

Write-Host "TeleCuidar - Inicializacao Local" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Cores para output
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarnColor = "Yellow"
$InfoColor = "Cyan"

# Função para matar processo em porta
function Kill-Port($port) {
    try {
        $pid = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue -OwningProcess | Select-Object -First 1 -ExpandProperty OwningProcess)
        if ($pid) {
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Liberada porta $port (PID $pid)" -ForegroundColor $SuccessColor
            return $true
        }
    } catch {
        # Silenciosamente ignorar se não houver processo
    }
    return $false
}

# ============================================
# PASSO 1: LIBERAR PORTAS
# ============================================
Write-Host "Passo 1: Liberando portas..." -ForegroundColor $InfoColor
Write-Host ""

Kill-Port 4200 | Out-Null
Kill-Port 5239 | Out-Null
Kill-Port 8443 | Out-Null
Kill-Port 3000 | Out-Null

Write-Host ""
Write-Host "Portas liberadas!" -ForegroundColor $SuccessColor
Write-Host ""

# ============================================
# PASSO 2: INICIAR POSTGRESQL (DOCKER)
# ============================================
Write-Host "Passo 2: Iniciando PostgreSQL local..." -ForegroundColor $InfoColor

try {
    Push-Location "C:\telecuidar"
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        docker compose -f docker-compose.dev.yml up -d postgres | Out-Null
        Write-Host "PostgreSQL iniciado (Docker)" -ForegroundColor $SuccessColor
    } else {
        Write-Host "Docker nao esta rodando. Abra o Docker Desktop e tente novamente." -ForegroundColor $ErrorColor
        Pop-Location
        exit 1
    }
    Pop-Location
} catch {
    Write-Host "Falha ao iniciar PostgreSQL via Docker. Verifique o Docker Desktop." -ForegroundColor $ErrorColor
    exit 1
}

Write-Host ""

# ============================================
# PASSO 3: LIMPAR CACHE (OPCIONAL)
# ============================================
Write-Host "Passo 3: Limpando cache..." -ForegroundColor $InfoColor

# Remover node_modules cache do Angular
if (Test-Path "C:\telecuidar\frontend\.angular") {
    Remove-Item -Path "C:\telecuidar\frontend\.angular" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cache do Angular limpo" -ForegroundColor $SuccessColor
}

Write-Host ""

# ============================================
# PASSO 4: ATUALIZAR ENVIRONMENT
# ============================================
Write-Host "Passo 4: Regenerando arquivos de environment..." -ForegroundColor $InfoColor

try {
    Push-Location "C:\telecuidar\frontend"
    & node scripts\generate-env.js
    Pop-Location
    Write-Host "Environment regenerado" -ForegroundColor $SuccessColor
} catch {
    Write-Host "Erro ao gerar environment, continuando..." -ForegroundColor $WarnColor
}

Write-Host ""

# ============================================
# PASSO 5: BUILD VERIFICAÇÃO
# ============================================
Write-Host "Passo 5: Verificando build do Backend..." -ForegroundColor $InfoColor

try {
    Push-Location "C:\telecuidar"
    dotnet build backend/WebAPI/WebAPI.csproj
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Backend build OK" -ForegroundColor $SuccessColor
    } else {
        Write-Host "Erro no build do backend!" -ForegroundColor $ErrorColor
        Pop-Location
        exit 1
    }
    Pop-Location
} catch {
    Write-Host "Erro ao fazer build: $_" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host ""

# ============================================
# PASSO 6: INICIAR SERVIÇOS
# ============================================
Write-Host "Passo 6: Iniciando Frontend e Backend..." -ForegroundColor $InfoColor
Write-Host ""

# Iniciar Frontend HTTPS
Write-Host "Iniciando Frontend HTTPS na porta 4200..." -ForegroundColor $InfoColor
$shellExe = "powershell.exe"
$frontendProcess = Start-Process $shellExe -ArgumentList @(
    '-NoExit',
    '-Command',
    'cd C:\telecuidar\frontend; ng serve --host 0.0.0.0 --port 4200 --ssl --disable-host-check'
) -PassThru -NoNewWindow
if ($frontendProcess) {
    Write-Host "   PID: $($frontendProcess.Id)" -ForegroundColor $InfoColor
} else {
    Write-Host "   Falha ao iniciar o Frontend" -ForegroundColor $ErrorColor
}

Start-Sleep -Seconds 3

# Iniciar Backend
Write-Host "Iniciando Backend na porta 5239..." -ForegroundColor $InfoColor
$backendProcess = Start-Process $shellExe -ArgumentList @(
    '-NoExit',
    '-Command',
    'cd C:\telecuidar; dotnet run --project backend/WebAPI/WebAPI.csproj --launch-profile https'
) -PassThru -NoNewWindow
if ($backendProcess) {
    Write-Host "   PID: $($backendProcess.Id)" -ForegroundColor $InfoColor
} else {
    Write-Host "   Falha ao iniciar o Backend" -ForegroundColor $ErrorColor
}

Start-Sleep -Seconds 5

# ============================================
# PASSO 7: VERIFICAÇÃO
# ============================================
Write-Host ""
Write-Host "Passo 7: Verificando Status..." -ForegroundColor $InfoColor
Write-Host ""

if ($frontendProcess -and -not $frontendProcess.HasExited) {
    Write-Host "Frontend rodando (PID: $($frontendProcess.Id))" -ForegroundColor $SuccessColor
} else {
    Write-Host "Frontend nao iniciou corretamente" -ForegroundColor $ErrorColor
}

if ($backendProcess -and -not $backendProcess.HasExited) {
    Write-Host "Backend rodando (PID: $($backendProcess.Id))" -ForegroundColor $SuccessColor
} else {
    Write-Host "Backend nao iniciou corretamente" -ForegroundColor $ErrorColor
}

Write-Host ""
Write-Host "=================================" -ForegroundColor $InfoColor
Write-Host "Sistema iniciado com sucesso!" -ForegroundColor $SuccessColor
Write-Host "=================================" -ForegroundColor $InfoColor
Write-Host ""
Write-Host "Acesse em: https://localhost:4200/" -ForegroundColor $InfoColor
Write-Host ""
Write-Host "Credenciais de teste:" -ForegroundColor $InfoColor
Write-Host "  - Email: med_gt@telecuidar.com" -ForegroundColor $InfoColor
Write-Host "  - Senha: 123" -ForegroundColor $InfoColor
Write-Host ""
Write-Host "Para parar: Ctrl+C ou feche este terminal" -ForegroundColor $WarnColor
Write-Host ""
Write-Host "Se houver erro, verifique os logs nas janelas do Frontend e Backend" -ForegroundColor $InfoColor
Write-Host "   Frontend vai abrir em: https://localhost:4200 (aceitar certificado)" -ForegroundColor $InfoColor
Write-Host ""

# Manter script aberto
Write-Host "Pressione Ctrl+C para parar todos os servicos..." -ForegroundColor $WarnColor
try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        # Verificar se processos ainda estão rodando
        if ($frontendProcess -and $frontendProcess.HasExited) {
            Write-Host "Frontend foi encerrado" -ForegroundColor $WarnColor
        }
        if ($backendProcess -and $backendProcess.HasExited) {
            Write-Host "Backend foi encerrado" -ForegroundColor $WarnColor
        }
    }
} finally {
    # Limpar processos ao sair
    Write-Host ""
    Write-Host "Encerrando serviços..." -ForegroundColor $WarnColor
    if ($frontendProcess) {
        Stop-Process -Id $frontendProcess.Id -ErrorAction SilentlyContinue
    }
    if ($backendProcess) {
        Stop-Process -Id $backendProcess.Id -ErrorAction SilentlyContinue
    }
    Write-Host "Servicos encerrados" -ForegroundColor $SuccessColor
}
