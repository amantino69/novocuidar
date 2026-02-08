@echo off
chcp 65001 >nul
title TeleCuidar Maleta - Selecionar Ambiente
color 1F

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║         TELECUIDAR - MALETA ITINERANTE                    ║
echo  ║                                                           ║
echo  ║   Serviço de captura de sinais vitais via Bluetooth       ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Selecione o ambiente:
echo.
echo   [1] PRODUÇÃO    - telecuidar.com.br (pacientes reais)
echo   [2] HOMOLOGAÇÃO - 192.168.18.31:5239 (testes internos)
echo   [3] LOCALHOST   - localhost:5239 (desenvolvimento local)
echo.
echo   [Q] Sair
echo.

set /p escolha="   Escolha (1/2/3/Q): "

if /i "%escolha%"=="1" goto producao
if /i "%escolha%"=="2" goto homologacao
if /i "%escolha%"=="3" goto localhost
if /i "%escolha%"=="Q" goto sair
goto inicio

:producao
cls
color 2F
echo.
echo  ══════════════════════════════════════════════════════════════
echo   PRODUÇÃO - https://www.telecuidar.com.br
echo  ══════════════════════════════════════════════════════════════
echo.
echo   Iniciando captura de sinais vitais...
echo   Pressione Ctrl+C para parar.
echo.
cd /d "%~dp0"
python maleta_itinerante.py
goto fim

:homologacao
cls
color 6F
echo.
echo  ══════════════════════════════════════════════════════════════
echo   HOMOLOGAÇÃO - http://192.168.18.31:5239
echo  ══════════════════════════════════════════════════════════════
echo.
echo   Iniciando captura de sinais vitais...
echo   Pressione Ctrl+C para parar.
echo.
cd /d "%~dp0"
python maleta_itinerante.py --url http://192.168.18.31:5239
goto fim

:localhost
cls
color 5F
echo.
echo  ══════════════════════════════════════════════════════════════
echo   LOCALHOST - http://localhost:5239
echo  ══════════════════════════════════════════════════════════════
echo.
echo   Iniciando captura de sinais vitais...
echo   Pressione Ctrl+C para parar.
echo.
cd /d "%~dp0"
python maleta_itinerante.py --local
goto fim

:sair
exit

:fim
echo.
echo   Script finalizado.
pause
