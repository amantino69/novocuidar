import { Injectable, inject } from '@angular/core';
import * as signalR from '@microsoft/signalr';
import { BehaviorSubject, Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

export interface PatientWaitingNotification {
  notificationId: string;
  title: string;
  message: string;
  type: string;
  isRead: boolean;
  createdAt: Date;
  unreadCount: number;
}

@Injectable({
  providedIn: 'root'
})
export class SignalRService {
  private hubConnection?: signalR.HubConnection;
  private patientWaitingSubject = new BehaviorSubject<PatientWaitingNotification | null>(null);
  private connectionStateSubject = new BehaviorSubject<'disconnected' | 'connecting' | 'connected'>('disconnected');
  private isStopping = false;
  private authService = inject(AuthService);
  
  public patientWaiting$ = this.patientWaitingSubject.asObservable();
  public connectionState$ = this.connectionStateSubject.asObservable();

  constructor() {}

  /**
   * Inicia conexão com o hub SignalR
   */
  public startConnection(token: string): void {
    if (this.hubConnection?.state === signalR.HubConnectionState.Connected) {
      console.log('SignalR já conectado');
      return;
    }

    this.connectionStateSubject.next('connecting');

    // SignalR hubs estão em /hubs, não em /api/hubs
    const hubUrl = environment.apiUrl.replace('/api', '') + '/hubs/notifications';
    
    this.hubConnection = new signalR.HubConnectionBuilder()
      .withUrl(hubUrl, {
        accessTokenFactory: () => token,
        skipNegotiation: false,
        transport: signalR.HttpTransportType.WebSockets | signalR.HttpTransportType.ServerSentEvents | signalR.HttpTransportType.LongPolling
      })
      .withAutomaticReconnect([0, 2000, 5000, 10000, 30000]) // Retry após 0s, 2s, 5s, 10s, 30s
      .configureLogging(signalR.LogLevel.Information)
      .build();

    // Eventos de conexão
    this.hubConnection.onreconnecting(() => {
      console.log('🔄 SignalR reconectando...');
      this.connectionStateSubject.next('connecting');
    });

    this.hubConnection.onreconnected(() => {
      console.log('✅ SignalR reconectado');
      this.connectionStateSubject.next('connected');
    });

    this.hubConnection.onclose((error) => {
      console.log('❌ SignalR desconectado', error);
      this.connectionStateSubject.next('disconnected');
    });

    // Escutar notificações de paciente aguardando
    this.hubConnection.on('NewNotification', (notification: PatientWaitingNotification) => {
      console.log('🔔 Nova notificação recebida:', notification);
      
      if (notification.type === 'PatientWaiting') {
        this.patientWaitingSubject.next(notification);
        this.playNotificationSound();
      }
    });

    // Escutar quando médico entra
    this.hubConnection.on('DoctorJoinedRoom', () => {
      console.log('✅ Médico entrou na sala');
    });

    // Iniciar conexão
    this.hubConnection
      .start()
      .then(async () => {
        console.log('✅ SignalR conectado com sucesso');
        this.connectionStateSubject.next('connected');
        
        // 🔔 IMPORTANTE: Inscrever no grupo do usuário para receber notificações pessoais
        const user = this.authService.getCurrentUser();
        if (user && this.hubConnection) {
          try {
            await this.hubConnection.invoke('JoinUserGroup', user.id);
            console.log('✅ Inscrito no grupo do usuário:', user.id);
            
            // Também inscrever no grupo da role para notificações de role
            await this.hubConnection.invoke('JoinRoleGroup', user.role);
            console.log('✅ Inscrito no grupo da role:', user.role);
          } catch (err) {
            console.error('❌ Erro ao inscrever nos grupos:', err);
          }
        }
      })
      .catch((err) => {
        console.error('❌ Erro ao conectar SignalR:', err);
        this.connectionStateSubject.next('disconnected');
        
        // Tentar reconectar após 5 segundos
        setTimeout(() => {
          console.log('🔄 Tentando reconectar...');
          this.startConnection(token);
        }, 5000);
      });
  }

  /**
   * Para a conexão SignalR
   */
  public stopConnection(): void {
    if (!this.hubConnection) {
      console.log('Sem conexão SignalR para parar');
      return;
    }
    
    if (this.hubConnection.state === signalR.HubConnectionState.Disconnected) {
      console.log('SignalR já está desconectado');
      return;
    }
    
    if (this.isStopping) {
      console.log('Já está parando conexão SignalR');
      return;
    }
    
    this.isStopping = true;
    this.hubConnection.stop()
      .then(() => {
        console.log('SignalR desconectado com sucesso');
        this.connectionStateSubject.next('disconnected');
        this.isStopping = false;
      })
      .catch((err) => {
        console.error('Erro ao desconectar SignalR:', err);
        this.isStopping = false;
      })
      .finally(() => {
        this.isStopping = false;
        this.hubConnection = undefined;
      });
  }

  /**
   * Notifica backend que médico entrou na consulta
   */
  public doctorJoinedConsultation(appointmentId: string): Promise<void> {
    if (this.hubConnection?.state === signalR.HubConnectionState.Connected) {
      return this.hubConnection.invoke('DoctorJoinedConsultation', appointmentId);
    }
    return Promise.reject('SignalR não está conectado');
  }

  /**
   * Limpa notificação atual
   */
  public clearCurrentNotification(): void {
    this.patientWaitingSubject.next(null);
  }

  /**
   * Toca som de notificação
   */
  private playNotificationSound(): void {
    try {
      const audio = new Audio('/assets/sounds/notification.mp3');
      audio.volume = 0.7;
      audio.play().catch(err => {
        console.warn('Não foi possível tocar som de notificação:', err);
      });
    } catch (err) {
      console.warn('Erro ao criar áudio:', err);
    }
  }

  /**
   * Verifica se está conectado
   */
  public isConnected(): boolean {
    return this.hubConnection?.state === signalR.HubConnectionState.Connected;
  }

  /**
   * Obtém estado da conexão
   */
  public getConnectionState(): signalR.HubConnectionState | undefined {
    return this.hubConnection?.state;
  }
}
