$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$checkpointBaseDir = "c:\telecuidar\.checkpoints"
$checkpointDir = "$checkpointBaseDir\checkpoint_$timestamp"

Write-Host "Creating checkpoint: $timestamp" -ForegroundColor Cyan

# Create directories
if (-not (Test-Path $checkpointBaseDir)) {
    New-Item -ItemType Directory -Path $checkpointBaseDir -Force | Out-Null
}
New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null

# Git commit
cd c:\telecuidar
Write-Host "Committing code..." -ForegroundColor Yellow
git add -A 2>&1 | Out-Null
git commit -m "CHECKPOINT $timestamp" 2>&1 | Out-Null
$gitHash = (git rev-parse --short HEAD 2>&1) -join ""
git tag "checkpoint-$timestamp" 2>&1 | Out-Null

# Database backup
Write-Host "Backing up database..." -ForegroundColor Yellow
docker exec telecuidar-postgres pg_dump -U postgres -d telecuidar --no-owner --no-acl 2>&1 | Out-File "$checkpointDir\banco.sql"

# Config files
Write-Host "Saving configs..." -ForegroundColor Yellow
Copy-Item "c:\telecuidar\.env" "$checkpointDir\.env" -Force -ErrorAction SilentlyContinue
Copy-Item "c:\telecuidar\.gitignore" "$checkpointDir\.gitignore" -Force -ErrorAction SilentlyContinue

# Docker status
Write-Host "Recording docker state..." -ForegroundColor Yellow
docker ps --all 2>&1 | Out-File "$checkpointDir\docker-ps.txt"
docker volume ls 2>&1 | Out-File "$checkpointDir\docker-volumes.txt"

# Summary
Write-Host "`nCheckpoint created: checkpoint_$timestamp" -ForegroundColor Green
Write-Host "To restore: .\checkpoint-restore.ps1 -CheckpointDate $timestamp" -ForegroundColor Cyan
