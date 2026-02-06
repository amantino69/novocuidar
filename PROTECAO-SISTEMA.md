# 🛡️ GUIA DE PROTEÇÃO - Sistema TeleCuidar POC

> **Status**: Sistema operacional (05/02/2026)  
> **Última proteção**: [Execute checkpoint-create.ps1 para atualizar]  
> **Objetivo**: Voltar ao estado funcionando em <2 minutos

---

## 🎯 LIÇÃO APRENDIDA - 75% de Overhead

```
[Problema Original]
Sistema cai → Tenta restart → Erros de migração
Tenta restart → Erros de arquivo → Falta .gitignore
Tenta restart → Banco corrompido → Semana perdida

[Solução Implementada]
Sistema cai → Execute: .\checkpoint-restore.ps1 -CheckpointDate YYYYMMDD_HHMMSS
           ↓
Sistema Online em <2 minutos
```

---

## 📁 Estrutura de Proteção

```
c:\telecuidar\
├── start.ps1                          [Startup robusto - sempre usar este]
├── checkpoint-create.ps1              [Salvar estado - executar quando está OK]
├── checkpoint-restore.ps1             [Restaurar - executar quando quebra]
└── .checkpoints\
    ├── checkpoint_20260205_093000\
    │   ├── banco.sql                 [Dump completo PostgreSQL]
    │   ├── .env                      [Variáveis de ambiente]
    │   ├── README.txt                [Como restaurar]
    │   └── docker-status.txt         [Estado dos containers]
    │
    └── checkpoint_20260205_093500\
        ├── banco.sql
        ├── .env
        └── ...
```

---

## 🚀 PROCEDIMENTO PADRÃO DE USO

### 1️⃣ INICIAR O SISTEMA (DIÁRIO)

```powershell
cd c:\telecuidar
.\start.ps1
```

**O que faz:**
- ✅ Mata processos das portas (4200, 5239, 8443)
- ✅ Verifica Git (avisa se há mudanças)
- ✅ Verifica Docker e PostgreSQL
- ✅ Verifica .gitignore (evita arquivos ignorados)
- ✅ Inicia Frontend + Backend em paralelo
- ✅ Aguarda inicialização (20 segundos)
- ✅ Valida ports (netstat)
- ✅ Testa autenticação
- ✅ Pronto para trabalhar!

---

### 2️⃣ QUANDO ESTÁ FUNCIONANDO - SALVAR CHECKPOINT

```powershell
cd c:\telecuidar
.\checkpoint-create.ps1
```

**Recomendações:**
- ✅ Executar toda manhã ao começar a trabalhar
- ✅ Executar após features grandes implementadas
- ✅ Executar antes de fazer mudanças arriscadas
- ✅ Executar quando o banco recebe muitos dados novos

**Tempo**: ~30 segundos

---

### 3️⃣ SISTEMA QUEBROU? - RESTAURAR IMEDIATAMENTE

```powershell
cd c:\telecuidar
.\checkpoint-restore.ps1 -CheckpointDate 20260205_093000
```

**O que faz:**
- ✅ Mata todos os processos (Node, .NET, cmd)
- ✅ Volta código para o commit anterior (git checkout)
- ✅ Restaura banco de dados (DROP + RESTORE)
- ✅ Restaura configurações (.env)
- ✅ Limpa cache (node_modules, bin, obj)
- ✅ Valida integridade do banco

**Tempo**: ~1-2 minutos

---

## 🔍 VERIFICAR CHECKPOINTS DISPONÍVEIS

```powershell
Get-ChildItem "c:\telecuidar\.checkpoints" -Directory | 
    Sort-Object CreationTime -Descending | 
    Select-Object -First 10 | 
    ForEach-Object { ".\checkpoint-restore.ps1 -CheckpointDate $($_.Name -replace 'checkpoint_')" }
```

---

## ⚠️ SINAIS DE PERIGO - NÃO PROSSIGA

| Sinal | Ação |
|-------|------|
| ❌ Git mostra mudanças não commitadas | `git add -A && git commit -m "...message..."` |
| ❌ .gitignore contém arquivos .cs ou .ts importantes | Faça `git add -f arquivo.cs` |
| ❌ Porta 4200/5239 já está em uso | `.\start.ps1` resolve automaticamente |
| ❌ PostgreSQL não inicia | `docker start telecuidar-postgres` |
| ❌ Erro de migração no startup | `.\checkpoint-restore.ps1 -CheckpointDate [última]` |

---

## 📋 REGRA DE OURO - O QUE FAZER

### ✅ SIM
```powershell
# Toda manhã
.\start.ps1

# Quando está funcionando
.\checkpoint-create.ps1

# Se quebrou
.\checkpoint-restore.ps1 -CheckpointDate 20260205_093000

# Antes de commit
git add -A
git commit -m "feat: Descrição clara"
git push origin main
```

### ❌ NÃO
```powershell
# Não rodar banco de dados manualmente
# Não dropar volumes sem backup
# Não ignorar avisos de .gitignore
# Não tentar "consertar" migrações
# Não fazer git reset --hard sem checkpoint
```

---

## 🧪 TESTE DE SISTEMA APÓS RESTORE

```powershell
# Verificar banco
docker exec telecuidar-postgres psql -U postgres -d telecuidar -c "SELECT COUNT(*) FROM \"Users\";"
docker exec telecuidar-postgres psql -U postgres -d telecuidar -c "SELECT COUNT(*) FROM \"Appointments\";"

# Verificar ports
netstat -ano | findstr "LISTENING" | findstr ":4200 :5239"

# Verificar autenticação
Invoke-WebRequest -Uri "http://localhost:5239/api/auth/login" -Method POST `
    -Body '{"email":"med_gt@telecuidar.com","password":"123"}' `
    -ContentType "application/json" -UseBasicParsing
```

---

## 📊 CHECKPOINTS AUTOMÁTICOS

Considerando adicionar tags Git automáticas:

```powershell
# Diariamente às 9h
$trigger = New-JobTrigger -Daily -At 9:00am
Register-ScheduledJob -Trigger $trigger -FilePath "c:\telecuidar\checkpoint-create.ps1" -Name "TeleCuidarCheckpoint"

# Verificar jobs
Get-ScheduledJob | Where-Object { $_.Name -match "TeleCuidar" }
```

---

## 🆘 EMERGÊNCIA - ROLLBACK MANUAL

Se os scripts falharem:

```powershell
# 1. Matar tudo
Get-Process | Where-Object { $_.ProcessName -match "dotnet|ng|node|cmd" } | Stop-Process -Force

# 2. Voltar código
git checkout HEAD~1

# 3. Limpar cache
Remove-Item -Path "c:\telecuidar\frontend\.angular" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "c:\telecuidar\backend\WebAPI\bin" -Recurse -Force
Remove-Item -Path "c:\telecuidar\backend\WebAPI\obj" -Recurse -Force

# 4. Dropar + Restaurar banco manualmente
docker exec telecuidar-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS telecuidar CASCADE;"
docker exec telecuidar-postgres psql -U postgres -d postgres -c "CREATE DATABASE telecuidar;"
docker cp "c:\telecuidar\.checkpoints\checkpoint_20260205_093000\banco.sql" telecuidar-postgres:/tmp/banco.sql
docker exec telecuidar-postgres psql -U postgres -d telecuidar -f /tmp/banco.sql

# 5. Restart
.\start.ps1
```

---

## 📈 MÉTRICAS DE SUCESSO

**Antes (2 dias perdidos):**
- Tempo para restart: 2-4 horas
- Taxa de sucesso: 10% (precisa fazer rollback)
- Retrabalho: 75% do tempo

**Depois (com checkpoints):**
- Tempo para restart: <2 minutos
- Taxa de sucesso: 95%+ (automated restore)
- Desenvolvimento: 95% do tempo

---

## 🔐 PROTEÇÃO DE DADOS CRÍTICOS

### Arquivos que NUNCA devem ser ignorados
```
backend/WebAPI/Program.cs
backend/WebAPI/appsettings.*.json
backend/Domain/Entities/Appointment.cs
backend/Domain/Enums/AppointmentEnums.cs
backend/WebAPI/Hubs/TeleconsultationHub.cs
frontend/src/app/services/*.ts
frontend/src/environments/*.ts
.env (NÃO está no repo, salvo em checkpoints)
```

### Verificar antes de cada commit
```powershell
# Listar arquivos que serão commitados
git diff --cached --name-only

# Se faltar algo importante, adicionar:
git add -f backend/WebAPI/Program.cs
```

---

## � DEPLOY PARA PRODUÇÃO (VPS)

### Pré-requisitos
- ✅ Sistema funcionando no localhost (testar login)
- ✅ Código commitado e push feito

### Comando de Deploy (1 linha)
```powershell
cd C:\telecuidar
.\deploy-vps.ps1
```

**O script faz tudo automaticamente:**
1. Verifica se localhost está funcionando
2. Exporta banco local (com schema correto)
3. Commit/push se necessário
4. Envia backup para VPS
5. Executa ./deploy.sh na VPS (restore banco + rebuild)
6. Valida que está funcionando

### Scripts na VPS (criados em 05/02/2026)
| Script | Comando | Uso |
|--------|---------|-----|
| `/opt/telecuidar/deploy.sh` | `./deploy.sh` | Deploy completo |
| `/opt/telecuidar/restore-db.sh` | `./restore-db.sh` | Só restore de banco |

### Se Deploy Falhar

**1. Ver logs do backend:**
```bash
ssh root@telecuidar.com.br "docker logs telecuidar-backend --tail=50"
```

**2. Reexecutar deploy manualmente:**
```bash
ssh root@telecuidar.com.br "cd /opt/telecuidar && ./deploy.sh"
```

**3. Se erro de schema (coluna faltando):**
```bash
# Forçar restore do banco local
ssh root@telecuidar.com.br "cd /opt/telecuidar && ./restore-db.sh"
```

### ⚠️ LIÇÃO APRENDIDA (05/02/2026)

**Problema comum:** `column xxx does not exist` na produção

**Causa:** EF Core migrations rodam no local mas não na VPS.

**Solução definitiva:** O script `deploy-vps.ps1` SEMPRE copia o banco local inteiro para a VPS, garantindo que o schema está igual.

---

## �📞 CHECKLIST - ANTES DE DORMIR

- [ ] Sistema está funcionando
- [ ] Checkpoint criado: `.\checkpoint-create.ps1`
- [ ] Código commitado: `git add -A && git commit -m "..."`
- [ ] Push feito: `git push origin main`
- [ ] Última checkpoint salvado em `c:\telecuidar\.checkpoints\`

---

## 🎓 LIÇÃO FINAL

> **"Antes: 75% infraestrutura, 25% desenvolvimento"**  
> **"Depois: 95% desenvolvimento, 5% proteção"**

Os 5 minutos por dia criando checkpoint = 2 dias não perdidos na próxima quebra.

**Vale muito a pena!** 💾✨
