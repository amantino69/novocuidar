# 🔔 Sistema de Notificação In-App - Sincronização Médico/Enfermeira

## 🎯 Objetivo

**Resolver o problema**: Enfermeira abre consulta A, médico entra na consulta B (consultas diferentes!)

**Solução**: Quando enfermeira clica "Iniciar Atendimento", médico recebe:
- ✅ **Alerta Visual** - Badge vermelho + Mensagem na tela
- ✅ **Alerta Sonoro** - Som de notificação
- ✅ **Link Direto** - Botão "Entrar na Consulta" que abre a consulta CORRETA

---

## 🔄 Fluxo Completo

```
┌──────────────────────────────────────────────────────────────┐
│ FLUXO DE SINCRONIZAÇÃO                                       │
└──────────────────────────────────────────────────────────────┘

1️⃣ RECEPCIONISTA (Sistema)
   └─► Paciente chega
   └─► Clica "Marcar Presença"
   └─► Appointment.Status = CheckedIn
   └─► Paciente entra na fila (WaitingList)

2️⃣ ENFERMEIRA (Consultório Digital)
   └─► Visualiza fila de espera
   └─► Clica em "Chamar Próximo Paciente"
   └─► Paciente entra fisicamente no consultório
   └─► Enfermeira clica "Iniciar Atendimento"
       │
       ├─► Appointment.Status = InProgress
       ├─► Appointment.ConsultationStartedAt = now()
       ├─► Appointment.AssistantId = enfermeira_logged_in
       └─► 🔔 DISPARA NOTIFICAÇÃO PARA O MÉDICO

3️⃣ NOTIFICAÇÃO ENVIADA (SignalR)
   └─► Backend → MedicalDevicesHub.SendNotificationToDoctor()
       │
       ├─► Envia via SignalR para médico específico
       ├─► Payload:
       │   {
       │     "appointmentId": "guid-da-consulta",
       │     "patientName": "João Silva",
       │     "patientAge": 65,
       │     "specialty": "Cardiologia",
       │     "assistantName": "Enfermeira Maria",
       │     "waitingTime": 5, // minutos
       │     "meetLink": "https://meet.telecuidar.com.br/room-xxx"
       │   }
       │
       └─► Incrementa Appointment.NotificationsSentCount++

4️⃣ MÉDICO (Sistema Aberto)
   └─► Tela do médico recebe notificação SignalR
       │
       ├─► 🔴 Badge no menu: "1 paciente aguardando"
       ├─► 🔔 Som de notificação (beep.mp3)
       ├─► 🎨 Modal/Toast aparece:
       │   ┌─────────────────────────────────────┐
       │   │ 👤 Paciente Aguardando             │
       │   ├─────────────────────────────────────┤
       │   │ Nome: João Silva                    │
       │   │ Idade: 65 anos                      │
       │   │ Especialidade: Cardiologia          │
       │   │ Apoio: Enfermeira Maria             │
       │   │ Aguardando: 5 minutos               │
       │   │                                     │
       │   │ [🚪 Entrar na Consulta] [❌ Fechar] │
       │   └─────────────────────────────────────┘
       │
       └─► Médico clica "Entrar na Consulta"
           └─► Redireciona para /teleconsultation/:appointmentId
               └─► Abre a sala Jitsi CORRETA

5️⃣ MÉDICO ENTRA (Atualização de Status)
   └─► Appointment.Status = InConsultation
   └─► Appointment.DoctorJoinedAt = now()
   └─► Notificação SignalR para enfermeira: "Médico entrou"

6️⃣ CONSULTA REALIZADA
   └─► Médico e enfermeira na mesma sala
   └─► Sinais vitais aparecem em tempo real
   └─► Chat funciona
   └─► Vídeo sincronizado

7️⃣ ENCERRAMENTO
   └─► Médico clica "Encerrar Consulta"
       ├─► Appointment.Status = Completed
       ├─► Appointment.ConsultationEndedAt = now()
       ├─► Calcula duração
       └─► Remove da fila

8️⃣ PRÓXIMO PACIENTE
   └─► Enfermeira clica "Chamar Próximo"
   └─► Volta ao passo 2️⃣
```

---

## 💻 Implementação Backend

### 1. Endpoint: Iniciar Atendimento

```csharp
// AppointmentController.cs

[HttpPost("{id}/start-consultation")]
[Authorize(Roles = "ASSISTANT")]
public async Task<IActionResult> StartConsultation(Guid id)
{
    var appointment = await _context.Appointments
        .Include(a => a.Patient)
        .Include(a => a.Professional)
        .Include(a => a.Specialty)
        .FirstOrDefaultAsync(a => a.Id == id);

    if (appointment == null)
        return NotFound("Consulta não encontrada");

    if (appointment.Status != AppointmentStatus.CheckedIn)
        return BadRequest("Paciente não fez check-in");

    // Atualizar appointment
    appointment.Status = AppointmentStatus.InProgress;
    appointment.ConsultationStartedAt = DateTime.UtcNow;
    appointment.AssistantId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier).Value);
    appointment.NotificationsSentCount++;
    appointment.LastNotificationSentAt = DateTime.UtcNow;

    await _context.SaveChangesAsync();

    // 🔔 ENVIAR NOTIFICAÇÃO PARA O MÉDICO
    var assistant = await _context.Users.FindAsync(appointment.AssistantId);
    
    var notification = new
    {
        AppointmentId = appointment.Id,
        PatientName = appointment.Patient.Name,
        PatientAge = CalculateAge(appointment.Patient.PatientProfile?.BirthDate),
        Specialty = appointment.Specialty.Name,
        AssistantName = assistant?.Name,
        WaitingTime = (DateTime.UtcNow - appointment.CheckInTime).Value.TotalMinutes,
        MeetLink = appointment.MeetLink
    };

    await _medicalDevicesHub.Clients
        .User(appointment.ProfessionalId.ToString())
        .SendAsync("PatientWaitingNotification", notification);

    return Ok(new
    {
        Success = true,
        Message = "Atendimento iniciado. Médico foi notificado.",
        Appointment = appointment
    });
}
```

### 2. Hub SignalR: MedicalDevicesHub

```csharp
// MedicalDevicesHub.cs

public class MedicalDevicesHub : Hub
{
    // Quando médico se conecta, entrar no grupo do userId
    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier; // ClaimsPrincipal UserId
        await Groups.AddToGroupAsync(Context.ConnectionId, userId);
        await base.OnConnectedAsync();
    }

    // Notificar médico específico
    public async Task NotifyDoctorPatientWaiting(object notification)
    {
        var appointmentId = notification.GetType().GetProperty("AppointmentId")?.GetValue(notification);
        await Clients.User(Context.UserIdentifier).SendAsync("PatientWaitingNotification", notification);
    }

    // Quando médico entra na consulta
    public async Task DoctorJoinedConsultation(Guid appointmentId)
    {
        // Atualizar status no banco
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment != null)
        {
            appointment.Status = AppointmentStatus.InConsultation;
            appointment.DoctorJoinedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        // Notificar enfermeira que médico entrou
        await Clients.Group($"appointment-{appointmentId}")
            .SendAsync("DoctorJoinedRoom");
    }
}
```

### 3. Configuração do SignalR no Program.cs

```csharp
// Program.cs

// Adicionar SignalR com autenticação
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
});

// Configurar autenticação para SignalR
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Permitir token via query string (para SignalR)
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                
                if (!string.IsNullOrEmpty(accessToken) && 
                    path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

// Mapear hubs
app.MapHub<MedicalDevicesHub>("/hubs/medical-devices");
```

---

## 🎨 Implementação Frontend

### 1. Serviço SignalR (Angular)

```typescript
// src/app/core/services/signalr.service.ts

import { Injectable } from '@angular/core';
import * as signalR from '@microsoft/signalr';
import { BehaviorSubject, Observable } from 'rxjs';

export interface PatientWaitingNotification {
  appointmentId: string;
  patientName: string;
  patientAge: number;
  specialty: string;
  assistantName: string;
  waitingTime: number;
  meetLink: string;
}

@Injectable({ providedIn: 'root' })
export class SignalRService {
  private hubConnection?: signalR.HubConnection;
  private patientWaitingSubject = new BehaviorSubject<PatientWaitingNotification | null>(null);
  
  public patientWaiting$ = this.patientWaitingSubject.asObservable();

  constructor() {}

  public startConnection(token: string): void {
    this.hubConnection = new signalR.HubConnectionBuilder()
      .withUrl('https://api.telecuidar.com.br/hubs/medical-devices', {
        accessTokenFactory: () => token
      })
      .withAutomaticReconnect()
      .build();

    this.hubConnection
      .start()
      .then(() => console.log('✅ SignalR Connected'))
      .catch(err => console.error('❌ SignalR Error:', err));

    // Escutar notificações de paciente aguardando
    this.hubConnection.on('PatientWaitingNotification', (notification: PatientWaitingNotification) => {
      console.log('🔔 Paciente aguardando:', notification);
      this.patientWaitingSubject.next(notification);
      this.playNotificationSound();
    });
  }

  public stopConnection(): void {
    this.hubConnection?.stop();
  }

  public doctorJoinedConsultation(appointmentId: string): void {
    this.hubConnection?.invoke('DoctorJoinedConsultation', appointmentId);
  }

  private playNotificationSound(): void {
    const audio = new Audio('/assets/sounds/notification.mp3');
    audio.play();
  }
}
```

### 2. Componente: Notificação Modal

```typescript
// src/app/shared/components/patient-waiting-modal/patient-waiting-modal.component.ts

import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { SignalRService, PatientWaitingNotification } from '@core/services/signalr.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-patient-waiting-modal',
  template: `
    <div class="modal" *ngIf="notification" @fadeIn>
      <div class="modal-content">
        <div class="modal-header">
          <h2>👤 Paciente Aguardando</h2>
          <button (click)="close()">❌</button>
        </div>
        
        <div class="modal-body">
          <p><strong>Nome:</strong> {{ notification.patientName }}</p>
          <p><strong>Idade:</strong> {{ notification.patientAge }} anos</p>
          <p><strong>Especialidade:</strong> {{ notification.specialty }}</p>
          <p><strong>Apoio:</strong> {{ notification.assistantName }}</p>
          <p class="waiting-time" [class.urgent]="notification.waitingTime > 10">
            <strong>Aguardando:</strong> {{ notification.waitingTime }} minutos
          </p>
        </div>
        
        <div class="modal-footer">
          <button class="btn-primary" (click)="enterConsultation()">
            🚪 Entrar na Consulta
          </button>
          <button class="btn-secondary" (click)="close()">
            Fechar
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .modal {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      z-index: 9999;
      background: white;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
      min-width: 400px;
      animation: slideDown 0.3s ease-out;
    }
    
    .modal-header {
      background: #2c3e50;
      color: white;
      padding: 16px;
      border-radius: 12px 12px 0 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .modal-body {
      padding: 20px;
    }
    
    .waiting-time.urgent {
      color: red;
      font-weight: bold;
    }
    
    .modal-footer {
      padding: 16px;
      display: flex;
      gap: 12px;
      justify-content: flex-end;
    }
    
    @keyframes slideDown {
      from { transform: translate(-50%, -60%); opacity: 0; }
      to { transform: translate(-50%, -50%); opacity: 1; }
    }
  `]
})
export class PatientWaitingModalComponent implements OnInit, OnDestroy {
  notification: PatientWaitingNotification | null = null;
  private subscription?: Subscription;

  constructor(
    private signalRService: SignalRService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.subscription = this.signalRService.patientWaiting$.subscribe(
      notification => {
        this.notification = notification;
      }
    );
  }

  ngOnDestroy(): void {
    this.subscription?.unsubscribe();
  }

  enterConsultation(): void {
    if (this.notification) {
      // Avisar backend que médico entrou
      this.signalRService.doctorJoinedConsultation(this.notification.appointmentId);
      
      // Redirecionar para consulta
      this.router.navigate(['/teleconsultation', this.notification.appointmentId]);
      
      this.close();
    }
  }

  close(): void {
    this.notification = null;
  }
}
```

### 3. Badge de Notificação no Menu

```typescript
// src/app/core/components/header/header.component.ts

export class HeaderComponent {
  unreadNotifications = 0;

  constructor(private signalRService: SignalRService) {
    this.signalRService.patientWaiting$.subscribe(notification => {
      if (notification) {
        this.unreadNotifications++;
      }
    });
  }
}
```

```html
<!-- header.component.html -->
<nav class="navbar">
  <a routerLink="/dashboard">
    <span class="notification-badge" *ngIf="unreadNotifications > 0">
      {{ unreadNotifications }}
    </span>
    Início
  </a>
</nav>
```

---

## 📱 Arquivo de Som (notification.mp3)

Colocar em: `frontend/src/assets/sounds/notification.mp3`

Opções:
- Som de campainha discreto
- Beep curto
- Sino de notificação

---

## ✅ Checklist de Implementação

### Backend
- [x] Adicionar campos em Appointment (AssistantId, ConsultationStartedAt, etc)
- [ ] Criar endpoint POST /api/appointment/{id}/start-consultation
- [ ] Configurar SignalR no Program.cs
- [ ] Criar/expandir MedicalDevicesHub com método de notificação
- [ ] Testar envio de notificação para usuário específico

### Frontend
- [ ] Instalar @microsoft/signalr (`npm install @microsoft/signalr`)
- [ ] Criar SignalRService
- [ ] Criar PatientWaitingModalComponent
- [ ] Adicionar badge de notificação no header
- [ ] Adicionar arquivo notification.mp3
- [ ] Conectar SignalR no login
- [ ] Testar notificação end-to-end

---

## 🧪 Testes

### Cenário 1: Médico Online
1. Médico loga no sistema (SignalR conecta)
2. Enfermeira marca presença do paciente
3. Enfermeira clica "Iniciar Atendimento"
4. Médico recebe notificação IMEDIATAMENTE
5. Médico clica "Entrar na Consulta"
6. Médico e enfermeira na mesma sala ✅

### Cenário 2: Médico Offline
1. Enfermeira clica "Iniciar Atendimento"
2. Sistema tenta enviar via SignalR (falha - médico offline)
3. Notificação fica armazenada no banco (NotificationCenter)
4. Quando médico logar, carregar notificações pendentes
5. Exibir modal com pacientes aguardando

---

## 🚀 Próximos Passos

1. Implementar backend (endpoints + SignalR)
2. Implementar frontend (SignalRService + Modal)
3. Testar localmente
4. Deploy em produção
5. Monitorar logs de notificações

**Após esta implementação, o problema de sincronização estará RESOLVIDO!** 🎉
