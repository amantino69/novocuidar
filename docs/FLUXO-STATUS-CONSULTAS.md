# Fluxo de Status de Consultas - TeleCuidar

## 📋 Análise do Sistema Atual

### Status Atuais (Problemáticos)
| Status | Português | Problema |
|--------|-----------|----------|
| Scheduled | Agendada | ✅ OK |
| Confirmed | Confirmada | ✅ OK |
| CheckedIn | Recepcionado | ✅ OK |
| InProgress | Em Andamento | ⚠️ Confuso - não diferencia quem está na sala |
| InConsultation | Em Consulta | ⚠️ Pouco usado |
| Completed | Finalizada | ✅ OK |
| Cancelled | Cancelada | ✅ OK |
| NoShow | Não Compareceu | ✅ OK |
| **Abandoned** | **Abandonada** | ❌ **PROBLEMÁTICO** - termo não é padrão, confuso para usuários |

### Problemas Identificados
1. **"Abandonada" é confuso** - Não é linguagem padrão em sistemas de saúde
2. **Não diferencia quem saiu** - Se o paciente ou médico que deixou a sala
3. **Falta alerta contextualizado** - Mesma mensagem para médico e paciente
4. **Sem controle de acesso temporal** - Paciente pode acessar consulta de dias anteriores
5. **Médico não consegue fechar consulta após o dia** - Perde dados registrados

---

## 🎯 Proposta: Novo Fluxo de Status

### Estados Propostos (Simplificado)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FLUXO DE VIDA DA CONSULTA                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐    Paciente     ┌───────────┐    Chegou ao    ┌───────────┐ │
│   │ AGENDADA │ ──confirma───▶  │ CONFIRMADA │ ───polo────▶   │RECEPCIONAD│ │
│   │Scheduled │                 │ Confirmed  │                 │ CheckedIn │ │
│   └────┬─────┘                 └─────┬──────┘                 └─────┬─────┘ │
│        │                             │                               │       │
│        │ Cancelar                    │ Cancelar                      │       │
│        ▼                             ▼                               ▼       │
│   ┌──────────┐                 ┌──────────┐                   Enfermeira    │
│   │CANCELADA │                 │CANCELADA │                   abre sala     │
│   │Cancelled │                 │Cancelled │                        │       │
│   └──────────┘                 └──────────┘                        ▼       │
│                                                               ┌───────────┐ │
│                                                               │AGUARDANDO │ │
│   ┌──────────┐     Não veio no dia                            │  MÉDICO   │ │
│   │   NÃO    │◀────────────────────────────────────────────── │AwaitingDr │ │
│   │COMPARECEU│                                                └─────┬─────┘ │
│   │ NoShow   │                                                      │       │
│   └──────────┘                                                Médico entra  │
│                                                                     │       │
│                                                                     ▼       │
│                                                               ┌───────────┐ │
│   ┌──────────┐     Médico                                     │ EM CONSUL │ │
│   │ PENDENTE │◀───sai sem────────────────────────────────────│   TA      │ │
│   │FECHAMENTO│    finalizar                                   │InConsult. │ │
│   │PendingEnd│                                                └─────┬─────┘ │
│   └────┬─────┘                                                      │       │
│        │                                                      Médico       │
│        │ Médico retorna                                      finaliza     │
│        │ e finaliza                                               │       │
│        │                                                          ▼       │
│        └──────────────────────────────────────────────────▶ ┌───────────┐ │
│                                                              │FINALIZADA │ │
│                                                              │ Completed │ │
│                                                              └───────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tabela de Status Proposta

| Status | Código | Descrição | Quem define | Ações disponíveis |
|--------|--------|-----------|-------------|-------------------|
| **Agendada** | `Scheduled` | Consulta criada | Sistema | Confirmar, Cancelar |
| **Confirmada** | `Confirmed` | Paciente confirmou | Paciente/Recepção | Cancelar, Check-in |
| **Recepcionado** | `CheckedIn` | Paciente chegou ao polo | Recepcionista | Iniciar atendimento |
| **Aguardando Médico** | `AwaitingDoctor` | Sala aberta, médico não entrou | Enfermeira | Médico entrar |
| **Em Consulta** | `InConsultation` | Médico e paciente em atendimento | Sistema | Finalizar, Sair |
| **Pendente Fechamento** | `PendingClosure` | Médico saiu sem finalizar | Sistema | Médico retomar/finalizar |
| **Finalizada** | `Completed` | Médico encerrou formalmente | Médico | Ver histórico |
| **Cancelada** | `Cancelled` | Cancelada antes de iniciar | Paciente/Médico/Admin | - |
| **Não Compareceu** | `NoShow` | Paciente não veio no dia | Sistema/Recepção | Reagendar |

---

## 🔐 Regras de Acesso por Papel

### Paciente
| Situação | Pode acessar? | Ação |
|----------|---------------|------|
| Consulta agendada para hoje | ✅ Sim | Entrar na sala |
| Consulta de dia anterior não finalizada | ❌ Não | Mostrar: "Consulta expirada" |
| Consulta finalizada | 👁️ Somente leitura | Ver resumo/receitas |
| Consulta cancelada | ❌ Não | - |

### Médico/Profissional
| Situação | Pode acessar? | Ação |
|----------|---------------|------|
| Consulta em andamento | ✅ Sim | Atender, finalizar |
| Consulta pendente de fechamento | ✅ Sim | Retomar e finalizar |
| Consulta finalizada | 👁️ Somente leitura | Ver histórico, emitir documentos |
| Qualquer consulta de seus pacientes | 👁️ Somente leitura | Ver prontuário |

### Enfermeira/Assistente
| Situação | Pode acessar? | Ação |
|----------|---------------|------|
| Consulta do dia - Recepcionado | ✅ Sim | Abrir sala, medir sinais |
| Consulta em andamento | ✅ Sim | Auxiliar na consulta |
| Consulta de dia anterior | ❌ Não | - |

---

## 💬 Mensagens de Confirmação (UX)

### Ao Sair da Consulta

#### Paciente tentando sair
```
┌────────────────────────────────────────────────────────┐
│  ⚠️  ATENÇÃO                                           │
│                                                        │
│  Você está saindo antes do médico finalizar a          │
│  consulta. O médico poderá encerrar sem sua presença.  │
│                                                        │
│  Deseja realmente sair?                                │
│                                                        │
│           [ Continuar na Consulta ]   [ Sair ]         │
└────────────────────────────────────────────────────────┘
```

#### Médico tentando sair SEM finalizar
```
┌────────────────────────────────────────────────────────┐
│  ⚠️  CONSULTA NÃO FINALIZADA                           │
│                                                        │
│  Você não finalizou a consulta formalmente.            │
│  A consulta ficará com status "Pendente Fechamento"    │
│  e você poderá retomar até o final do dia.             │
│                                                        │
│  Deseja:                                               │
│                                                        │
│  [ Voltar e Finalizar ]  [ Sair e Retomar Depois ]     │
└────────────────────────────────────────────────────────┘
```

#### Médico finalizando consulta
```
┌────────────────────────────────────────────────────────┐
│  ✅  FINALIZAR CONSULTA                                │
│                                                        │
│  Ao finalizar, a consulta será encerrada e o paciente  │
│  receberá o resumo do atendimento.                     │
│                                                        │
│  Certifique-se de que:                                 │
│  ✓ Registrou o SOAP corretamente                       │
│  ✓ Emitiu receitas necessárias                         │
│  ✓ Solicitou exames se aplicável                       │
│                                                        │
│  [ Cancelar ]              [ Confirmar Finalização ]   │
└────────────────────────────────────────────────────────┘
```

---

## ⏰ Regras de Timeout e Dias

### Consultas do Dia
- **Paciente**: Pode entrar a partir de 15 minutos antes até 30 minutos após horário
- **Médico**: Pode atender a qualquer momento do dia da consulta
- **Após meia-noite**: Consulta muda para "Não Compareceu" se não foi iniciada

### Consultas Pendentes de Fechamento
- **Médico tem até 24h** para finalizar uma consulta que saiu sem fechar
- **Após 24h**: Sistema marca como finalizada automaticamente com observação
- **Paciente não pode reentrar** em consulta pendente de fechamento

---

## 🔄 Transições Automáticas (Background Job)

```python
# Executar a cada hora
def processar_consultas_passadas():
    agora = datetime.now()
    
    # 1. Consultas do dia anterior que não iniciaram → NoShow
    consultas = Appointment.filter(
        data < agora.date(),
        status__in=['Scheduled', 'Confirmed', 'CheckedIn', 'AwaitingDoctor']
    )
    for c in consultas:
        c.status = 'NoShow'
        c.save()
    
    # 2. Consultas pendentes há mais de 24h → Completed (auto)
    consultas = Appointment.filter(
        status='PendingClosure',
        updated_at < agora - timedelta(hours=24)
    )
    for c in consultas:
        c.status = 'Completed'
        c.completion_note = 'Finalizada automaticamente após 24h'
        c.save()
```

---

## 📱 UX: Visualização na Lista de Consultas

### Para Médico

| Status | Cor | Ícone | Ação Primária |
|--------|-----|-------|---------------|
| Aguardando Médico | 🟡 Amarelo | 🔔 | **Entrar na Consulta** |
| Em Consulta | 🟢 Verde | 📹 | **Retomar Consulta** |
| Pendente Fechamento | 🟠 Laranja | ⚠️ | **Finalizar Consulta** |
| Finalizada | 🔵 Azul | ✓ | Ver Histórico |
| Cancelada | ⚫ Cinza | ✗ | - |

### Para Paciente

| Status | Cor | Mensagem | Ação |
|--------|-----|----------|------|
| Confirmada (hoje) | 🟢 Verde | "Pronto para começar" | Entrar na Sala |
| Em Consulta | 🟢 Verde | "Em andamento" | Entrar na Sala |
| Finalizada | 🔵 Azul | "Consulta realizada" | Ver Resumo |
| Não Compareceu | 🔴 Vermelho | "Você não compareceu" | Reagendar |

---

## 🛠️ Implementação Técnica

### 1. Atualizar Enum (Backend)
```csharp
public enum AppointmentStatus
{
    Scheduled,       // Agendada
    Confirmed,       // Confirmada pelo paciente
    CheckedIn,       // Recepcionado no polo
    AwaitingDoctor,  // Aguardando médico (substitui InProgress)
    InConsultation,  // Médico e paciente em atendimento
    PendingClosure,  // Médico saiu sem finalizar (substitui Abandoned)
    Completed,       // Finalizada pelo médico
    Cancelled,       // Cancelada
    NoShow           // Não compareceu
}
```

### 2. Middleware de Acesso
```csharp
// Validar acesso baseado no dia e papel
public bool CanAccessConsultation(User user, Appointment appointment)
{
    var isToday = appointment.ScheduledDate.Date == DateTime.Today;
    
    return (user.Role, appointment.Status) switch
    {
        // Médico sempre pode acessar suas consultas
        (Role.Professional, _) when appointment.ProfessionalId == user.Id => true,
        
        // Paciente só no dia e se não estiver pendente de fechamento
        (Role.Patient, AppointmentStatus.PendingClosure) => false,
        (Role.Patient, _) => isToday,
        
        // Assistente só no dia
        (Role.Assistant, _) => isToday,
        
        _ => false
    };
}
```

### 3. Job de Limpeza Noturno
```csharp
// Hangfire ou similar - executar às 00:30
[AutomaticRetry(Attempts = 3)]
public async Task ProcessarConsultasExpiradas()
{
    var ontem = DateTime.Today.AddDays(-1);
    
    // Não iniciadas → NoShow
    await _context.Appointments
        .Where(a => a.ScheduledDate.Date == ontem)
        .Where(a => a.Status == AppointmentStatus.Scheduled 
                 || a.Status == AppointmentStatus.Confirmed)
        .ExecuteUpdateAsync(s => s.SetProperty(a => a.Status, AppointmentStatus.NoShow));
    
    // Pendentes há mais de 24h → Completed
    var limite = DateTime.UtcNow.AddHours(-24);
    await _context.Appointments
        .Where(a => a.Status == AppointmentStatus.PendingClosure)
        .Where(a => a.UpdatedAt < limite)
        .ExecuteUpdateAsync(s => s
            .SetProperty(a => a.Status, AppointmentStatus.Completed)
            .SetProperty(a => a.CompletionNotes, "Finalizada automaticamente pelo sistema"));
}
```

---

## 📊 Comparação: Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Status confuso | "Abandonada" | "Pendente Fechamento" |
| Acesso paciente | Qualquer dia | Apenas dia da consulta |
| Alerta ao sair | Genérico | Contextualizado por papel |
| Médico fecha depois | Não era claro | Pode retomar até 24h |
| Limpeza automática | Manual | Job noturno |
| UX na lista | Status técnicos | Estados amigáveis + cores |

---

## ✅ Checklist de Implementação

- [x] Atualizar enum `AppointmentStatus` no backend (InProgress/Abandoned → Obsolete, valores 100/101)
- [x] Criar migration para converter `Abandoned` → `PendingClosure` (compatibilidade via valores obsoletos)
- [x] Implementar validação de acesso no `TeleconsultationHub.JoinConsultation()`
- [ ] Criar job Hangfire para processamento noturno (NoShow + auto-complete PendingClosure)
- [x] Atualizar mensagens de confirmação no frontend (paciente) - alerta diferenciado
- [x] Atualizar mensagens de confirmação no frontend (médico) - alerta "Pendente Fechamento"
- [x] Atualizar cores e labels na lista de consultas (`getStatusLabel`, `getStatusVariant`)
- [x] Implementar reconexão automática para médico em consultas PendingClosure
- [x] Implementar evento `AccessDenied` + redirect para consultas expiradas
- [ ] Testes automatizados para transições de estado

### Validações de Acesso Implementadas (09/02/2026)

| Papel | Consulta finalizada | Consulta pendente fechamento | Consulta de outro dia |
|-------|---------------------|------------------------------|----------------------|
| Paciente | ❌ Bloqueado | ❌ Bloqueado (médico finalizando) | ❌ Bloqueado |
| Assistente | ❌ Bloqueado | ✅ Pode entrar | ❌ Bloqueado |
| Médico | ❌ Bloqueado | ✅ Retoma (→ InConsultation) | ✅ Pode entrar |

---

## 📚 Referências

- CFM Resolução 2.314/2022 - Telemedicina no Brasil
- HIMSS - Telehealth Best Practices
- HL7 FHIR - Appointment Resource Status
- UX Research - Healthcare Scheduling Patterns
