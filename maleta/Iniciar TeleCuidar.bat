@echo off
title TeleCuidar Maleta - Captura Automatica
color 1F
cls

echo ============================================================
echo.
echo            TELECUIDAR - MALETA ITINERANTE
echo            Captura Automatica de Sinais Vitais
echo.
echo ============================================================
echo.
echo O servico vai iniciar automaticamente...
echo.
echo Dispositivos suportados:
echo   - Balanca OKOK
echo   - Omron HEM-7156T (Pressao)
echo.
echo ------------------------------------------------------------
echo.

cd /d "%~dp0"
python servico_maleta.py

pause
