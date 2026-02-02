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
echo   * Estetoscopio - detecta uso e captura sozinho!
echo.
echo   NAO PRECISA APERTAR NADA!
echo.
echo  =========================================================
echo.

cd /d "%~dp0"
set PYTHONIOENCODING=utf-8

:: Ativa o ambiente virtual
call ..\.venv\Scripts\activate.bat

:: Inicia BLE (balanca, pressao, termometro) em janela separada minimizada
start /min "TeleCuidar BLE" cmd /c "cd /d %~dp0.. && call .venv\Scripts\activate.bat && color 2F && python maleta\maleta_itinerante.py"

:loop
python maleta_automatica.py

echo.
echo Sistema reiniciando em 5 segundos...
timeout /t 5 /nobreak > nul
goto loop
echo Sistema encerrou. Reiniciando em 5 segundos...
timeout /t 5 /nobreak > nul
goto loop
