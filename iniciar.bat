@echo off
title TeleCuidar - Iniciando Sistema
color 1F

echo.
echo ============================================================
echo    TELECUIDAR - INICIANDO SISTEMA
echo ============================================================
echo.

cd /d C:\telecuidar

echo [1/5] Verificando Docker Desktop...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo        Docker nao esta rodando. Iniciando...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo        Aguardando Docker iniciar - 60 segundos...
    timeout /t 60 /nobreak >nul
)

echo [2/5] Iniciando PostgreSQL...
docker start telecuidar-postgres-dev >nul 2>&1
timeout /t 5 /nobreak >nul

echo [3/5] Limpando portas ocupadas...
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":4200"') do taskkill /PID %%a /F >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":5239"') do taskkill /PID %%a /F >nul 2>&1
timeout /t 2 /nobreak >nul

echo [4/5] Iniciando Frontend...
start "Frontend" cmd /c "cd /d C:\telecuidar\frontend && ng serve --host 0.0.0.0 --port 4200"

echo [5/5] Iniciando Backend...
start "Backend" cmd /c "cd /d C:\telecuidar && dotnet run --project backend/WebAPI/WebAPI.csproj"

echo.
echo ============================================================
echo    SISTEMA INICIANDO...
echo ============================================================
echo.
echo    Frontend: http://localhost:4200
echo    Backend:  http://localhost:5239
echo.
echo    Aguarde 30 segundos para compilacao completa.
echo.
echo    Credenciais: med_gt@telecuidar.com / 123
echo ============================================================
echo.

timeout /t 30 /nobreak >nul

echo.
echo Verificando portas...
netstat -ano | findstr ":4200" >nul 2>&1
if %errorlevel%==0 (
    echo    Frontend 4200: OK
) else (
    echo    Frontend 4200: AGUARDANDO
)

netstat -ano | findstr ":5239" >nul 2>&1
if %errorlevel%==0 (
    echo    Backend 5239: OK
) else (
    echo    Backend 5239: AGUARDANDO
)

echo.
echo Pronto! Acesse http://localhost:4200
echo.
pause
