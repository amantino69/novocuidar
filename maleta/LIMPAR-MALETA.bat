@echo off
chcp 65001 >nul
title Limpar Pasta Maleta - TeleCuidar
color 4F

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║   ATENÇÃO: ESTE SCRIPT APAGA ARQUIVOS!                    ║
echo  ║                                                           ║
echo  ║   Execute APENAS no computador da MALETA                  ║
echo  ║   NÃO execute no computador de desenvolvimento!           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Arquivos que serão MANTIDOS:
echo   - maleta_itinerante.py
echo   - config.json
echo   - requirements.txt
echo   - Maleta-HOMOLOGACAO.bat
echo   - Maleta-PRODUCAO.bat
echo   - logs/
echo.

set /p confirm="   Tem certeza que quer continuar? (S/N): "
if /i not "%confirm%"=="S" goto cancelado

echo.
echo   Limpando arquivos desnecessários...
echo.

cd /d "%~dp0"

:: Deletar scripts de análise/teste
del /q analise_*.py 2>nul
del /q ausculta_*.py 2>nul
del /q ausculta_*.wav 2>nul
del /q capturar_*.py 2>nul
del /q capture_*.py 2>nul
del /q decode_*.py 2>nul
del /q diagnostico_*.py 2>nul
del /q download_*.py 2>nul
del /q eko_*.py 2>nul
del /q eko_*.bin 2>nul
del /q enviar_*.py 2>nul
del /q foco_*.py 2>nul
del /q fono_*.wav 2>nul
del /q instalar_*.py 2>nul
del /q ler_*.py 2>nul
del /q maleta_automatica.py 2>nul
del /q maleta_unificada.py 2>nul
del /q maleta_itinerante_original.py 2>nul
del /q monitor_*.py 2>nul
del /q protocolo_*.py 2>nul
del /q scan_*.py 2>nul
del /q servico_*.py 2>nul
del /q setup_*.py 2>nul
del /q telecuidar_ble_service.py 2>nul
del /q testar_*.py 2>nul
del /q teste_*.py 2>nul
del /q ultima_*.py 2>nul

:: Deletar scripts de configuração duplicados/antigos
del /q "CONFIGURAR INICIALIZACAO.ps1" 2>nul
del /q ConfigurarStartup.ps1 2>nul
del /q ConfigurarInicializacao.bat 2>nul
del /q IniciarMaletaTeleCuidar.bat 2>nul

:: Deletar guias e docs
del /q "GUIA RAPIDO.txt" 2>nul
del /q GUIA-OPERADOR.md 2>nul
del /q README.md 2>nul

:: Deletar scripts .bat antigos/duplicados
del /q "Iniciar Estetoscopio.bat" 2>nul
del /q "INICIAR MALETA COMPLETA.bat" 2>nul
del /q "Iniciar Maleta PRODUCAO.bat" 2>nul
del /q "Iniciar Maleta.bat" 2>nul
del /q "Iniciar TeleCuidar.bat" 2>nul
del /q INICIAR.bat 2>nul

:: Deletar arquivos temporários
del /q dir.txt 2>nul
del /q *.log 2>nul

:: Deletar este próprio script após uso
del /q LIMPAR-MALETA.bat 2>nul

:: Limpar pasta __pycache__
rmdir /s /q __pycache__ 2>nul

echo.
echo   ✅ Limpeza concluída!
echo.
echo   ─────────────────────────────────────────────────────────────
echo.
echo   Criando atalho na Área de Trabalho (HOMOLOGAÇÃO)...

:: Criar atalho na área de trabalho
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $s = $ws.CreateShortcut(\"$desktop\Maleta HOMOLOGACAO.lnk\"); $s.TargetPath = '%~dp0Maleta-HOMOLOGACAO.bat'; $s.WorkingDirectory = '%~dp0'; $s.Description = 'TeleCuidar Maleta - Homologação'; $s.Save(); Write-Host '   Atalho criado: ' $desktop'\Maleta HOMOLOGACAO.lnk'"

echo.
echo   ─────────────────────────────────────────────────────────────
echo.
echo   Arquivos restantes:
echo.
dir /b
echo.
echo   ─────────────────────────────────────────────────────────────
echo.
echo   PRÓXIMOS PASSOS:
echo.
echo   1. Instale as dependências Python:
echo      pip install -r requirements.txt
echo.
echo   2. Use o atalho "Maleta HOMOLOGACAO" na área de trabalho
echo      ou execute: Maleta-HOMOLOGACAO.bat
echo.
echo   3. No seu PC de desenvolvimento, inicie o backend:
echo      http://192.168.18.31:5239
echo.
pause
goto fim

:cancelado
echo.
echo   Operação cancelada.
echo.
pause

:fim
