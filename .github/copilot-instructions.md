# 📋 Instruções para IA - TeleCuidar POC
# Set-Location C:\telecuidar\frontend; ng serve --host 0.0.0.0 --port 4200 --ssl

# cd C:\telecuidar\maleta
# python ausculta_ondemand.py --prod


> ** SOMENTE RODE LOCALHOST NA PORTA 4200 (FRONTEND) E 5239 (BACKEND) 
Se tiverem ocupadas mate elas sem me perguntar**


IMPORTANTE**: Este arquivo contém instruções críticas para qualquer IA que trabalhe neste projeto.
> Leia completamente antes de fazer qualquer alteração.

---
***
VResolva com pragmatismo: Sem Hangfire. Sem migrations complexas. Sem burocracia.

Estratégia:

✅ Migration simples (LastActivityAt apenas)
✅ UpdateActivity é método trivial (sem background job)
✅ Seed resetável em 30 segundos
✅ Script automático de startup
✅ Documentação clara para NUNCA voltar a isso

***



## � LIÇÕES APRENDIDAS - INCIDENTE DE DEPLOY 04/02/2026

### O que aconteceu
Sistema ficou fora do ar por horas durante tentativa de deploy. Múltiplos problemas:
1. Arquivos novos estavam sendo ignorados pelo `.gitignore`
2. Migrações do Entity Framework não estavam sendo aplicadas
3. Inconsistência entre ambiente local e produção

### Causa Raiz
- **Arquivos ignorados**: Novos arquivos criados (WaitingList.cs, UrgencyLevel.cs, ReceptionistController.cs, signalr.service.ts, etc.) estavam em pastas que batiam com padrões do `.gitignore`
- **Banco desatualizado**: O PostgreSQL na VPS tinha schema antigo, e as migrações não foram aplicadas corretamente
- **Falta de verificação**: Não foi verificado se todos os arquivos estavam commitados antes do deploy

### REGRA DE OURO PARA DEPLOYS
> **Se funciona em homologação local, copie o banco local para produção!**
> 
> Não tente "rodar migrações" ou "sincronizar schema" - copie o banco inteiro.

### 🚨 ALERTA CRÍTICO - BANCO DE DADOS EM PRODUÇÃO

> **⚠️ ATENÇÃO: ANTES de qualquer operação que APAGUE, SOBRESCREVA ou MOVA banco de dados:**
>
> 1. **PERGUNTE AO USUÁRIO**: "O banco de produção contém dados reais de pacientes ou apenas dados de seeder/teste?"
> 2. **Se houver dados reais**: FAÇA BACKUP COMPLETO antes de qualquer operação
> 3. **Documente**: Anote data/hora do backup e onde foi salvo
>
> **Fase atual (POC)**: Banco contém apenas dados de seeder - pode ser sobrescrito
> **Fase futura (Produção)**: Banco conterá dados reais de pacientes - NUNCA sobrescrever sem backup

```powershell
# ANTES de qualquer operação destrutiva, SEMPRE fazer backup:
docker exec telecuidar-postgres pg_dump -U telecuidar -d telecuidar > backup_YYYYMMDD_HHMM.sql
```

---

## 🔧 LIÇÕES APRENDIDAS - DEPLOY 06/02/2026

### Problemas e Soluções

| Problema | Causa | Solução |
|----------|-------|--------|
| Script deploy parava por "mudanças pendentes" | `deploy_backup.sql` criado na raiz do projeto | Mover backup para `backups/` (já ignorada pelo git) |
| Erro `invalid byte sequence for encoding "UTF8": 0xff` | Windows salva arquivos com encoding UTF16/BOM | Converter com `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))` |
| Backend unhealthy - `column AssistantId does not exist` | Restore do banco falhou, schema incompleto | Re-exportar e restaurar com encoding correto |
| Frontend não aparece após `docker compose build` | Build não inicia container automaticamente | Sempre executar `docker compose up -d frontend` após build |
| Ausculta captura chiado em produção, perfeita em localhost | WebRTC/Jitsi aplica AGC/NS/AEC no áudio | Desabilitar processamento: `disableAP`, `disableAEC`, `disableNS`, `disableAGC`, `disableHPF` |

### Correções Implementadas

1. **deploy-vps.ps1**: Backup agora vai para `backups/deploy_backup.sql`
2. **jitsi.service.ts**: Adicionado `disableAP/AEC/NS/AGC/HPF: true`
3. **custom-config.js**: Mesmas configurações server-side no Jitsi

### Checklist Pós-Deploy (OBRIGATÓRIO)
```powershell
# 1. Verificar todos containers UP e HEALTHY
ssh root@telecuidar.com.br "docker compose ps"

# 2. Se frontend não aparece:
ssh root@telecuidar.com.br "docker compose up -d frontend"

# 3. Testar endpoint
Invoke-WebRequest -Uri "https://www.telecuidar.com.br" -UseBasicParsing | Select-Object StatusCode
```

---

## ⚠️ PROCEDIMENTO OBRIGATÓRIO ANTES DE QUALQUER DEPLOY

### 1. Verificar arquivos ignorados
```powershell
# Listar TODOS os arquivos ignorados no projeto
git status --ignored --porcelain | Select-String "backend/|frontend/src/"

# Se aparecer algum arquivo .cs, .ts, .html, .scss - ADICIONAR!
git add -f caminho/do/arquivo
```

### 2. Testar build local ANTES de commitar
```powershell
# Backend
cd C:\telecuidar
dotnet build backend/WebAPI/WebAPI.csproj

# Frontend  
cd C:\telecuidar\frontend
npx ng build --configuration=production
```

### 3. Se build local passar, faça o deploy COPIANDO O BANCO
```powershell
# 1. Exportar banco do PostgreSQL local
docker exec telecuidar-postgres-dev pg_dump -U postgres -d telecuidar --no-owner --no-acl > C:\telecuidar\backup_deploy.sql

# 2. Converter para UTF8 (evita erros de encoding)
[System.IO.File]::WriteAllText("C:\telecuidar\backup_deploy_utf8.sql", (Get-Content C:\telecuidar\backup_deploy.sql -Raw), [System.Text.Encoding]::UTF8)

# 3. Copiar para VPS
scp C:\telecuidar\backup_deploy_utf8.sql root@telecuidar.com.br:/opt/telecuidar/backup.sql

# 4. Na VPS - Restaurar banco
ssh root@telecuidar.com.br "cd /opt/telecuidar && docker compose stop backend && docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'DROP DATABASE IF EXISTS telecuidar;' && docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'CREATE DATABASE telecuidar;' && docker cp /opt/telecuidar/backup.sql telecuidar-postgres:/tmp/backup.sql && docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -f /tmp/backup.sql"

# 5. Subir sistema
ssh root@telecuidar.com.br "cd /opt/telecuidar && git pull origin main && docker compose build backend frontend --no-cache && docker compose up -d"
```

---

## �🔐 Repositório GitHub

### Conta e Repositório CORRETOS
- **Proprietário**: `amantino69`
- **Repositório**: `novocuidar`
- **URL HTTPS**: `https://github.com/amantino69/novocuidar.git`
- **URL com Token**: Use a variável de ambiente `$GITHUB_TOKEN` ou consulte o arquivo `.git/config`

### ⚠️ ATENÇÃO - Repositório ANTIGO (NÃO USAR para desenvolvimento)
- O repositório `guilhermevieirao/telecuidar` é o repositório ORIGINAL
- O script `deploy.sh` clona deste repositório antigo
- **NUNCA** usar este repositório para desenvolvimento da POC

### Configuração do Remote
```bash
# Verificar remotes configurados
git remote -v

# O remote correto deve ser:
# origin ou novocuidar -> https://github.com/amantino69/novocuidar.git

# Se precisar adicionar/corrigir (substitua $GITHUB_TOKEN pelo token real):
git remote set-url origin https://$GITHUB_TOKEN@github.com/amantino69/novocuidar.git

# Ou adicionar como novo remote:
git remote add novocuidar https://$GITHUB_TOKEN@github.com/amantino69/novocuidar.git

# NOTA: O token está configurado no .git/config local
# Para ver: cat .git/config | grep url
```

---

## � ATIVAR SISTEMA DE HOMOLOGAÇÃO (LOCAL)

### ⚠️ IMPORTANTE - Leia antes de executar!
Esta seção explica como iniciar o sistema TeleCuidar localmente para testes/homologação.
- **Frontend**: Angular na porta 4200
- **Backend**: .NET na porta 5239
- **Pasta local**: `C:\telecuidar`

### Método 1: Usar Task do VS Code (RECOMENDADO)
```
1. Abrir VS Code na pasta C:\telecuidar
2. Pressionar Ctrl+Shift+P
3. Digitar "Tasks: Run Task"
4. Selecionar "Iniciar Sem Jitsi"
```

Ou usar a ferramenta `run_task`:
```
run_task com id="Iniciar Sem Jitsi" e workspaceFolder="c:\telecuidar"
```

### Método 2: Comandos Manuais (se a task falhar)

**Passo 1 - Matar processos existentes nas portas:**
```powershell
# Verificar se portas estão ocupadas
netstat -ano | findstr ":4200"
netstat -ano | findstr ":5239"

# Se houver processos, matar pelo PID (substituir XXXX pelo número)
Stop-Process -Id XXXX -Force
```

**Passo 2 - Iniciar Frontend:**
```powershell
cd C:\telecuidar\frontend
ng serve --host 0.0.0.0 --port 4200
```
> Aguardar aparecer: `➜ Local: http://localhost:4200/`

**Passo 3 - Iniciar Backend (em outro terminal):**
```powershell
cd C:\telecuidar
dotnet run --project backend/WebAPI/WebAPI.csproj
```
> Aguardar aparecer: `Now listening on: http://0.0.0.0:5239`

### Credenciais de Teste (senha: `123`)
| Tipo | Email |
|------|-------|
| Médico | med_gt@telecuidar.com |
| Paciente | pac_aj@telecuidar.com |
| Enfermeira | enf_do@telecuidar.com |
| Admin | adm_ca@telecuidar.com |

### Problemas Comuns

**Porta 4200 ocupada:**
```powershell
netstat -ano | findstr ":4200"
# Pegar o PID da última coluna e matar:
Stop-Process -Id <PID> -Force
```

**Banco de dados corrompido:**
```powershell
Remove-Item "C:\telecuidar\backend\WebAPI\telecuidar.db" -Force
# Reiniciar backend - o banco será recriado automaticamente
```

**Backend fecha sozinho:**
- NÃO executar outros comandos no mesmo terminal do backend
- Usar terminais separados para frontend e backend

---

## 🎥 ATIVAR JITSI EM DESENVOLVIMENTO LOCAL (HTTPS)

### Por que HTTPS é necessário?
O Jitsi Meet (meet.telecuidar.com.br) requer HTTPS para funcionar. Quando o frontend roda em HTTP (localhost:4200), o navegador bloqueia:
- Mixed content (HTTP carregando recursos HTTPS)
- Acesso à câmera/microfone (requer contexto seguro)

### Método: Frontend com SSL Auto-Assinado

**Passo 1 - Iniciar Frontend com HTTPS:**
```powershell
cd C:\telecuidar\frontend
ng serve --host 0.0.0.0 --port 4200 --ssl
```
> Aguardar aparecer: `➜ Local: https://localhost:4200/`

**Passo 2 - Iniciar Backend (em outro terminal):**
```powershell
cd C:\telecuidar
dotnet run --project backend/WebAPI/WebAPI.csproj
```

**Passo 3 - Acessar no navegador:**
```
https://localhost:4200
```

⚠️ **IMPORTANTE - Aceitar certificado auto-assinado:**
Na primeira vez, o navegador mostrará aviso de segurança:
- **Chrome**: Clicar em "Avançado" → "Continuar para localhost (não seguro)"
- **Firefox**: Clicar em "Avançado" → "Aceitar o risco e continuar"
- **Edge**: Clicar em "Avançado" → "Continuar para localhost (não seguro)"

### Configuração do Jitsi
O backend está configurado para usar o Jitsi de produção:
- **Domínio**: `meet.telecuidar.com.br`
- **Arquivo de config**: `backend/WebAPI/appsettings.Development.json`

```json
{
  "JitsiSettings": {
    "Enabled": true,
    "Domain": "meet.telecuidar.com.br",
    "AppId": "telecuidar",
    "AppSecret": "TelecuidarJitsiSecretKey2024LocalDevelopment!@#$%^&*()",
    "RequiresAuth": true,
    "DynamicDomain": false
  }
}
```

### Resumo das URLs em Desenvolvimento com Jitsi
| Serviço | URL | Protocolo |
|---------|-----|-----------|
| Frontend | https://localhost:4200 | HTTPS (obrigatório) |
| Backend | http://localhost:5239 | HTTP |
| Jitsi | https://meet.telecuidar.com.br | HTTPS (produção) |

### Comando Rápido (Copiar e Colar)
```powershell
# Terminal 1 - Frontend com HTTPS
cd C:\telecuidar\frontend; ng serve --host 0.0.0.0 --port 4200 --ssl

# Terminal 2 - Backend
cd C:\telecuidar; dotnet run --project backend/WebAPI/WebAPI.csproj
```

### Credenciais de Teste
| Tipo | Email | Senha |
|------|-------|-------|
| Médico | med_gt@telecuidar.com | 123 |
| Paciente | pac_aj@telecuidar.com | 123 |
| Enfermeira | enf_do@telecuidar.com | 123 |

---

## 🐳 Containers Docker

### Arquitetura de Containers (ATUALIZADA - PostgreSQL)
```
┌─────────────────────────────────────────────────────────────┐
│                      telecuidar-nginx                        │
│                    (Porta 80, 443)                           │
└─────────────────────┬───────────────────┬───────────────────┘
                      │                   │
         ┌────────────▼────────┐ ┌───────▼────────────┐
         │ telecuidar-frontend │ │ telecuidar-backend │
         │    (Porta 4000)     │ │   (Porta 5000)     │
         └─────────────────────┘ └────────┬───────────┘
                                          │
                               ┌──────────▼──────────┐
                               │ telecuidar-postgres │
                               │   PostgreSQL 16     │
                               │   (Porta 5432)      │
                               └─────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Jitsi Meet (Videoconferência)             │
├─────────────────┬─────────────────┬─────────────────────────┤
│ telecuidar-     │ telecuidar-     │ telecuidar-jitsi-web    │
│ prosody         │ jicofo          │ (Porta 8443)            │
├─────────────────┼─────────────────┴─────────────────────────┤
│ telecuidar-jvb  │ (Portas 8080, 10000/udp)                  │
└─────────────────┴───────────────────────────────────────────┘
```

### ⚠️ IMPORTANTE - Banco de Dados é PostgreSQL (NÃO SQLite!)
- **Produção (VPS)**: Container `telecuidar-postgres` com volume `telecuidar-postgres-data`
- **Homologação (Local)**: Container `telecuidar-postgres-dev` 
- **Connection String**: `Host=postgres;Port=5432;Database=telecuidar;Username=telecuidar;Password=...`

### Comandos Essenciais
```bash
# Ver status de todos os containers
docker compose ps

# Ver logs de um container específico
docker logs telecuidar-backend -f --tail=50
docker logs telecuidar-frontend -f --tail=50

# Reiniciar um container
docker compose restart backend
docker compose restart frontend

# Parar todos os containers
docker compose down

# Iniciar todos os containers
docker compose up -d

# Reconstruir um container (após mudanças no código)
docker compose build backend --no-cache
docker compose build frontend --no-cache
```

### Volumes Importantes
```bash
# Listar volumes
docker volume ls | grep telecuidar

# Volumes críticos:
# - telecuidar-postgres-data    -> Banco de dados PostgreSQL (CRÍTICO!)
# - telecuidar-backend-uploads  -> Arquivos enviados
# - telecuidar-backend-avatars  -> Fotos de perfil
# - telecuidar-backend-logs     -> Logs da aplicação
```

---

## 🗄️ Banco de Dados - PostgreSQL

### ⚠️ ATENÇÃO: Sistema usa PostgreSQL (migrado de SQLite em 04/02/2026)

### Containers PostgreSQL
| Ambiente | Container | Usuário | Banco |
|----------|-----------|---------|-------|
| Homologação (Local) | `telecuidar-postgres-dev` | `postgres` | `telecuidar` |
| Produção (VPS) | `telecuidar-postgres` | `telecuidar` | `telecuidar` |

### Backup do Banco (LOCAL → VPS)
```powershell
# 1. Exportar do container local
docker exec telecuidar-postgres-dev pg_dump -U postgres -d telecuidar --no-owner --no-acl > C:\telecuidar\backup.sql

# 2. Converter para UTF8
[System.IO.File]::WriteAllText("C:\telecuidar\backup_utf8.sql", (Get-Content C:\telecuidar\backup.sql -Raw), [System.Text.Encoding]::UTF8)

# 3. Enviar para VPS
scp C:\telecuidar\backup_utf8.sql root@telecuidar.com.br:/opt/telecuidar/backup.sql

# 4. Restaurar na VPS
ssh root@telecuidar.com.br "docker compose stop backend && docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'DROP DATABASE IF EXISTS telecuidar;' && docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'CREATE DATABASE telecuidar;' && docker cp /opt/telecuidar/backup.sql telecuidar-postgres:/tmp/backup.sql && docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -f /tmp/backup.sql && docker compose up -d backend"
```

### Verificar Tabelas (VPS)
```bash
ssh root@telecuidar.com.br "docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -c '\dt'"
```

### Verificar Migrações Aplicadas
```bash
ssh root@telecuidar.com.br "echo 'SELECT MigrationId FROM \"__EFMigrationsHistory\" ORDER BY MigrationId;' | docker exec -i telecuidar-postgres psql -U telecuidar -d telecuidar"
```

### Usuários POC

#### Médicos (Role: PROFESSIONAL = 1)
| Email | Nome | Especialidade | Senha |
|-------|------|---------------|-------|
| med_gt@telecuidar.com | Geraldo Tadeu | Clínica Geral | 123 |
| med_aj@telecuidar.com | Antônio Jorge | Psiquiatria | 123 |

#### Assistentes/Enfermeiras (Role: ASSISTANT = 3)
| Email | Nome | Senha |
|-------|------|-------|
| enf_do@telecuidar.com | Daniela Ochoa | 123 |

#### Administradores (Role: ADMIN = 2)
| Email | Nome | Senha |
|-------|------|-------|
| adm_ca@telecuidar.com | Cláudio Amantino | 123 |

#### Pacientes (Role: PATIENT = 0)
| Email | Nome | Sexo | Nascimento | Idade |
|-------|------|------|------------|-------|
| pac_maria@telecuidar.com | Maria Silva | F | 1952-11-20 | 73 anos |
| pac_dc@telecuidar.com | Daniel Carrara | M | 1985-06-10 | 40 anos |
| pac_joao@telecuidar.com | João Santos | M | 1995-02-28 | 30 anos |
| pac_ana@telecuidar.com | Ana Oliveira | F | 1990-08-05 | 35 anos |
| pac_lucia@telecuidar.com | Lúcia Ferreira | F | 1965-04-30 | 60 anos |
| pac_pedro@telecuidar.com | Pedro Costa | M | 1978-12-12 | 47 anos |

### Consultas POC
- **Total**: ~70 consultas
- **Período**: Dezembro/2025 a Março/2026
- **Status**: Agendadas e Realizadas

---

## �️ PROTEÇÃO MÁXIMA CONTRA QUEBRAS (LIÇÃO APRENDIDA 05/02/2026)

> **Problema**: Sistema cai aleatoriamente → Restart leva 2 dias → 75% de overhead infraestrutura  
> **Solução**: Checkpoints automáticos + Restore em <2 minutos

### ⚡ INICIAR O SISTEMA (SEMPRE USE ISTO)
```powershell
cd c:\telecuidar
.\start.ps1
```
Faz tudo automaticamente:
- Mata processos das portas
- Verifica Git, Docker, PostgreSQL
- Inicia Frontend + Backend
- Valida autenticação
- Pronto em 30 segundos

### 💾 SALVAR ESTADO (Quando está funcionando)
```powershell
cd c:\telecuidar
.\checkpoint-create.ps1
```
Cria backup completo de:
- Código (git tag)
- Banco (dump PostgreSQL)
- Configurações (.env)

**Executar:** Toda manhã, antes de features grandes, antes de riscos

### ↩️ RESTAURAR (Quando quebra)
```powershell
cd c:\telecuidar
.\checkpoint-restore.ps1 -CheckpointDate 20260205_093000
```
Volta tudo em <2 minutos:
- Git checkout
- DROP + RESTORE banco
- Limpa cache
- Pronto!

**Documentação completa**: [PROTECAO-SISTEMA.md](PROTECAO-SISTEMA.md)

---

## 📝 POP - Procedimento Operacional Padrão (DESENVOLVIMENTO)

### 1️⃣ Iniciar Trabalho Diário
```bash
cd c:\telecuidar

# Usar script robusto de startup
.\start.ps1

# Verificar se código está atualizado
git pull origin main
```

### 2️⃣ Após Fazer Alterações no Código

#### Passo 1: Verificar Mudanças
```bash
git status
git diff --name-only
```

#### Passo 2: Testar Localmente (Frontend)
```bash
cd /opt/telecuidar/frontend
npm install --legacy-peer-deps  # Se necessário
npx ng build --configuration=production

# Verificar se não há erros de compilação
```

#### Passo 3: Commit
```bash
cd /opt/telecuidar
git add .
git commit -m "Descrição clara da alteração"

# Exemplos de boas mensagens:
# feat: Adiciona exibição de Sexo e Idade na tela de sinais vitais
# fix: Corrige erro de conexão SignalR
# refactor: Reorganiza componentes de teleconsulta
```

#### Passo 4: Push
```bash
git push origin main
# ou
git push novocuidar main

# Se der erro de autenticação, verifique o token no .git/config
# O token já está configurado no remote local
```

### 3️⃣ Deploy em Produção

#### ⚠️ NÃO USAR deploy.sh para atualização!
O script `deploy.sh` clona o repositório ANTIGO e **apaga todo o trabalho local**.

#### Procedimento Correto de Deploy:

```bash
cd /opt/telecuidar

# 1. BACKUP do banco de dados ANTES de qualquer coisa
docker cp telecuidar-backend:/app/data/telecuidar.db /opt/telecuidar/backend/WebAPI/telecuidar.db
echo "Backup do banco realizado em $(date)" >> /opt/telecuidar/backups/backup.log

# 2. Reconstruir o Frontend
docker compose build frontend --no-cache

# 3. Reconstruir o Backend (se houve mudanças)
docker compose build backend --no-cache

# 4. Reiniciar os containers
docker compose up -d frontend backend

# 5. Aguardar containers ficarem healthy
sleep 15
docker compose ps

# 6. Verificar se está funcionando
curl -s https://www.telecuidar.com.br/api/health | jq '.'

# 7. Verificar logs por erros
docker logs telecuidar-backend --tail=20
docker logs telecuidar-frontend --tail=20
```

### 4️⃣ Rollback em Caso de Problema

```bash
# Se algo der errado após deploy:

# 1. Verificar logs do backend
docker logs telecuidar-backend --tail=50

# 2. Se o problema é no banco - restaurar backup anterior
# (mantenha sempre o último backup funcional em /opt/telecuidar/)
docker compose stop backend
docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'DROP DATABASE IF EXISTS telecuidar;'
docker exec telecuidar-postgres psql -U telecuidar -d postgres -c 'CREATE DATABASE telecuidar;'
docker cp /opt/telecuidar/backup_anterior.sql telecuidar-postgres:/tmp/backup.sql
docker exec telecuidar-postgres psql -U telecuidar -d telecuidar -f /tmp/backup.sql
docker compose up -d backend

# 3. Se precisar voltar código:
git log --oneline -5  # Ver últimos commits
git revert HEAD       # Reverter último commit
git push origin main
docker compose build backend frontend --no-cache
docker compose up -d
```

---

## 🔧 Variáveis de Ambiente Importantes

### Arquivo .env
```bash
# POC Seeder - Manter TRUE para ambiente de POC
POC_SEED_ENABLED=true

# Outras configurações importantes no .env:
# - JWT_SECRET
# - DATABASE_PATH=/app/data/telecuidar.db
# - JITSI_APP_ID
# - JITSI_APP_SECRET
```

---

## 🎥 JITSI - Remoção da Watermark (SOLUÇÃO DEFINITIVA)

### ⚠️ IMPORTANTE - Não perder esta configuração!

A watermark do Jitsi foi removida através de arquivos customizados montados no container.
**NÃO REMOVER** os seguintes arquivos do repositório:

### Arquivos Críticos
| Arquivo | Função |
|---------|--------|
| `jitsi-config/head.html` | CSS injetado no Jitsi para ocultar watermark via display:none |
| `jitsi-config/custom/custom-interface_config.js` | Configurações que desabilitam watermark server-side |

### Como Funciona
1. O `docker-compose.yml` monta esses arquivos no container `telecuidar-jitsi-web`
2. O `head.html` é carregado pelo Jitsi e injeta CSS que oculta a watermark
3. O `custom-interface_config.js` define `SHOW_JITSI_WATERMARK: false`

### Volumes no docker-compose.yml (NÃO REMOVER!)
```yaml
jitsi-web:
  volumes:
    # ... outros volumes ...
    # Customizações TeleCuidar - Remove watermark
    - ./jitsi-config/head.html:/usr/share/jitsi-meet/head.html:ro
    - ./jitsi-config/custom/custom-interface_config.js:/defaults/interface_config.js:ro
```

### Se a Watermark Voltar a Aparecer
1. Verificar se os arquivos estão no repositório:
   ```bash
   ls -la jitsi-config/head.html
   ls -la jitsi-config/custom/custom-interface_config.js
   ```

2. Verificar se estão montados no container:
   ```bash
   docker exec telecuidar-jitsi-web cat /usr/share/jitsi-meet/head.html | head -5
   ```

3. Reiniciar o container Jitsi:
   ```bash
   docker compose restart jitsi-web
   ```

4. Limpar cache do navegador (Ctrl+Shift+Delete)

---

## ❌ O QUE NÃO FAZER (LIÇÕES APRENDIDAS)

1. **NÃO executar `./deploy.sh`** - Ele clona o repositório antigo e apaga tudo

2. **NÃO confiar que "MigrateAsync" vai funcionar em produção**
   - Migrações EF podem falhar silenciosamente
   - SEMPRE copie o banco de homologação para produção

3. **NÃO fazer deploy sem verificar arquivos ignorados**
   ```powershell
   # ANTES de cada commit, verifique:
   git status --ignored --porcelain | Select-String "backend/|frontend/src/"
   ```

4. **NÃO remover volumes Docker sem backup**:
   ```bash
   # ERRADO - NUNCA fazer isso sem backup:
   docker volume rm telecuidar-postgres-data
   ```

5. **NÃO fazer push para o repositório errado**:
   ```bash
   # ERRADO:
   git push origin main  # Se origin for guilhermevieirao/telecuidar
   ```

6. **NÃO usar npm install sem --legacy-peer-deps** no frontend

7. **NÃO confiar que Docker "isola tudo"**
   - Diferenças de encoding (UTF-8 vs UTF-16) quebram imports de banco
   - Diferenças de usuários PostgreSQL (postgres vs telecuidar) causam erros
   - Connection strings devem ser EXATAMENTE iguais

8. **NÃO tentar "sincronizar schema" manualmente**
   - Se o banco de homologação funciona, COPIE ele inteiro
   - Não tente aplicar migrações individualmente

---

## ✅ PROCEDIMENTO CORRETO DE DEPLOY (ATUALIZADO 05/02/2026)

### 🚀 Método Recomendado (1 comando)

```powershell
cd C:\telecuidar
.\deploy-vps.ps1
```

O script faz **TUDO** automaticamente:
1. Verifica se localhost está funcionando
2. Exporta banco local (com schema correto)
3. Commit/push se necessário
4. Envia backup para VPS
5. Executa ./deploy.sh na VPS (restore banco + rebuild)
6. Valida que está funcionando em produção

### Pré-Requisitos
- Sistema funcionando 100% em homologação local
- Docker Desktop rodando (para PostgreSQL)
- Credenciais SSH configuradas para root@telecuidar.com.br

### Scripts na VPS (criados 05/02/2026)
| Script | Descrição |
|--------|-----------|
| `/opt/telecuidar/deploy.sh` | Deploy completo (git pull + restore + build + up) |
| `/opt/telecuidar/restore-db.sh` | Somente restore de banco |

### Se Deploy Falhar

```bash
# Ver logs do backend
ssh root@telecuidar.com.br "docker logs telecuidar-backend --tail=50"

# Reexecutar deploy
ssh root@telecuidar.com.br "cd /opt/telecuidar && ./deploy.sh"

# Só restaurar banco (se erro de schema)
ssh root@telecuidar.com.br "cd /opt/telecuidar && ./restore-db.sh"
```

### ⚠️ LIÇÃO APRENDIDA (05/02/2026)

**Problema:** Deploy falha com `column xxx does not exist`

**Causa:** EF Core migrations rodam no local mas não na VPS (Windows CRLF corrompe comandos SSH).

**Solução:** O script `deploy-vps.ps1` copia o banco inteiro do local para VPS, garantindo schema igual. Scripts bash ficam NA VPS para evitar problemas de encoding.

---

## ✅ POP - Rodar Sistema Localmente (SEM ERROS)

### 🚀 Método Rápido (RECOMENDADO)

**Duplo-clique em**: `C:\telecuidar\start-local.bat`

Isso vai:
1. ✅ Matar todos processos nas portas (4200, 5239, 8443, 3000)
2. ✅ Iniciar PostgreSQL local (Docker)
3. ✅ Limpar cache do Angular
4. ✅ Regenerar arquivos de environment
5. ✅ Fazer build verificação do backend
6. ✅ Iniciar Frontend HTTPS na 4200
7. ✅ Iniciar Backend (HTTP 5239 + HTTPS 7121)
8. ✅ Abrir automaticamente https://localhost:4200/

**Credenciais:**
- Email: `med_gt@telecuidar.com`
- Senha: `123`

### 🔧 Método Manual (se o .bat não funcionar)

```powershell
# Terminal PowerShell como Admin em C:\telecuidar

# 1. Matar processos nas portas
Get-NetTCPConnection -LocalPort 4200 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
Get-NetTCPConnection -LocalPort 5239 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
Get-NetTCPConnection -LocalPort 8443 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# 2. Limpar cache
Remove-Item -Path "C:\telecuidar\frontend\.angular" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Regenerar environment
cd C:\telecuidar\frontend
node scripts\generate-env.js
cd C:\telecuidar

# 4. Frontend (Terminal 1)
cd C:\telecuidar\frontend
ng serve --host 0.0.0.0 --port 4200 --ssl --disable-host-check

# 5. Backend (Terminal 2)
cd C:\telecuidar
dotnet run --project backend/WebAPI/WebAPI.csproj

# 6. Abrir navegador
https://localhost:4200/
```

### ❌ Troubleshooting

| Problema | Solução |
|----------|---------|
| Porta já em uso | Rodar `start-local.bat` novamente (mata processos) |
| "Mixed content" no HTTPS | Regenerar environment: `cd frontend && node scripts\generate-env.js` |
| Docker não inicia | Abrir Docker Desktop e rodar novamente |
| Backend não responde | Verificar: `Invoke-WebRequest https://localhost:7121/Health` |
| Frontend branco | Acessar via https://localhost:4200 e aceitar certificado |
| Erro de build | `dotnet clean backend/WebAPI/WebAPI.csproj` antes de rodar |
| Porta 5239 ocupada após crash | `Get-Process | Where {$_.ProcessName -match "dotnet"} | Stop-Process -Force` |

---

## ✅ Checklist Pré-Deploy

- [ ] Sistema testado e funcionando em homologação local
- [ ] Verificar arquivos ignorados: `git status --ignored --porcelain`
- [ ] Build backend OK: `dotnet build backend/WebAPI/WebAPI.csproj`
- [ ] Build frontend OK: `npx ng build --configuration=production`
- [ ] Commit feito com mensagem descritiva
- [ ] Push para `amantino69/novocuidar`
- [ ] Banco PostgreSQL exportado do local
- [ ] Banco importado na VPS
- [ ] Containers reconstruídos: `docker compose build --no-cache`
- [ ] Containers iniciados: `docker compose up -d`
- [ ] Todos containers healthy: `docker compose ps`
- [ ] Teste manual no navegador: https://www.telecuidar.com.br

---

## 🏗️ Arquitetura de Componentes - ATENÇÃO!

### Aba "Sinais" na Teleconsulta
A aba "Sinais" na teleconsulta **NÃO** usa `biometrics-tab.html`.

A estrutura real é:
```
teleconsultation-sidebar.html
  └── Quando activeTab === 'Sinais'
      └── <app-medical-devices-tab>  (arquivo: medical-devices-tab.ts)
          ├── Para OPERADOR (Paciente/Assistente/Admin):
          │   └── <app-device-connection-panel>  ← ESTE é o componente correto!
          │       (arquivo: device-connection-panel.ts - template inline)
          └── Para MÉDICO (Professional):
              └── <app-vital-signs-panel>
                  (arquivo: vital-signs-panel.ts - template inline)
```

⚠️ **LIÇÃO APRENDIDA**: Sempre verificar qual componente está realmente sendo renderizado antes de editar. Use `grep_search` para encontrar onde os seletores são usados.

---

## 📞 Informações de Acesso

- **URL Produção**: https://www.telecuidar.com.br
- **URL Jitsi**: https://meet.telecuidar.com.br
- **API**: https://www.telecuidar.com.br/api

---

## 🧳 MALETA ITINERANTE - Dispositivos Médicos BLE

### Conceito
A maleta viaja para comunidades remotas onde não há médicos. Um técnico/enfermeiro leva a maleta e atende múltiplos pacientes por dia. O médico especialista atende via teleconsulta da capital.

### Arquitetura
```
┌─────────────────────────────────────────────────────────────┐
│                    MALETA TELEMEDICINA                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │ Computador  │ │   Monitor   │ │ Equipamentos Médicos    ││
│  │ Windows     │ │             │ │ • Omron HEM-7156T       ││
│  │             │ │             │ │ • Balança OKOK          ││
│  │ [maleta_    │ │ [Chrome]    │ │ • Termômetro MOBI       ││
│  │ itinerante  │ │ telecuidar  │ │                         ││
│  │ .py]        │ │ .com.br     │ │                         ││
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │ API: /api/biometrics/ble-reading   │ Bluetooth LE
         ▼                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                SERVIDOR PRODUÇÃO (VPS)                       │
│            https://www.telecuidar.com.br                     │
│                                                              │
│  ┌─────────────┐    SignalR     ┌─────────────────────────┐ │
│  │ BiometricsController ───────► MedicalDevicesHub        │ │
│  │ /ble-reading │               │ SendAsync("Biometrics   │ │
│  │ /active-appointment         │ Updated", dados)        │ │
│  └─────────────┘               └───────────┬─────────────┘ │
└────────────────────────────────────────────┼────────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────┐
                              │ Tela do Médico          │
                              │ (vital-signs-panel.ts)  │
                              │ Dados aparecem em       │
                              │ tempo real!             │
                              └─────────────────────────┘
```

### Dispositivos Suportados
| Dispositivo | MAC Address | Método | Status |
|-------------|-------------|--------|--------|
| Balança OKOK | F8:8F:C8:3A:B7:92 | Advertisement | ✅ Funcionando |
| Omron HEM-7156T | 00:5F:BF:9A:64:DF | GATT | ✅ Funcionando |
| Termômetro MOBI | DC:23:4E:DA:E9:DD | GATT | 🔧 Em teste |

### Scripts Principais
| Arquivo | Descrição |
|---------|-----------|
| `maleta/maleta_itinerante.py` | Script principal - detecta consulta ativa automaticamente |
| `maleta/Iniciar Maleta.bat` | Batch para iniciar o serviço (duplo-clique) |
| `ble_bridge.py` | Script manual com `--prod` para testes |

### APIs Backend (BiometricsController)
| Endpoint | Descrição |
|----------|-----------|
| `GET /api/biometrics/active-appointment` | Retorna consulta ativa (Status=InProgress) |
| `POST /api/biometrics/ble-reading` | Recebe leitura BLE e envia via SignalR |
| `POST /api/biometrics/ble-cache` | Cache temporário para botão "Capturar Sinais" |

### Fluxo de Dados (SignalR)
```
1. maleta_itinerante.py detecta dispositivo BLE
2. POST /api/biometrics/ble-reading { appointmentId, deviceType, values }
3. BiometricsController processa e salva no banco
4. MedicalDevicesHub.SendAsync("BiometricsUpdated", appointmentId, data)
5. Frontend (vital-signs-panel.ts) recebe via subscription
6. Dados aparecem na tela do médico em tempo real
```

---

## 🔐 SEGURANÇA - APIs e Sistemas Locais

### APIs que NÃO requerem autenticação (por design)
```
GET  /api/biometrics/active-appointment  → Retorna apenas ID da consulta ativa
POST /api/biometrics/ble-reading         → Requer appointmentId válido (GUID)
POST /api/biometrics/ble-cache           → Cache temporário por IP
GET  /api/health                         → Health check
```

⚠️ **ATENÇÃO**: Estas APIs são abertas para permitir que a maleta envie dados sem autenticação complexa. A segurança é garantida por:
1. **appointmentId** é um GUID aleatório - impossível adivinhar
2. Só funciona para consultas com status "Em Andamento"
3. Dados são validados antes de salvar

### APIs que REQUEREM autenticação (JWT)
- Todas as outras APIs do sistema
- Login, cadastro, consultas, prontuários, etc.

### Proteções Implementadas
1. **HTTPS obrigatório** em produção
2. **CORS configurado** para domínios permitidos
3. **Rate limiting** (implícito no Nginx)
4. **Validação de appointmentId** - deve existir e estar ativo

### Recomendações de Segurança Futuras
```csharp
// TODO: Adicionar no BiometricsController
// 1. Rate limiting por IP (máx 10 req/min)
// 2. Validar que appointmentId foi criado há menos de 24h
// 3. Log de todas as tentativas para auditoria
// 4. Whitelist de IPs das maletas (se IPs fixos)
```

---

## 🚐 CONFIGURAÇÃO DE NOVAS MALETAS

### Pré-requisitos no Computador da Maleta
- Windows 10/11
- Python 3.10+ instalado
- Bluetooth ativado
- Conexão com internet (4G ou WiFi)

### Passo 1: Baixar o Código
```powershell
# Criar pasta
mkdir C:\telecuidar
cd C:\telecuidar

# Clonar repositório (ou copiar via pendrive)
git clone https://github.com/amantino69/novocuidar.git .
```

### Passo 2: Instalar Dependências Python
```powershell
cd C:\telecuidar\maleta
pip install -r requirements.txt
```

Dependências necessárias:
- `bleak` - Biblioteca Bluetooth LE
- `aiohttp` - Requisições HTTP assíncronas

### Passo 3: Configurar MACs dos Dispositivos
Editar `C:\telecuidar\maleta\maleta_itinerante.py`:
```python
# Linha ~50 - Alterar MACs conforme dispositivos da maleta
DEVICES = {
    "F8:8F:C8:3A:B7:92": {  # ← MAC da balança DESTA maleta
        "type": "scale",
        "name": "Balança OKOK",
        ...
    },
    "00:5F:BF:9A:64:DF": {  # ← MAC do Omron DESTA maleta
        "type": "blood_pressure",
        ...
    }
}
```

### Passo 4: Descobrir MAC dos Dispositivos
```powershell
cd C:\telecuidar\maleta
python scan_devices.py
# Liga os dispositivos e anota os MACs que aparecem
```

### Passo 5: Criar Atalhos
```powershell
# Atalho no Desktop
$WScriptShell = New-Object -ComObject WScript.Shell
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$Shortcut = $WScriptShell.CreateShortcut("$DesktopPath\TeleCuidar Maleta.lnk")
$Shortcut.TargetPath = 'C:\telecuidar\maleta\Iniciar Maleta.bat'
$Shortcut.WorkingDirectory = 'C:\telecuidar\maleta'
$Shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,22'
$Shortcut.Save()

# Atalho na Inicialização (abre automaticamente com Windows)
$StartupPath = [Environment]::GetFolderPath('Startup')
$Shortcut2 = $WScriptShell.CreateShortcut("$StartupPath\TeleCuidar Maleta.lnk")
$Shortcut2.TargetPath = 'C:\telecuidar\maleta\Iniciar Maleta.bat'
$Shortcut2.WorkingDirectory = 'C:\telecuidar\maleta'
$Shortcut2.Save()
```

### Passo 6: Configurar Chrome para Modo Kiosk (Opcional)
Criar atalho na pasta Startup:
```
Destino: "C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk https://www.telecuidar.com.br
```

### Passo 7: Testar
1. Reiniciar o computador
2. Verificar se a janela azul "TeleCuidar Maleta" abre
3. Fazer login no telecuidar.com.br
4. Entrar numa teleconsulta
5. Fazer medição - dados devem aparecer na tela

### Checklist de Configuração de Nova Maleta
- [ ] Python instalado
- [ ] Dependências instaladas (`pip install -r requirements.txt`)
- [ ] MACs dos dispositivos configurados
- [ ] Atalho no Desktop criado
- [ ] Atalho na Inicialização criado
- [ ] Bluetooth ativado
- [ ] Teste de medição realizado com sucesso

---

## 📋 INVENTÁRIO DE MALETAS

| Município | MAC Balança | MAC Omron | MAC Termômetro | Status |
|-----------|-------------|-----------|----------------|--------|
| POC (Dev) | F8:8F:C8:3A:B7:92 | 00:5F:BF:9A:64:DF | DC:23:4E:DA:E9:DD | ✅ Ativo |
| Município 1 | A definir | A definir | A definir | ⏳ Pendente |
| Município 2 | A definir | A definir | A definir | ⏳ Pendente |

---

## 📅 Última Atualização
- **Data**: 06/02/2026
- **Autor**: IA Assistant
- **Motivo**: Lições aprendidas deploy 06/02 - encoding UTF8, frontend não subindo, WebRTC corrompendo áudio do estetoscópio
