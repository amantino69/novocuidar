import { Injectable, Inject, PLATFORM_ID, OnDestroy, NgZone } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Subject, Observable } from 'rxjs';
import { environment } from '@env/environment';
import { AuthService } from './auth.service';

// Interfaces para eventos da teleconsulta
export interface ParticipantEvent {
  connectionId: string;
  timestamp: Date;
}

export interface DataUpdatedEvent {
  dataType: string;
  data?: any;
  timestamp: Date;
}

export interface AttachmentEvent {
  attachment?: any;
  attachmentId?: string;
  timestamp: Date;
}

export interface PrescriptionUpdatedEvent {
  prescription?: any;
  timestamp: Date;
}

export interface StatusChangedEvent {
  status: string;
  timestamp: Date;
}

export interface TypingIndicatorEvent {
  connectionId: string;
  isTyping: boolean;
  timestamp: Date;
}

export interface ChatMessageEvent {
  message: string;
  senderRole: string;
  connectionId: string;
  timestamp: Date;
}

export interface MobileUploadEvent {
  title: string;
  type: string;
  fileUrl: string;
  timestamp: number;
}

export interface PhonocardiogramFrame {
  timestamp: number;
  waveform: number[];
  heartRate: number;
  s1Amplitude: number;
  s2Amplitude: number;
}

@Injectable({
  providedIn: 'root'
})
export class TeleconsultationRealTimeService implements OnDestroy {
  private hubConnection: any = null;
  private connectionPromise: Promise<void> | null = null;
  private isBrowser: boolean;
  private currentAppointmentId: string | null = null;
  private activityCheckInterval: any = null; // Para atividade periódica (timeout prevention)
  
  // Subjects para eventos
  private _participantJoined$ = new Subject<ParticipantEvent>();
  public participantJoined$ = this._participantJoined$.asObservable();
  
  private _participantLeft$ = new Subject<ParticipantEvent>();
  public participantLeft$ = this._participantLeft$.asObservable();
  
  private _dataUpdated$ = new Subject<DataUpdatedEvent>();
  public dataUpdated$ = this._dataUpdated$.asObservable();
  
  private _attachmentAdded$ = new Subject<AttachmentEvent>();
  public attachmentAdded$ = this._attachmentAdded$.asObservable();
  
  private _attachmentRemoved$ = new Subject<AttachmentEvent>();
  public attachmentRemoved$ = this._attachmentRemoved$.asObservable();
  
  private _prescriptionUpdated$ = new Subject<PrescriptionUpdatedEvent>();
  public prescriptionUpdated$ = this._prescriptionUpdated$.asObservable();
  
  private _statusChanged$ = new Subject<StatusChangedEvent>();
  public statusChanged$ = this._statusChanged$.asObservable();
  
  private _typingIndicator$ = new Subject<TypingIndicatorEvent>();
  public typingIndicator$ = this._typingIndicator$.asObservable();
  
  private _chatMessage$ = new Subject<ChatMessageEvent>();
  public chatMessage$ = this._chatMessage$.asObservable();
  
  private _accessDenied$ = new Subject<{ message: string }>();
  public accessDenied$ = this._accessDenied$.asObservable();
  
  private _mobileUploadReceived$ = new Subject<MobileUploadEvent>();
  public mobileUploadReceived$ = this._mobileUploadReceived$.asObservable();

  private _phonocardiogramFrame$ = new Subject<PhonocardiogramFrame>();
  public phonocardiogramFrame$ = this._phonocardiogramFrame$.asObservable();

  private phonocardiogramCallback: ((frame: PhonocardiogramFrame) => void) | null = null;

  constructor(
    @Inject(PLATFORM_ID) private platformId: Object,
    private authService: AuthService,
    private ngZone: NgZone
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnDestroy(): void {
    this.clearActivityInterval();
    this.disconnect();
  }

  async connect(): Promise<void> {
    if (!this.isBrowser) {
      return Promise.resolve();
    }

    if (this.hubConnection && this.hubConnection.state === 'Connected') {
      return Promise.resolve();
    }

    if (this.connectionPromise) {
      return this.connectionPromise;
    }

    this.connectionPromise = this.createConnection();
    return this.connectionPromise;
  }

  private async createConnection(): Promise<void> {
    try {
      const signalR = await import('@microsoft/signalr');
      
      const token = this.authService.getAccessToken();
      
      this.hubConnection = new signalR.HubConnectionBuilder()
        .withUrl(`${environment.apiUrl.replace('/api', '')}/hubs/teleconsultation`, {
          accessTokenFactory: () => token || ''
        })
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .configureLogging(signalR.LogLevel.Information)
        .build();

      this.setupEventListeners();
      
      await this.hubConnection.start();
      console.log('[TeleconsultationRealTime] Conectado ao hub de teleconsulta');
      
    } catch (error) {
      console.error('[TeleconsultationRealTime] Erro ao conectar:', error);
      this.connectionPromise = null;
      throw error;
    }
  }

  private setupEventListeners(): void {
    if (!this.hubConnection) return;

    this.hubConnection.on('ParticipantJoined', (event: ParticipantEvent) => {
      this.ngZone.run(() => this._participantJoined$.next(event));
    });

    this.hubConnection.on('ParticipantLeft', (event: ParticipantEvent) => {
      this.ngZone.run(() => this._participantLeft$.next(event));
    });

    this.hubConnection.on('DataUpdated', (event: DataUpdatedEvent) => {
      this.ngZone.run(() => this._dataUpdated$.next(event));
    });

    this.hubConnection.on('AttachmentAdded', (event: AttachmentEvent) => {
      this.ngZone.run(() => this._attachmentAdded$.next(event));
    });

    this.hubConnection.on('AttachmentRemoved', (event: AttachmentEvent) => {
      this.ngZone.run(() => this._attachmentRemoved$.next(event));
    });

    this.hubConnection.on('PrescriptionUpdated', (event: PrescriptionUpdatedEvent) => {
      this.ngZone.run(() => this._prescriptionUpdated$.next(event));
    });

    this.hubConnection.on('StatusChanged', (event: StatusChangedEvent) => {
      this.ngZone.run(() => this._statusChanged$.next(event));
    });

    this.hubConnection.on('TypingIndicator', (event: TypingIndicatorEvent) => {
      this.ngZone.run(() => this._typingIndicator$.next(event));
    });

    this.hubConnection.on('ChatMessage', (event: ChatMessageEvent) => {
      this.ngZone.run(() => this._chatMessage$.next(event));
    });

    // Acesso negado à consulta (expirada, pendente fechamento, etc)
    this.hubConnection.on('AccessDenied', (data: { Message: string }) => {
      console.warn('[TeleconsultationRealTime] Acesso negado:', data.Message);
      this.ngZone.run(() => this._accessDenied$.next({ message: data.Message }));
    });

    this.hubConnection.on('MobileUploadReceived', (event: MobileUploadEvent) => {
      this.ngZone.run(() => this._mobileUploadReceived$.next(event));
    });

    // Fonocardiograma em tempo real
    this.hubConnection.on('ReceivePhonocardiogramFrame', (frame: PhonocardiogramFrame) => {
      console.log('[SignalR] ReceivePhonocardiogramFrame:', {
        hasFrame: !!frame,
        heartRate: frame?.heartRate,
        waveformLength: frame?.waveform?.length
      });
      this.ngZone.run(() => {
        this._phonocardiogramFrame$.next(frame);
        if (this.phonocardiogramCallback) {
          this.phonocardiogramCallback(frame);
        }
      });
    });

    // Handle reconnection
    this.hubConnection.onreconnected(() => {
      console.log('[TeleconsultationRealTime] Reconectado ao hub');
      // Rejoin consultation if we were in one
      if (this.currentAppointmentId) {
        this.joinConsultation(this.currentAppointmentId);
      }
    });
  }

  async joinConsultation(appointmentId: string): Promise<void> {
    await this.connect();
    if (this.hubConnection) {
      this.currentAppointmentId = appointmentId;
      
      // Obter role e nome do usuário para notificar o médico
      const user = this.authService.getCurrentUser();
      const userRole = user?.role || null;
      const userName = user ? `${user.name} ${user.lastName || ''}`.trim() : null;
      
      await this.hubConnection.invoke('JoinConsultation', appointmentId, userRole, userName);
      console.log('[TeleconsultationRealTime] Entrou na consulta:', appointmentId, '- Role:', userRole);
      
      // Iniciar intervalo para atualizar atividade (a cada 2 minutos)
      // Isso previne que a consulta seja marcada como Abandoned pelo timeout job
      this.clearActivityInterval();
      this.activityCheckInterval = setInterval(() => {
        this.updateActivity(appointmentId);
      }, 2 * 60 * 1000); // 2 minutos em milissegundos
      
      console.log('[TeleconsultationRealTime] Intervalo de atividade iniciado (a cada 2 min)');
    }
  }

  async leaveConsultation(appointmentId: string): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('LeaveConsultation', appointmentId);
      this.currentAppointmentId = null;
      this.clearActivityInterval();
      console.log('[TeleconsultationRealTime] Saiu da consulta:', appointmentId);
    }
  }

  /**
   * Atualiza LastActivityAt no backend (chamado periodicamente durante a consulta)
   * Previne que a consulta seja marcada como Abandoned pelo timeout job
   */
  private async updateActivity(appointmentId: string): Promise<void> {
    if (this.hubConnection && this.hubConnection.state === 'Connected') {
      try {
        await this.hubConnection.invoke('UpdateActivity', appointmentId);
        console.log('[TeleconsultationRealTime] Atividade atualizada para consulta:', appointmentId);
      } catch (error) {
        // Silenciar erros para não poluir o console (chamadas frequentes)
        console.debug('[TeleconsultationRealTime] Erro ao atualizar atividade:', error);
      }
    }
  }

  /**
   * Limpa o intervalo de atividade
   */
  private clearActivityInterval(): void {
    if (this.activityCheckInterval) {
      clearInterval(this.activityCheckInterval);
      this.activityCheckInterval = null;
      console.log('[TeleconsultationRealTime] Intervalo de atividade cancelado');
    }
  }

  async notifyDataUpdated(appointmentId: string, dataType: string, data?: any): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('NotifyDataUpdated', appointmentId, dataType, data);
    }
  }

  async notifyAttachmentAdded(appointmentId: string, attachment: any): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('NotifyAttachmentAdded', appointmentId, attachment);
    }
  }

  async notifyAttachmentRemoved(appointmentId: string, attachmentId: string): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('NotifyAttachmentRemoved', appointmentId, attachmentId);
    }
  }

  async notifyPrescriptionUpdated(appointmentId: string, prescription?: any): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('NotifyPrescriptionUpdated', appointmentId, prescription);
    }
  }

  async sendTypingIndicator(appointmentId: string, isTyping: boolean): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('SendTypingIndicator', appointmentId, isTyping);
    }
  }

  async sendChatMessage(appointmentId: string, message: string, senderRole: string): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('SendChatMessage', appointmentId, message, senderRole);
    }
  }

  async registerMobileUploadToken(token: string): Promise<void> {
    await this.connect();
    if (this.hubConnection) {
      await this.hubConnection.invoke('RegisterMobileUploadToken', token);
      console.log('[TeleconsultationRealTime] Registrado para uploads com token:', token);
    }
  }

  async unregisterMobileUploadToken(token: string): Promise<void> {
    if (this.hubConnection) {
      await this.hubConnection.invoke('UnregisterMobileUploadToken', token);
      console.log('[TeleconsultationRealTime] Removido de uploads com token:', token);
    }
  }

  disconnect(): void {
    if (this.hubConnection) {
      this.hubConnection.stop();
      this.hubConnection = null;
      this.connectionPromise = null;
      this.currentAppointmentId = null;
    }
  }

  // Helper to filter data updates by type
  getDataUpdates$(dataType: string): Observable<DataUpdatedEvent> {
    return new Observable(observer => {
      const subscription = this._dataUpdated$.subscribe(event => {
        if (event.dataType === dataType) {
          observer.next(event);
        }
      });
      return () => subscription.unsubscribe();
    });
  }

  // ========== FONOCARDIOGRAMA EM TEMPO REAL ==========

  /**
   * Envia frame de fonocardiograma para o médico
   */
  async sendPhonocardiogramFrame(appointmentId: string, frame: PhonocardiogramFrame): Promise<void> {
    if (this.hubConnection && this.hubConnection.state === 'Connected') {
      try {
        await this.hubConnection.invoke('SendPhonocardiogramFrame', appointmentId, frame);
      } catch (error) {
        // Silenciar erros de envio para não poluir o console (frames são contínuos)
      }
    }
  }

  /**
   * Registra callback para receber frames de fonocardiograma
   */
  onPhonocardiogramFrame(callback: (frame: PhonocardiogramFrame) => void): void {
    this.phonocardiogramCallback = callback;
  }

  /**
   * Remove callback de fonocardiograma
   */
  offPhonocardiogramFrame(): void {
    this.phonocardiogramCallback = null;
  }
}
