#!/bin/bash
# Script de deploy executado na VPS
# Enviado pelo deploy-vps.ps1

set -e
cd /opt/telecuidar

echo '[1/6] Puxando cÃ³digo do GitHub...'
git pull origin main

echo '[2/6] Parando backend...'
docker compose stop backend

echo '[3/6] Restaurando banco de dados...'
docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'DROP DATABASE IF EXISTS telecuidar;' || true
docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'CREATE DATABASE telecuidar;'
docker cp /opt/telecuidar/deploy_backup.sql telecuidar-postgres:/tmp/backup.sql
docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -f /tmp/backup.sql

echo '[4/6] Reconstruindo Backend...'
docker compose build backend

echo '[5/6] Reconstruindo Frontend...'
docker compose build frontend

echo '[6/6] Iniciando sistema...'
docker compose up -d

echo 'Aguardando 30s para healthcheck...'
sleep 30

echo ''
echo '=== STATUS DOS CONTAINERS ==='
docker compose ps
