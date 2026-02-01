@echo off
chcp 65001 > nul
title TeleCuidar - Maleta Itinerante Unificada
color 1F
cls

echo.
echo  =========================================================
echo.
echo       TELECUIDAR - MALETA ITINERANTE
echo.
echo  =========================================================
echo.
echo   Este programa captura AUTOMATICAMENTE os dados de:
echo.
echo   * Balanca OKOK (peso)
echo   * Monitor de Pressao Omron HEM-7156T (PA, FC)
echo   * Termometro MOBI (temperatura)
echo   * Estetoscopio Digital via entrada P2 (fonocardiograma)
echo.
echo  ---------------------------------------------------------
echo.
echo   INSTRUCOES:
echo.
echo   1. Faca login no TeleCuidar no navegador
echo   2. Entre na teleconsulta
echo   3. Clique em "Acontecendo" para ativar a captura
echo   4. Ligue os dispositivos e use normalmente
echo   5. Para ESTETOSCOPIO: pressione ENTER para capturar
echo   6. Os dados aparecem na tela do medico em tempo real!
echo.
echo   NAO FECHE ESTA JANELA durante o atendimento!
echo.
echo  =========================================================
echo.

cd /d "%~dp0"

:: Define encoding UTF-8
set PYTHONIOENCODING=utf-8

:loop
echo.
echo [%date% %time%] Iniciando sistema da maleta...
echo.

:: Inicia BLE (balanca, pressao, termometro) em janela separada
start "TeleCuidar BLE" cmd /c "color 2F && python maleta_itinerante.py"

:: Executa estetoscopio nesta janela
python maleta_unificada.py --prod --no-ble

echo.
echo Sistema encerrou. Reiniciando em 5 segundos...
timeout /t 5 /nobreak > nul
goto loop
