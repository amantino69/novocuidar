#!/bin/bash
# ========================================
# TeleCuidar - Iniciar Homologação
# ========================================

set -e

echo "🚀 Iniciando TeleCuidar em HOMOLOGAÇÃO..."
echo ""

# Carregar variáveis de ambiente
if [ -f ".env.staging" ]; then
    export $(cat .env.staging | xargs)
    echo "✅ Variáveis carregadas de .env.staging"
else
    echo "⚠️  Arquivo .env.staging não encontrado. Usando valores padrão."
fi

echo ""
echo "📦 Construindo imagens..."
docker-compose -f docker-compose.staging.yml build

echo ""
echo "🔧 Iniciando containers..."
docker-compose -f docker-compose.staging.yml up -d

echo ""
echo "⏳ Aguardando PostgreSQL ficar pronto..."
for i in {1..30}; do
    if docker-compose -f docker-compose.staging.yml exec -T postgres pg_isready -U ${DB_USER:-postgres} -d telecuidar > /dev/null 2>&1; then
        echo "✅ PostgreSQL está pronto!"
        break
    fi
    echo "  Tentativa $i/30..."
    sleep 2
done

echo ""
echo "⏳ Aguardando Backend ficar pronto..."
for i in {1..60}; do
    if docker-compose -f docker-compose.staging.yml exec -T backend curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "✅ Backend está pronto!"
        break
    fi
    echo "  Tentativa $i/60..."
    sleep 2
done

echo ""
echo "✅ TeleCuidar em Homologação iniciado com sucesso!"
echo ""
echo "📍 URLs:"
echo "   Frontend:  http://localhost:4000"
echo "   Backend:   http://localhost:5000"
echo "   Jitsi:     https://localhost:8443"
echo "   Swagger:   http://localhost:5000/swagger/index.html"
echo ""
echo "🔑 Credenciais de Teste (senha: 123):"
echo "   Médico:      med_gt@telecuidar.com (Geraldo Tadeu - Cardiologia)"
echo "   Psiquiatra:  med_aj@telecuidar.com (Antonio Jorge)"
echo "   Assistente:  enf_do@telecuidar.com (Danila Ochoa)"
echo "   Paciente:    pac_dc@telecuidar.com (Daniel Carrara)"
echo "   Admin:       adm_ca@telecuidar.com (Claudio Amantino)"
echo ""
echo "📋 Para ver logs:"
echo "   docker-compose -f docker-compose.staging.yml logs -f backend"
echo "   docker-compose -f docker-compose.staging.yml logs -f frontend"
echo ""
echo "🛑 Para parar:"
echo "   docker-compose -f docker-compose.staging.yml down"
