@echo off
title TeleCuidar - Estetoscopio Digital
color 1F

echo.
echo ============================================================
echo    TELECUIDAR - ESTETOSCOPIO DIGITAL (FONOCARDIOGRAMA)
echo ============================================================
echo.
echo Capturando audio do estetoscopio conectado via P2...
echo Enviando para o servidor de producao...
echo.
echo Pressione Ctrl+C para parar.
echo.

cd /d "%~dp0"
python ausculta_capture.py --prod --continuous

pause
