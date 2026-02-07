@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: TELECUIDAR - MALETA PRODUÇÃO
:: ============================================================================
:: Este script inicia a maleta para uso em PRODUÇÃO (telecuidar.com.br)
:: - NÃO inicia frontend/backend local
:: - Inicia scripts Python para captura de dispositivos médicos
:: - Abre navegador em telecuidar.com.br
:: ============================================================================

title TeleCuidar - Maleta Produção

echo.
echo ==============================================================
echo   TELECUIDAR - MALETA PRODUCAO
echo ==============================================================
echo.

cd /d C:\telecuidar

:: ============================================================================
:: 1. VERIFICAR CONEXÃO COM INTERNET
:: ============================================================================
echo [1/4] Verificando conexao com internet...
ping -n 1 telecuidar.com.br >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Sem conexao com internet ou servidor indisponivel!
    echo        Verifique sua conexao e tente novamente.
    pause
    exit /b 1
)
echo       OK - Conexao com telecuidar.com.br estabelecida

:: ============================================================================
:: 2. VERIFICAR BLUETOOTH
:: ============================================================================
echo.
echo [2/4] Verificando Bluetooth...

:: Verifica se o serviço Bluetooth está rodando
sc query bthserv | find "RUNNING" >nul 2>&1
if errorlevel 1 (
    echo [AVISO] Servico Bluetooth nao esta rodando. Tentando iniciar...
    net start bthserv >nul 2>&1
    timeout /t 2 >nul
)

:: Verifica novamente
sc query bthserv | find "RUNNING" >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Bluetooth nao disponivel!
    echo        Ative o Bluetooth nas configuracoes do Windows.
    pause
    exit /b 1
)
echo       OK - Bluetooth ativo

:: ============================================================================
:: 3. MATAR PROCESSOS PYTHON ANTERIORES
:: ============================================================================
echo.
echo [3/4] Limpando processos anteriores...

:: Mata processos Python anteriores da maleta
taskkill /F /IM python.exe /FI "WINDOWTITLE eq TeleCuidar*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq Maleta*" >nul 2>&1
timeout /t 1 >nul

echo       OK - Processos limpos

:: ============================================================================
:: 4. INICIAR SCRIPTS PYTHON
:: ============================================================================
echo.
echo [4/4] Iniciando captura de dispositivos medicos...

:: Verifica se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado!
    echo        Instale Python 3.10+ e adicione ao PATH.
    pause
    exit /b 1
)

:: Inicia maleta_itinerante.py (BLE: balança, pressão, termômetro) - PRODUÇÃO
:: Sem flag = produção (--local seria para localhost)
echo       Iniciando captura BLE (balanca, pressao, termometro)...
start "TeleCuidar - BLE Devices [PRODUCAO]" /MIN cmd /k "cd /d C:\telecuidar\maleta && python maleta_itinerante.py"

timeout /t 2 >nul

:: Inicia ausculta_ondemand.py (estetoscópio via P2/USB) - PRODUÇÃO  
:: --prod = produção (sem flag seria localhost)
echo       Iniciando captura de ausculta (estetoscopio)...
start "TeleCuidar - Ausculta [PRODUCAO]" /MIN cmd /k "cd /d C:\telecuidar\maleta && python ausculta_ondemand.py --prod"

echo       OK - Scripts de captura iniciados

:: ============================================================================
:: 5. ABRIR NAVEGADOR EM PRODUÇÃO
:: ============================================================================
echo.
echo ==============================================================
echo   SISTEMA PRONTO
echo ==============================================================
echo.
echo   Scripts rodando em segundo plano:
echo   - Captura BLE (balanca, pressao, termometro)
echo   - Captura Ausculta (estetoscopio)
echo.
echo   Dados serao enviados para: https://www.telecuidar.com.br
echo.
echo   Abrindo navegador...
echo.

:: Abre navegador em telecuidar.com.br
start "" "https://www.telecuidar.com.br"

:: ============================================================================
:: 6. MANTER JANELA ABERTA COM STATUS
:: ============================================================================
echo ==============================================================
echo   MALETA TELECUIDAR ATIVA - PRODUCAO
echo ==============================================================
echo.
echo   [!] NAO FECHE ESTA JANELA
echo.
echo   Esta janela mantem os scripts de captura rodando.
echo   Para encerrar, feche esta janela ou pressione Ctrl+C.
echo.
echo   Credenciais de teste:
echo   - Medico: med_gt@telecuidar.com / 123
echo   - Paciente: pac_maria@telecuidar.com / 123
echo.
echo   Problemas? Verifique as janelas minimizadas:
echo   - "TeleCuidar - BLE Devices [PRODUCAO]"
echo   - "TeleCuidar - Ausculta [PRODUCAO]"
echo.

:: Loop para manter a janela aberta e mostrar status periodicamente
:loop
timeout /t 60 >nul
echo [%time%] Maleta ativa - enviando dados para telecuidar.com.br
goto loop
