@echo off
chcp 65001 > nul
title TeleCuidar - Maleta Itinerante
color 1F

echo.
echo ============================================================
echo.
echo       TELECUIDAR - MALETA DE PROPEDEUTICA
echo.
echo ============================================================
echo.
echo   Este programa captura AUTOMATICAMENTE os dados de:
echo.
echo   - Balanca OKOK (peso)
echo   - Monitor de Pressao Omron HEM-7156T (PA, FC)
echo   - Termometro MOBI (temperatura)
echo   - Estetoscopio Eko CORE 500 (fonocardiograma)
echo.
echo   INSTRUCOES:
echo   1. Faca login no TeleCuidar no navegador
echo   2. Entre na teleconsulta
echo   3. Ligue os dispositivos e use normalmente
echo   4. Os dados aparecem na tela do medico automaticamente!
echo.
echo   NAO FECHE ESTA JANELA durante o atendimento!
echo.
echo ============================================================
echo.

cd /d C:\telecuidar\maleta

:: Define encoding UTF-8
set PYTHONIOENCODING=utf-8

:loop
echo.
echo [%date% %time%] Iniciando servico da maleta...
echo.

:: Usa --local para homologacao, remova para producao
python maleta_itinerante.py --local

echo.
echo Servico encerrou. Reiniciando em 5 segundos...
timeout /t 5 /nobreak > nul
goto loop
