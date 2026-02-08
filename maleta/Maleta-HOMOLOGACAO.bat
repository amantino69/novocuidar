@echo off
chcp 65001 >nul
title TeleCuidar Maleta - HOMOLOGAÇÃO
color 6F

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║   TELECUIDAR MALETA - HOMOLOGAÇÃO                         ║
echo  ║   http://192.168.18.31:5239                               ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Capturando sinais vitais via Bluetooth...
echo   Dispositivos: Balança, Omron (PA), Termômetro
echo.
echo   ATENÇÃO: Dados vão para servidor de TESTE!
echo.
echo   Pressione Ctrl+C para parar.
echo.

cd /d "%~dp0"
python maleta_itinerante.py --url http://192.168.18.31:5239

pause
