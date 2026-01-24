# Dados POC TeleCuidar

## Credenciais de Acesso

**Senha padrão para todos os usuários: `123`**

### Administrador
| Email | Nome | Papel |
|-------|------|-------|
| adm_ca@telecuidar.com | Cláudio Amantino | Admin |

### Médicos
| Email | Nome | Especialidade |
|-------|------|---------------|
| med_aj@telecuidar.com | Dr. Antônio Jorge | Psiquiatria |
| med_gt@telecuidar.com | Dr. Geraldo Tadeu | Cardiologia |

### Assistente
| Email | Nome | Papel |
|-------|------|-------|
| enf_do@telecuidar.com | Daniela Ochoa | Assistente |

### Pacientes
| Email | Nome |
|-------|------|
| pac_dc@telecuidar.com | Daniel Carrara |
| pac_maria@telecuidar.com | Maria Silva |
| pac_joao@telecuidar.com | João Santos |
| pac_ana@telecuidar.com | Ana Oliveira |
| pac_pedro@telecuidar.com | Pedro Costa |
| pac_lucia@telecuidar.com | Lúcia Ferreira |

## Especialidades
- **Cardiologia** - Dr. Geraldo Tadeu
- **Psiquiatria** - Dr. Antônio Jorge
- **Clínica Geral** - (disponível para novos médicos)

## Consultas

### Realizadas (30 consultas)
- Período: Dezembro 2025 a Janeiro 2026
- Todas com dados clínicos completos:
  - ✅ **Sinais Vitais (BiometricsJson)**: PA, FC, FR, SatO2, Temperatura, Glicose, Peso, Altura
  - ✅ **Anamnese completa (AnamnesisJson)**: Queixa principal, HDA, antecedentes, medicamentos, alergias
  - ✅ **SOAP completo (SoapJson)**: Subjetivo, Objetivo, Avaliação, Plano
  - ✅ **23 Anexos**: ECGs, Holter, exames laboratoriais, receituários, laudos
- Distribuídas entre os 6 pacientes e 2 médicos

### Agendadas (40 consultas)
- Período: Fevereiro e Março de 2026
- Distribuídas de forma uniforme entre pacientes e médicos

## 📊 Dados Clínicos por Paciente

### Daniel Carrara
- **Perfil**: Jovem saudável com ansiedade
- **Sinais Vitais**: PA normal (120-130/78-85), FC 68-88 bpm
- **Consultas**: 6 realizadas (cardio + psiquiatria)
- **Anexos**: ECG, Holter, Receituário escitalopram

### Maria Silva (73 anos)
- **Perfil**: Hipertensa idosa
- **Sinais Vitais**: PA 125-145/78-92, FC 68-78 bpm
- **Consultas**: 5 realizadas (cardio)
- **Anexos**: Exames laboratoriais, perfil lipídico, receituário anti-hipertensivos

### João Santos
- **Perfil**: Transtorno de pânico
- **Sinais Vitais**: PA 118-140/72-90, FC 68-98 bpm (variação por ansiedade)
- **Consultas**: 5 realizadas (psiquiatria + cardio)
- **Anexos**: Receituário B (sertralina/clonazepam), escalas PHQ-9/GAD-7, atestado academia

### Ana Oliveira
- **Perfil**: Gestante 20 semanas
- **Sinais Vitais**: PA normal (108-112/68-72), FC 82-90 bpm
- **Consultas**: 4 realizadas (cardio + psiquiatria)
- **Anexos**: Ecocardiograma, ECG gestacional, laudo aptidão cardíaca

### Pedro Costa
- **Perfil**: Diabético tipo 2 + HAS
- **Sinais Vitais**: PA 124-142/78-90, Glicose 118-156
- **Consultas**: 5 realizadas (cardio + psiquiatria)
- **Anexos**: HbA1c, perfil lipídico, função renal, ECG/Eco, receituário DM/HAS

### Lúcia Ferreira (60 anos)
- **Perfil**: Depressão grave (viúva há 1 ano)
- **Sinais Vitais**: PA 122-130/76-82, FC 68-86 bpm
- **Consultas**: 5 realizadas (psiquiatria + cardio)
- **Anexos**: Escalas depressão (PHQ-9, HAM-D, Beck), receituário B (mirtazapina), TSH/hemograma

## Cenários de Demonstração

### 1. Fluxo do Médico
- Login: `med_aj@telecuidar.com` / `123`
- Ver agenda do dia
- Acessar histórico de consultas
- Iniciar teleconsulta

### 2. Fluxo do Paciente
- Login: `pac_dc@telecuidar.com` / `123`
- Ver suas consultas agendadas
- Acessar histórico médico
- Participar de teleconsulta

### 3. Fluxo do Administrador
- Login: `adm_ca@telecuidar.com` / `123`
- Gerenciar usuários
- Ver relatórios
- Gerenciar especialidades

### 4. Fluxo do Assistente
- Login: `enf_do@telecuidar.com` / `123`
- Agendar consultas
- Gerenciar pacientes

## Script de Reset

Para restaurar a base POC do zero:

```bash
# Parar o backend
docker stop telecuidar-backend

# Fazer backup do banco atual
cp /var/lib/docker/volumes/telecuidar-backend-data/_data/telecuidar.db /tmp/backup_$(date +%Y%m%d_%H%M%S).db

# Copiar base POC consolidada
sudo cp /tmp/telecuidar_poc_v4.db /var/lib/docker/volumes/telecuidar-backend-data/_data/telecuidar.db
sudo chown 1655:1655 /var/lib/docker/volumes/telecuidar-backend-data/_data/telecuidar.db
sudo chmod 664 /var/lib/docker/volumes/telecuidar-backend-data/_data/telecuidar.db

# Reiniciar backend
docker start telecuidar-backend
```

### Scripts SQL de Referência

Os scripts SQL que geraram a base POC estão em:
- `/opt/telecuidar/scripts/poc-seed-final.sql` - Usuários, consultas, especialidades
- `/opt/telecuidar/scripts/poc-biometrics.sql` - Sinais vitais e anamneses detalhadas
- `/opt/telecuidar/scripts/poc-attachments.sql` - Anexos (exames, receitas, laudos)

## Backup

O backup do banco POC consolidado está em:
- `/tmp/telecuidar_poc_v4.db` (versão final com todos os dados)
- `/tmp/telecuidar_backup_20260124_162256.db` (banco original antes da POC)
