# ============================================================================
# DEPLOY TELECUIDAR - LOCALHOST -> VPS
# ============================================================================
# Este script faz deploy do que funciona no localhost para a VPS
# 
# NOVO: Usa scripts bash na VPS para evitar problemas de encoding Windows
#
# Uso: .\deploy-vps.ps1
# ============================================================================

param(
    [switch]$SkipLocalTest,
    [switch]$SkipBanco
)

$ErrorActionPreference = "Continue"
Set-Location "C:\telecuidar"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "  DEPLOY TELECUIDAR - LOCALHOST -> VPS" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PASSO 1: VERIFICAR LOCALHOST
# ============================================================================
if (-not $SkipLocalTest) {
    Write-Host "[1/5] Verificando localhost..." -ForegroundColor Yellow
    
    try {
        $loginBody = '{"email":"med_gt@telecuidar.com","password":"123"}'
        $loginResponse = Invoke-WebRequest -Uri "http://localhost:5239/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Write-Host "  OK - Backend localhost funcionando" -ForegroundColor Green
    }
    catch {
        Write-Host "  ERRO - Backend localhost NAO esta rodando!" -ForegroundColor Red
        Write-Host "  Execute primeiro: .\start.ps1" -ForegroundColor Yellow
        exit 1
    }
}

# ============================================================================
# PASSO 2: EXPORTAR BANCO LOCAL
# ============================================================================
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "C:\telecuidar\backups\deploy_backup.sql"

if (-not $SkipBanco) {
    Write-Host ""
    Write-Host "[2/5] Exportando banco local..." -ForegroundColor Yellow
    
    # Exportar com pg_dump
    docker exec telecuidar-postgres pg_dump -U postgres -d telecuidar --no-owner --no-acl --clean --if-exists > $backupFile 2>$null
    
    if (-not (Test-Path $backupFile) -or (Get-Item $backupFile).Length -lt 1000) {
        Write-Host "  ERRO - Falha ao exportar banco!" -ForegroundColor Red
        exit 1
    }
    
    $tamanhoKB = [math]::Round((Get-Item $backupFile).Length / 1024, 2)
    Write-Host "  OK - Banco exportado ($tamanhoKB KB)" -ForegroundColor Green
}

# ============================================================================
# PASSO 3: COMMIT E PUSH
# ============================================================================
Write-Host ""
Write-Host "[3/5] Verificando codigo..." -ForegroundColor Yellow

$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host "  Mudancas nao commitadas encontradas" -ForegroundColor Yellow
    git status --short
    $confirm = Read-Host "  Commitar? (s/N)"
    if ($confirm -eq "s" -or $confirm -eq "S") {
        git add -A
        $msg = Read-Host "  Mensagem"
        if (-not $msg) { $msg = "deploy $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
        git commit -m $msg
    }
    else {
        Write-Host "  Cancelado" -ForegroundColor Red
        exit 1
    }
}

git push origin main 2>$null
Write-Host "  OK - Codigo sincronizado" -ForegroundColor Green

# ============================================================================
# PASSO 4: COPIAR BACKUP PARA VPS
# ============================================================================
Write-Host ""
Write-Host "[4/5] Enviando backup para VPS..." -ForegroundColor Yellow
Write-Host "  (Digite a senha SSH quando solicitado)" -ForegroundColor Gray

scp $backupFile root@telecuidar.com.br:/opt/telecuidar/deploy_backup.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERRO - Falha ao copiar backup!" -ForegroundColor Red
    exit 1
}
Write-Host "  OK - Backup enviado" -ForegroundColor Green

# ============================================================================
# PASSO 5: EXECUTAR DEPLOY NA VPS (usando script bash)
# ============================================================================
Write-Host ""
Write-Host "[5/5] Executando deploy na VPS..." -ForegroundColor Yellow
Write-Host "  (Digite a senha SSH novamente)" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANTE: O script da VPS sera executado automaticamente." -ForegroundColor Cyan
Write-Host "  Aguarde a conclusao (pode demorar 3-5 minutos)..." -ForegroundColor Cyan
Write-Host ""

# Executa o script bash que esta na VPS (sem problemas de encoding)
ssh root@telecuidar.com.br "cd /opt/telecuidar && ./deploy.sh"

# ============================================================================
# RESULTADO
# ============================================================================
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "  DEPLOY ENVIADO!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "  Producao: https://www.telecuidar.com.br" -ForegroundColor Cyan
Write-Host "  Verificar: ssh root@telecuidar.com.br 'docker compose ps'" -ForegroundColor Gray
Write-Host "  Logs: ssh root@telecuidar.com.br 'docker logs telecuidar-backend -f'" -ForegroundColor Gray
Write-Host ""
