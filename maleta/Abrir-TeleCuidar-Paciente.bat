@echo off
title TeleCuidar - Navegador Paciente
color 2F

echo.
echo  ========================================================
echo    TELECUIDAR - ACESSO DO PACIENTE (REDE LOCAL)
echo  ========================================================
echo.
echo   Abrindo navegador com permissoes de camera/microfone...
echo.

REM Fecha Chrome existente para evitar conflito
taskkill /f /im chrome.exe >nul 2>&1
timeout /t 2 >nul

REM Abre Chrome com flag para permitir camera/mic em HTTP
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" ^
    --unsafely-treat-insecure-origin-as-secure="http://192.168.18.31:4200" ^
    --user-data-dir="%TEMP%\TeleCuidarChrome" ^
    --no-first-run ^
    --disable-default-apps ^
    "http://192.168.18.31:4200"

echo.
echo   Chrome aberto! Aguarde carregar o TeleCuidar...
echo.
timeout /t 3
exit
