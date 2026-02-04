import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { SignalRService, PatientWaitingNotification } from '../../../core/services/signalr.service';
import { AppointmentsService } from '../../../core/services/appointments.service';
import { SoundNotificationService } from '../../../core/services/sound-notification.service';
import { RealTimeService } from '../../../core/services/real-time.service';

@Component({
  selector: 'app-patient-waiting-modal',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div *ngIf="notification" class="modal-overlay">
      <div class="modal-container">
        <div class="modal-header">
          <div class="icon-wrapper">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z"/>
              <path d="M12 16v-4"/>
              <path d="M12 8h.01"/>
            </svg>
          </div>
          <h2>{{ notification.title }}</h2>
          <button class="close-btn" (click)="dismiss()" aria-label="Fechar">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <p class="message">{{ notification.message }}</p>
          
          <div class="info-grid">
            <div class="info-item">
              <span class="label">Horário da notificação:</span>
              <span class="value">{{ notification.createdAt | date:'HH:mm' }}</span>
            </div>
          </div>

          <div class="pulse-indicator">
            <div class="pulse-ring"></div>
            <div class="pulse-dot"></div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn btn-secondary" (click)="dismiss()" [disabled]="loading">
            Agora Não
          </button>
          <button class="btn btn-primary" (click)="enterConsultation()" [disabled]="loading">
            <svg *ngIf="!loading" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
              <polyline points="10 17 15 12 10 7"/>
              <line x1="15" y1="12" x2="3" y2="12"/>
            </svg>
            <span *ngIf="loading" class="spinner"></span>
            Entrar na Consulta
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(4px);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 9999;
      padding: 20px;
    }

    .modal-container {
      background: white;
      border-radius: 16px;
      max-width: 500px;
      width: 100%;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }

    .modal-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 32px 24px 24px;
      text-align: center;
      position: relative;
    }

    .icon-wrapper {
      width: 80px;
      height: 80px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0%, 100% {
        transform: scale(1);
        opacity: 1;
      }
      50% {
        transform: scale(1.05);
        opacity: 0.9;
      }
    }

    .modal-header h2 {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
    }

    .close-btn {
      position: absolute;
      top: 16px;
      right: 16px;
      background: rgba(255, 255, 255, 0.2);
      border: none;
      color: white;
      width: 32px;
      height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: background 0.2s;
    }

    .close-btn:hover {
      background: rgba(255, 255, 255, 0.3);
    }

    .modal-body {
      padding: 32px 24px;
    }

    .message {
      font-size: 18px;
      color: #2d3748;
      text-align: center;
      margin: 0 0 24px;
      line-height: 1.6;
    }

    .info-grid {
      background: #f7fafc;
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 24px;
    }

    .info-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
    }

    .label {
      font-size: 14px;
      color: #718096;
    }

    .value {
      font-size: 16px;
      font-weight: 600;
      color: #2d3748;
    }

    .pulse-indicator {
      position: relative;
      width: 60px;
      height: 60px;
      margin: 0 auto;
    }

    .pulse-ring {
      position: absolute;
      width: 100%;
      height: 100%;
      border: 4px solid #667eea;
      border-radius: 50%;
      animation: pulse-ring 2s infinite;
    }

    @keyframes pulse-ring {
      0% {
        transform: scale(0.8);
        opacity: 1;
      }
      100% {
        transform: scale(1.2);
        opacity: 0;
      }
    }

    .pulse-dot {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 20px;
      height: 20px;
      background: #667eea;
      border-radius: 50%;
    }

    .modal-footer {
      padding: 0 24px 24px;
      display: flex;
      gap: 12px;
      justify-content: flex-end;
    }

    .btn {
      padding: 12px 24px;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 500;
      border: none;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s;
    }

    .btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .btn-secondary {
      background: #e2e8f0;
      color: #4a5568;
    }

    .btn-secondary:hover:not(:disabled) {
      background: #cbd5e0;
    }

    .btn-primary {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }

    .btn-primary:hover:not(:disabled) {
      transform: translateY(-2px);
      box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
    }

    .spinner {
      width: 16px;
      height: 16px;
      border: 2px solid white;
      border-top-color: transparent;
      border-radius: 50%;
      animation: spin 0.6s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  `],
  animations: []
})
export class PatientWaitingModalComponent implements OnInit, OnDestroy {
  notification: PatientWaitingNotification | null = null;
  loading = false;
  meetLink: string = '';
  appointmentId: string = '';
  private destroy$ = new Subject<void>();
  private realTimeService = inject(RealTimeService);

  constructor(
    private signalRService: SignalRService,
    private appointmentsService: AppointmentsService,
    private soundService: SoundNotificationService,
    private router: Router
  ) {}

  ngOnInit(): void {
    console.log('🏥 PatientWaitingModalComponent inicializado');
    
    // Escutar notificações do SignalR (PatientWaiting - check-in)
    this.signalRService.patientWaiting$
      .pipe(takeUntil(this.destroy$))
      .subscribe((notification: any) => {
        console.log('📬 PatientWaitingModal recebeu patientWaiting$:', notification);
        if (notification && notification.type === 'PatientWaiting') {
          console.log('✅ Configurando modal com notificação PatientWaiting');
          
          // Extrair dados adicionais se existirem
          if (notification.data) {
            this.appointmentId = notification.data.appointmentId || notification.data.AppointmentId || '';
            this.meetLink = notification.data.meetLink || notification.data.MeetLink || '';
            console.log('💾 Dados extraídos:', { appointmentId: this.appointmentId, meetLink: this.meetLink });
          }
          
          this.notification = notification;
          this.playNotificationSound();
        }
      });

    // Escutar notificações de demanda espontânea pronta
    this.realTimeService.newNotification$
      .pipe(takeUntil(this.destroy$))
      .subscribe((notification: any) => {
        if (notification && 
            (notification.type === 'SpontaneousDemandReady' || notification.type === 'PatientReady')) {
          console.log('📬 Notificação recebida:', notification);
          
          // Salvar dados adicionais PRIMEIRO
          this.appointmentId = notification.data?.appointmentId || '';
          this.meetLink = notification.data?.meetLink || '';
          
          console.log('💾 Dados salvos:', { appointmentId: this.appointmentId, meetLink: this.meetLink });
          
          // Converter para o formato PatientWaitingNotification
          this.notification = {
            notificationId: notification.data?.appointmentId || notification.notificationId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            createdAt: notification.createdAt,
            isRead: false,
            unreadCount: 1
          };
          
          console.log('🔔 Notificação configurada:', this.notification);
          
          
          // Tocar som mais urgente se for demanda espontânea
          if (notification.type === 'SpontaneousDemandReady') {
            this.soundService.playUrgentAlert();
          } else {
            this.playNotificationSound();
          }
        }
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  dismiss(): void {
    this.signalRService.clearCurrentNotification();
  }

  /**
   * Toca som de notificação
   */
  private playNotificationSound(): void {
    try {
      this.soundService.playUrgentAlert();
    } catch (error) {
      console.warn('Erro ao tocar som de notificação:', error);
    }
  }

  enterConsultation(): void {
    if (!this.notification) return;

    this.loading = true;

    // Se tiver appointmentId específico (demanda espontânea), usar ele
    const appointmentId = this.appointmentId || this.notification.notificationId;

    console.log('📞 Entrando na consulta:', { appointmentId, meetLink: this.meetLink, notification: this.notification });

    // Navegar para consulta
    this.router.navigate(['/teleconsulta', appointmentId]);
    this.signalRService.clearCurrentNotification();
    this.loading = false;
  }
}
