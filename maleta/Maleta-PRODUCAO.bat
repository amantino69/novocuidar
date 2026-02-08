@echo off
chcp 65001 >nul
title TeleCuidar Maleta - PRODUÇÃO
color 2F

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║   TELECUIDAR MALETA - PRODUÇÃO                            ║
echo  ║   https://www.telecuidar.com.br                           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Capturando sinais vitais via Bluetooth...
echo   Dispositivos: Balança, Omron (PA), Termômetro
echo.
echo   Pressione Ctrl+C para parar.
echo.

cd /d "%~dp0"
python maleta_itinerante.py

pause
