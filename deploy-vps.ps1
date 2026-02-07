# ============================================================================
# DEPLOY TELECUIDAR - LOCALHOST -> VPS
# ============================================================================
# Este script faz deploy do que funciona no localhost para a VPS
# 
# CORRECAO DEFINITIVA: Nunca usa redirecionamento PowerShell para evitar
# problemas de encoding (BOM/UTF-16)
#
# Uso: .\deploy-vps.ps1
# ============================================================================

param(
    [switch]$SkipLocalTest,
    [switch]$SkipBanco
)

$ErrorActionPreference = "Stop"
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
# PASSO 2: EXPORTAR BANCO LOCAL (SEM REDIRECIONAMENTO!)
# ============================================================================
$backupFile = "C:\telecuidar\backups\deploy_backup.sql"

if (-not $SkipBanco) {
    Write-Host ""
    Write-Host "[2/5] Exportando banco local..." -ForegroundColor Yellow
    
    # IMPORTANTE: Nunca usar ">" ou "|" do PowerShell - corrompe encoding!
    # Solucao: gravar DENTRO do container e depois copiar com docker cp
    
    # 1. Remove backup anterior do container
    docker exec telecuidar-postgres rm -f /tmp/backup.sql 2>$null
    
    # 2. Faz dump DENTRO do container (opcao -f grava direto no arquivo)
    $dumpResult = docker exec telecuidar-postgres pg_dump -U postgres -d telecuidar --no-owner --no-acl --clean --if-exists -f /tmp/backup.sql 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO - pg_dump falhou: $dumpResult" -ForegroundColor Red
        exit 1
    }
    
    # 3. Copia do container para o host (transferencia binaria, sem conversao)
    docker cp telecuidar-postgres:/tmp/backup.sql $backupFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO - docker cp falhou!" -ForegroundColor Red
        exit 1
    }
    
    # 4. Verifica se arquivo e valido
    if (-not (Test-Path $backupFile) -or (Get-Item $backupFile).Length -lt 1000) {
        Write-Host "  ERRO - Backup vazio ou muito pequeno!" -ForegroundColor Red
        exit 1
    }
    
    # 5. Verifica encoding (primeiros bytes devem ser "--" = 0x2D 0x2D)
    $bytes = [System.IO.File]::ReadAllBytes($backupFile)
    if ($bytes[0] -ne 0x2D -or $bytes[1] -ne 0x2D) {
        Write-Host "  ERRO - Encoding invalido! Primeiros bytes: $($bytes[0]) $($bytes[1])" -ForegroundColor Red
        Write-Host "  Esperado: 45 45 (--)" -ForegroundColor Yellow
        exit 1
    }
    
    $tamanhoKB = [math]::Round((Get-Item $backupFile).Length / 1024, 2)
    Write-Host "  OK - Banco exportado ($tamanhoKB KB) - Encoding verificado!" -ForegroundColor Green
}

# ============================================================================
# PASSO 3: COMMIT E PUSH
# ============================================================================
Write-Host ""
Write-Host "[3/5] Verificando codigo..." -ForegroundColor Yellow

$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host "  Mudancas nao commitadas encontradas:" -ForegroundColor Yellow
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

$ErrorActionPreference = "Continue"
git push origin main 2>$null
$ErrorActionPreference = "Stop"
Write-Host "  OK - Codigo sincronizado" -ForegroundColor Green

# ============================================================================
# PASSO 4: COPIAR BACKUP PARA VPS
# ============================================================================
Write-Host ""
Write-Host "[4/5] Enviando arquivos para VPS..." -ForegroundColor Yellow
Write-Host "  (Digite a senha SSH quando solicitado)" -ForegroundColor Gray

# Envia backup
$ErrorActionPreference = "Continue"
scp $backupFile root@telecuidar.com.br:/opt/telecuidar/deploy_backup.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERRO - Falha ao copiar backup!" -ForegroundColor Red
    exit 1
}

# Envia script de restore atualizado (garante que VPS tem versao correta)
scp "C:\telecuidar\scripts\restore-db-vps.sh" root@telecuidar.com.br:/opt/telecuidar/restore-db.sh
ssh root@telecuidar.com.br "chmod +x /opt/telecuidar/restore-db.sh"

Write-Host "  OK - Backup e scripts enviados" -ForegroundColor Green

# ============================================================================
# PASSO 5: EXECUTAR DEPLOY NA VPS
# ============================================================================
Write-Host ""
Write-Host "[5/6] Executando deploy na VPS..." -ForegroundColor Yellow
Write-Host "  (Digite a senha SSH mais uma vez)" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANTE: Aguarde a conclusao (pode demorar 5-10 minutos)..." -ForegroundColor Cyan
Write-Host ""

# Envia script de deploy e executa (uma única conexão SSH)
scp "C:\telecuidar\scripts\deploy-remote.sh" root@telecuidar.com.br:/opt/telecuidar/deploy-remote.sh
ssh root@telecuidar.com.br "chmod +x /opt/telecuidar/deploy-remote.sh && /opt/telecuidar/deploy-remote.sh"

# ============================================================================
# RESULTADO
# ============================================================================
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "  DEPLOY CONCLUIDO!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "  Producao: https://www.telecuidar.com.br" -ForegroundColor Cyan
Write-Host "  Verificar: ssh root@telecuidar.com.br 'docker compose ps'" -ForegroundColor Gray
Write-Host "  Logs: ssh root@telecuidar.com.br 'docker logs telecuidar-backend -f'" -ForegroundColor Gray
Write-Host ""
