@echo off
chcp 65001 >nul
title TeleCuidar Maleta - REDE LOCAL
color 5F

echo.
echo  ╔═════════════════════════════════════════════════════════════╗
echo  ║   TELECUIDAR MALETA - REDE LOCAL                            ║
echo  ║   http://192.168.18.31:5239                                 ║
echo  ╚═════════════════════════════════════════════════════════════╝
echo.
echo   Esta maleta envia dados para o servidor na REDE LOCAL.
echo   Paciente acessa: http://192.168.18.31:4200
echo   Medico acessa:   http://localhost:4200 ou outro IP
echo.
echo   Equipamentos: Balanca, Omron (PA), Estetoscopio USB
echo.
echo   Pressione Ctrl+C para parar.
echo.

cd /d "%~dp0"

REM Verificar se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado! Instale o Python 3.10+
    pause
    exit /b 1
)

echo [1/2] Iniciando captura BLE (Balanca + Pressao) na REDE LOCAL...
start "Maleta BLE - REDE LOCAL" cmd /k "cd /d %~dp0 && color 5F && python maleta_itinerante.py --url http://192.168.18.31:5239"

echo [2/2] Iniciando captura Ausculta (Estetoscopio) na REDE LOCAL...
timeout /t 2 >nul
start "Maleta Ausculta - REDE LOCAL" cmd /k "cd /d %~dp0 && color 6F && python ausculta_ondemand.py --lan"

echo.
echo ╔═════════════════════════════════════════════════════════════╗
echo ║                    MALETA INICIADA!                          ║
echo ║                                                              ║
echo ║   Duas janelas foram abertas:                                ║
echo ║   - ROXO:   Balanca e Pressao (BLE)                          ║
echo ║   - AMARELO: Estetoscopio USB                                ║
echo ║                                                              ║
echo ║   Servidor: http://192.168.18.31:5239                        ║
echo ║   Mantenha ambas abertas durante as consultas.               ║
echo ╚═════════════════════════════════════════════════════════════╝
echo.
timeout /t 5
exit
