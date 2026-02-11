# Script para corrigir configuração CADSUS na VPS
# Execute este script e digite a senha quando solicitado

Write-Host "=== Corrigindo CADSUS na VPS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quando solicitado, digite a senha: ZXCASDzxcasd1@" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pressione ENTER para continuar..."
Read-Host

# Conectar e executar comandos
ssh root@telecuidar.com.br @"
echo 'CNS_AMBIENTE=producao' >> /opt/telecuidar/.env
echo 'CNS_CERT_PATH=/app/certs/certificado.pfx' >> /opt/telecuidar/.env
echo 'CNS_CERT_PASSWORD=A3jfa4p2' >> /opt/telecuidar/.env
echo ''
echo '=== Configuracao adicionada ==='
grep CNS /opt/telecuidar/.env
echo ''
echo '=== Reiniciando backend ==='
cd /opt/telecuidar
docker compose up -d backend --force-recreate
echo ''
echo '=== Aguardando 15 segundos ==='
sleep 15
echo ''
echo '=== Verificando variaveis no container ==='
docker exec telecuidar-backend printenv | grep CNS
echo ''
echo '=== Concluido! ==='
"@

Write-Host ""
Write-Host "Script finalizado!" -ForegroundColor Green
