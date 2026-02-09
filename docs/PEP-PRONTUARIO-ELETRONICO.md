# 📋 PEP - Prontuário Eletrônico do Paciente

## 🎯 Visão Geral

O PEP do TeleCuidar é um repositório organizado de toda a vida clínica do paciente, acessível pelo médico durante a teleconsulta. Baseado nas melhores práticas do CFM (Resolução 1.638/2002) e padrões internacionais (IOM).

### Princípios
1. **Longitudinal**: Toda a vida do paciente em um lugar
2. **Estruturado**: Dados padronizados para análise e pesquisa
3. **Visual**: Gráficos de evolução para tomada de decisão
4. **Auditável**: Registro legal com rastreabilidade
5. **Privado**: Acesso controlado com justificativa

---

## 🏗️ Arquitetura Proposta

### Nova Estrutura do Botão "Histórico" → "Prontuário"

```
┌─────────────────────────────────────────────────────────────────┐
│                    📋 PRONTUÁRIO ELETRÔNICO                      │
│                        (Botão "Histórico")                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 👤 PERFIL DO PACIENTE                                    │    │
│  │ Nome: Maria Silva | Sexo: F | Idade: 73 anos             │    │
│  │ CPF: xxx.xxx.xxx-xx | Tipo Sanguíneo: A+ | Alergias: ⚠️  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📊 DASHBOARD DE SAÚDE (Gráficos de Evolução)            │ ▼  │
│  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │    │
│  │ │  PA 📈   │ │ Peso 📉  │ │Glicemia  │ │  IMC     │     │    │
│  │ │120/80    │ │ 72kg     │ │ 98mg/dL  │ │ 24.5    │     │    │
│  │ │Estável   │ │ -3kg     │ │ Normal   │ │ Normal   │     │    │
│  │ └──────────┘ └──────────┘ └──────────┘ └──────────┘     │    │
│  │                                                          │    │
│  │ [Expandir gráficos detalhados]                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📅 TIMELINE CLÍNICA                                      │    │
│  │ Filtros: [Todas] [Consultas] [Exames] [Receitas] [Atestados]│ │
│  │                                                          │    │
│  │ ┌────────────────────────────────────────────────────┐  │    │
│  │ │ 📆 15/01/2026 - CONSULTA PSIQUIATRIA               │  │    │
│  │ │ Dr. Antônio Jorge | Status: ✅ Concluída           │  │    │
│  │ │                                                     │  │    │
│  │ │ 📋 RESUMO (expandível):                            │  │    │
│  │ │ • QP: Ansiedade generalizada                       │  │    │
│  │ │ • Avaliação: TAG em tratamento, boa resposta       │  │    │
│  │ │ • Conduta: Manter Sertralina 50mg                  │  │    │
│  │ │                                                     │  │    │
│  │ │ 📊 Sinais Vitais:                                  │  │    │
│  │ │ PA: 118/72 | FC: 68bpm | SpO₂: 98% | Peso: 72kg   │  │    │
│  │ │                                                     │  │    │
│  │ │ 📄 Documentos:                                     │  │    │
│  │ │ [📜 Receita] [📋 Atestado 3 dias] [📊 Exame]      │  │    │
│  │ │                                                     │  │    │
│  │ │ 🔊 Ausculta: [▶️ Reproduzir] Cardíaca - 12s        │  │    │
│  │ │ 🎥 Gravação: [▶️ Reproduzir] 23min                 │  │    │
│  │ │                                                     │  │    │
│  │ │ 🤖 Insights IA:                                    │  │    │
│  │ │ "Paciente apresenta melhora de 30% nos sintomas    │  │    │
│  │ │ comparado à última consulta. Recomendo manter..."  │  │    │
│  │ └────────────────────────────────────────────────────┘  │    │
│  │                                                          │    │
│  │ ┌────────────────────────────────────────────────────┐  │    │
│  │ │ 📆 10/12/2025 - CONSULTA CLÍNICA GERAL            │  │    │
│  │ │ Dr. Geraldo Tadeu | Status: ✅ Concluída          │  │    │
│  │ │ ... (conteúdo expandível)                          │  │    │
│  │ └────────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [📊 Ver Gráficos Completos] [📄 Exportar PDF] [🖨️ Imprimir]    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Seções do PEP

### 1. Cabeçalho - Perfil do Paciente
Dados fixos do paciente sempre visíveis:
- Nome completo, idade, sexo
- Alergias (com destaque visual se houver)
- Tipo sanguíneo
- Condições crônicas principais
- Última consulta

### 2. Dashboard de Saúde (Gráficos de Evolução)
Gráficos de linha temporal mostrando tendências:

#### Métricas Principais
| Métrica | Fonte | Período |
|---------|-------|---------|
| Pressão Arterial | BiometricsJson | Últimos 12 meses |
| Peso/IMC | BiometricsJson | Últimos 12 meses |
| Glicemia | BiometricsJson | Últimos 6 meses |
| Frequência Cardíaca | BiometricsJson | Últimas 10 consultas |
| SpO₂ | BiometricsJson | Últimas 10 consultas |
| Temperatura | BiometricsJson | Últimas 10 consultas |

#### Visualização
- Mini-cards com último valor e tendência (↑↓→)
- Clique para expandir gráfico completo
- Linhas de referência (valores normais)
- Cores: verde (normal), amarelo (atenção), vermelho (crítico)

### 3. Timeline Clínica
Lista cronológica reversa (mais recente primeiro) de todos os eventos clínicos:

#### Tipos de Evento
| Tipo | Ícone | Descrição |
|------|-------|-----------|
| Consulta | 📅 | Teleconsulta realizada |
| Prescrição | 💊 | Receitas emitidas |
| Exame | 🔬 | Solicitações de exames |
| Atestado | 📋 | Atestados médicos |
| Laudo | 📄 | Laudos médicos |
| Ausculta | 🔊 | Gravações de ausculta |
| Gravação | 🎥 | Gravação da teleconsulta |
| Encaminhamento | ➡️ | Referências para especialistas |
| Retorno | 🔄 | Consultas de retorno |

### 4. Detalhes da Consulta (Expandido)
Ao clicar em uma consulta, exibe:

```
┌─────────────────────────────────────────────────────────────────┐
│ 📆 15/01/2026 - TELECONSULTA PSIQUIATRIA                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 🏥 INFORMAÇÕES GERAIS                                           │
│ ├─ Médico: Dr. Antônio Jorge - CRM 12345/GO                     │
│ ├─ Início: 09:15 | Fim: 09:45 | Duração: 30min                  │
│ └─ Apoio: Enf. Daniela Ochoa                                    │
│                                                                  │
│ 📊 SINAIS VITAIS                                                │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Peso    │ Altura │ IMC   │ PA       │ FC     │ SpO₂  │ Temp ││
│ │ 72 kg   │ 1.65m  │ 26.4  │ 118/72   │ 68bpm  │ 98%   │ 36.2°││
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ 📝 ANAMNESE                                                     │
│ ├─ Queixa Principal: Ansiedade persistente                      │
│ ├─ HDA: Paciente relata melhora de 40% dos sintomas...         │
│ ├─ HPP: TAG diagnosticado em 2024, em tratamento...            │
│ ├─ Antecedentes Familiares: Mãe com depressão                  │
│ └─ Hábitos: Não tabagista, exercício 3x/semana                 │
│                                                                  │
│ 📋 SOAP                                                         │
│ ├─ S (Subjetivo): Paciente refere melhora significativa...     │
│ ├─ O (Objetivo): BEG, calma, sem sinais de ansiedade aguda     │
│ ├─ A (Avaliação): TAG em remissão parcial                      │
│ └─ P (Plano): Manter Sertralina 50mg, retorno em 30 dias       │
│                                                                  │
│ 🩺 EXAME FÍSICO / DADOS COMPLEMENTARES                         │
│ ├─ 🔊 Ausculta Cardíaca: [▶️ Reproduzir 12s] RCR 2T s/sopros   │
│ ├─ 🔊 Ausculta Pulmonar: [▶️ Reproduzir 15s] MVF s/RA          │
│ └─ 📷 Imagens: Nenhuma                                          │
│                                                                  │
│ 📄 DOCUMENTOS EMITIDOS                                          │
│ ├─ 💊 Receita #001: Sertralina 50mg [📥 Download] [✓ Assinada] │
│ ├─ 📋 Atestado: Afastamento 3 dias [📥 Download] [✓ Assinado]  │
│ └─ 🔬 Exame: Hemograma + TSH [📥 Download]                      │
│                                                                  │
│ 🤖 INSIGHTS DA IA                                               │
│ ├─ Resumo: "Paciente com TAG em tratamento apresentou..."       │
│ ├─ Hipótese: "Resposta parcial à ISRS, considerar ajuste dose" │
│ └─ Alerta: "Monitorar: histórico familiar de depressão"        │
│                                                                  │
│ 🎥 GRAVAÇÃO DA CONSULTA                                         │
│ └─ [▶️ Reproduzir] 30min 25s | [📥 Download]                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5. Seção AI Insights
Dedicada às análises da IA:

```
┌─────────────────────────────────────────────────────────────────┐
│ 🤖 INSIGHTS DA INTELIGÊNCIA ARTIFICIAL                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 📊 ANÁLISE DE TENDÊNCIAS                                        │
│ "Paciente apresenta tendência de pressão arterial elevada nos   │
│ últimos 3 meses. Média: 142/89 mmHg. Recomenda-se revisão       │
│ de medicação anti-hipertensiva."                                │
│                                                                  │
│ 💊 INTERAÇÕES MEDICAMENTOSAS                                    │
│ ⚠️ "Sertralina + Ibuprofeno: Risco aumentado de sangramento."  │
│                                                                  │
│ 🎯 HIPÓTESE DIAGNÓSTICA SUGERIDA                               │
│ "Baseado nos sintomas relatados e evolução clínica:"           │
│ 1. TAG (F41.1) - Confiança: 85%                                │
│ 2. Episódio Depressivo Leve (F32.0) - Confiança: 45%           │
│                                                                  │
│ 📋 RESUMO PARA CONTINUIDADE                                     │
│ "Paciente de 73 anos, sexo feminino, em acompanhamento por TAG │
│ desde 2024. Atualmente em uso de Sertralina 50mg com boa       │
│ tolerância. Última consulta mostrou melhora de sintomas..."    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Modelagem de Dados

### Novas Entidades Necessárias

#### 1. ConsultationRecording (Gravação de Consulta)
```csharp
public class ConsultationRecording : BaseEntity
{
    public Guid AppointmentId { get; set; }
    public string FilePath { get; set; } = "";       // Caminho no servidor
    public long FileSizeBytes { get; set; }          // Tamanho em bytes
    public int DurationSeconds { get; set; }         // Duração em segundos
    public string MimeType { get; set; } = "video/webm";
    public bool IsAvailable { get; set; } = false;   // Disponível para reprodução
    public DateTime? RecordedAt { get; set; }
    
    // Consentimento - LGPD
    public bool PatientConsented { get; set; } = false;
    public bool ProfessionalConsented { get; set; } = false;
    public DateTime? ConsentedAt { get; set; }
    
    // Navegação
    public Appointment Appointment { get; set; } = null!;
}
```

#### 2. AuscultationRecording (Gravação de Ausculta)
```csharp
public class AuscultationRecording : BaseEntity
{
    public Guid AppointmentId { get; set; }
    public string Type { get; set; } = "";           // "cardiac", "pulmonary", "bowel", "carotid"
    public string? Position { get; set; }            // "Mitral", "Aórtico", "Pulmonar", "Tricúspide", etc.
    public string FilePath { get; set; } = "";       // Caminho do arquivo de áudio
    public long FileSizeBytes { get; set; }
    public int DurationSeconds { get; set; }
    public string MimeType { get; set; } = "audio/wav";
    public string? ClinicalNotes { get; set; }       // Anotações do médico sobre o achado
    
    // Análise IA (futura)
    public string? AIAnalysis { get; set; }          // Análise automática do som
    public double? AIConfidence { get; set; }        // Confiança da análise
    
    // Navegação
    public Appointment Appointment { get; set; } = null!;
}
```

#### 3. ClinicalNote (Evolução/Nota Clínica)
```csharp
public class ClinicalNote : BaseEntity
{
    public Guid AppointmentId { get; set; }
    public Guid AuthorId { get; set; }               // Médico que escreveu
    public string NoteType { get; set; } = "";       // "evolution", "addendum", "correction"
    public string Content { get; set; } = "";        // Conteúdo em texto
    
    // Assinatura
    public string? DigitalSignature { get; set; }
    public DateTime? SignedAt { get; set; }
    
    // Navegação
    public Appointment Appointment { get; set; } = null!;
    public User Author { get; set; } = null!;
}
```

#### 4. Referral (Encaminhamento)
```csharp
public class Referral : BaseEntity
{
    public Guid AppointmentId { get; set; }
    public Guid OriginProfessionalId { get; set; }
    public Guid? DestinationSpecialtyId { get; set; }
    public string? DestinationProfessionalName { get; set; }
    public string? DestinationFacilityName { get; set; }
    
    public string Reason { get; set; } = "";         // Motivo do encaminhamento
    public string Priority { get; set; } = "Normal"; // "Emergency", "Urgent", "Normal"
    public string ClinicalSummary { get; set; } = "";
    
    // Status
    public string Status { get; set; } = "Pending";  // "Pending", "Scheduled", "Completed", "Cancelled"
    
    // Assinatura
    public string? DigitalSignature { get; set; }
    public DateTime? SignedAt { get; set; }
    
    // Navegação
    public Appointment Appointment { get; set; } = null!;
    public User OriginProfessional { get; set; } = null!;
    public Specialty? DestinationSpecialty { get; set; }
}
```

### Alterações em Appointment.cs
```csharp
// Adicionar campos:
public bool RecordingEnabled { get; set; } = false;  // Gravação habilitada para esta consulta
public bool RecordingConsented { get; set; } = false; // Consentimento obtido

// Navigation Properties (adicionar):
public ConsultationRecording? Recording { get; set; }
public ICollection<AuscultationRecording> Auscultations { get; set; } = new List<AuscultationRecording>();
public ICollection<ClinicalNote> ClinicalNotes { get; set; } = new List<ClinicalNote>();
public ICollection<Referral> Referrals { get; set; } = new List<Referral>();
```

---

## 📊 API - Endpoints Necessários

### Timeline Enriquecida
```
GET /api/patients/{patientId}/pep
GET /api/patients/{patientId}/pep/vitals-chart?metrics=bp,weight,bmi&period=12months
GET /api/patients/{patientId}/pep/appointments/{appointmentId}/full
GET /api/patients/{patientId}/pep/ai-insights
```

### Gravações
```
GET /api/appointments/{id}/recording/stream
GET /api/appointments/{id}/auscultations
GET /api/appointments/{id}/auscultations/{auscultationId}/stream
POST /api/appointments/{id}/recording/consent
```

---

## ⚙️ Configurações do Sistema

### Parâmetros de Gravação (appsettings.json)
```json
{
  "RecordingSettings": {
    "Enabled": true,
    "RequirePatientConsent": true,
    "RequireProfessionalConsent": true,
    "MaxDurationMinutes": 60,
    "StoragePath": "/app/data/recordings",
    "RetentionDays": 365,
    "AllowedMimeTypes": ["video/webm", "audio/wav"]
  }
}
```

---

## 🛡️ Segurança e Conformidade

### LGPD / CFM
1. **Consentimento**: Paciente e médico devem consentir para gravação
2. **Rastreabilidade**: Todo acesso ao PEP é auditado (AuditLog)
3. **Justificativa**: Médico deve informar motivo ao acessar histórico
4. **Retenção**: Mínimo 20 anos conforme CFM
5. **Criptografia**: Gravações armazenadas com encriptação

### Níveis de Acesso
| Role | Acesso |
|------|--------|
| Professional | PEP completo de seus pacientes |
| Assistant | Sinais vitais apenas durante consulta |
| Admin | Auditoria e configurações |
| Patient | NÃO implementado nesta fase |

---

## 📅 Fases de Implementação

### Fase 1: Redesign do Histórico (2-3 dias)
- [ ] Renomear "Histórico" → "Prontuário"  
- [ ] Novo layout com dashboard no topo
- [ ] Cards de métricas com tendências
- [ ] Timeline com filtros
- [ ] Detalhes expandidos da consulta

### Fase 2: Gráficos de Evolução (2 dias)
- [ ] Endpoint de métricas temporais
- [ ] Componente de gráfico de linha (Chart.js ou similar)
- [ ] Integração com dashboard

### Fase 3: Seção AI Insights (1 dia)
- [ ] Layout da seção
- [ ] Integração com campos AI existentes
- [ ] Exibição de resumos e hipóteses

### Fase 4: Sistema de Gravação (3-4 dias)
- [ ] Modelos de dados (migrations)
- [ ] Upload/storage de vídeos
- [ ] Streaming de reprodução
- [ ] UI de consentimento
- [ ] Player de vídeo

### Fase 5: Ausculta no PEP (1-2 dias)
- [ ] Listagem de gravações de ausculta
- [ ] Player de áudio
- [ ] Vinculação com consultas

---

## 🎨 Tecnologias Sugeridas

### Frontend
- **Gráficos**: ngx-charts ou Chart.js
- **Player de Vídeo**: VideoJS ou HTML5 nativo
- **Player de Áudio**: WaveSurfer.js (visualização de ondas)

### Backend
- **Storage**: Sistema de arquivos local (/app/data/recordings)
- **Streaming**: FileStreamResult com chunked transfer

---

## ✅ Validação com CFM/SBIS

O PEP proposto atende aos 12 atributos do IOM (Institute of Medicine):

1. ✅ Lista de problemas atuais e pregressos
2. ✅ Medidas de estado funcional e saúde
3. ✅ Documentação do raciocínio clínico (SOAP)
4. ✅ Registro longitudinal (toda a vida)
5. ✅ Confidencialidade (auditoria)
6. ✅ Acesso contínuo a usuários autorizados
7. ✅ Visualização customizada (filtros, gráficos)
8. ✅ Acesso a outros recursos (IA)
9. ✅ Instrumentos de análise e decisão
10. ✅ Entrada de dados facilitada
11. ✅ Controle de custos/qualidade (métricas)
12. ✅ Flexibilidade para especialidades

---

**Próximo Passo**: Implementar Fase 1 - Redesign do componente de histórico.
