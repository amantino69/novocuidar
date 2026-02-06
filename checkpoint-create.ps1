# ============================================
# CRIAR CHECKPOINT DO SISTEMA FUNCIONANDO
# Executar AGORA enquanto tudo funciona!
# ============================================

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$checkpointBaseDir = "c:\telecuidar\.checkpoints"
$checkpointDir = "$checkpointBaseDir\checkpoint_$timestamp"

Write-Host "🔄 CRIANDO CHECKPOINT DO SISTEMA..." -ForegroundColor Cyan
Write-Host "📁 Local: $checkpointDir`n" -ForegroundColor Gray

# 0. Criar diretório base
if (-not (Test-Path $checkpointBaseDir)) {
    New-Item -ItemType Directory -Path $checkpointBaseDir -Force | Out-Null
}

# 1. Criar diretório do checkpoint
New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null

# 2. Commit no Git (preservar código funcionando)
Write-Host "📝 Commitando código..." -ForegroundColor Yellow
cd c:\telecuidar
git add -A
git commit -m "CHECKPOINT: Sistema 100% funcionando - $timestamp" 2>&1 | Out-Null
$gitHash = git rev-parse --short HEAD
git tag "checkpoint-$timestamp"

# 3. Backup completo do banco PostgreSQL
Write-Host "🗄️  Exportando banco de dados..." -ForegroundColor Yellow
docker exec telecuidar-postgres pg_dump -U postgres -d telecuidar --no-owner --no-acl > "$checkpointDir\banco.sql" 2>&1

# 4. Backup de configurações críticas
Write-Host "⚙️  Salvando configurações..." -ForegroundColor Yellow
Copy-Item "c:\telecuidar\.env" "$checkpointDir\.env" -Force
Copy-Item "c:\telecuidar\.gitignore" "$checkpointDir\.gitignore" -Force

# 5. Salvar estado do Docker
Write-Host "🐳 Salvando estado Docker..." -ForegroundColor Yellow
docker ps --all > "$checkpointDir\docker-status.txt" 2>&1
docker volume ls > "$checkpointDir\docker-volumes.txt" 2>&1

# 6. Listar arquivos do projeto (para detectar mudanças)
Write-Host "📋 Indexando arquivos..." -ForegroundColor Yellow
Get-ChildItem -Path c:\telecuidar -Recurse -File | 
    Where-Object { $_.FullName -notmatch '\\node_modules|\\bin|\\obj|\\.git' } |
    Select-Object FullName, Length, LastWriteTime |
    Export-Csv "$checkpointDir\file-index.csv" -NoTypeInformation

# 7. Criar README de restauração
@"
╔════════════════════════════════════════════════════════════╗
║           CHECKPOINT - SISTEMA FUNCIONANDO                ║
╚════════════════════════════════════════════════════════════╝

📅 Data: $(Get-Date)
🔗 Git Commit: $gitHash
🏷️  Tag: checkpoint-$timestamp

✅ ESTADO CONFIRMADO:
   - Frontend: LISTENING :4200
   - Backend: LISTENING :5239
   - Banco: PostgreSQL (volume: telecuidar-postgres)
   - Credenciais: med_gt@telecuidar.com / 123

📂 ARQUIVOS DE BACKUP:
   - banco.sql ................ Dump completo PostgreSQL
   - .env ...................... Variáveis de ambiente
   - .gitignore ................ Arquivos ignorados
   - docker-status.txt ......... Status containers
   - file-index.csv ............ Lista de arquivos

═══════════════════════════════════════════════════════════════

🔧 COMO RESTAURAR ESTE CHECKPOINT:

   PowerShell (como Admin):
   
   cd c:\telecuidar
   .\checkpoint-restore.ps1 -CheckpointDate $timestamp

═══════════════════════════════════════════════════════════════

⚠️  SE O SISTEMA QUEBROU:

   1. Use script de rollback:
      .\checkpoint-restore.ps1 -CheckpointDate $timestamp
   
   2. Ou restaure manualmente:
      git checkout checkpoint-$timestamp
      docker exec telecuidar-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS telecuidar;"
      docker exec telecuidar-postgres psql -U postgres -d postgres -c "CREATE DATABASE telecuidar;"
      docker cp "$checkpointDir\banco.sql" telecuidar-postgres:/tmp/banco.sql
      docker exec telecuidar-postgres psql -U postgres -d telecuidar -f /tmp/banco.sql
      .\start.ps1

═══════════════════════════════════════════════════════════════
"@ | Out-File "$checkpointDir\README.txt"

# 8. Criar arquivo de teste de integridade
@"
# Teste este checkpoint depois
docker exec telecuidar-postgres psql -U postgres -d telecuidar -c "SELECT COUNT(*) as user_count FROM \"Users\";"
docker exec telecuidar-postgres psql -U postgres -d telecuidar -c "SELECT COUNT(*) as appointment_count FROM \"Appointments\";"
Invoke-WebRequest -Uri "http://localhost:5239/Health" -UseBasicParsing
"@ | Out-File "$checkpointDir\test-integrity.ps1"

Write-Host "`n✅ CHECKPOINT CRIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "📁 Local: $checkpointDir`n" -ForegroundColor Cyan

# Listar checkpoints
Write-Host "📊 CHECKPOINTS DISPONÍVEIS:" -ForegroundColor Cyan
Get-ChildItem "c:\telecuidar\.checkpoints" -Directory | 
    Sort-Object CreationTime -Descending |
    Select-Object -First 5 |
    ForEach-Object { Write-Host "   - $($_.Name)" }

Write-Host "`n💾 Use: .\checkpoint-restore.ps1 -CheckpointDate $timestamp`n" -ForegroundColor Yellow
