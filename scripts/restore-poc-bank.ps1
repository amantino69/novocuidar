# Script: Restaurar banco POC do backup
# Uso: .\scripts\restore-poc-bank.ps1 -BackupFile "backups/telecuidar_poc_backup_2026-02-02_10-30-00.sql"

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

if (!(Test-Path $BackupFile)) {
    Write-Host "❌ Arquivo de backup não encontrado: $BackupFile" -ForegroundColor Red
    exit 1
}

Write-Host "🔄 Parando backend..." -ForegroundColor Cyan
docker compose -f docker-compose.dev.yml stop backend 2>$null

Write-Host "⏳ Aguardando 5 segundos..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "🗑️  Deletando banco antigo..." -ForegroundColor Yellow
$env:PGPASSWORD = "postgres"
docker compose -f docker-compose.dev.yml exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS telecuidar;" 2>$null
docker compose -f docker-compose.dev.yml exec -T postgres psql -U postgres -c "CREATE DATABASE telecuidar;" 2>$null

Write-Host "📂 Restaurando backup..." -ForegroundColor Cyan
Get-Content $BackupFile | docker compose -f docker-compose.dev.yml exec -T postgres psql -U postgres -d telecuidar --no-password

Write-Host "✅ Banco restaurado com sucesso!" -ForegroundColor Green
Write-Host "🚀 Backend pronto para iniciar:" -ForegroundColor Green
Write-Host "   dotnet run --project backend/WebAPI/WebAPI.csproj" -ForegroundColor Cyan
