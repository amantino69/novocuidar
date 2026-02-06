@echo off
chcp 65001 > nul
title TeleCuidar - Maleta Automatica
color 1F
cls

echo.
echo  =========================================================
echo.
echo       TELECUIDAR - MALETA AUTOMATICA
echo.
echo  =========================================================
echo.
echo   TOTALMENTE AUTOMATICO! A enfermeira so precisa:
echo.
echo   1. Deixar esta janela aberta
echo   2. Usar o TeleCuidar no navegador
echo   3. Usar os equipamentos normalmente
echo.
echo   * Balanca      - detecta peso automaticamente
echo   * Omron        - detecta pressao automaticamente  
echo   * Termometro   - detecta temperatura automaticamente
echo   * Estetoscopio - captura sob demanda (clique no botao)
echo.
echo   NAO PRECISA APERTAR NADA!
echo.
echo  =========================================================
echo.

cd /d "%~dp0"
set PYTHONIOENCODING=utf-8

:: Inicia BLE (balanca, pressao, termometro) em janela separada
start "TeleCuidar BLE" cmd /k "cd /d C:\telecuidar\maleta && chcp 65001 > nul && color 2F && title Maleta BLE && python maleta_itinerante.py"

:: Inicia Ausculta ON-DEMAND em janela separada (nao gera arquivos ate ser solicitado)
start "TeleCuidar Ausculta" cmd /k "cd /d C:\telecuidar\maleta && chcp 65001 > nul && color 3F && title Maleta Ausculta && python ausculta_ondemand.py"

echo.
echo   Janelas BLE e Ausculta abertas em segundo plano.
echo   Esta janela pode ser fechada.
echo.
pause
