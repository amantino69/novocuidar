#!/bin/bash
# ============================================================================
# RESTORE DATABASE - TeleCuidar
# ============================================================================
# Script robusto com validação de encoding ANTES do restore
# Uso: ./restore-db.sh [arquivo_backup.sql]
# ============================================================================

set -e

BACKUP_FILE="${1:-/opt/telecuidar/deploy_backup.sql}"
cd /opt/telecuidar

echo "========================================"
echo "  RESTAURANDO BANCO TELECUIDAR"
echo "========================================"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERRO: Arquivo $BACKUP_FILE nao encontrado!"
    exit 1
fi

# ============================================================================
# VALIDACAO DE ENCODING (ANTES de tentar restore)
# ============================================================================
echo ""
echo "[1/6] Validando encoding do backup..."

# Verificar primeiros bytes (deve ser 0x2D 0x2D = "--")
FIRST_BYTES=$(xxd -l 2 -p "$BACKUP_FILE")
if [ "$FIRST_BYTES" != "2d2d" ]; then
    echo ""
    echo "=============================================="
    echo "ERRO CRITICO: ENCODING INVALIDO!"
    echo "=============================================="
    echo "Primeiros bytes: $FIRST_BYTES"
    echo "Esperado: 2d2d (caracteres --)"
    echo ""
    echo "Provaveis causas:"
    echo "  1. PowerShell corrompeu o arquivo com BOM"
    echo "  2. Encoding UTF-16 ao inves de UTF-8"
    echo ""
    echo "Solucao: Re-exporte o backup usando:"
    echo "  docker exec container pg_dump -U user -d db -f /tmp/backup.sql"
    echo "  docker cp container:/tmp/backup.sql ./backup.sql"
    echo ""
    exit 1
fi

# Verificar se arquivo parece ser SQL válido
if ! head -5 "$BACKUP_FILE" | grep -q "PostgreSQL"; then
    echo "AVISO: Arquivo nao parece ser um dump PostgreSQL valido"
    head -3 "$BACKUP_FILE"
    echo ""
    read -p "Continuar mesmo assim? (s/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

TAMANHO=$(du -h "$BACKUP_FILE" | cut -f1)
echo "  OK - Encoding valido, tamanho: $TAMANHO"

# ============================================================================
# BACKUP DE SEGURANCA
# ============================================================================
echo ""
echo "[2/6] Criando backup de seguranca..."
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
docker exec telecuidar-postgres pg_dump -U telecuidar -d telecuidar --no-owner --no-acl -f /tmp/backup_antes_restore_$BACKUP_DATE.sql 2>/dev/null || true
echo "  OK - Backup salvo em /tmp/backup_antes_restore_$BACKUP_DATE.sql (dentro do container)"

# ============================================================================
# PARAR BACKEND
# ============================================================================
echo ""
echo "[3/6] Parando backend..."
docker compose stop backend

# ============================================================================
# DROP E CREATE DATABASE
# ============================================================================
echo ""
echo "[4/6] Recriando banco..."
docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'DROP DATABASE IF EXISTS telecuidar;'
docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'CREATE DATABASE telecuidar;'

# ============================================================================
# COPIAR E RESTAURAR
# ============================================================================
echo ""
echo "[5/6] Restaurando banco..."
docker cp "$BACKUP_FILE" telecuidar-postgres:/tmp/restore.sql

# Restaurar e capturar erros
RESTORE_OUTPUT=$(docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -f /tmp/restore.sql 2>&1)
RESTORE_EXIT=$?

# Mostrar últimas linhas do output
echo "$RESTORE_OUTPUT" | tail -10

if [ $RESTORE_EXIT -ne 0 ]; then
    echo ""
    echo "AVISO: psql retornou codigo $RESTORE_EXIT (pode haver erros)"
fi

# ============================================================================
# VALIDACAO POS-RESTORE
# ============================================================================
echo ""
echo "[6/6] Validando restauracao..."

# Verificar se tabela Appointments existe
TABLE_COUNT=$(docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'Appointments';")
if [ "$TABLE_COUNT" -lt 1 ]; then
    echo "ERRO: Tabela Appointments nao existe!"
    exit 1
fi

# Verificar coluna LastActivityAt
COLUMN_EXISTS=$(docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -t -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'Appointments' AND column_name = 'LastActivityAt';")
if [ -z "$COLUMN_EXISTS" ]; then
    echo "ERRO: Coluna LastActivityAt NAO existe!"
    echo "O backup pode estar incompleto ou corrompido."
    exit 1
fi

# Contar registros
USER_COUNT=$(docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -t -c "SELECT COUNT(*) FROM \"Users\";")
APPT_COUNT=$(docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -t -c "SELECT COUNT(*) FROM \"Appointments\";")

echo ""
echo "========================================"
echo "  RESTAURACAO CONCLUIDA COM SUCESSO!"
echo "========================================"
echo "  Usuarios: $USER_COUNT"
echo "  Consultas: $APPT_COUNT"
echo "  Coluna LastActivityAt: OK"
echo ""

# Subir backend
echo "Iniciando backend..."
docker compose up -d backend
echo ""
echo "Aguardando backend ficar healthy..."
sleep 10
docker compose ps backend
