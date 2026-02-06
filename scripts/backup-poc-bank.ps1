# Script: Fazer backup do banco POC seedado
# Uso: .\scripts\backup-poc-bank.ps1

$BackupDir = "$PSScriptRoot\..\backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupFile = "$BackupDir\telecuidar_poc_backup_$Timestamp.sql"

# Criar pasta se não existir
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Write-Host "💾 Fazendo backup do banco POC..." -ForegroundColor Cyan

$env:PGPASSWORD = "postgres"
docker compose -f docker-compose.dev.yml exec -T postgres pg_dump `
    -U postgres `
    -d telecuidar `
    --no-password `
    > $BackupFile

if ($LASTEXITCODE -eq 0) {
    $Size = (Get-Item $BackupFile).Length / 1MB
    Write-Host "✅ Backup criado com sucesso!" -ForegroundColor Green
    Write-Host "📁 Arquivo: $BackupFile" -ForegroundColor Green
    Write-Host "📊 Tamanho: $([Math]::Round($Size, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao fazer backup!" -ForegroundColor Red
}
