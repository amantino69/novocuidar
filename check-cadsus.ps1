# Script para verificar status do CADSUS
# Pode ser executado a qualquer momento para garantir que o serviço está funcionando

Write-Host "=== Verificando CADSUS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar health
Write-Host "1. Verificando configuracao..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "https://www.telecuidar.com.br/api/cns/health" -Method Get -ErrorAction Stop
    if ($health.status -eq "configured") {
        Write-Host "   [OK] Servico configurado" -ForegroundColor Green
    } else {
        Write-Host "   [ERRO] Servico NAO configurado!" -ForegroundColor Red
        Write-Host "   Mensagem: $($health.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   [ERRO] Falha ao conectar: $_" -ForegroundColor Red
    exit 1
}

# 2. Verificar token
Write-Host ""
Write-Host "2. Verificando token..." -ForegroundColor Yellow
try {
    $token = Invoke-RestMethod -Uri "https://www.telecuidar.com.br/api/cns/token/status" -Method Get -ErrorAction Stop
    if ($token.hasToken -and $token.isValid) {
        Write-Host "   [OK] Token valido" -ForegroundColor Green
        Write-Host "   Expira em: $($token.expiresAt)" -ForegroundColor Cyan
        Write-Host "   Tempo restante: $($token.expiresIn) minutos" -ForegroundColor Cyan
        
        # Alertar se expirar em menos de 7 dias
        if ($token.expiresIn -lt 10080) {
            Write-Host "   [ALERTA] Token expira em menos de 7 dias!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   [AVISO] Token nao existe ou expirado - renovando..." -ForegroundColor Yellow
        $renew = Invoke-RestMethod -Uri "https://www.telecuidar.com.br/api/cns/token/renew" -Method Post -ErrorAction Stop
        if ($renew.success) {
            Write-Host "   [OK] Token renovado com sucesso!" -ForegroundColor Green
            Write-Host "   Nova expiracao: $($renew.expiresAt)" -ForegroundColor Cyan
        } else {
            Write-Host "   [ERRO] Falha ao renovar token: $($renew.message)" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "   [ERRO] Falha ao verificar token: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== CADSUS OK ===" -ForegroundColor Green
Write-Host ""
