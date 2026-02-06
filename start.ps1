# ============================================
# TELECUIDAR - STARTUP ROBUSTO
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TELECUIDAR - INICIANDO SISTEMA" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. VERIFICAR/INICIAR DOCKER
Write-Host "[1/5] Verificando Docker..." -ForegroundColor Yellow
$dockerOk = $false
try {
    $null = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerOk = $true
        Write-Host "      Docker OK" -ForegroundColor Green
    }
} catch {}

if (-not $dockerOk) {
    Write-Host "      Iniciando Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
    Write-Host "      Aguardando Docker (60s)..." -ForegroundColor Gray
    
    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 5
        try {
            $null = docker ps 2>&1
            if ($LASTEXITCODE -eq 0) {
                $dockerOk = $true
                Write-Host "      Docker pronto!" -ForegroundColor Green
                break
            }
        } catch {}
        Write-Host "      Aguardando... $((($i+1)*5))s" -ForegroundColor Gray
    }
    
    if (-not $dockerOk) {
        Write-Host "      ERRO: Docker nao iniciou!" -ForegroundColor Red
        Exit 1
    }
}

# 2. INICIAR POSTGRESQL
Write-Host "[2/5] Iniciando PostgreSQL..." -ForegroundColor Yellow
$pgRunning = docker ps --filter "name=postgres" --format "{{.Names}}" 2>&1
if ($pgRunning) {
    Write-Host "      PostgreSQL ja esta rodando" -ForegroundColor Green
} else {
    # Tenta iniciar container existente
    docker start telecuidar-postgres-dev 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        docker start telecuidar-postgres 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "      Criando container PostgreSQL..." -ForegroundColor Gray
        docker run -d --name telecuidar-postgres-dev -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=telecuidar -p 5432:5432 postgres:16 2>&1 | Out-Null
    }
    
    Start-Sleep -Seconds 5
    Write-Host "      PostgreSQL iniciado" -ForegroundColor Green
}

# 3. LIMPAR PORTAS
Write-Host "[3/5] Limpando portas..." -ForegroundColor Yellow
$ports = @(4200, 5239)
foreach ($port in $ports) {
    $processList = netstat -ano 2>$null | Select-String ":$port" | ForEach-Object {
        ($_ -split '\s+')[-1]
    } | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique
    
    foreach ($processId in $processList) {
        try {
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}
Start-Sleep -Seconds 2
Write-Host "      Portas liberadas" -ForegroundColor Green

# 4. INICIAR FRONTEND
Write-Host "[4/5] Iniciando Frontend..." -ForegroundColor Yellow
Start-Process cmd.exe -ArgumentList "/c cd /d C:\telecuidar\frontend && ng serve --host 0.0.0.0 --port 4200" -WindowStyle Minimized

# 5. INICIAR BACKEND
Write-Host "[5/5] Iniciando Backend..." -ForegroundColor Yellow
Start-Process cmd.exe -ArgumentList "/c cd /d C:\telecuidar && dotnet run --project backend/WebAPI/WebAPI.csproj" -WindowStyle Minimized

# AGUARDAR
Write-Host ""
Write-Host "Aguardando compilacao (30s)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# VERIFICAR PORTAS
Write-Host ""
Write-Host "Verificando portas..." -ForegroundColor Yellow
$frontendOk = netstat -ano 2>$null | Select-String ":4200.*LISTENING"
$backendOk = netstat -ano 2>$null | Select-String ":5239.*LISTENING"

if ($frontendOk) {
    Write-Host "   Frontend (4200): OK" -ForegroundColor Green
} else {
    Write-Host "   Frontend (4200): ERRO - Verifique janela do Angular" -ForegroundColor Red
}

if ($backendOk) {
    Write-Host "   Backend (5239): OK" -ForegroundColor Green
} else {
    Write-Host "   Backend (5239): ERRO - Verifique janela do .NET" -ForegroundColor Red
}

# RESULTADO
Write-Host ""
if ($frontendOk -and $backendOk) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   SISTEMA PRONTO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Frontend: http://localhost:4200" -ForegroundColor Cyan
    Write-Host "   Backend:  http://localhost:5239" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Login: med_gt@telecuidar.com / 123" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   ERRO - Sistema nao iniciou corretamente" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Verifique as janelas minimizadas de Frontend e Backend" -ForegroundColor Yellow
    Write-Host ""
}
