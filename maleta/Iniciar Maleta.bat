@echo off
title TeleCuidar - Maleta de Dispositivos Medicos
color 1F

echo.
echo ============================================================
echo.
echo       TELECUIDAR - MALETA DE DISPOSITIVOS MEDICOS
echo.
echo ============================================================
echo.
echo   Este programa captura automaticamente os dados da:
echo   - Balanca OKOK
echo   - Monitor de Pressao Omron HEM-7156T
echo   - Termometro MOBI
echo.
echo   E envia para a tela do medico durante a teleconsulta.
echo.
echo   NAO FECHE ESTA JANELA durante o atendimento!
echo.
echo ============================================================
echo.

cd /d C:\telecuidar\maleta
python maleta_itinerante.py

echo.
echo ============================================================
echo   MALETA ENCERRADA
echo   Pressione qualquer tecla para fechar...
echo ============================================================
pause > nul
