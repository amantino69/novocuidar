# Script: Reset para banco LIMPO (apenas migrations, sem dados POC)
# Uso: .\scripts\reset-clean-bank.ps1

Write-Host "🔄 Resetando para banco LIMPO..." -ForegroundColor Yellow

Write-Host "⏸️  Parando backend..." -ForegroundColor Cyan
docker compose -f docker-compose.dev.yml stop backend 2>$null
Start-Sleep -Seconds 3

Write-Host "🗑️  Deletando banco..." -ForegroundColor Cyan
$env:PGPASSWORD = "postgres"
docker compose -f docker-compose.dev.yml exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS telecuidar;" 2>$null

Write-Host "🔨 Recriando banco..." -ForegroundColor Cyan
docker compose -f docker-compose.dev.yml exec -T postgres psql -U postgres -c "CREATE DATABASE telecuidar;" 2>$null

Write-Host "✅ Banco limpo criado!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Próxima vez que iniciar o backend, ele executará migrations automaticamente" -ForegroundColor Cyan
Write-Host "   dotnet run --project backend/WebAPI/WebAPI.csproj" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Se precisar dos dados POC após:" -ForegroundColor Yellow
Write-Host "   .\scripts\restore-poc-bank.ps1 -BackupFile ""backups/telecuidar_poc_backup_LATEST.sql""" -ForegroundColor Cyan
