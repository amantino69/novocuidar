@echo off
chcp 65001 > nul
title TeleCuidar - Escolher Modo
color 0B
cls

:MENU
echo.
echo  =========================================================
echo.
echo       TELECUIDAR - MALETA ITINERANTE
echo.
echo  =========================================================
echo.
echo   Escolha o modo de operacao:
echo.
echo      [1] HOMOLOGACAO (localhost:5239)
echo          Para testes locais no computador de desenvolvimento
echo.
echo      [2] PRODUCAO (telecuidar.com.br)
echo          Para uso real em campo com o servidor de producao
echo.
echo      [3] SAIR
echo.
echo  =========================================================
echo.

set /p opcao="Digite sua opcao (1/2/3): "

if "%opcao%"=="1" (
    call "%~dp0Iniciar Maleta.bat"
    goto :EOF
)

if "%opcao%"=="2" (
    call "%~dp0Iniciar Maleta PRODUCAO.bat"
    goto :EOF
)

if "%opcao%"=="3" (
    exit
)

echo.
echo   Opcao invalida! Digite 1, 2 ou 3.
echo.
pause
goto :MENU
