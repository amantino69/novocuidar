# 🚀 TeleCuidar - Guia de Homologação com Docker

## 📋 Pré-requisitos

- ✅ Docker Desktop instalado (Windows/Mac) ou Docker Engine (Linux)
- ✅ Docker Compose v2.0+
- ✅ Mínimo 4GB RAM livre
- ✅ Portas disponíveis: 4000 (Frontend), 5000 (Backend), 5432 (PostgreSQL), 8443 (Jitsi)

## 🎯 Arquitetura de Homologação

```
┌─────────────────────────────────────────────────────────┐
│                   HOMOLOGAÇÃO LOCAL                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Frontend    │  │  Backend     │  │  PostgreSQL  │  │
│  │  :4000       │  │  :5000       │  │  :5432       │  │
│  │  Angular     │  │  .NET 8      │  │  Banco       │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│         └─────────────────┼─────────────────┘           │
│                           │                             │
│  ┌──────────────────────────────────────────────────┐  │
│  │          JITSI MEET (Videoconferência)          │  │
│  │  - Prosody (XMPP)                               │  │
│  │  - Jicofo (Conference Focus)                    │  │
│  │  - JVB (Videobridge)                            │  │
│  │  - Web (Interface)                              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Iniciando a Homologação

### Windows (Recomendado)

1. **Abra o PowerShell ou CMD na pasta do projeto:**
   ```powershell
   cd C:\telecuidar
   ```

2. **Execute o script de inicialização:**
   ```powershell
   .\start-staging.bat
   ```

3. **Aguarde ~2-3 minutos** para todos os containers ficarem prontos

### Linux/Mac

```bash
cd /path/to/telecuidar
chmod +x start-staging.sh
./start-staging.sh
```

### Manual (Qualquer SO)

```bash
# Carregar variáveis de ambiente
export $(cat .env.staging | xargs)

# Construir imagens
docker-compose -f docker-compose.staging.yml build

# Iniciar containers
docker-compose -f docker-compose.staging.yml up -d

# Verificar status
docker-compose -f docker-compose.staging.yml ps
```

## 📍 URLs de Acesso

| Serviço | URL | Usuário | Senha |
|---------|-----|---------|-------|
| Frontend | http://localhost:4000 | - | - |
| Backend API | http://localhost:5000 | - | - |
| Swagger API Docs | http://localhost:5000/swagger/index.html | - | - |
| Jitsi Web | https://localhost:8443 | - | - |
| PostgreSQL | localhost:5432 | postgres | postgres |

## 🔑 Credenciais de Teste (Senha: 123)

### Médicos
- **Geraldo Tadeu** (Cardiologista)
  - Email: `gt@telecuidar.com`
  - Especialidade: Cardiologia

- **Antonio Jorge** (Psiquiatra)
  - Email: `aj@telecuidar.com`
  - Especialidade: Psiquiatria

### Assistente/Enfermeira
- **Danila Ochoa**
  - Email: `do@telecuidar.com`

### Paciente
- **Daniel Carrara**
  - Email: `dc@telecuidar.com`
  - Consultas agendadas com ambos os médicos

### Administrador
- **Claudio Amantino**
  - Email: `ca@telecuidar.com`

## 📊 Dados de Teste Carregados

- ✅ 2 Médicos com especialidades
- ✅ 1 Assistente/Enfermeira
- ✅ 1 Paciente
- ✅ 1 Administrador
- ✅ 40 Consultas agendadas (20 por médico) - Status: Confirmadas
- ✅ Todas as especialidades do sistema
- ✅ Conselhos profissionais (CRM)

## 🔍 Verificando Status

```bash
# Ver todos os containers
docker-compose -f docker-compose.staging.yml ps

# Ver logs de um serviço específico
docker-compose -f docker-compose.staging.yml logs -f backend
docker-compose -f docker-compose.staging.yml logs -f frontend
docker-compose -f docker-compose.staging.yml logs -f postgres

# Verificar saúde do backend
curl http://localhost:5000/health

# Conectar ao banco PostgreSQL
docker-compose -f docker-compose.staging.yml exec postgres psql -U postgres -d telecuidar
```

## 🧪 Fluxo de Teste Recomendado

### 1. Teste de Login
1. Acesse http://localhost:4000
2. Faça login com `gt@telecuidar.com` / `123` (Médico)
3. Verifique se a dashboard carrega corretamente

### 2. Teste de Consultas
1. Navegue para "Consultas"
2. Verifique se as 20 consultas de Daniel aparecem
3. Clique em uma consulta para abrir os detalhes

### 3. Teste de Videochamada (Jitsi)
1. Inicie uma teleconsulta
2. Verifique se o Jitsi abre em https://localhost:8443
3. Teste câmera e microfone
4. Verifique qualidade da transmissão

### 4. Teste de Sinais Vitais (se houver maleta)
1. Deixe a maleta rodando
2. Inicie uma teleconsulta ativa
3. Verifique se os sinais vitais aparecem em tempo real

### 5. Teste de Relórios
1. Acesse "Relatórios" (se houver)
2. Verifique se os gráficos carregam corretamente

## 🛠️ Operações Comuns

### Parar a Homologação
```bash
docker-compose -f docker-compose.staging.yml down
```

### Reiniciar um Serviço
```bash
docker-compose -f docker-compose.staging.yml restart backend
```

### Limpar Dados e Reiniciar
```bash
docker-compose -f docker-compose.staging.yml down -v
docker-compose -f docker-compose.staging.yml up -d
```

### Acessar Banco de Dados
```bash
docker-compose -f docker-compose.staging.yml exec postgres psql -U postgres -d telecuidar

# Dentro do psql:
\dt                    -- Listar tabelas
SELECT COUNT(*) FROM "Users";  -- Ver usuários
SELECT COUNT(*) FROM "Appointments";  -- Ver consultas
\q                     -- Sair
```

### Ver Variáveis de Ambiente do Backend
```bash
docker-compose -f docker-compose.staging.yml exec backend printenv | grep -E "DATABASE|JWT|JITSI"
```

## 🔐 Segurança em Homologação

⚠️ **IMPORTANTE**: As credenciais abaixo são APENAS para teste local:
- Senha padrão do PostgreSQL: `postgres`
- JWT Secret: Genérico e inseguro
- Jitsi Secret: Conhecido

**Em Produção:**
- ✅ Use senhas fortes e únicas
- ✅ Configure SSL/TLS com certificados válidos
- ✅ Use variáveis de ambiente seguras (secrets)
- ✅ Ative autenticação JWT no Jitsi
- ✅ Configure CORS restritivo

## 🐛 Troubleshooting

### Porta já em uso
```bash
# Ver qual processo está usando a porta
lsof -i :4000  # Linux/Mac
netstat -ano | findstr :4000  # Windows

# Mudar porta no docker-compose.staging.yml
# Exemplo: 4001:4000 (porta externa:interna)
```

### Container não inicia
```bash
# Ver logs de erro
docker-compose -f docker-compose.staging.yml logs backend

# Reconstruir imagem
docker-compose -f docker-compose.staging.yml build --no-cache backend
```

### PostgreSQL não conecta
```bash
# Verificar se está pronto
docker-compose -f docker-compose.staging.yml exec postgres pg_isready -U postgres

# Verificar logs
docker-compose -f docker-compose.staging.yml logs postgres
```

### Frontend não carrega
```bash
# Verificar logs
docker-compose -f docker-compose.staging.yml logs frontend

# Verificar se backend está respondendo
curl http://localhost:5000/health
```

## 📝 Logs e Debugging

### Ver logs em tempo real
```bash
# Todos os serviços
docker-compose -f docker-compose.staging.yml logs -f

# Filtrar por serviço
docker-compose -f docker-compose.staging.yml logs -f backend --tail=50

# Buscar por erro
docker-compose -f docker-compose.staging.yml logs | grep -i error
```

### Acessar container interativamente
```bash
# Terminal do Backend
docker-compose -f docker-compose.staging.yml exec backend /bin/bash

# Terminal do Frontend
docker-compose -f docker-compose.staging.yml exec frontend /bin/sh

# Terminal do PostgreSQL
docker-compose -f docker-compose.staging.yml exec postgres bash
```

## 🚀 Próximos Passos (Produção)

1. **Configurar domínio DNS real**
   - Frontend: www.telecuidar.com.br
   - Backend: api.telecuidar.com.br
   - Jitsi: meet.telecuidar.com.br

2. **Obter certificados SSL válidos**
   - Let's Encrypt + Certbot
   - Nginx como proxy reverso

3. **Configurar backups automáticos**
   - PostgreSQL: pg_dump diário
   - Volumes: rsync/restic

4. **Monitoramento e Logs**
   - ELK Stack (Elasticsearch, Logstash, Kibana)
   - Prometheus + Grafana

5. **Performance**
   - CDN para assets estáticos
   - Cache Redis para sessões
   - Load balancer se múltiplas instâncias

## 📞 Suporte

Para problemas ou dúvidas sobre homologação:
1. Verifique os logs com `docker-compose -f docker-compose.staging.yml logs`
2. Consulte este guia na seção Troubleshooting
3. Verifique a documentação de cada serviço

---

**Última atualização:** 01/02/2026
**Versão:** 1.0
