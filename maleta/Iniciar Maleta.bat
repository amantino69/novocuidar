@echo off
chcp 65001 > nul
title TeleCuidar - Maleta LOCAL
color 1F
cls

echo.
echo  =========================================================
echo.
echo       TELECUIDAR - MALETA (LOCAL)
echo.
echo      *** CONECTADO A: localhost:5239 ***
echo.
echo  =========================================================
echo.
echo   Este modo envia dados para o servidor LOCAL.
echo   Use apenas para homologacao/testes.
echo.
echo   * Balanca      - detecta peso automaticamente
echo   * Omron        - detecta pressao automaticamente  
echo   * Termometro   - detecta temperatura automaticamente
echo   * Estetoscopio - captura sob demanda (clique no botao)
echo.
echo  =========================================================
echo.

cd /d "%~dp0"
set PYTHONIOENCODING=utf-8

:: Inicia BLE (balanca, pressao, termometro) em janela separada - LOCAL
start "TeleCuidar BLE" cmd /k "cd /d C:\telecuidar\maleta && chcp 65001 > nul && color 2F && title Maleta BLE LOCAL && python maleta_itinerante.py --local"

:: Inicia Ausculta ON-DEMAND em janela separada - LOCAL
start "TeleCuidar Ausculta" cmd /k "cd /d C:\telecuidar\maleta && chcp 65001 > nul && color 3F && title Maleta Ausculta LOCAL && python ausculta_ondemand.py"

echo.
echo   Janelas BLE e Ausculta abertas em segundo plano.
echo   Esta janela pode ser fechada.
echo.
pause
