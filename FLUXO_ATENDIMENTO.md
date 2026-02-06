# 🏥 Fluxo de Agendamento, Recepção e Atendimento - TeleCuidar

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Perfis de Usuário](#perfis-de-usuário)
3. [Fluxo de Atendimento](#fluxo-de-atendimento)
4. [Melhorias Propostas](#melhorias-propostas)
5. [Modelo de Dados](#modelo-de-dados)
6. [Estados e Transições](#estados-e-transições)
7. [Sistema de Notificações](#sistema-de-notificações)
8. [Implementação Técnica](#implementação-técnica)

---

## 🎯 Visão Geral

### Cenário
Cada unidade de saúde possui um **Consultório Digital** onde pacientes fazem teleconsultas com profissionais especialistas geograficamente distantes.

### Participantes
- **Paciente** (comunidade)
- **Recepcionista** (unidade de saúde - novo perfil)
- **Enfermeira/Assistente** (consultório digital - suporte presencial)
- **Médico** (especialista - pode estar em outro local)
- **Administrador** (gestão do sistema)

---

## 👥 Perfis de Usuário

### 1. **Paciente** (PATIENT - Nível 0)
- Agenda consulta (online ou com recepcionista)
- Chega na unidade no horário marcado
- Comparece na recepção
- Aguarda na fila
- Entra no consultório digital com apoio da enfermeira
- Realiza consulta remota

### 2. **Recepcionista** (RECEPTIONIST - Nível 3) ⭐ NOVO
**Responsabilidades:**
- Receber pacientes que chegam
- Confirmar identidade e agendamento
- Atualizar status de presença/ausência
- Gerenciar fila de espera (ordenar por chegada/agendamento)
- Informar enfermeira sobre próximo paciente
- Lidar com pacientes que não compareceram

**Permissões:**
- Visualizar agenda do dia
- Marcar presença/ausência
- Adicionar/remover da fila
- Visualizar dados básicos do paciente
- Imprimir comprovante de agendamento

### 3. **Assistente/Enfermeira** (ASSISTANT - Nível 2)
**Responsabilidades:**
- Consultar fila de espera atualizada
- Chamar próximo paciente
- Abrir atendimento no sistema (criar appointment entry)
- Orientar paciente durante sinal de vital
- Suportar paciente na captura de dados biométricos
- Apoiar transmissão de imagens/ausculta
- Encerrar atendimento após consulta

### 4. **Médico/Profissional** (PROFESSIONAL - Nível 1)
**Responsabilidades:**
- Receber notificação de paciente aguardando
- Acessar teleconsulta
- Avaliar paciente
- Solicitar exames/procedimentos
- Registrar prescrição e diagnóstico
- Encerrar atendimento

### 5. **Administrador** (ADMIN - Nível 2)
- Gerenciar usuários de todos os perfis
- Configurar especialidades por unidade
- Gerenciar horários de funcionamento
- Configurar notificações
- Gerar relatórios

---

## 🔄 Fluxo de Atendimento

### Fase 1: Agendamento
```
┌─────────────────────────────────────────────────────┐
│ AGENDAMENTO                                         │
└─────────────────────────────────────────────────────┘
    │
    ├─► [Sistema Online] Paciente agenda via app/web
    │   └─► Valida disponibilidade de médico
    │   └─► Cria Appointment com status "SCHEDULED"
    │
    └─► [Com Recepcionista] Recepcionista agenda
        └─► Insere paciente na agenda
        └─► Envia confirmação (SMS/Email)
```

### Fase 2: Chegada e Recepção
```
┌─────────────────────────────────────────────────────┐
│ RECEPÇÃO (Dia do Atendimento)                       │
└─────────────────────────────────────────────────────┘
    │
    ├─► Paciente chega na unidade
    │
    ├─► Recepcionista:
    │   ├─ Consulta agenda do dia
    │   ├─ Verifica identidade
    │   ├─ Marca presença (Appointment.Status = "CHECKED_IN")
    │   └─ Adiciona à fila de espera (WaitingList.Position)
    │
    └─► Sistema atualiza:
        ├─ Fila visível na tela da enfermeira
        ├─ Próximo paciente destacado
        └─ [OPCIONAL] Enviar SMS/notify para médico: "Você tem X pacientes aguardando"
```

### Fase 3: Chamada e Entrada no Consultório Digital
```
┌─────────────────────────────────────────────────────┐
│ CHAMADA (Enfermeira no Consultório Digital)         │
└─────────────────────────────────────────────────────┘
    │
    ├─► Enfermeira consulta fila de espera
    │   └─► Visualiza próximo paciente ordenado
    │
    ├─► Enfermeira chama paciente (fisicamente)
    │
    ├─► Paciente entra no consultório
    │
    ├─► Enfermeira no sistema:
    │   ├─ Clica em "Iniciar Atendimento"
    │   ├─ Appointment.Status = "IN_PROGRESS"
    │   ├─ Appointment.CheckInTime = now()
    │   └─ Appointment.AssistantId = assistente_logged_in
    │
    └─► 🔔 NOTIFICAÇÃO ENVIADA AO MÉDICO:
        ├─ WhatsApp: "Paciente [Nome] aguardando"
        ├─ SMS: "Consulta iniciada - [Nome] [Horário]"
        ├─ Email: "[Nome] está na sala - entre no link"
        ├─ Sistema: Badge na home do médico + Link direto
        └─ [Se médico offline] Armazenar em NotificationCenter
```

### Fase 4: Consulta Remota
```
┌─────────────────────────────────────────────────────┐
│ TELECONSULTA (Video + Suporte)                      │
└─────────────────────────────────────────────────────┘
    │
    ├─► Médico clica no link/notificação
    │   └─► Entra na sala de videoconferência (Jitsi)
    │
    ├─► Durante a consulta:
    │   ├─ Paciente transmite sinais vitais
    │   ├─ Enfermeira captura dados biométricos
    │   ├─ Câmera/ausculta virtual
    │   ├─ Médico prescreve
    │   └─ Enfermeira registra instruções
    │
    └─► [Sistemas em tempo real]
        ├─ Sinais vitais aparecem na tela do médico
        ├─ Chat entre médico/enfermeira/paciente
        ├─ Histórico de consulta sendo registrado
        └─ [OPCIONAL] Gravação de consulta (com consentimento)
```

### Fase 5: Encerramento
```
┌─────────────────────────────────────────────────────┐
│ ENCERRAMENTO (Médico ou Enfermeira)                 │
└─────────────────────────────────────────────────────┘
    │
    ├─► Médico encerra consulta:
    │   ├─ Salva diagnóstico
    │   ├─ Emite prescrição
    │   └─ Define follow-up (se necessário)
    │
    ├─► Appointment.Status = "COMPLETED"
    ├─ Appointment.EndTime = now()
    │
    ├─► Enfermeira:
    │   ├─ Despede paciente
    │   ├─ Imprime/envia prescrição
    │   ├─ Clica "Próximo Paciente" na fila
    │   └─ [Automático] Remove da fila de espera
    │
    └─► 🔄 Volta para Fase 3 com próximo paciente
```

---

## ✨ Melhorias Propostas

### 1. **Sistema Inteligente de Fila**
```
MELHORIA: Smart Queue Management

ANTES:
├─ Fila simples por ordem de chegada
└─ Sem priorização

DEPOIS:
├─ Priorização por:
│  ├─ Urgência (triagem)
│  ├─ Horário agendado (paciente 9h antes de 10h)
│  ├─ Pacientes recorrentes (faster track)
│  └─ Acompanhantes (pacientes idosos com prioridade)
│
├─ Avisos automáticos:
│  ├─ "Chamando próximo em 2 minutos"
│  ├─ "Paciente não respondeu após 3 chamadas"
│  └─ "Transferir para horário posterior?"
│
└─ Dashboard da recepcionista:
   ├─ Tempo médio de espera
   ├─ Taxa de absenteísmo
   └─ Próximos agendados
```

### 2. **Notificações Inteligentes para Médico**
```
MELHORIA: Multi-channel Intelligent Notifications

Baseado em Preferências:
├─ Se médico ONLINE no sistema:
│  └─ Notificação visual + Som (badge na home)
│
├─ Se médico OFFLINE:
│  ├─ WhatsApp (com link da consulta)
│  ├─ SMS (fallback)
│  ├─ Email (confirmação)
│  └─ Armazenar em "Notificações" até abrir sistema
│
├─ Renotificar se não clicar:
│  ├─ Após 1 min: Reenviar via SMS
│  ├─ Após 3 min: Chamar médico (telefone)
│  ├─ Após 5 min: Avisar paciente "Aguardando médico"
│  └─ Após 10 min: Opção de reagendar
│
└─ Histórico de notificações
   └─ Por que médico não respondeu?
```

### 3. **Controle de Pré-consulta**
```
MELHORIA: Pre-Consultation Checklist

Antes da enfermeira chamar:
├─ Enfermeira confirma:
│  ├─ Paciente apresentou identidade?
│  ├─ Consentimento informado foi obtido?
│  ├─ Câmera/microfone testados?
│  ├─ Sinais vitais já foram medidos?
│  └─ Imagens/exames já foram capturados?
│
└─ Sistema marca como "READY_FOR_CALL"
   └─ Torna mais rápido chamar o médico
```

### 4. **Sala de Espera Virtual**
```
MELHORIA: Virtual Waiting Room

Enquanto aguarda:
├─ Tela mostra:
│  ├─ Posição na fila
│  ├─ Tempo estimado de espera
│  ├─ Especialidade e médico
│  ├─ "Você será chamado em breve"
│  └─ [Info de espera] "Preparar câmera/microfone"
│
├─ Verificação de câmera/áudio:
│  └─ Antes de chamar: "Teste sua câmera/microfone"
│
└─ Chat com enfermeira:
   └─ Se paciente tiver dúvida
```

### 5. **Resgate de Não-presentes**
```
MELHORIA: No-show Management

Se paciente AGENDADO mas não compareceu:
├─ Recepcionista marca como "NO_SHOW"
│  └─ Appointment.Status = "NO_SHOW"
│
├─ Sistema:
│  ├─ Oferece: Remarcar para próxima semana?
│  ├─ Envia SMS: "Sentiremos sua falta. Deseja remarcar?"
│  ├─ Libera horário para outro paciente
│  └─ Gera relatório de faltas
│
└─ Médico visualiza:
   └─ Falta não penaliza especialista
```

### 6. **Abertura de Atendimento Automática**
```
MELHORIA: Automatic Appointment Opening

ANTES:
└─ Enfermeira clica "Iniciar Atendimento" + Médico entra = 2 ações

DEPOIS:
├─ Enfermeira marca presença = Appointment abre automaticamente
├─ Médico já vê "Paciente aguardando"
├─ Contagem regressiva começa (tempo de espera do médico)
└─ Se médico não entrar em 10 min, avisar gerente
```

### 7. **Handoff entre Médicos** (Se necessário)
```
MELHORIA: Consultation Handoff

Se paciente precisa de segundo parecer:
├─ Médico A no sistema: "Pedir parecer de especialista"
├─ Sistema cria nova fila
├─ Médico B recebe notificação
├─ Médico B entra NA MESMA sala
├─ Ambos interagem com paciente
└─ Ambos documentam parecer
```

### 8. **Análise em Tempo Real**
```
MELHORIA: Real-time Analytics Dashboard

Recepcionista visualiza:
├─ ⏱️ Tempo médio de espera (hoje)
├─ 📊 Pacientes em espera vs completos
├─ 📈 Taxa de ausência
├─ ⚠️ Consultas demorando muito
├─ 🔴 Alertas: "Médico não respondeu"
└─ 📋 Previsão: "Fila vai ficar pesada 14h-15h"

Médico visualiza:
├─ 👥 Quantos pacientes na fila minha?
├─ ⏳ Tempo estimado para próxima
├─ 📞 Número de tentativas de notificação
└─ 🏥 Status de outro médicos (se houver rodízio)
```

---

## 🗄️ Modelo de Dados

### Tabelas Novas Necessárias

#### 1. **UserRole - RECEPTIONIST**
```sql
-- Adicionar novo role
INSERT INTO Roles (Id, Name, Permissions) VALUES 
('3', 'RECEPTIONIST', 'VIEW_SCHEDULE,CHECK_IN,MANAGE_QUEUE');
```

#### 2. **WaitingList** (Nova)
```
WaitingList:
├─ Id (GUID)
├─ AppointmentId (FK → Appointments)
├─ UnityId (FK → Units/Unidades)
├─ PatientId (FK → Users)
├─ HealthcareProfessionalId (FK → Users/Médicos)
├─ Position (INT - 1, 2, 3, etc)
├─ Priority (INT - 0=Normal, 1=Urgente, 2=VIP)
├─ CheckInTime (DateTime)
├─ CalledTime (DateTime - quando foi chamado)
├─ CallAttempts (INT - quantas vezes foi chamado)
├─ Status (ENUM):
│  ├─ WAITING
│  ├─ CALLED
│  ├─ IN_CONSULTATION
│  ├─ COMPLETED
│  ├─ NO_SHOW
│  └─ CANCELLED
├─ CreatedAt
└─ UpdatedAt
```

#### 3. **NotificationCenter** (Nova)
```
NotificationCenter:
├─ Id (GUID)
├─ UserId (FK → Users/Médico)
├─ AppointmentId (FK → Appointments)
├─ Type (ENUM):
│  ├─ PATIENT_WAITING
│  ├─ PATIENT_CHECKED_IN
│  ├─ CONSULTATION_STARTED
│  ├─ CONSULTATION_ENDED
│  ├─ URGENT_ALERT
│  └─ SYSTEM_MESSAGE
├─ Channels (Multi-select):
│  ├─ WHATSAPP
│  ├─ SMS
│  ├─ EMAIL
│  └─ SYSTEM
├─ Content
├─ ActionLink
├─ IsRead (boolean)
├─ ReadAt (DateTime)
├─ SentAt (DateTime)
├─ RetryCount (INT)
├─ LastRetryAt (DateTime)
├─ Status (ENUM):
│  ├─ PENDING
│  ├─ SENT
│  ├─ FAILED
│  ├─ DELIVERED
│  └─ FAILED_DELIVERY
└─ CreatedAt
```

#### 4. **ConsultationSettings** (Nova)
```
ConsultationSettings:
├─ Id (GUID)
├─ UnityId (FK → Units)
├─ NotifyViaSMS (boolean)
├─ NotifyViaWhatsApp (boolean)
├─ NotifyViaEmail (boolean)
├─ NotifyInSystem (boolean)
├─ RenotifyAfterMinutes (INT - ex: 1, 3, 5)
├─ MaxWaitTimeMinutes (INT - ex: 30)
├─ AllowQueuePriority (boolean)
├─ RecordConsultations (boolean + consent)
├─ AutoOpenAppointment (boolean)
├─ EnableVirtualWaitingRoom (boolean)
├─ UpdatedAt
└─ UpdatedBy (FK → Users/Admin)
```

#### 5. **AuditLog** (Existente - expandir)
```
Registrar:
├─ Quando recepcionista marca presença
├─ Quando enfermeira abre atendimento
├─ Quando médico entra/sai
├─ Todas as notificações enviadas
├─ Falhas na notificação
└─ Duração de cada consulta
```

### Modificações em Tabelas Existentes

#### **Appointments** (Expandir)
```
Adicionar campos:
├─ AssistantId (FK → Users) - Enfermeira que abriu
├─ CheckInTime (DateTime)
├─ WaitingListPosition (INT)
├─ Status (adicionar:):
│  ├─ SCHEDULED
│  ├─ CHECKED_IN ← Recepcionista marcou
│  ├─ IN_PROGRESS ← Enfermeira abriu
│  ├─ IN_CONSULTATION ← Médico entrou
│  ├─ COMPLETED
│  ├─ NO_SHOW
│  ├─ CANCELLED
│  └─ RESCHEDULED
├─ PreConsultationChecklistCompleted (bool)
├─ NotificationSentAt (DateTime)
├─ NotificationRetryCount (INT)
├─ ConsultationStartedAt (DateTime)
├─ ConsultationEndedAt (DateTime)
├─ DurationInMinutes (INT)
├─ PatientNoShowCount (INT - histórico)
└─ IsRecorded (bool + consent)
```

---

## 🔀 Estados e Transições

```
Estados de Appointment:

SCHEDULED (Agendado)
    │
    ├─► CHECKED_IN (Recepcionista marca presença)
    │       │
    │       ├─► NO_SHOW (Não compareceu)
    │       │
    │       ├─► CANCELLED (Cancelado)
    │       │
    │       └─► IN_PROGRESS (Enfermeira abre atendimento)
    │           │
    │           ├─► [NOTIFICAÇÃO ENVIADA AO MÉDICO]
    │           │
    │           └─► IN_CONSULTATION (Médico entra)
    │               │
    │               └─► COMPLETED (Médico encerra)
    │
    └─► CANCELLED (Antes de chegar)

Transições Automáticas:
├─ CHECKED_IN → NO_SHOW (após 15 min sem entrar no consultório)
├─ IN_PROGRESS → PENDING_DOCTOR (após 10 min sem médico entrar)
└─ COMPLETED → FOLLOW_UP_SCHEDULED (se médico criar novo agendamento)
```

---

## 🔔 Sistema de Notificações

### Fluxo Completo

```
1️⃣ GATILHO: Enfermeira clica "Abrir Atendimento"
   └─ Appointment.Status = IN_PROGRESS

2️⃣ VERIFICAÇÃO: Sistema verifica se médico está online
   ├─ Se ONLINE:
   │  └─ Notificação visual + Sound na tela
   └─ Se OFFLINE:
      └─ Consulta ConsultationSettings do médico

3️⃣ SELEÇÃO DE CANAL:
   ├─ Se médico preferir WhatsApp:
   │  ├─ Enviar via Twilio/WhatsApp
   │  ├─ Incluir link clicável: "https://telecuidar/consultation/[id]"
   │  └─ Se falhar: Tentar SMS
   │
   ├─ Se preferir SMS:
   │  ├─ Enviar via Twilio/SMS
   │  └─ Se falhar: Tentar WhatsApp
   │
   ├─ Se preferir Email:
   │  ├─ Enviar com HTML template + link
   │  └─ Se falhar: Tentar SMS
   │
   └─ SEMPRE marcar no NotificationCenter do sistema

4️⃣ ARMAZENAMENTO:
   └─ NotificationCenter entry:
      ├─ UserId = médico_id
      ├─ AppointmentId = appointment_id
      ├─ Status = SENT
      ├─ Channels = [WHATSAPP, SMS, EMAIL]
      └─ SentAt = now()

5️⃣ RETENTATIVA:
   ├─ Se médico não clicar em 1 min:
   │  ├─ Reenviar SMS (mais invasivo)
   │  └─ Incrementar retry_count
   │
   ├─ Se não clicar em 3 min:
   │  ├─ Chamar médico (número cadastrado)
   │  └─ Avisar paciente: "Médico está a caminho"
   │
   └─ Se não clicar em 5 min:
      ├─ Opção 1: Remarcar consulta
      ├─ Opção 2: Tentar médico substituto
      └─ Opção 3: Avisar paciente do atraso

6️⃣ SUCESSO:
   └─ Médico clica link → Notificação marcada como READ
      └─ NotificationCenter.IsRead = true
```

### Templates de Mensagem

#### WhatsApp
```
Olá Dr. [NOME_MEDICO]! 👋

O paciente [NOME_PACIENTE] está aguardando você! ⏳

🏥 Unidade: [NOME_UNIDADE]
🕐 Horário: [HORARIO_AGENDADO]
📝 Especialidade: [ESPECIALIDADE]

Clique abaixo para iniciar a consulta:
👉 https://app.telecuidar.com.br/consultation/[APPOINTMENT_ID]

Obrigado! 🙏
```

#### SMS
```
Dr(a). [NOME], paciente [PACIENTE] aguardando em [UNIDADE] 
às [HORARIO]. Clique: https://telecuidar.com.br/c/[ID]
```

#### Email
```html
<h2>Nova Consulta Aguardando</h2>
<p>Olá Dr(a). <strong>[NOME_MEDICO]</strong>,</p>

<p>O paciente <strong>[NOME_PACIENTE]</strong> 
está pronto para sua consulta!</p>

<table>
  <tr><td><strong>Unidade:</strong></td><td>[UNIDADE]</td></tr>
  <tr><td><strong>Horário:</strong></td><td>[HORARIO]</td></tr>
  <tr><td><strong>Especialidade:</strong></td><td>[ESPECIALIDADE]</td></tr>
</table>

<a href="https://app.telecuidar.com.br/consultation/[ID]" 
   class="btn-primary">Iniciar Consulta</a>

Tempo de espera do paciente: <strong>[MINUTOS]</strong> minutos
```

---

## 💻 Implementação Técnica

### 1. Backend - Endpoints Necessários

#### RecepcionistController (Novo)
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "RECEPTIONIST")]
public class ReceptionistController : ControllerBase
{
    // GET: /api/receptionist/today-appointments?unityId=xxx
    [HttpGet("today-appointments")]
    public async Task<IActionResult> GetTodayAppointments(Guid unityId)
    
    // POST: /api/receptionist/check-in
    [HttpPost("check-in")]
    public async Task<IActionResult> CheckInPatient(Guid appointmentId)
    
    // GET: /api/receptionist/waiting-list?unityId=xxx
    [HttpGet("waiting-list")]
    public async Task<IActionResult> GetWaitingList(Guid unityId)
    
    // PUT: /api/receptionist/appointment/{id}/no-show
    [HttpPut("appointment/{id}/no-show")]
    public async Task<IActionResult> MarkAsNoShow(Guid id)
    
    // GET: /api/receptionist/statistics
    [HttpGet("statistics")]
    public async Task<IActionResult> GetStatistics(Guid unityId, DateTime date)
}
```

#### AppointmentController (Expandir)
```csharp
// POST: /api/appointment/{id}/start-attendance
[HttpPost("{id}/start-attendance")]
[Authorize(Roles = "ASSISTANT")]
public async Task<IActionResult> StartAttendance(Guid id)
{
    // 1. Marcar Appointment como IN_PROGRESS
    // 2. Registrar AssistantId
    // 3. Enviar notificação ao médico
    // 4. Retornar dados para abrir consultório
}

// POST: /api/appointment/{id}/end-attendance
[HttpPost("{id}/end-attendance")]
[Authorize(Roles = "ASSISTANT,PROFESSIONAL")]
public async Task<IActionResult> EndAttendance(Guid id)
{
    // 1. Marcar Appointment como COMPLETED
    // 2. Registrar duração
    // 3. Chamar próximo da fila
}
```

#### NotificationController (Novo)
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationController : ControllerBase
{
    // GET: /api/notification/unread-count
    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    
    // GET: /api/notification/list
    [HttpGet("list")]
    public async Task<IActionResult> GetNotifications(int page = 1)
    
    // PUT: /api/notification/{id}/mark-read
    [HttpPut("{id}/mark-read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    
    // DELETE: /api/notification/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(Guid id)
}
```

### 2. Background Services

#### NotificationBackgroundService (Novo)
```csharp
public class NotificationBackgroundService : BackgroundService
{
    // Executar a cada 1 minuto
    // Verificar NotificationCenter.Status = PENDING
    // Tentar reenviar
    // Incrementar retry_count
}
```

#### QueueManagementService (Novo)
```csharp
public class QueueManagementService : BackgroundService
{
    // Executar a cada 30 segundos
    // Verificar Appointments com status = IN_PROGRESS
    // Se médico não entrou em 10 min, avisar
    // Se paciente não respondeu em 15 min, marcar NO_SHOW
}
```

### 3. SignalR Hubs (Expandir)

#### ConsultationHub (Modificar)
```csharp
public class ConsultationHub : Hub
{
    // Quando enfermeira abre atendimento
    public async Task NotifyDoctorPatientWaiting(
        Guid appointmentId, 
        string patientName, 
        string unityName)
    
    // Médico entra na consulta
    public async Task DoctorJoinedConsultation(Guid appointmentId)
    
    // Paciente aguarda na sala de espera virtual
    public async Task PatientWaitingInVirtualRoom(Guid appointmentId)
    
    // Próximo paciente será chamado em X segundos
    public async Task PatientCallComingSoon(Guid appointmentId, int seconds)
}
```

### 4. Frontend - Componentes

#### ReceptionistDashboard (Novo)
- Agenda do dia
- Botão "Marcar Presença"
- Fila visual (com posição de cada paciente)
- Estatísticas em tempo real
- Botão "Remarcar" para no-show

#### EnfermeiraNursingStation (Modificar)
- Fila de espera atualizada em tempo real
- Próximo paciente destacado
- Botão "Chamar Paciente"
- Botão "Iniciar Atendimento"
- Timer de tempo de espera
- Pre-consultation checklist

#### DoctorNotificationCenter (Novo)
- Badge com número de notificações
- Lista de pacientes aguardando
- Tempo de espera em vermelho se > 10 min
- Link rápido para consulta
- Histórico de notificações
- Marcação de notificação como lida

#### VirtualWaitingRoom (Novo)
- Posição na fila
- Tempo estimado de espera
- Nome do médico/especialidade
- Botão "Testar Câmera/Áudio"
- Mensagem de espera
- Chat com enfermeira

---

## 📱 Integração com Externos

### WhatsApp (Twilio)
```
POST /api/notifications/send-whatsapp
Body: {
  "phone": "+5585987654321",
  "message": "Dr(a)., paciente [NOME] aguardando...",
  "link": "https://telecuidar.com.br/c/[ID]"
}
```

### SMS (Twilio)
```
POST /api/notifications/send-sms
Body: {
  "phone": "+5585987654321",
  "message": "Consulta: [PACIENTE] às [HORÁRIO]"
}
```

### Email (SendGrid)
```
POST /api/notifications/send-email
Body: {
  "to": "medico@telecuidar.com",
  "subject": "Nova Consulta Aguardando",
  "template": "new-consultation",
  "data": { ... }
}
```

---

## 🎓 Fluxo Resumido (Visão Geral)

```
┌────────────────────────────────────────────────────────────┐
│ TELECUIDAR - Fluxo de Atendimento Completo               │
└────────────────────────────────────────────────────────────┘

HORA ANTERIOR:
  Médico: Sistema aberto, aguardando pacientes
  
  
09:00 - CHEGADA
  Paciente: Chega na unidade
  Recepcionista: Verifica identidade → Clica "Check-in"
  Sistema: Status = CHECKED_IN → Fila atualizada
  

09:05 - CHAMADA
  Enfermeira: Visualiza fila → Chama "João Silva"
  Paciente: Entra no consultório digital
  Enfermeira: Clica "Iniciar Atendimento"
  Sistema: Status = IN_PROGRESS
  
  
🔔 NOTIFICAÇÃO (Automática)
  Médico (WhatsApp): "João Silva está aguardando em Unidade [X]"
  Médico (SMS): "Consulta: João Silva às 09:05"
  Médico (Sistema): Badge vermelho "1 paciente aguardando"
  
  
09:06 - ATENDIMENTO
  Médico: Clica link → Entra na videoconferência
  Paciente: Transmite sinais vitais
  Enfermeira: Captura dados biométricos
  Médico: Interage com paciente e enfermeira
  Enfermeira: Registra dados/imagens
  
  
09:25 - ENCERRAMENTO
  Médico: Emite prescrição
  Enfermeira: Encerra atendimento
  Paciente: Recebe prescrição
  Sistema: Status = COMPLETED
  
  
09:26 - PRÓXIMO
  Enfermeira: Clica "Próximo Paciente"
  Fila: Atualiza posições
  Próximo paciente é chamado
  Volta ao passo CHAMADA
```

---

## ✅ Resumo de Melhorias

| Melhoria | Benefício | Prioridade |
|----------|-----------|-----------|
| Novo perfil Recepcionista | Organizar fila estruturada | 🔴 ALTA |
| Smart Queue Management | Reduzir tempo de espera | 🟠 MÉDIA |
| Notificações Multi-canal | Médico não erra consulta | 🔴 ALTA |
| Sala de Espera Virtual | Experiência do paciente | 🟢 BAIXA |
| Resgate de No-show | Reduzir faltas | 🟠 MÉDIA |
| Virtual Waiting Room | Entretimento/Confiança | 🟢 BAIXA |
| Analytics em Tempo Real | Gestão de fila | 🟠 MÉDIA |
| Abertura Automática | Economizar cliques | 🟡 BAIXA |

---

## 🚀 Próximos Passos

1. **Aprovação do Fluxo** - Confirmar que o fluxo atende necessidades
2. **Priorizar Implementações** - Definir o que fazer primeiro
3. **Criar Mockups de UI** - Desenhar as telas do recepcionista
4. **Implementar Backend** - Criar endpoints e banco de dados
5. **Implementar Frontend** - Criar componentes Angular
6. **Testar Integração** - Testar com múltiplos usuários
7. **Deploy** - Colocar em produção

---

**Data de Criação**: 01/02/2026  
**Versão**: 1.0  
**Status**: Proposta para Aprovação  
