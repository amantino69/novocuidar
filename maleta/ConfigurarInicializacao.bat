@echo off
chcp 65001 >nul
title TeleCuidar - Configurar Inicialização Automática
color 1F

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║   TELECUIDAR - Configurar Inicialização Automática        ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Este script configura a maleta para iniciar automaticamente
echo   quando o Windows ligar.
echo.
echo   ─────────────────────────────────────────────────────────────
echo.
echo   [1] Iniciar com Windows → PRODUÇÃO (telecuidar.com.br)
echo   [2] Iniciar com Windows → HOMOLOGAÇÃO (192.168.18.31)
echo   [3] Iniciar com Windows → MENU (escolher na hora)
echo.
echo   [R] REMOVER inicialização automática
echo   [Q] Sair
echo.

set /p escolha="   Escolha (1/2/3/R/Q): "

if /i "%escolha%"=="1" goto producao
if /i "%escolha%"=="2" goto homologacao
if /i "%escolha%"=="3" goto menu
if /i "%escolha%"=="R" goto remover
if /i "%escolha%"=="Q" goto sair

:producao
set TARGET=Maleta-PRODUCAO.bat
set DESC=TeleCuidar Maleta - Producao
goto criar

:homologacao
set TARGET=Maleta-HOMOLOGACAO.bat
set DESC=TeleCuidar Maleta - Homologacao
goto criar

:menu
set TARGET=IniciarMaletaTeleCuidar.bat
set DESC=TeleCuidar Maleta - Menu
goto criar

:criar
echo.
echo   Criando atalho na pasta Startup...

:: Criar VBS temporário para criar o atalho
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set SHORTCUT=%STARTUP%\TeleCuidar Maleta.lnk
set SCRIPT_DIR=%~dp0

:: Usar PowerShell para criar o atalho
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%SCRIPT_DIR%%TARGET%'; $s.WorkingDirectory = '%SCRIPT_DIR%'; $s.Description = '%DESC%'; $s.Save()"

if exist "%SHORTCUT%" (
    echo.
    echo   ✅ Atalho criado com sucesso!
    echo.
    echo   Localização: %SHORTCUT%
    echo   Destino: %SCRIPT_DIR%%TARGET%
    echo.
    echo   Na próxima vez que o Windows iniciar, a maleta
    echo   será ativada automaticamente.
) else (
    echo.
    echo   ❌ Erro ao criar atalho!
)
goto fim

:remover
set SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TeleCuidar Maleta.lnk
if exist "%SHORTCUT%" (
    del "%SHORTCUT%"
    echo.
    echo   ✅ Inicialização automática REMOVIDA
) else (
    echo.
    echo   ℹ️  Não havia inicialização automática configurada
)
goto fim

:sair
echo.
echo   Nenhuma alteração feita.
goto fim

:fim
echo.
pause
