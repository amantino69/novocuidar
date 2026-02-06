@echo off
title TeleCuidar - Estetoscopio Digital
color 1F

echo.
echo ============================================================
echo    TELECUIDAR - ESTETOSCOPIO DIGITAL (FONOCARDIOGRAMA)
echo ============================================================
echo.
echo Capturando audio do estetoscopio conectado no MICROFONE (P2)...
echo O estetoscopio deve estar plugado na entrada de microfone.
echo Enviando para o servidor de producao...
echo.
echo Pressione Ctrl+C para parar.
echo.

cd /d "%~dp0"
python ausculta_capture.py --prod --continuous

pause
