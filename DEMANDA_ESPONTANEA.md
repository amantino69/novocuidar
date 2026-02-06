# 🚨 DEMANDA ESPONTÂNEA - Sistema de Atendimento Urgente

## 📋 Visão Geral

Sistema completo de demanda espontânea (walk-in) que permite à recepcionista registrar pacientes que chegam sem agendamento prévio, com classificação de risco e notificação automática para médicos.

---

## 🔄 Fluxo Completo

### 1. Recepcionista - Registro da Demanda

**Acesso:** `/recepcao/demanda-espontanea`

**Passo a passo:**

1. **Buscar Paciente**
   - Digite nome, CPF ou telefone
   - Busca com debounce (300ms)
   - Resultados em tempo real

2. **Selecionar Especialidade**
   - Lista todas especialidades disponíveis
   - Mostra quantidade de médicos por especialidade

3. **Classificar Urgência (Protocolo de Manchester)**
   - 🔴 **Vermelho**: Crítico - Atendimento imediato
   - 🟠 **Laranja**: Muito urgente - até 30 min
   - 🟡 **Amarelo**: Urgente - até 1 hora
   - 🟢 **Verde**: Pouco urgente - até 2 horas
   - Opcional: Adicionar queixa principal

4. **Selecionar Médico** (Opcional)
   - Sistema mostra médicos da especialidade
   - Status online/offline
   - Opção de atribuição automática

**Resultado:**
- Consulta criada com status `CheckedIn`
- Entrada na fila de espera com prioridade
- Notificação enviada ao médico via SignalR

---

### 2. Enfermeira - Consultório Digital

**Visualização da Fila:**

```typescript
// Painel mostra demandas espontâneas destacadas
interface WaitingItem {
  isSpontaneous: boolean;  // Destaque visual
  urgencyLevel: 'Red' | 'Orange' | 'Yellow' | 'Green';
  chiefComplaint: string;
  waitingTime: number;  // minutos
  position: number;
}
```

**Ações disponíveis:**
- Ver fila ordenada por urgência/chegada
- Chamar próximo paciente
- Iniciar teleconsulta

---

### 3. Médico - Notificação em Tempo Real

#### Notificação SignalR

Quando uma demanda espontânea é criada, o médico recebe:

**Evento:** `NewSpontaneousDemand`

**Dados:**
```typescript
{
  appointmentId: string;
  patientName: string;
  patientAge: string;
  chiefComplaint: string;
  urgencyLevel: 'Red' | 'Orange' | 'Yellow' | 'Green';
  urgencyColor: '#dc3545' | '#fd7e14' | '#ffc107' | '#28a745';
  position: number;
  estimatedWaitMinutes: number;
  requiresImmediateAttention: boolean;  // true para Red/Orange
  meetLink: string;  // Link da videoconferência
}
```

#### Alertas Visuais e Sonoros

**Para urgências Red/Orange:**
- 🔔 Som de notificação (bell.mp3)
- 🚨 Banner vermelho piscante
- ⏰ Contador de tempo esperando

**Para urgências Yellow/Green:**
- 🔔 Som suave (notification.mp3)
- 💙 Banner azul
- 📊 Posição na fila

---

## 🗄️ Estrutura de Dados

### Backend Entities

#### Appointment
```csharp
public enum AppointmentType {
    // ... existing
    SpontaneousDemand  // NOVO
}

public class Appointment {
    public AppointmentType Type { get; set; }
    public DateTime? CheckInTime { get; set; }  // Hora do registro
    public string? Observation { get; set; }    // Queixa principal
}
```

#### WaitingList
```csharp
public class WaitingList {
    public int Priority { get; set; }  // 0-3 baseado na urgência
    public UrgencyLevel? UrgencyLevel { get; set; }
    public bool IsSpontaneousDemand { get; set; }
    public string? ChiefComplaint { get; set; }
    public int Position { get; set; }
}

public enum UrgencyLevel {
    Green = 0,   // Baixa
    Yellow = 1,  // Média
    Orange = 2,  // Alta
    Red = 3      // Crítica
}
```

---

## 🔌 APIs Backend

### ReceptionistController

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/receptionist/spontaneous-demand` | POST | Criar demanda espontânea |
| `/api/receptionist/patients/search?query={q}` | GET | Buscar pacientes |
| `/api/receptionist/specialties` | GET | Listar especialidades |
| `/api/receptionist/professionals/by-specialty/{id}` | GET | Médicos da especialidade |
| `/api/receptionist/waiting-list` | GET | Fila de espera |

### Exemplo de Requisição

```json
POST /api/receptionist/spontaneous-demand
{
  "patientId": "uuid",
  "specialtyId": "uuid",
  "professionalId": "uuid",  // opcional
  "urgencyLevel": "Red",
  "chiefComplaint": "Dor torácica intensa há 30 minutos"
}
```

### Resposta

```json
{
  "success": true,
  "message": "Demanda espontânea registrada com sucesso",
  "appointmentId": "uuid",
  "position": 1,
  "professionalName": "Dr. João Silva",
  "estimatedWaitMinutes": 5
}
```

---

## 🔔 Notificações SignalR

### SchedulingHub - Novos Métodos

```typescript
// Médico se inscreve para receber demandas da sua especialidade
schedulingHub.invoke('JoinSpontaneousDemandQueue', specialtyId);

// Escutar novas demandas
schedulingHub.on('NewSpontaneousDemand', (notification) => {
  // Mostrar alerta
  // Tocar som
  // Adicionar à lista
});

// Escutar atualizações da fila
schedulingHub.on('SpontaneousDemandQueueUpdated', (notification) => {
  // Atualizar contador
});
```

---

## 🎨 Frontend Components

### SpontaneousDemandComponent

**Arquivo:** `frontend/src/app/pages/user/receptionist/spontaneous-demand/`

**Características:**
- Busca de pacientes com debounce
- Stepper visual (4 etapas)
- Classificação de risco colorida
- Fila de espera em tempo real
- Responsivo (mobile-first)

**Estados:**
```typescript
step: 'search' | 'specialty' | 'urgency' | 'professional'
```

---

## 🚀 Como Testar

### 1. Backend

```powershell
# Iniciar backend
cd C:\telecuidar
dotnet run --project backend/WebAPI/WebAPI.csproj
```

### 2. Frontend

```powershell
# Iniciar frontend
cd C:\telecuidar\frontend
ng serve --host 0.0.0.0 --port 4200
```

### 3. Fluxo de Teste

1. **Login como Recepcionista**
   - Email: `rec_ma@telecuidar.com`
   - Senha: `123`

2. **Acessar Demanda Espontânea**
   - No painel, clicar no card vermelho "Demanda Espontânea"
   - Ou navegar para `/recepcao/demanda-espontanea`

3. **Criar Demanda**
   - Buscar paciente: "Maria Silva"
   - Especialidade: "Clínica Geral"
   - Urgência: "Vermelho - Crítica"
   - Queixa: "Dor torácica intensa"
   - Médico: "Dr. Geraldo Tadeu"

4. **Verificar Fila**
   - Painel lateral mostra a fila atualizada
   - Paciente aparece com badge vermelho

5. **Login como Médico** (em aba privada/outro navegador)
   - Email: `med_gt@telecuidar.com`
   - Senha: `123`
   - Verificar se recebeu notificação

6. **Login como Enfermeira**
   - Email: `enf_do@telecuidar.com`
   - Senha: `123`
   - Ver demanda no Consultório Digital

---

## 🔧 Melhorias Futuras (Sugeridas)

### Prioridade Alta
- [ ] Notificação push para médicos (Service Worker)
- [ ] Som de alerta customizável
- [ ] Dashboard de métricas (tempo médio de espera, etc)
- [ ] Histórico de demandas do dia

### Prioridade Média
- [ ] Transferência de demanda para outro médico
- [ ] Reagendamento de demanda para consulta regular
- [ ] Impressão de senha/ficha de atendimento
- [ ] QR Code para acompanhamento da fila

### Prioridade Baixa
- [ ] Integração com totem de auto-atendimento
- [ ] SMS/WhatsApp para notificar paciente
- [ ] Estatísticas por tipo de urgência
- [ ] Treinamento de IA para sugerir especialidade

---

## 📊 Métricas de Sucesso

Para avaliar a eficácia do sistema:

1. **Tempo de Resposta**
   - Meta: Urgência vermelha atendida em < 10 minutos
   - Urgência laranja em < 30 minutos

2. **Taxa de Atendimento**
   - Meta: 95% das demandas atendidas no tempo estimado

3. **Satisfação**
   - Feedback do paciente após atendimento
   - Avaliação de 1-5 estrelas

4. **Uso do Sistema**
   - Número de demandas/dia
   - Distribuição por urgência
   - Especialidades mais demandadas

---

## 🐛 Troubleshooting

### Notificação não chegou ao médico

1. Verificar se médico está logado
2. Verificar console do navegador (erros SignalR)
3. Checar logs do backend:
   ```powershell
   docker logs telecuidar-backend --tail=50 | grep "Spontaneous"
   ```

### Paciente não aparece na busca

1. Verificar se paciente existe no banco
2. Checar role do usuário (deve ser PATIENT)
3. Testar endpoint direto:
   ```bash
   curl http://localhost:5239/api/receptionist/patients/search?query=maria
   ```

### Fila não atualiza

1. Verificar intervalo de refresh (30s)
2. Forçar atualização manual (botão refresh)
3. Verificar permissões do usuário

---

## 📚 Referências

- Protocolo de Manchester: https://www.protocolodemanchester.com.br/
- SignalR Hubs: https://docs.microsoft.com/pt-br/aspnet/core/signalr/hubs
- Angular Signals: https://angular.io/guide/signals

---

## 📅 Changelog

### [1.0.0] - 2026-02-01

#### Adicionado
- Sistema completo de demanda espontânea
- Classificação de risco (4 níveis)
- Notificações SignalR para médicos
- Fila de espera com priorização
- Busca inteligente de pacientes
- Interface responsiva com stepper

#### Backend
- Novo endpoint `POST /receptionist/spontaneous-demand`
- Enum `UrgencyLevel` (Green, Yellow, Orange, Red)
- Campos `IsSpontaneousDemand`, `ChiefComplaint` em `WaitingList`
- Notificações via `SchedulingHub`

#### Frontend
- Componente `SpontaneousDemandComponent`
- Rota `/recepcao/demanda-espontanea`
- Botão destacado no painel da recepcionista
- Integração com SignalR

---

## 👥 Contato e Suporte

Para dúvidas ou sugestões sobre o sistema de demanda espontânea:
- Abrir issue no GitHub: `github.com/amantino69/novocuidar/issues`
- Email: amantino@yahoo.com

---

**Desenvolvido com ❤️ para o TeleCuidar POC**
