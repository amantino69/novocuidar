@echo off
REM Script batch para iniciar o TeleCuidar em desenvolvimento
REM Duplo clique para rodar!

cls
title TeleCuidar - Inicializacao Local

echo ====================================
echo  TeleCuidar - Inicializacao Local
echo ====================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "C:\telecuidar\start-local.ps1"

pause
