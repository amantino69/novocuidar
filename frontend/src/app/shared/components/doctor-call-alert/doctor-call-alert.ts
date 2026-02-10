/**
 * DoctorCallAlertComponent
 * 
 * Componente global que mostra alerta quando enfermeira chama o médico.
 * Funciona em QUALQUER página, não apenas em "Minhas Consultas".
 * 
 * - Escuta evento WaitingInRoom via SignalRService (conexão global do app.ts)
 * - Toca som de alerta (campainha)
 * - Mostra toast fixo com informações da consulta
 * - Botão para entrar diretamente na teleconsulta
 * 
 * IMPORTANTE: Usa SignalRService (não RealTimeService) para garantir que
 * a conexão SignalR seja a mesma que é inicializada no app.ts, assim
 * o médico recebe notificações em QUALQUER página do sistema.
 */

import { Component, OnInit, OnDestroy, PLATFORM_ID, Inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';
import { SignalRService, WaitingInRoomData } from '@core/services/signalr.service';
import { SoundNotificationService } from '@core/services/sound-notification.service';
import { AuthService } from '@core/services/auth.service';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';

interface DoctorCallData {
  appointmentId: string;
  patientName: string;
  userRole: string;
  timestamp: Date;
}

@Component({
  selector: 'app-doctor-call-alert',
  standalone: true,
  imports: [CommonModule, IconComponent],
  template: `
    @if (isProfessional && activeCall) {
      <div class="doctor-call-alert" [class.entering]="isEntering" [class.leaving]="isLeaving">
        <div class="alert-header">
          <div class="bell-icon">
            <app-icon name="bell" [size]="24" />
          </div>
          <span class="alert-title">Paciente Aguardando!</span>
          <button class="close-btn" (click)="dismiss()">
            <app-icon name="x" [size]="18" />
          </button>
        </div>
        
        <div class="alert-body">
          <div class="patient-info">
            <app-icon name="user" [size]="20" />
            <span class="patient-name">{{ activeCall.patientName }}</span>
          </div>
          <p class="alert-message">
            {{ getRoleName(activeCall.userRole) }} chamou você para a consulta
          </p>
        </div>
        
        <div class="alert-actions">
          <button class="btn-enter" (click)="enterConsultation()">
            <app-icon name="video" [size]="18" />
            Entrar na Consulta
          </button>
        </div>
      </div>
    }
  `,
  styles: [`
    .doctor-call-alert {
      position: fixed;
      bottom: 24px;
      right: 24px;
      width: 340px;
      background: linear-gradient(135deg, #1e3a5f 0%, #0f172a 100%);
      border-radius: 16px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(59, 130, 246, 0.3);
      overflow: hidden;
      z-index: 10000;
      animation: slideIn 0.4s ease-out;
      border: 2px solid #3b82f6;
    }
    
    .doctor-call-alert.entering {
      animation: slideIn 0.4s ease-out;
    }
    
    .doctor-call-alert.leaving {
      animation: slideOut 0.3s ease-in forwards;
    }
    
    @keyframes slideIn {
      from {
        transform: translateX(120%);
        opacity: 0;
      }
      to {
        transform: translateX(0);
        opacity: 1;
      }
    }
    
    @keyframes slideOut {
      from {
        transform: translateX(0);
        opacity: 1;
      }
      to {
        transform: translateX(120%);
        opacity: 0;
      }
    }
    
    .alert-header {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: linear-gradient(90deg, #dc2626 0%, #b91c1c 100%);
      color: white;
    }
    
    .bell-icon {
      animation: ring 0.5s ease-in-out infinite;
    }
    
    @keyframes ring {
      0%, 100% { transform: rotate(0deg); }
      25% { transform: rotate(15deg); }
      75% { transform: rotate(-15deg); }
    }
    
    .alert-title {
      flex: 1;
      font-size: 16px;
      font-weight: 700;
      letter-spacing: 0.5px;
    }
    
    .close-btn {
      background: rgba(255, 255, 255, 0.2);
      border: none;
      border-radius: 50%;
      width: 28px;
      height: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      color: white;
      transition: background 0.2s;
    }
    
    .close-btn:hover {
      background: rgba(255, 255, 255, 0.3);
    }
    
    .alert-body {
      padding: 16px;
      color: white;
    }
    
    .patient-info {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 8px;
    }
    
    .patient-name {
      font-size: 18px;
      font-weight: 600;
      color: #60a5fa;
    }
    
    .alert-message {
      margin: 0;
      font-size: 14px;
      color: #94a3b8;
    }
    
    .alert-actions {
      padding: 12px 16px 16px;
    }
    
    .btn-enter {
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 14px 20px;
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
      color: white;
      border: none;
      border-radius: 10px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .btn-enter:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
    }
    
    .btn-enter:active {
      transform: translateY(0);
    }
    
    /* Mobile responsiveness */
    @media (max-width: 480px) {
      .doctor-call-alert {
        bottom: 16px;
        right: 16px;
        left: 16px;
        width: auto;
      }
    }
  `]
})
export class DoctorCallAlertComponent implements OnInit, OnDestroy {
  activeCall: DoctorCallData | null = null;
  isProfessional = false;
  isEntering = false;
  isLeaving = false;
  
  private subscriptions: Subscription[] = [];
  private dismissTimeout: any;
  private waitingRoomSubscribed = false;
  
  constructor(
    private signalRService: SignalRService,
    private soundService: SoundNotificationService,
    private authService: AuthService,
    private router: Router,
    private cdr: ChangeDetectorRef,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}
  
  ngOnInit(): void {
    if (!isPlatformBrowser(this.platformId)) return;
    
    console.log('[DoctorCallAlert] Inicializando componente global...');
    
    // Usar authState$ para detectar quando usuario esta pronto
    const authSub = this.authService.authState$.pipe(
      filter(state => state.isAuthenticated && !!state.user)
    ).subscribe(state => {
      this.isProfessional = state.user?.role === 'PROFESSIONAL';
      console.log('[DoctorCallAlert] Usuario autenticado, isProfessional:', this.isProfessional);
      
      if (this.isProfessional && !this.waitingRoomSubscribed) {
        this.subscribeToWaitingRoom();
      }
    });
    this.subscriptions.push(authSub);
    
    // Tambem verificar o usuario atual (caso ja logado)
    const user = this.authService.getCurrentUser();
    if (user?.role === 'PROFESSIONAL') {
      this.isProfessional = true;
      console.log('[DoctorCallAlert] Usuario ja logado como PROFESSIONAL');
      this.subscribeToWaitingRoom();
    }
  }
  
  private subscribeToWaitingRoom(): void {
    if (this.waitingRoomSubscribed) return;
    this.waitingRoomSubscribed = true;
    
    console.log('[DoctorCallAlert] Inscrevendo em SignalRService.waitingInRoom$...');
    
    // SignalRService já é inicializado globalmente no app.ts
    // Apenas nos inscrevemos no observable waitingInRoom$
    const waitingSub = this.signalRService.waitingInRoom$.pipe(
      filter(data => data !== null)
    ).subscribe(data => {
      if (data) {
        console.log('[DoctorCallAlert] *** CHAMADA RECEBIDA ***:', data);
        this.showAlert(data);
        this.cdr.detectChanges();
      }
    });
    this.subscriptions.push(waitingSub);
    
    // Log estado da conexao
    const connSub = this.signalRService.connectionState$.subscribe(state => {
      console.log('[DoctorCallAlert] Status conexao SignalR:', state);
    });
    this.subscriptions.push(connSub);
    
    console.log('[DoctorCallAlert] Inscricao em waitingInRoom$ ativa!');
  }
  
  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout);
    }
  }
  
  private showAlert(data: DoctorCallData): void {
    // Cancelar timeout anterior se houver
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout);
    }
    
    // Mostrar alerta
    this.isLeaving = false;
    this.isEntering = true;
    this.activeCall = data;
    
    // Tocar som de alerta
    this.soundService.playUrgentAlert();
    
    // Repetir som após 3 segundos
    setTimeout(() => {
      if (this.activeCall) {
        this.soundService.playUrgentAlert();
      }
    }, 3000);
    
    // Auto-dismiss após 30 segundos
    this.dismissTimeout = setTimeout(() => {
      this.dismiss();
    }, 30000);
    
    // Remover classe entering após animação
    setTimeout(() => {
      this.isEntering = false;
    }, 400);
  }
  
  dismiss(): void {
    this.isLeaving = true;
    setTimeout(() => {
      this.activeCall = null;
      this.isLeaving = false;
    }, 300);
  }
  
  enterConsultation(): void {
    if (!this.activeCall) return;
    
    const appointmentId = this.activeCall.appointmentId;
    this.dismiss();
    
    // Navegar para a teleconsulta
    this.router.navigate(['/teleconsulta', appointmentId]);
  }
  
  getRoleName(role: string): string {
    switch (role) {
      case 'ASSISTANT': return 'A enfermeira';
      case 'PATIENT': return 'O paciente';
      case 'RECEPTIONIST': return 'A recepcionista';
      default: return 'Alguém';
    }
  }
}
