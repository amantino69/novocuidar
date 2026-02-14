@echo off
chcp 65001 >nul
title TeleCuidar - Maleta Completa
color 1F

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║           TELECUIDAR - MALETA DE TELEMEDICINA                ║
echo ║                                                              ║
echo ║   Iniciando todos os scripts de captura automaticamente...  ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0"

REM Verificar se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado! Instale o Python 3.10+
    pause
    exit /b 1
)

echo [1/2] Iniciando captura BLE (Balanca + Pressao)...
start "Maleta BLE - Balanca e Pressao" cmd /k "cd /d %~dp0 && color 1F && python maleta_itinerante.py --local"

echo [2/2] Iniciando captura Ausculta (Estetoscopio USB)...
timeout /t 2 >nul
start "Maleta Ausculta - Estetoscopio" cmd /k "cd /d %~dp0 && color 3F && python ausculta_ondemand.py"

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    MALETA INICIADA!                          ║
echo ║                                                              ║
echo ║   Duas janelas foram abertas:                                ║
echo ║   - AZUL ESCURO: Balanca e Pressao (BLE)                     ║
echo ║   - AZUL CLARO:  Estetoscopio USB                            ║
echo ║                                                              ║
echo ║   Mantenha ambas abertas durante as consultas.               ║
echo ║   Esta janela pode ser fechada.                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
timeout /t 5
exit
