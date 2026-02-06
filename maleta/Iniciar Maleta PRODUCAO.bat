@echo off
chcp 65001 > nul
title TeleCuidar - Maleta PRODUCAO
color 4F
cls

echo.
echo  =========================================================
echo.
echo       TELECUIDAR - MALETA (PRODUCAO)
echo.
echo      *** CONECTADO A: telecuidar.com.br ***
echo.
echo  =========================================================
echo.
echo   Este modo envia dados para o servidor de producao.
echo   Use apenas quando a maleta estiver em campo real.
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

:: Inicia BLE (balanca, pressao, termometro) em janela separada - PRODUCAO
start "TeleCuidar BLE PROD" cmd /k "cd /d C:\telecuidar\maleta && chcp 65001 > nul && color 2F && title Maleta BLE PROD && python maleta_itinerante.py"

:: Inicia Ausculta ON-DEMAND em janela separada - PRODUCAO
start "TeleCuidar Ausculta PROD" cmd /k "cd /d C:\telecuidar\maleta && chcp 65001 > nul && color 3F && title Maleta Ausculta PROD && python ausculta_ondemand.py --prod"

echo.
echo   Janelas BLE e Ausculta abertas em segundo plano.
echo   ** MODO PRODUCAO - telecuidar.com.br **
echo.
pause
