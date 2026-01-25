import { Component, Input, OnInit, OnDestroy, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Subscription, firstValueFrom } from 'rxjs';

import { IconComponent } from '@shared/components/atoms/icon/icon';
import { MedicalDevicesSyncService, VitalSignsData } from '@app/core/services/medical-devices-sync.service';
import { AIService, AnalyzeVitalsRequest } from '@app/core/services/ai.service';
import { UsersService, User } from '@core/services/users.service';
import { Appointment } from '@core/services/appointments.service';
import { environment } from '@env/environment';

interface VitalDisplay {
  label: string;
  value: string;
  unit: string;
  icon: string;
  color: string;
  status: 'normal' | 'warning' | 'critical';
  timestamp?: Date;
}

@Component({
  selector: 'app-vital-signs-panel',
  standalone: true,
  imports: [CommonModule, IconComponent],
  template: `
    <div class="vital-signs-panel">
      <div class="panel-header">
        <h4>
          <app-icon name="activity" [size]="20" />
          Sinais Vitais em Tempo Real
        </h4>
        <span class="connection-indicator" [class.connected]="isConnected">
          <span class="indicator-dot"></span>
          {{ isConnected ? 'Conectado' : 'Aguardando' }}
        </span>
      </div>

      @if (!hasAnyData) {
        <div class="waiting-state">
          <div class="waiting-icon">
            <app-icon name="bluetooth" [size]="48" />
          </div>
          <h5>Aguardando dados do paciente...</h5>
          <p>Os sinais vitais aparecerão aqui quando o paciente conectar os dispositivos</p>
        </div>
      } @else {
        <div class="vitals-grid">
          @if (vitals['spo2']) {
            <div class="vital-card spo2" [class]="getStatusClass(vitals['spo2'])">
              <div class="vital-icon">
                <app-icon name="droplet" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">SpO₂</span>
                <span class="vital-value">{{ vitals['spo2'].value }}<small>{{ vitals['spo2'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['spo2'].status"></div>
            </div>
          }

          @if (vitals['pulseRate']) {
            <div class="vital-card pulse" [class]="getStatusClass(vitals['pulseRate'])">
              <div class="vital-icon pulse-animation">
                <app-icon name="heart" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">Freq. Cardíaca</span>
                <span class="vital-value">{{ vitals['pulseRate'].value }}<small>{{ vitals['pulseRate'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['pulseRate'].status"></div>
            </div>
          }

          @if (vitals['temperature']) {
            <div class="vital-card temp" [class]="getStatusClass(vitals['temperature'])">
              <div class="vital-icon">
                <app-icon name="thermometer" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">Temperatura</span>
                <span class="vital-value">{{ vitals['temperature'].value }}<small>{{ vitals['temperature'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['temperature'].status"></div>
            </div>
          }

          @if (vitals['bloodPressure']) {
            <div class="vital-card bp" [class]="getStatusClass(vitals['bloodPressure'])">
              <div class="vital-icon">
                <app-icon name="activity" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">Pressão Arterial</span>
                <span class="vital-value">{{ vitals['bloodPressure'].value }}<small>{{ vitals['bloodPressure'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['bloodPressure'].status"></div>
            </div>
          }

          @if (vitals['weight']) {
            <div class="vital-card weight">
              <div class="vital-icon">
                <app-icon name="box" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">Peso</span>
                <span class="vital-value">{{ vitals['weight'].value }}<small>{{ vitals['weight'].unit }}</small></span>
              </div>
            </div>
          }

          @if (vitals['height']) {
            <div class="vital-card height">
              <div class="vital-icon">
                <app-icon name="maximize" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">Altura</span>
                <span class="vital-value">{{ vitals['height'].value }}<small>{{ vitals['height'].unit }}</small></span>
              </div>
            </div>
          }

          @if (imc) {
            <div class="vital-card imc" [class]="getImcStatusClass()">
              <div class="vital-icon">
                <app-icon name="scale" [size]="20" />
              </div>
              <div class="vital-info">
                <span class="vital-label">IMC</span>
                <span class="vital-value">{{ imc }}<small>kg/m²</small></span>
                <span class="imc-classification">{{ imcClassification }}</span>
              </div>
              <div class="vital-indicator" [class]="imcStatus"></div>
            </div>
          }
        </div>

        <!-- Botão Análise IA -->
        @if (hasAnyData) {
          <div class="ai-analysis-section">
            <button class="btn-ai-analysis" (click)="openAIAnalysis()" [disabled]="isAnalyzing">
              @if (isAnalyzing) {
                <app-icon name="loader" [size]="16" class="spin" />
                <span>Analisando...</span>
              } @else {
                <app-icon name="sparkles" [size]="16" />
                <span>Análise IA dos Sinais Vitais</span>
              }
            </button>
          </div>
        }

        @if (lastUpdate) {
          <div class="last-update">
            <app-icon name="clock" [size]="14" />
            Última atualização: {{ formatTime(lastUpdate) }}
          </div>
        }
      }

      <!-- Modal de Análise IA -->
      @if (showAIModal) {
        <div class="modal-overlay" (click)="closeAIModal()">
          <div class="modal-content" (click)="$event.stopPropagation()">
            <div class="modal-header">
              <div class="modal-title">
                <app-icon name="sparkles" [size]="20" />
                <span>Análise IA dos Sinais Vitais</span>
              </div>
              <button class="modal-close" (click)="closeAIModal()">
                <app-icon name="close" [size]="20" />
              </button>
            </div>
            <div class="modal-body">
              @if (isAnalyzing) {
                <div class="analyzing-state">
                  <app-icon name="loader" [size]="32" class="spin" />
                  <p>Consultando DeepSeek AI...</p>
                </div>
              } @else if (aiAnalysisError) {
                <div class="error-state">
                  <app-icon name="alert-triangle" [size]="32" />
                  <p>{{ aiAnalysisError }}</p>
                  <button class="btn-retry" (click)="retryAnalysis()">
                    <app-icon name="refresh-cw" [size]="14" />
                    Tentar novamente
                  </button>
                </div>
              } @else {
                <div class="ai-analysis-content" [innerHTML]="formattedAIAnalysis"></div>
                <div class="ai-disclaimer">
                  <app-icon name="info" [size]="14" />
                  <span>Esta análise é uma sugestão da IA. O médico responsável deve validar todas as conclusões.</span>
                </div>
              }
            </div>
            <div class="modal-footer">
              <span class="generated-at" *ngIf="aiAnalysisGeneratedAt">
                Gerado em: {{ aiAnalysisGeneratedAt | date:'dd/MM/yyyy HH:mm' }}
              </span>
              <button class="btn-close-modal" (click)="closeAIModal()">Fechar</button>
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .vital-signs-panel {
      padding: 16px;
      height: 100%;
      display: flex;
      flex-direction: column;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;

      h4 {
        display: flex;
        align-items: center;
        gap: 8px;
        margin: 0;
        font-size: 16px;
        font-weight: 600;
        color: var(--text-primary);
      }

      .connection-indicator {
        display: flex;
        align-items: center;
        gap: 6px;
        font-size: 12px;
        color: var(--text-secondary);

        .indicator-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background: var(--color-secondary);
        }

        &.connected {
          color: var(--text-success);

          .indicator-dot {
            background: var(--color-success);
            animation: pulse-dot 2s infinite;
          }
        }
      }
    }

    .waiting-state {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      padding: 40px 20px;
      color: var(--text-secondary);

      .waiting-icon {
        width: 80px;
        height: 80px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: var(--bg-secondary);
        border-radius: 50%;
        margin-bottom: 16px;
        animation: waiting-pulse 2s infinite;
      }

      h5 {
        margin: 0 0 8px 0;
        font-size: 16px;
        color: var(--text-primary);
      }

      p {
        margin: 0;
        font-size: 13px;
        max-width: 280px;
      }
    }

    .vitals-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 16px;
      flex: 1;
    }

    .vital-card {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 14px;
      background: var(--bg-secondary);
      border-radius: 12px;
      border-left: 3px solid transparent;
      position: relative;
      transition: all 0.3s ease;

      &.spo2 { border-left-color: #3b82f6; }
      &.pulse { border-left-color: #ef4444; }
      &.temp { border-left-color: #f97316; }
      &.bp { border-left-color: #10b981; }
      &.weight { border-left-color: #8b5cf6; }
      &.height { border-left-color: #06b6d4; }
      &.imc { border-left-color: #ec4899; }

      &.warning {
        background: var(--bg-warning-subtle);
      }

      &.critical {
        background: var(--bg-danger-subtle);
        animation: critical-pulse 1s infinite;
      }

      .vital-icon {
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: var(--bg-tertiary);
        border-radius: 10px;

        &.pulse-animation {
          animation: heartbeat 1s infinite;
        }
      }

      .vital-info {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 4px;

        .vital-label {
          font-size: 11px;
          color: var(--text-secondary);
          text-transform: uppercase;
          letter-spacing: 0.3px;
          font-weight: 500;
        }

        .vital-value {
          font-size: 20px;
          font-weight: 600;
          color: var(--text-primary);
          line-height: 1.2;
          font-variant-numeric: tabular-nums;

          small {
            font-size: 12px;
            font-weight: 400;
            margin-left: 2px;
            color: var(--text-tertiary);
          }
        }

        .imc-classification {
          font-size: 10px;
          color: var(--text-secondary);
          font-weight: 500;
        }
      }

      .vital-indicator {
        position: absolute;
        top: 8px;
        right: 8px;
        width: 10px;
        height: 10px;
        border-radius: 50%;

        &.normal { background: #10b981; }
        &.warning { background: #f59e0b; }
        &.critical { background: #ef4444; animation: blink 0.5s infinite; }
      }
    }

    .last-update {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid var(--border-color);
      font-size: 12px;
      color: var(--text-secondary);
    }

    .medical-analysis {
      margin-top: 16px;
      padding: 12px;
      background: var(--bg-warning-subtle);
      border-radius: 8px;
      border-left: 3px solid #f59e0b;

      &.normal {
        background: var(--bg-success-subtle);
        border-left-color: #10b981;
      }

      .analysis-header {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 13px;
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 8px;
      }

      .analysis-summary {
        margin: 0;
        font-size: 12px;
        color: var(--text-secondary);
      }

      .alerts-list {
        display: flex;
        flex-direction: column;
        gap: 6px;
      }

      .alert-item {
        display: flex;
        align-items: flex-start;
        gap: 8px;
        font-size: 12px;
        padding: 6px 8px;
        border-radius: 4px;
        background: rgba(255, 255, 255, 0.5);

        &.warning {
          color: #92400e;
        }

        &.critical {
          color: #dc2626;
          background: rgba(239, 68, 68, 0.1);
          font-weight: 500;
        }

        span {
          flex: 1;
          line-height: 1.4;
        }
      }
    }

    @keyframes pulse-dot {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(1.2); }
    }

    @keyframes waiting-pulse {
      0%, 100% { opacity: 0.6; }
      50% { opacity: 1; }
    }

    @keyframes heartbeat {
      0%, 100% { transform: scale(1); }
      14% { transform: scale(1.1); }
      28% { transform: scale(1); }
      42% { transform: scale(1.1); }
      70% { transform: scale(1); }
    }

    @keyframes critical-pulse {
      0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.3); }
      50% { box-shadow: 0 0 0 8px rgba(239, 68, 68, 0); }
    }

    @keyframes blink {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.3; }
    }

    .ai-analysis-section {
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid var(--border-color);
    }

    .btn-ai-analysis {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      width: 100%;
      padding: 12px 16px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
      color: white;
      transition: all 0.2s ease;

      &:hover:not(:disabled) {
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);
      }

      &:disabled {
        opacity: 0.7;
        cursor: not-allowed;
      }

      .spin {
        animation: spin 1s linear infinite;
      }
    }

    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.6);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 10000;
      padding: 20px;
    }

    .modal-content {
      background: var(--bg-primary);
      border-radius: 16px;
      max-width: 600px;
      width: 100%;
      max-height: 80vh;
      display: flex;
      flex-direction: column;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
    }

    .modal-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 16px 20px;
      border-bottom: 1px solid var(--border-color);
      background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
      border-radius: 16px 16px 0 0;
      color: white;

      .modal-title {
        display: flex;
        align-items: center;
        gap: 10px;
        font-size: 16px;
        font-weight: 600;
      }

      .modal-close {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border: none;
        border-radius: 8px;
        background: rgba(255, 255, 255, 0.2);
        color: white;
        cursor: pointer;
        transition: background 0.2s ease;

        &:hover {
          background: rgba(255, 255, 255, 0.3);
        }
      }
    }

    .modal-body {
      flex: 1;
      overflow-y: auto;
      padding: 20px;

      .analyzing-state, .error-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 40px 20px;
        text-align: center;
        color: var(--text-secondary);

        p {
          margin: 16px 0 0 0;
          font-size: 14px;
        }
      }

      .error-state {
        color: var(--text-danger);

        .btn-retry {
          display: flex;
          align-items: center;
          gap: 6px;
          margin-top: 16px;
          padding: 8px 16px;
          border: 1px solid var(--border-color);
          border-radius: 6px;
          background: var(--bg-secondary);
          color: var(--text-primary);
          cursor: pointer;

          &:hover {
            background: var(--bg-tertiary);
          }
        }
      }

      .ai-analysis-content {
        font-size: 14px;
        line-height: 1.7;
        color: var(--text-primary);

        :deep(h1), :deep(h2), :deep(h3) {
          margin: 16px 0 8px 0;
          font-weight: 600;
          color: var(--text-primary);
        }

        :deep(h1) { font-size: 18px; }
        :deep(h2) { font-size: 16px; }
        :deep(h3) { font-size: 14px; }

        :deep(p) {
          margin: 8px 0;
        }

        :deep(ul), :deep(ol) {
          margin: 8px 0;
          padding-left: 20px;
        }

        :deep(li) {
          margin: 4px 0;
        }

        :deep(strong) {
          font-weight: 600;
          color: var(--text-primary);
        }
      }

      .ai-disclaimer {
        display: flex;
        align-items: flex-start;
        gap: 8px;
        margin-top: 16px;
        padding: 12px;
        background: var(--bg-warning-subtle);
        border-radius: 8px;
        font-size: 12px;
        color: var(--text-secondary);
        border-left: 3px solid #f59e0b;

        span {
          flex: 1;
          line-height: 1.5;
        }
      }
    }

    .modal-footer {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px 20px;
      border-top: 1px solid var(--border-color);
      background: var(--bg-secondary);
      border-radius: 0 0 16px 16px;

      .generated-at {
        font-size: 11px;
        color: var(--text-tertiary);
      }

      .btn-close-modal {
        padding: 8px 20px;
        border: none;
        border-radius: 6px;
        font-size: 13px;
        font-weight: 500;
        cursor: pointer;
        background: var(--color-primary);
        color: white;

        &:hover {
          opacity: 0.9;
        }
      }
    }

    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }
  `]
})
export class VitalSignsPanelComponent implements OnInit, OnDestroy, OnChanges {
  @Input() appointmentId: string | null = null;
  @Input() appointment: Appointment | null = null;
  @Input() userrole: string = '';

  isConnected = false;
  hasAnyData = false;
  lastUpdate: Date | null = null;
  
  vitals: Record<string, VitalDisplay> = {};
  
  // IMC
  imc: string | null = null;
  imcClassification: string = '';
  imcStatus: 'normal' | 'warning' | 'critical' = 'normal';
  
  // Alertas médicos
  alerts: { type: 'warning' | 'critical'; icon: string; message: string }[] = [];
  
  // Modal de análise IA
  showAIModal = false;
  isAnalyzing = false;
  aiAnalysis: string = '';
  formattedAIAnalysis: string = '';
  aiAnalysisError: string = '';
  aiAnalysisGeneratedAt: Date | null = null;
  
  // Dados brutos para enviar à IA
  private rawBiometrics: any = {};
  
  // Dados do paciente para IA
  private patientData: User | null = null;

  private subscriptions = new Subscription();

  constructor(
    private http: HttpClient,
    private syncService: MedicalDevicesSyncService,
    private aiService: AIService,
    private usersService: UsersService
  ) {}

  ngOnInit(): void {
    // Carrega dados existentes do banco
    this.loadExistingData();
    
    // Carrega dados do paciente
    this.loadPatientData();
    
    // Conecta ao hub
    if (this.appointmentId) {
      this.syncService.connect(this.appointmentId);
    }

    // Observa conexão
    this.subscriptions.add(
      this.syncService.isConnected$.subscribe(connected => {
        this.isConnected = connected;
      })
    );

    // Observa sinais vitais recebidos
    this.subscriptions.add(
      this.syncService.vitalSignsReceived$.subscribe(data => {
        this.processVitalSigns(data);
      })
    );
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['appointment'] && changes['appointment'].currentValue) {
      this.loadPatientData();
    }
  }

  private loadPatientData(): void {
    if (this.appointment?.patientId) {
      this.usersService.getUserById(this.appointment.patientId).subscribe({
        next: (user) => {
          this.patientData = user;
          console.log('[VitalSignsPanel] Dados do paciente carregados:', user.name, user.patientProfile?.gender, user.patientProfile?.birthDate);
        },
        error: (error) => {
          console.warn('[VitalSignsPanel] Erro ao carregar dados do paciente:', error);
        }
      });
    }
  }

  private async loadExistingData(): Promise<void> {
    if (!this.appointmentId) return;

    try {
      const apiUrl = `${environment.apiUrl}/appointments/${this.appointmentId}/biometrics`;
      const data = await firstValueFrom(this.http.get<any>(apiUrl));
      
      if (data && this.hasAnyVitalData(data)) {
        // Converte dados do banco para formato do componente
        const vitalSignsData: VitalSignsData = {
          appointmentId: this.appointmentId,
          senderRole: 'loaded',
          timestamp: data.lastUpdated ? new Date(data.lastUpdated) : new Date(),
          vitals: {
            spo2: data.oxygenSaturation,
            pulseRate: data.heartRate,
            heartRate: data.heartRate,
            systolic: data.bloodPressureSystolic,
            diastolic: data.bloodPressureDiastolic,
            temperature: data.temperature,
            weight: data.weight,
            height: data.height
          }
        };
        this.processVitalSigns(vitalSignsData);
      }
    } catch (error) {
      console.warn('[VitalSignsPanel] Erro ao carregar dados existentes:', error);
    }
  }

  private hasAnyVitalData(data: any): boolean {
    return data.oxygenSaturation || data.heartRate || data.bloodPressureSystolic || 
           data.bloodPressureDiastolic || data.temperature || data.weight || data.height;
  }

  private processVitalSigns(data: VitalSignsData): void {
    this.hasAnyData = true;
    this.lastUpdate = new Date(data.timestamp);

    const v = data.vitals;
    
    // Armazena dados brutos para enviar à IA
    this.rawBiometrics = {
      spo2: v.spo2 ?? (v as any).oxygenSaturation,
      heartRate: v.pulseRate ?? v.heartRate ?? (v as any).heartRate,
      systolic: v.systolic ?? (v as any).bloodPressureSystolic,
      diastolic: v.diastolic ?? (v as any).bloodPressureDiastolic,
      temperature: v.temperature,
      weight: v.weight,
      height: v.height ?? (v as any).height
    };

    // Suporta tanto spo2 quanto oxygenSaturation
    const spo2Value = v.spo2 ?? (v as any).oxygenSaturation;
    if (spo2Value !== undefined && spo2Value !== null) {
      this.vitals['spo2'] = {
        label: 'SpO₂',
        value: spo2Value.toString(),
        unit: '%',
        icon: 'droplet',
        color: '#3b82f6',
        status: this.getSpo2Status(spo2Value)
      };
    }

    // Suporta tanto pulseRate quanto heartRate
    const pulseValue = v.pulseRate ?? v.heartRate ?? (v as any).heartRate;
    if (pulseValue !== undefined && pulseValue !== null) {
      this.vitals['pulseRate'] = {
        label: 'Freq. Cardíaca',
        value: pulseValue.toString(),
        unit: 'bpm',
        icon: 'heart',
        color: '#ef4444',
        status: this.getPulseStatus(pulseValue)
      };
    }

    if (v.temperature !== undefined && v.temperature !== null) {
      this.vitals['temperature'] = {
        label: 'Temperatura',
        value: Number(v.temperature).toFixed(1),
        unit: '°C',
        icon: 'thermometer',
        color: '#f97316',
        status: this.getTemperatureStatus(v.temperature)
      };
    }

    // Suporta tanto systolic/diastolic quanto bloodPressureSystolic/bloodPressureDiastolic
    const systolicValue = v.systolic ?? (v as any).bloodPressureSystolic;
    const diastolicValue = v.diastolic ?? (v as any).bloodPressureDiastolic;
    if (systolicValue !== undefined && diastolicValue !== undefined && 
        systolicValue !== null && diastolicValue !== null) {
      this.vitals['bloodPressure'] = {
        label: 'Pressão Arterial',
        value: `${systolicValue}/${diastolicValue}`,
        unit: 'mmHg',
        icon: 'activity',
        color: '#10b981',
        status: this.getBloodPressureStatus(systolicValue, diastolicValue)
      };
    }

    if (v.weight !== undefined && v.weight !== null) {
      this.vitals['weight'] = {
        label: 'Peso',
        value: Number(v.weight).toFixed(1),
        unit: 'kg',
        icon: 'box',
        color: '#8b5cf6',
        status: 'normal'
      };
    }

    // Altura
    const heightValue = v.height ?? (v as any).height;
    if (heightValue !== undefined && heightValue !== null) {
      this.vitals['height'] = {
        label: 'Altura',
        value: heightValue.toString(),
        unit: 'cm',
        icon: 'ruler',
        color: '#06b6d4',
        status: 'normal'
      };
    }

    // Calcula IMC se tiver peso e altura
    this.calculateIMC();
    
    // Gera alertas médicos
    this.generateAlerts();
  }

  private getSpo2Status(value: number): 'normal' | 'warning' | 'critical' {
    if (value >= 95) return 'normal';
    if (value >= 90) return 'warning';
    return 'critical';
  }

  private getPulseStatus(value: number): 'normal' | 'warning' | 'critical' {
    if (value >= 60 && value <= 100) return 'normal';
    if (value >= 50 && value <= 120) return 'warning';
    return 'critical';
  }

  private getTemperatureStatus(value: number): 'normal' | 'warning' | 'critical' {
    if (value >= 36 && value <= 37.5) return 'normal';
    if (value >= 35 && value <= 38.5) return 'warning';
    return 'critical';
  }

  private getBloodPressureStatus(systolic: number, diastolic: number): 'normal' | 'warning' | 'critical' {
    if (systolic <= 120 && diastolic <= 80) return 'normal';
    if (systolic <= 140 && diastolic <= 90) return 'warning';
    return 'critical';
  }

  getStatusClass(vital: VitalDisplay): string {
    return vital.status;
  }

  getImcStatusClass(): string {
    return this.imcStatus;
  }

  private calculateIMC(): void {
    const weight = this.vitals['weight'];
    const height = this.vitals['height'];
    
    if (!weight || !height) {
      this.imc = null;
      return;
    }

    const weightValue = parseFloat(weight.value);
    const heightValue = parseFloat(height.value);
    
    if (weightValue > 0 && heightValue > 0) {
      const heightInMeters = heightValue / 100;
      const imcValue = weightValue / (heightInMeters * heightInMeters);
      this.imc = imcValue.toFixed(1);
      
      // Classificação do IMC
      if (imcValue < 18.5) {
        this.imcClassification = 'Abaixo do peso';
        this.imcStatus = 'warning';
      } else if (imcValue < 25) {
        this.imcClassification = 'Peso normal';
        this.imcStatus = 'normal';
      } else if (imcValue < 30) {
        this.imcClassification = 'Sobrepeso';
        this.imcStatus = 'warning';
      } else if (imcValue < 35) {
        this.imcClassification = 'Obesidade grau I';
        this.imcStatus = 'warning';
      } else if (imcValue < 40) {
        this.imcClassification = 'Obesidade grau II';
        this.imcStatus = 'critical';
      } else {
        this.imcClassification = 'Obesidade grau III';
        this.imcStatus = 'critical';
      }
    }
  }

  private generateAlerts(): void {
    this.alerts = [];

    // Alerta SpO2
    const spo2 = this.vitals['spo2'];
    if (spo2) {
      const value = parseFloat(spo2.value);
      if (value < 90) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `SpO₂ crítica (${value}%): Hipoxemia severa. Considerar oxigenoterapia imediata.`
        });
      } else if (value < 95) {
        this.alerts.push({
          type: 'warning',
          icon: 'alert-circle',
          message: `SpO₂ baixa (${value}%): Dessaturação leve. Monitorar e investigar causa.`
        });
      }
    }

    // Alerta Frequência Cardíaca
    const pulse = this.vitals['pulseRate'];
    if (pulse) {
      const value = parseFloat(pulse.value);
      if (value < 50) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `Bradicardia severa (${value} bpm): Avaliar medicações, distúrbios eletrolíticos e função tireoidiana.`
        });
      } else if (value < 60) {
        this.alerts.push({
          type: 'warning',
          icon: 'alert-circle',
          message: `Bradicardia (${value} bpm): Pode ser normal em atletas. Correlacionar com sintomas.`
        });
      } else if (value > 120) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `Taquicardia (${value} bpm): Investigar dor, febre, ansiedade, desidratação ou arritmia.`
        });
      } else if (value > 100) {
        this.alerts.push({
          type: 'warning',
          icon: 'alert-circle',
          message: `Frequência cardíaca elevada (${value} bpm): Monitorar e avaliar contexto clínico.`
        });
      }
    }

    // Alerta Temperatura
    const temp = this.vitals['temperature'];
    if (temp) {
      const value = parseFloat(temp.value);
      if (value >= 39) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `Febre alta (${value}°C): Investigar foco infeccioso. Considerar antitérmico e hidratação.`
        });
      } else if (value >= 37.5) {
        this.alerts.push({
          type: 'warning',
          icon: 'thermometer',
          message: `Febre (${value}°C): Estado febril. Monitorar evolução e sintomas associados.`
        });
      } else if (value < 35.5) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `Hipotermia (${value}°C): Verificar ambiente, estado nutricional e possível choque.`
        });
      }
    }

    // Alerta Pressão Arterial
    const bp = this.vitals['bloodPressure'];
    if (bp) {
      const [systolic, diastolic] = bp.value.split('/').map(v => parseFloat(v));
      if (systolic >= 180 || diastolic >= 110) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `Crise hipertensiva (${bp.value} mmHg): Avaliar lesão de órgão-alvo. Encaminhar urgência se sintomático.`
        });
      } else if (systolic >= 140 || diastolic >= 90) {
        this.alerts.push({
          type: 'warning',
          icon: 'activity',
          message: `Hipertensão (${bp.value} mmHg): Confirmar com medições repetidas. Orientar mudanças de estilo de vida.`
        });
      } else if (systolic < 90 || diastolic < 60) {
        this.alerts.push({
          type: 'warning',
          icon: 'alert-circle',
          message: `Hipotensão (${bp.value} mmHg): Avaliar hidratação, medicações e sintomas posturais.`
        });
      }
    }

    // Alerta IMC
    if (this.imc) {
      const imcValue = parseFloat(this.imc);
      if (imcValue >= 40) {
        this.alerts.push({
          type: 'critical',
          icon: 'alert-triangle',
          message: `Obesidade mórbida (IMC ${this.imc}): Risco cardiovascular muito alto. Considerar encaminhamento especializado.`
        });
      } else if (imcValue >= 30) {
        this.alerts.push({
          type: 'warning',
          icon: 'scale',
          message: `Obesidade (IMC ${this.imc}): Orientar dieta, exercícios e rastreio de comorbidades.`
        });
      } else if (imcValue < 18.5) {
        this.alerts.push({
          type: 'warning',
          icon: 'alert-circle',
          message: `Baixo peso (IMC ${this.imc}): Investigar causa nutricional, psiquiátrica ou orgânica.`
        });
      }
    }
  }

  formatTime(date: Date): string {
    return date.toLocaleTimeString('pt-BR', { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  }

  // === Métodos da Modal de Análise IA ===
  
  openAIAnalysis(): void {
    this.showAIModal = true;
    this.aiAnalysisError = '';
    
    // Se já tem análise recente (últimos 5 minutos), não refaz
    if (this.aiAnalysis && this.aiAnalysisGeneratedAt) {
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
      if (this.aiAnalysisGeneratedAt > fiveMinutesAgo) {
        return;
      }
    }
    
    this.requestAIAnalysis();
  }

  closeAIModal(): void {
    this.showAIModal = false;
  }

  retryAnalysis(): void {
    this.aiAnalysisError = '';
    this.requestAIAnalysis();
  }

  private getPatientAge(): number | undefined {
    const birthDate = this.patientData?.patientProfile?.birthDate;
    if (!birthDate) return undefined;
    
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age > 0 ? age : undefined;
  }

  private async requestAIAnalysis(): Promise<void> {
    this.isAnalyzing = true;
    this.aiAnalysisError = '';

    const request: AnalyzeVitalsRequest = {
      patientAge: this.getPatientAge(),
      patientGender: this.patientData?.patientProfile?.gender,
      biometrics: {
        oxygenSaturation: this.rawBiometrics.spo2 ? parseInt(this.rawBiometrics.spo2) : undefined,
        heartRate: this.rawBiometrics.heartRate ? parseInt(this.rawBiometrics.heartRate) : undefined,
        bloodPressureSystolic: this.rawBiometrics.systolic ? parseInt(this.rawBiometrics.systolic) : undefined,
        bloodPressureDiastolic: this.rawBiometrics.diastolic ? parseInt(this.rawBiometrics.diastolic) : undefined,
        temperature: this.rawBiometrics.temperature ? parseFloat(this.rawBiometrics.temperature) : undefined,
        weight: this.rawBiometrics.weight ? parseFloat(this.rawBiometrics.weight) : undefined,
        height: this.rawBiometrics.height ? parseInt(this.rawBiometrics.height) : undefined
      }
    };

    try {
      const response = await firstValueFrom(this.aiService.analyzeVitals(request));
      this.aiAnalysis = response.analysis;
      this.formattedAIAnalysis = this.formatMarkdown(response.analysis);
      this.aiAnalysisGeneratedAt = new Date(response.generatedAt);
    } catch (error: any) {
      console.error('[VitalSignsPanel] Erro ao analisar sinais vitais:', error);
      this.aiAnalysisError = error?.error?.message || 'Erro ao comunicar com o serviço de IA. Tente novamente.';
    } finally {
      this.isAnalyzing = false;
    }
  }

  private formatMarkdown(text: string): string {
    // Converte markdown básico para HTML
    let html = text
      // Headers
      .replace(/^### (.*$)/gim, '<h3>$1</h3>')
      .replace(/^## (.*$)/gim, '<h2>$1</h2>')
      .replace(/^# (.*$)/gim, '<h1>$1</h1>')
      // Bold
      .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
      // Italic
      .replace(/\*(.*?)\*/gim, '<em>$1</em>')
      // Line breaks
      .replace(/\n/gim, '<br>');
    
    return html;
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }
}
