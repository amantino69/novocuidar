@echo off
title TeleCuidar - Iniciando Sistema Completo
color 1F
setlocal enabledelayedexpansion

echo.
echo ============================================================
echo    TELECUIDAR - INICIANDO SISTEMA COMPLETO
echo ============================================================
echo.

cd /d C:\telecuidar

REM ============================================================
REM 1. VERIFICAR E INICIAR DOCKER
REM ============================================================
echo [1/7] Verificando Docker Desktop...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo        Docker nao esta rodando. Iniciando...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo        Aguardando Docker iniciar - 45 segundos...
    timeout /t 45 /nobreak >nul
    
    REM Verificar novamente
    docker ps >nul 2>&1
    if %errorlevel% neq 0 (
        echo        [ERRO] Docker ainda nao respondeu. Tente novamente.
        pause
        exit /b 1
    )
)
echo        Docker: OK

REM ============================================================
REM 2. INICIAR POSTGRESQL
REM ============================================================
echo [2/7] Iniciando PostgreSQL...
REM Tentar ambos os nomes de container
docker start telecuidar-postgres >nul 2>&1
docker start telecuidar-postgres-dev >nul 2>&1
timeout /t 3 /nobreak >nul

REM Verificar se algum container postgres esta rodando
docker ps --filter "name=postgres" --format "{{.Names}}" 2>nul | findstr /i "postgres" >nul
if %errorlevel%==0 (
    echo        PostgreSQL: OK
) else (
    echo        [AVISO] Container PostgreSQL nao encontrado!
    echo        Tentando criar container...
    docker run -d --name telecuidar-postgres -e POSTGRES_USER=telecuidar -e POSTGRES_PASSWORD=telecuidar123 -e POSTGRES_DB=telecuidar -p 5432:5432 postgres:16 >nul 2>&1
    timeout /t 5 /nobreak >nul
)

REM ============================================================
REM 3. LIMPAR PORTAS OCUPADAS
REM ============================================================
echo [3/7] Limpando portas ocupadas...

REM Matar processos na porta 4200 (Frontend)
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":4200 " ^| findstr "LISTENING"') do (
    if %%a NEQ 0 taskkill /PID %%a /F >nul 2>&1
)

REM Matar processos na porta 5239 (Backend)
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":5239 " ^| findstr "LISTENING"') do (
    if %%a NEQ 0 taskkill /PID %%a /F >nul 2>&1
)

REM Matar processos dotnet orfaos
taskkill /IM dotnet.exe /F >nul 2>&1

timeout /t 2 /nobreak >nul
echo        Portas limpas: OK

REM ============================================================
REM 4. INICIAR FRONTEND
REM ============================================================
echo [4/7] Iniciando Frontend (Angular)...
start "TeleCuidar - Frontend" cmd /k "cd /d C:\telecuidar\frontend && ng serve --host 0.0.0.0 --port 4200 && pause"

REM ============================================================
REM 5. INICIAR BACKEND
REM ============================================================
echo [5/7] Iniciando Backend (.NET)...
start "TeleCuidar - Backend" cmd /k "cd /d C:\telecuidar && dotnet run --project backend/WebAPI/WebAPI.csproj && pause"

REM ============================================================
REM 6. AGUARDAR COMPILACAO
REM ============================================================
echo [6/7] Aguardando compilacao (35 segundos)...
echo.
echo    Frontend: http://localhost:4200
echo    Backend:  http://localhost:5239
echo.
timeout /t 35 /nobreak >nul

REM ============================================================
REM 7. INICIAR MALETA DE DISPOSITIVOS (AUTO)
REM ============================================================
echo [7/7] Iniciando Maleta de Dispositivos Medicos...
echo.
echo    Dispositivos suportados:
echo      - Balanca OKOK (peso) via Bluetooth
echo      - Omron HEM-7156T (pressao) via Bluetooth
echo      - Estetoscopio Digital (ausculta) via P2
echo      - Termometro MOBI (em breve)
echo      - Oximetro (em breve)
echo.

REM Iniciar captura BLE (peso, pressao, temperatura) - modo local
echo    Iniciando captura BLE...
start "TeleCuidar - Maleta BLE" cmd /k "cd /d C:\telecuidar\maleta && python maleta_itinerante.py --local && pause"
timeout /t 2 /nobreak >nul

REM Iniciar captura de Ausculta (sob demanda)
echo    Iniciando captura de Ausculta (sob demanda)...
start "TeleCuidar - Ausculta" cmd /k "cd /d C:\telecuidar\maleta && python ausculta_ondemand.py && pause"
timeout /t 1 /nobreak >nul

echo    Maleta iniciada!

REM ============================================================
REM VERIFICACAO FINAL
REM ============================================================
echo.
echo ============================================================
echo    VERIFICANDO STATUS DO SISTEMA
echo ============================================================
echo.

REM Verificar Frontend
netstat -ano 2>nul | findstr ":4200 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo    [OK] Frontend 4200: RODANDO
) else (
    echo    [..] Frontend 4200: AINDA COMPILANDO
)

REM Verificar Backend
netstat -ano 2>nul | findstr ":5239 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo    [OK] Backend 5239: RODANDO
) else (
    echo    [..] Backend 5239: AINDA COMPILANDO
)

REM Verificar PostgreSQL
docker ps --filter "name=postgres" --format "{{.Names}}" 2>nul | findstr /i "postgres" >nul 2>&1
if %errorlevel%==0 (
    echo    [OK] PostgreSQL: RODANDO
) else (
    echo    [!!] PostgreSQL: PARADO
)

echo.
echo ============================================================
echo    SISTEMA PRONTO!
echo ============================================================
echo.
echo    Acesse: http://localhost:4200
echo.
echo    Credenciais de teste:
echo      Medico:    med_gt@telecuidar.com / 123
echo      Paciente:  pac_maria@telecuidar.com / 123
echo      Enfermeira: enf_do@telecuidar.com / 123
echo.
echo    IMPORTANTE - NAO FECHE AS JANELAS:
echo      - "TeleCuidar - Frontend" (Angular)
echo      - "TeleCuidar - Backend" (.NET)
echo      - "TeleCuidar - Maleta BLE" (peso/pressao/temperatura)
echo      - "TeleCuidar - Ausculta" (estetoscopio)
echo.
echo    Dispositivos prontos para captura:
echo      * Balanca - suba e aguarde estabilizar
echo      * Pressao - aperte START no Omron
echo      * Ausculta - clique "Capturar" na tela
echo.
echo    Para encerrar: feche TODAS as janelas acima
echo ============================================================
echo.

REM Abrir navegador
start "" http://localhost:4200

pause
