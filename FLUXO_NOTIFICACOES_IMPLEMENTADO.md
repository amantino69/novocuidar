# ✅ FLUXO DE NOTIFICAÇÕES - DEMANDA ESPONTÂNEA E CHECK-IN

## 🎯 O que foi implementado

O sistema agora possui um fluxo completo de notificações em tempo real para:

1. **Check-in de Paciente** → Médico recebe aviso sonoro e visual
2. **Demanda Espontânea** → Enfermeira visualiza no painel
3. **Registro de Demanda** → Médico recebe notificação com som

---

## 📊 Fluxo Completo

### 1️⃣ RECEPCIONISTA FAZ CHECK-IN

```
Recepcionista clica no botão "✅ Check-in" 
    ↓
Backend atualiza status → CheckedIn
    ↓
Backend cria entrada na fila de espera
    ↓
Backend envia notificação SignalR ao médico
    ↓
Frontend recebe via RealTimeService
    ↓
Modal aparece com AVISO SONORO (urgent-alert.mp3)
    ↓
Médico clica "Entrar na Consulta"
```

**Arquivos modificados:**
- `backend/WebAPI/Controllers/ReceptionistController.cs` - Adicionado `IRealTimeNotificationService`
- `frontend/src/app/shared/components/patient-waiting-modal/patient-waiting-modal.component.ts` - Importado `SoundNotificationService` e toca som

---

### 2️⃣ RECEPCIONISTA REGISTRA DEMANDA ESPONTÂNEA

```
Recepcionista cria Demanda Espontânea
    ↓
Backend recebe dados (paciente, especialidade, urgência)
    ↓
Backend cria Appointment com status CheckedIn
    ↓
Backend cria entrada WaitingList com:
  - Priority (baseado em UrgencyLevel)
  - IsSpontaneousDemand = true
  - ChiefComplaint (queixa do paciente)
    ↓
Backend envia notificação SignalR aos médicos da especialidade
    ↓
MÉDICO: Recebe notificação + som (urgent-alert para Red/Orange)
    ↓
ENFERMEIRA: Vê alerta vermelho no Consultório Digital
```

**Arquivos:**
- Backend: `backend/WebAPI/Controllers/ReceptionistController.cs` (método `RegisterSpontaneousDemand`)
- Frontend (Médico): Dashboard com notificação e som
- Frontend (Enfermeira): Digital Office com alerta visual

---

## 🔔 ARQUIVOS MODIFICADOS

### Backend

#### `ReceptionistController.cs`
```csharp
// ✅ Injetar IRealTimeNotificationService
private readonly IRealTimeNotificationService _realTimeNotification;

// ✅ CheckIn - Notificar médico
await _realTimeNotification.NotifyUserAsync(
    appointment.ProfessionalId.ToString(),
    new UserNotificationUpdate { ... }
);

// ✅ SpontaneousDemand - Notificar grupos
await _schedulingHub.Clients.Group($"user_{professional.Id}")
    .SendAsync("NewSpontaneousDemand", notification);
```

### Frontend

#### 1. **patient-waiting-modal.component.ts**
```typescript
// ✅ Importar SoundNotificationService
import { SoundNotificationService } from '...';

// ✅ Reproduzir som ao receber notificação
private playNotificationSound(): void {
  this.soundService.playUrgentAlert();
}
```

#### 2. **digital-office.ts** (Enfermeira)
```typescript
// ✅ Subscribe a novas notificações
const notificationSub = this.realTimeService.newNotification$.subscribe(
  (notification: any) => {
    this.handleNewNotification(notification);
  }
);

// ✅ Mostrar alerta de demanda espontânea
private handleNewNotification(notification: any): void {
  if (notification?.type === 'PatientWaiting') {
    this.spontaneousDemands = [demandItem, ...this.spontaneousDemands];
    this.showSpontaneousAlert = true;
    // Auto-hide após 10 segundos
  }
}
```

#### 3. **digital-office.html**
```html
<!-- ✅ Alerta de demanda espontânea -->
@if (showSpontaneousAlert && spontaneousDemands.length > 0) {
  <div class="digital-office__spontaneous-alert">
    <div class="alert-header">
      <app-icon name="alert-circle" [size]="24" />
      <h3>🚨 Nova Demanda Espontânea!</h3>
      <button class="alert-close" (click)="showSpontaneousAlert = false">×</button>
    </div>
    <div class="alert-content">
      <p class="alert-message">{{ spontaneousDemands[0].message }}</p>
      <small class="alert-time">{{ spontaneousDemands[0].createdAt | date:'HH:mm:ss' }}</small>
    </div>
  </div>
}
```

---

## 🎵 SONS DISPONÍVEIS

Arquivo: `sound-notification.service.ts`

| Som | Urgência | Quando Toca |
|-----|----------|------------|
| `urgent-alert.mp3` 🔴 | Red/Orange | Check-in ou Demanda Crítica |
| `notification.mp3` 📢 | Yellow/Green | Demanda Normal |
| `success.mp3` ✅ | - | Ação com sucesso |
| `warning.mp3` ⚠️ | - | Avisos |

---

## 🧪 COMO TESTAR

### Teste 1: CHECK-IN COM AVISO SONORO

1. Abra dois navegadores:
   - **Aba 1**: Painel do Recepcionista (http://localhost:4200/recepcao)
   - **Aba 2**: Painel do Médico (http://localhost:4200/dashboard)

2. No Painel da Recepcionista:
   - Clique "✅ Check-in" em uma consulta agendada
   
3. Resultado esperado:
   - ✅ Médico recebe modal com aviso
   - 🔊 Som `urgent-alert.mp3` toca automaticamente
   - 🎯 Modal pulsante aparece no centro

---

### Teste 2: DEMANDA ESPONTÂNEA COM ALERTA NA ENFERMEIRA

1. Abra dois navegadores:
   - **Aba 1**: Recepcionista (http://localhost:4200/recepcao)
   - **Aba 2**: Enfermeira/Consultório Digital (http://localhost:4200/consultorio-digital)
   - **Aba 3**: Médico (http://localhost:4200/dashboard)

2. No Painel da Recepcionista:
   - Clique em "Demanda Espontânea"
   - Preencha os dados (paciente, especialidade, urgência)
   - Clique "Registrar"

3. Resultados esperados:
   - ✅ **Enfermeira**: Alerta vermelho aparece no topo (10 segundos)
   - ✅ **Médico**: Notificação com som (urgent-alert para urgência crítica)
   - ✅ **Fila**: Paciente aparece com badge de demanda espontânea

---

## 📱 FLUXO VISUAL

```
┌─────────────────────────────────────────────────────────────┐
│                    RECEPCIONISTA                             │
│                                                              │
│  [Consulta Agendada]  →  [✅ Check-in]                      │
│                              ↓                               │
└──────────────────────────────┼──────────────────────────────┘
                               │
                    SignalR "NewNotification"
                               │
                ┌──────────────┬──────────────┐
                ↓              ↓              ↓
            ┌─────────┐  ┌─────────┐  ┌─────────┐
            │ MÉDICO  │  │ENFERMEIRA│  │ FILA   │
            └─────────┘  └─────────┘  └─────────┘
            
            Modal com  │ Alerta no  │ Paciente
            aviso      │ topo da    │ entra na
            sonoro     │ tela       │ fila
            
            🔊 Som     │ 🚨 Banner  │ ➕ Entrada
               toca   │    Red     │    Nova
```

---

## 🔧 CONFIGURAÇÃO AVANÇADA

### Desabilitar Som (Menu do Usuário)

```typescript
// Usuário pode silenciar notificações
soundService.toggleMute();

// Verificar status
if (soundService.isSoundMuted()) {
  console.log("Som silenciado");
}
```

### Customizar Sons

Edite `sound-notification.service.ts`:

```typescript
private preloadSound(key: string, path: string): void {
  const audio = new Audio(path);  // ← Alterar caminho do arquivo
  // ...
}
```

---

## 📋 CHECKLIST DE VERIFICAÇÃO

- [x] Backend envia notificações SignalR em check-in
- [x] Backend envia notificações para demanda espontânea
- [x] Frontend (Médico) recebe e reproduz som
- [x] Frontend (Médico) modal aparece com dados corretos
- [x] Frontend (Enfermeira) alerta aparece no Consultório Digital
- [x] Fila de espera atualiza em tempo real
- [x] Sons carregam corretamente
- [x] Sem erros de compilação Angular

---

## 🐛 POSSÍVEIS PROBLEMAS

### Som não toca
**Causa**: Navegador bloqueou autoplay de áudio
**Solução**: 
1. Verificar console do navegador (F12)
2. Usuário deve interagir com página antes (clique)
3. Permitir áudio nas configurações do site

### Notificação não chega
**Causa**: Conexão SignalR não estabelecida
**Solução**:
1. Verificar se backend está rodando
2. Verificar logs do backend: `docker logs telecuidar-backend`
3. Verificar console do navegador (F12)

### Fila não atualiza
**Causa**: Real-time service não conectado
**Solução**:
1. Recarregar página
2. Verificar conexão internet
3. Fazer logout e login novamente

---

## 📈 PRÓXIMOS PASSOS (FUTURO)

1. **Web Push Notifications** - Notificar mesmo com aba fechada
2. **Notificações por Email** - Backup se SignalR falhar
3. **Dashboard de Métricas** - Tempo médio de resposta
4. **Histórico de Notificações** - Manter registro
5. **Configuração de Preferências** - Usuário escolhe quais notificações
6. **Mobile App** - Aplicativo nativo com notificações push

---

## 📞 SUPORTE

Se encontrar problemas:

1. Verificar logs do backend:
   ```bash
   docker logs telecuidar-backend -f
   ```

2. Verificar console do navegador (F12)

3. Testar conexão SignalR:
   - Abrir DevTools → Network
   - Procurar por "WebSocket"
   - Deve estar em "101 Switching Protocols"

4. Abrir issue no GitHub:
   - https://github.com/amantino69/novocuidar/issues

---

**Implementado em**: 02/02/2026
**Versão**: 1.0.0
**Status**: ✅ Completo e Testado
