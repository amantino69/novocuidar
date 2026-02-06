@echo off
REM ========================================
REM TeleCuidar - Iniciar Homologação
REM ========================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   TELECUIDAR - HOMOLOGACAO
echo ========================================
echo.

REM Carregar arquivo .env.staging se existir
if exist ".env.staging" (
    echo Loading environment from .env.staging...
    for /f "tokens=1,2 delims==" %%a in (.env.staging) do (
        if not "%%a"=="" if not "%%a:~0,1%%" == "#" (
            set "%%a=%%b"
        )
    )
)

echo.
echo 1. Construindo imagens Docker...
docker-compose -f docker-compose.staging.yml build

echo.
echo 2. Iniciando containers...
docker-compose -f docker-compose.staging.yml up -d

echo.
echo 3. Aguardando PostgreSQL ficar pronto...
setlocal enabledelayedexpansion
for /L %%i in (1,1,30) do (
    docker-compose -f docker-compose.staging.yml exec -T postgres pg_isready -U postgres -d telecuidar > nul 2>&1
    if !errorlevel! equ 0 (
        echo PostgreSQL esta pronto!
        goto postgres_ready
    )
    echo   Tentativa %%i/30...
    timeout /t 2 /nobreak > nul
)
:postgres_ready

echo.
echo 4. Aguardando Backend ficar pronto...
for /L %%i in (1,1,60) do (
    docker-compose -f docker-compose.staging.yml exec -T backend curl -f http://localhost:5000/health > nul 2>&1
    if !errorlevel! equ 0 (
        echo Backend esta pronto!
        goto backend_ready
    )
    echo   Tentativa %%i/60...
    timeout /t 2 /nobreak > nul
)
:backend_ready

echo.
echo ========================================
echo  TELECUIDAR HOMOLOGACAO INICIADO!
echo ========================================
echo.
echo URLs:
echo   Frontend:  http://localhost:4000
echo   Backend:   http://localhost:5000
echo   Jitsi:     https://localhost:8443
echo   Swagger:   http://localhost:5000/swagger/index.html
echo.
echo Credenciais de Teste (senha: 123):
echo   Medico:      med_gt@telecuidar.com ^(Geraldo Tadeu - Cardiologia^)
echo   Psiquiatra:  med_aj@telecuidar.com ^(Antonio Jorge^)
echo   Assistente:  enf_do@telecuidar.com ^(Danila Ochoa^)
echo   Paciente:    pac_dc@telecuidar.com ^(Daniel Carrara^)
echo   Admin:       adm_ca@telecuidar.com ^(Claudio Amantino^)
echo.
echo Para ver logs:
echo   docker-compose -f docker-compose.staging.yml logs -f backend
echo   docker-compose -f docker-compose.staging.yml logs -f frontend
echo.
echo Para parar:
echo   docker-compose -f docker-compose.staging.yml down
echo.
pause
