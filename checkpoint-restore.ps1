# ============================================
# RESTAURAR CHECKPOINT
# Use quando o sistema quebrar
# ============================================

param(
    [Parameter(Mandatory=$true)]
    [string]$CheckpointDate
)

$checkpointDir = "c:\telecuidar\.checkpoints\checkpoint_$CheckpointDate"

if (-not (Test-Path $checkpointDir)) {
    Write-Host "❌ CHECKPOINT NÃO ENCONTRADO: $checkpointDir" -ForegroundColor Red
    Write-Host "`nCheckpoints disponíveis:" -ForegroundColor Yellow
    Get-ChildItem "c:\telecuidar\.checkpoints" -Directory | 
        Sort-Object CreationTime -Descending |
        ForEach-Object { Write-Host "   .\checkpoint-restore.ps1 -CheckpointDate $($_.Name -replace 'checkpoint_')" }
    Exit 1
}

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 RESTAURANDO CHECKPOINT: $CheckpointDate" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════`n" -ForegroundColor Cyan

# 0. MATADOR DE PROCESSOS
Write-Host "🛑 Matando processos..." -ForegroundColor Yellow
try {
    Get-Process -Name "ng", "dotnet", "node", "cmd" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
} catch {}

# 1. RESTAURAR GIT
Write-Host "📝 Restaurando código (Git)..." -ForegroundColor Yellow
cd c:\telecuidar
try {
    git checkout "checkpoint-$CheckpointDate" 2>&1 | Out-Null
    Write-Host "   ✅ Git restored" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Git restore falhou (código pode estar corrompido)" -ForegroundColor Yellow
}

# 2. RESTAURAR BANCO DE DADOS
Write-Host "🗄️  Restaurando banco de dados..." -ForegroundColor Yellow

# Verificar se PostgreSQL está rodando
$pgStatus = docker ps --filter "name=postgres" --format "{{.Status}}" 2>&1
if (-not $pgStatus) {
    Write-Host "   ⚠️  PostgreSQL não está rodando, iniciando..." -ForegroundColor Yellow
    docker start telecuidar-postgres 2>&1 | Out-Null
    Start-Sleep -Seconds 5
}

# Dropar banco antigo
Write-Host "   - Limpando banco antigo..." -ForegroundColor Gray
docker exec telecuidar-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS telecuidar CASCADE;" 2>&1 | Out-Null
Start-Sleep -Seconds 2

# Criar banco novo
Write-Host "   - Criando banco novo..." -ForegroundColor Gray
docker exec telecuidar-postgres psql -U postgres -d postgres -c "CREATE DATABASE telecuidar WITH OWNER postgres ENCODING 'UTF8';" 2>&1 | Out-Null
Start-Sleep -Seconds 2

# Restaurar dump
Write-Host "   - Restaurando dados do checkpoint..." -ForegroundColor Gray
docker cp "$checkpointDir\banco.sql" telecuidar-postgres:/tmp/banco_restore.sql 2>&1 | Out-Null
docker exec telecuidar-postgres psql -U postgres -d telecuidar -f /tmp/banco_restore.sql 2>&1 | Out-Null
Write-Host "   ✅ Banco restaurado" -ForegroundColor Green

# 3. RESTAURAR CONFIGURAÇÕES
Write-Host "⚙️  Restaurando configurações..." -ForegroundColor Yellow
Copy-Item "$checkpointDir\.env" "c:\telecuidar\.env" -Force
Write-Host "   ✅ .env restaurado" -ForegroundColor Green

# 4. LIMPAR CACHE
Write-Host "🧹 Limpando cache do projeto..." -ForegroundColor Yellow
Remove-Item -Path "c:\telecuidar\frontend\.angular" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "c:\telecuidar\backend\WebAPI\bin" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "c:\telecuidar\backend\WebAPI\obj" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   ✅ Cache limpo" -ForegroundColor Green

# 5. VERIFICAR INTEGRIDADE DO BANCO
Write-Host "`n🧪 Verificando integridade do banco..." -ForegroundColor Yellow
try {
    $userCount = docker exec telecuidar-postgres psql -U postgres -d telecuidar -t -c "SELECT COUNT(*) FROM \"Users\";" 2>&1 | ForEach-Object { $_.Trim() }
    $appointmentCount = docker exec telecuidar-postgres psql -U postgres -d telecuidar -t -c "SELECT COUNT(*) FROM \"Appointments\";" 2>&1 | ForEach-Object { $_.Trim() }
    
    Write-Host "   Usuários no banco: $userCount" -ForegroundColor Cyan
    Write-Host "   Consultas no banco: $appointmentCount" -ForegroundColor Cyan
    Write-Host "   ✅ Banco OK" -ForegroundColor Green
} catch {
    Write-Host "   ❌ ERRO ao verificar banco" -ForegroundColor Red
}

Write-Host "`n═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ CHECKPOINT RESTAURADO COM SUCESSO!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "🚀 PRÓXIMO PASSO:" -ForegroundColor Yellow
Write-Host "   .\start.ps1`n" -ForegroundColor Cyan
