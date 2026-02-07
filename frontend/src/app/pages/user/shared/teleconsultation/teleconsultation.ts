  import { Component, OnInit, OnDestroy, HostListener, Inject, PLATFORM_ID, ChangeDetectorRef } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { ButtonComponent } from '@shared/components/atoms/button/button';
import { ThemeToggleComponent } from '@shared/components/atoms/theme-toggle/theme-toggle';
import { JitsiVideoComponent } from '@shared/components/organisms/jitsi-video/jitsi-video';
import { AppointmentsService, Appointment } from '@core/services/appointments.service';
import { JitsiService } from '@core/services/jitsi.service';
import { ModalService } from '@core/services/modal.service';
import { AuthService } from '@core/services/auth.service';
import { DeviceDetectorService } from '@core/services/device-detector.service';
import { TeleconsultationRealTimeService, StatusChangedEvent, DataUpdatedEvent } from '@core/services/teleconsultation-realtime.service';
import { TeleconsultationDataCollectorService } from '@core/services/teleconsultation-data-collector.service';
import { MedicalDevicesSyncService } from '@core/services/medical-devices-sync.service';
import { TeleconsultationSidebarComponent } from './sidebar/teleconsultation-sidebar';
import { VitalsStatusBarComponent } from './components/vitals-status-bar/vitals-status-bar';
import { getTeleconsultationTabs, TAB_ID_TO_LEGACY_NAME, TabConfig } from './tabs/tab-config';
import { Subscription } from 'rxjs';
import { environment } from '@env/environment';

@Component({
  selector: 'app-teleconsultation',
  standalone: true,
  imports: [
    CommonModule,
    IconComponent,
    ButtonComponent,
    ThemeToggleComponent,
    RouterModule,
    TeleconsultationSidebarComponent,
    JitsiVideoComponent,
    VitalsStatusBarComponent
  ],
  templateUrl: './teleconsultation.html',
  styleUrls: ['./teleconsultation.scss']
})
export class TeleconsultationComponent implements OnInit, OnDestroy {
  appointmentId: string | null = null;
  appointment: Appointment | null = null;
  userrole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' | 'REGULATOR' | 'REGULATOR' = 'PATIENT';
  
  // UI States
  isHeaderVisible = true;
  isSidebarOpen = false;
  isSidebarFull = false;
  activeTab: string = '';
  isMobile = false;
  
  // Jitsi States
  jitsiEnabled = false;
  jitsiError: string | null = null;
  isCallConnected = false;

  // Estado do modo ditado do médico (para paciente)
  isDoctorDictating = false;

  // Tabs configuration - usando configuração centralizada
  currentTabs: string[] = [];
  private tabConfigs: TabConfig[] = [];
  
  // Data for AI from other tabs
  patientData: any = null;
  preConsultationData: any = null;
  anamnesisData: any = null;
  biometricsData: any = null;
  soapData: any = null;
  specialtyFieldsData: any = null;

  private subscriptions: Subscription[] = [];
  private isBrowser: boolean;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private http: HttpClient,
    private appointmentsService: AppointmentsService,
    private jitsiService: JitsiService,
    private modalService: ModalService,
    private authService: AuthService,
    private deviceDetector: DeviceDetectorService,
    private teleconsultationRealTime: TeleconsultationRealTimeService,
    private dataCollector: TeleconsultationDataCollectorService,
    private medicalDevicesSync: MedicalDevicesSyncService,
    private cdr: ChangeDetectorRef,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnInit(): void {
    this.checkScreenSize();
    this.appointmentId = this.route.snapshot.paramMap.get('id');
    this.determineuserrole();
    this.setupTabs();
    this.checkJitsiConfig();
    
    if (this.appointmentId) {
      this.loadAppointment(this.appointmentId);
      
      // AUTOMÁTICO: Marca esta consulta como ativa para a maleta
      this.marcarConsultaAtiva(this.appointmentId);
      
      // Setup real-time connection
      if (this.isBrowser) {
        this.setupRealTimeConnection();
      }
    }
  }
  
  /**
   * Marca automaticamente a consulta como ativa para a maleta itinerante
   * Chamado quando o usuário entra na sala de teleconsulta
   */
  private marcarConsultaAtiva(appointmentId: string): void {
    const url = `${environment.apiUrl}/biometrics/acontecendo/${appointmentId}`;
    this.http.post(url, {}).subscribe({
      next: () => console.log('[Teleconsultation] 🟢 Consulta marcada como ativa para maleta:', appointmentId),
      error: (err) => console.warn('[Teleconsultation] Não foi possível marcar consulta ativa:', err)
    });
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
    this.jitsiService.dispose();
    
    // Leave teleconsultation room
    if (this.appointmentId) {
      this.teleconsultationRealTime.leaveConsultation(this.appointmentId);
      
      // AUTOMÁTICO: Desmarca a consulta como ativa quando sai
      this.desmarcarConsultaAtiva(this.appointmentId);
    }
  }
  
  /**
   * Desmarca a consulta como ativa quando o usuário sai da sala
   */
  private desmarcarConsultaAtiva(appointmentId: string): void {
    const url = `${environment.apiUrl}/biometrics/acontecendo`;
    // Usa fetch síncrono pois ngOnDestroy pode não esperar o Observable
    this.http.delete(url).subscribe({
      next: () => console.log('[Teleconsultation] 🔴 Consulta desmarcada:', appointmentId),
      error: () => {} // Ignora erro silenciosamente
    });
  }

  private setupRealTimeConnection(): void {
    if (!this.appointmentId) return;
    
    // Join the teleconsultation room
    this.teleconsultationRealTime.joinConsultation(this.appointmentId).catch(error => {
      console.error('[Teleconsultation] Erro ao conectar tempo real:', error);
    });
    
    // Conecta ao hub de dispositivos médicos
    // - Médico: para ENVIAR notificação de ditado
    // - Paciente: para RECEBER notificação de ditado
    this.medicalDevicesSync.connect(this.appointmentId).catch(error => {
      console.error('[Teleconsultation] Erro ao conectar dispositivos médicos:', error);
    });
    
    // Paciente: escuta mudanças no modo ditado do médico
    if (this.userrole === 'PATIENT') {
      const dictationSub = this.medicalDevicesSync.dictationModeActive$.subscribe(
        (isActive: boolean) => {
          console.log('[Teleconsultation] Modo ditado do médico:', isActive);
          this.isDoctorDictating = isActive;
          
          // Muta/desmuta o áudio do Jitsi
          if (isActive) {
            this.jitsiService.setRemoteAudioMuted(true);
          } else {
            this.jitsiService.setRemoteAudioMuted(false);
          }
          
          this.cdr.detectChanges();
        }
      );
      this.subscriptions.push(dictationSub);
    }
    
    // Subscribe to status changes
    const statusSub = this.teleconsultationRealTime.statusChanged$.subscribe(
      (event: StatusChangedEvent) => {
        if (this.appointment) {
          this.appointment = { ...this.appointment, status: event.status as any };
          this.cdr.detectChanges();
        }
      }
    );
    this.subscriptions.push(statusSub);
    
    // Subscribe to data updates to reload appointment when needed
    const dataSub = this.teleconsultationRealTime.dataUpdated$.subscribe(
      (event: DataUpdatedEvent) => {
        // Reload appointment when important data changes
        if (['soap', 'anamnesis', 'preConsultation'].includes(event.dataType)) {
          this.reloadAppointment();
        }
      }
    );
    this.subscriptions.push(dataSub);
  }

  private reloadAppointment(): void {
    if (this.appointmentId) {
      this.appointmentsService.getAppointmentById(this.appointmentId).subscribe({
        next: (appt) => {
          if (appt) {
            this.appointment = appt;
            this.cdr.detectChanges();
          }
        },
        error: (error) => {
          console.error('[Teleconsultation] Erro ao recarregar consulta:', error);
        }
      });
    }
  }

  @HostListener('window:resize', [])
  onResize() {
    this.checkScreenSize();
  }

  checkScreenSize() {
    if (isPlatformBrowser(this.platformId)) {
      this.isMobile = this.deviceDetector.isMobile();
      if (this.isMobile && this.isSidebarOpen) {
        this.isSidebarFull = true;
      }
    }
  }

  determineuserrole() {
    const currentUser = this.authService.currentUser();
    if (currentUser) {
      this.userrole = currentUser.role;
    } else {
      // Fallback to PATIENT if no user is found
      this.userrole = 'PATIENT';
    }
  }

  setupTabs() {
    // Usar configuração centralizada de tabs
    this.tabConfigs = getTeleconsultationTabs(this.userrole);
    // Converter para nomes legados usados pelo sidebar
    this.currentTabs = this.tabConfigs.map(tab => TAB_ID_TO_LEGACY_NAME[tab.id] || tab.label);
    if (this.currentTabs.length > 0) {
      this.activeTab = this.currentTabs[0];
    }
  }

  loadAppointment(id: string) {
    this.appointmentsService.getAppointmentById(id).subscribe({
      next: (appt) => {
        if (appt) {
          this.appointment = appt;
          // Coletar dados de TODAS as abas para uso na IA
          this.collectDataFromAllTabs(id);
          this.cdr.detectChanges();
        }
      },
      error: (error) => {
        // Se for erro 401, o interceptor já redireciona automaticamente
        if (error.status === 401) {
          return; // Não fazer nada, deixar o interceptor cuidar
        }
        
        // Para outros erros, logar e mostrar mensagem
        console.error('Erro ao carregar consulta:', error);
        this.modalService.alert({
          title: 'Erro',
          message: 'Não foi possível carregar os dados da consulta.',
          variant: 'danger'
        }).subscribe(() => {
          this.router.navigate(['/painel']);
        });
      }
    });
  }

  toggleHeader() {
    this.isHeaderVisible = !this.isHeaderVisible;
  }

  toggleSidebar() {
    this.isSidebarOpen = !this.isSidebarOpen;
    if (this.isSidebarOpen) {
      // Force full screen on mobile when opening
      if (this.isMobile) {
        this.isSidebarFull = true;
      }
    } else {
      this.isSidebarFull = false; // Reset full mode when closing
    }
  }

  toggleSidebarMode() {
    if (!this.isMobile) {
      this.isSidebarFull = !this.isSidebarFull;
    }
  }

  setActiveTab(tab: string) {
    this.activeTab = tab;
    
    // Quando mudar para a aba de IA, recarregar o appointment para pegar os dados mais recentes
    // das outras abas (SOAP, Anamnese, Campos da Especialidade, etc.)
    if (tab === 'IA' && this.appointmentId) {
      this.refreshDataForAI();
    }
  }

  /**
   * Recarrega os dados do appointment e recoletar dados para a IA
   * Chamado quando o usuário muda para a aba de IA para garantir dados atualizados
   */
  private refreshDataForAI(): void {
    if (!this.appointmentId) return;
    
    this.appointmentsService.getAppointmentById(this.appointmentId).subscribe({
      next: (appt) => {
        if (appt) {
          this.appointment = appt;
          this.collectDataFromAllTabs(this.appointmentId!);
        }
      },
      error: (error) => {
        console.error('[Teleconsultation] Erro ao atualizar dados para IA:', error);
      }
    });
  }

  onFinishConsultation(observations: string) {
    if (this.appointmentId) {
      this.appointmentsService.completeAppointment(this.appointmentId, observations).subscribe({
        next: () => {
          this.modalService.alert({
            title: 'Consulta Finalizada',
            message: 'Consulta finalizada com sucesso!',
            variant: 'success'
          }).subscribe(() => {
            this.router.navigate(['/painel']);
          });
        },
        error: () => {
          this.modalService.alert({
            title: 'Erro',
            message: 'Erro ao finalizar consulta.',
            variant: 'danger'
          }).subscribe();
        }
      });
    }
  }

  exitCall() {
    this.modalService.confirm({
      title: 'Sair da Consulta',
      message: 'Tem certeza que deseja sair da teleconsulta?',
      variant: 'warning',
      confirmText: 'Sim, sair',
      cancelText: 'Cancelar'
    }).subscribe({
      next: (result) => {
        if (result.confirmed) {
          this.jitsiService.dispose();
          this.router.navigate(['/painel']);
        }
      }
    });
  }

  /**
   * Verifica se o Jitsi está habilitado
   */
  private checkJitsiConfig(): void {
    this.subscriptions.push(
      this.jitsiService.getConfig().subscribe({
        next: (config) => {
          this.jitsiEnabled = config.enabled;
        },
        error: () => {
          this.jitsiEnabled = false;
        }
      })
    );
  }

  /**
   * Handler quando a conferência é conectada
   */
  onConferenceJoined(info: any): void {
    this.isCallConnected = true;
  }

  /**
   * Handler quando a conferência é desconectada
   */
  onConferenceLeft(info: any): void {
    this.isCallConnected = false;
  }

  /**
   * Handler para erros na chamada
   */
  onJitsiError(error: string): void {
    this.jitsiError = error;
    this.modalService.alert({
      title: 'Erro na Videochamada',
      message: error,
      variant: 'danger'
    }).subscribe();
  }

  /**
   * Handler quando a chamada é encerrada
   */
  onCallEnded(): void {
    this.isCallConnected = false;
  }

  /**
   * Coleta dados de TODAS as abas para uso na IA
   * Garante que o resumo e a hipótese diagnóstica usem informações completas
   */
  private collectDataFromAllTabs(appointmentId: string): void {
    if (!this.appointment) return;

    this.subscriptions.push(
      this.dataCollector.collectAllData(this.appointment, appointmentId).subscribe({
        next: (data) => {
          this.patientData = data.patientData;
          this.preConsultationData = data.preConsultationData;
          this.anamnesisData = data.anamnesisData;
          this.biometricsData = data.biometricsData;
          this.soapData = data.soapData;
          this.specialtyFieldsData = data.specialtyFieldsData;
          this.cdr.detectChanges();
        },
        error: (error) => {
          console.error('[Teleconsultation] Erro ao coletar dados das abas:', error);
        }
      })
    );
  }

  /**
   * 🔔 CAMPAINHA - Enfermeira chama o médico
   * Envia notificação visual e sonora ao médico associado a esta consulta
   */
  callDoctor(): void {
    if (!this.appointmentId) return;

    // Chamar endpoint simples que envia notificação ao médico
    this.http.post(`${environment.apiUrl}/appointments/${this.appointmentId}/call-doctor`, {})
      .subscribe({
        next: () => {
          this.modalService.alert({
            title: '🔔 Médico Chamado',
            message: 'O médico recebeu sua notificação.',
            variant: 'success'
          }).subscribe();
        },
        error: (error) => {
          console.error('Erro ao chamar médico:', error);
          this.modalService.alert({
            title: 'Erro',
            message: 'Não foi possível notificar o médico. Tente novamente.',
            variant: 'danger'
          }).subscribe();
        }
      });
  }
}
