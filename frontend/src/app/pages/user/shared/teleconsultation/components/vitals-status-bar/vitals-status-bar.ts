import { Component, Input, OnInit, OnDestroy, OnChanges, SimpleChanges, Inject, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { HttpClient } from '@angular/common/http';

import { IconComponent } from '@shared/components/atoms/icon/icon';
import { MedicalDevicesSyncService, VitalSignsData } from '@app/core/services/medical-devices-sync.service';
import { Appointment } from '@core/services/appointments.service';
import { UsersService, User } from '@core/services/users.service';
import { AIService, AnalyzeVitalsRequest } from '@app/core/services/ai.service';
import { ModalService } from '@core/services/modal.service';
import { environment } from '@env/environment';

@Component({
  selector: 'app-vitals-status-bar',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  template: `
    <div class="vitals-bar" [class.professional]="isProfessional">
      <!-- LINHA 1: Paciente + Ações -->
      <div class="row-1">
        <div class="patient-info">
          <span class="patient-badge">
            <app-icon name="user" [size]="22" />
            <strong>{{ patientName || 'Paciente' }}</strong>
          </span>
          <span class="chip">Sexo: <b>{{ getGenderLabel() }}</b></span>
          <span class="chip">Idade: <b>{{ patientAge ? patientAge + ' anos' : '--' }}</b></span>
        </div>
        
        <div class="actions">
          <!-- OPERADOR: botão capturar -->
          <button *ngIf="!isProfessional" class="btn-capture" (click)="capturarSinais()" [disabled]="isCapturing">
            <span *ngIf="isCapturing" class="spinner"></span>
            <app-icon *ngIf="!isCapturing" name="radio" [size]="20" />
            <span>{{ isCapturing ? 'Buscando...' : '📡 Capturar Sinais' }}</span>
          </button>
          
          <!-- MÉDICO: botão analisar -->
          <button *ngIf="isProfessional" class="btn-analyze" (click)="analisarSinais()" [disabled]="!hasAnyVitals() || isAnalyzing">
            <span *ngIf="isAnalyzing" class="spinner"></span>
            <app-icon *ngIf="!isAnalyzing" name="sparkles" [size]="20" />
            <span>🧠 Analisar Sinais Vitais</span>
          </button>
          
          <span *ngIf="captureMessage" class="msg" [class.ok]="captureSuccess" [class.err]="!captureSuccess">
            {{ captureMessage }}
          </span>
          
          <span *ngIf="lastSync" class="sync-info">
            <app-icon name="check-circle" [size]="16" />
            Sync: {{ lastSync | date:'HH:mm:ss' }}
          </span>
        </div>
      </div>
      
      <!-- LINHA 2: Sinais Vitais -->
      <div class="row-2">
        <!-- Peso -->
        <div class="vital" [class.has-value]="weight">
          <label><app-icon name="scale" [size]="18" /> Peso</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="weight" (ngModelChange)="onVitalChange()" placeholder="--">
            <span *ngIf="isProfessional" class="readonly">{{ weight || '--' }}</span>
            <small>kg</small>
          </div>
        </div>
        
        <!-- Altura -->
        <div class="vital" [class.has-value]="height">
          <label><app-icon name="activity" [size]="18" /> Altura</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="height" (ngModelChange)="onVitalChange()" placeholder="--">
            <span *ngIf="isProfessional" class="readonly">{{ height || '--' }}</span>
            <small>cm</small>
          </div>
        </div>
        
        <!-- IMC -->
        <div class="vital imc" [class.has-value]="imc" [class.warn]="imcStatus==='warning'" [class.crit]="imcStatus==='critical'">
          <label><app-icon name="bar-chart" [size]="18" /> IMC</label>
          <div class="value-box">
            <span class="readonly calc">{{ imc ? imc.toFixed(1) : '--' }}</span>
          </div>
        </div>
        
        <div class="sep"></div>
        
        <!-- SpO2 -->
        <div class="vital" [class.has-value]="spo2" [class.warn]="spo2 && spo2 >= 90 && spo2 < 95" [class.crit]="spo2 && spo2 < 90">
          <label><app-icon name="droplet" [size]="18" /> SpO₂</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="spo2" (ngModelChange)="onVitalChange()" placeholder="--">
            <span *ngIf="isProfessional" class="readonly">{{ spo2 || '--' }}</span>
            <small>%</small>
          </div>
        </div>
        
        <!-- FC -->
        <div class="vital" [class.has-value]="heartRate" [class.warn]="heartRate && (heartRate < 60 || heartRate > 100)" [class.crit]="heartRate && (heartRate < 50 || heartRate > 120)">
          <label><app-icon name="heart" [size]="18" /> FC</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="heartRate" (ngModelChange)="onVitalChange()" placeholder="--">
            <span *ngIf="isProfessional" class="readonly">{{ heartRate || '--' }}</span>
            <small>bpm</small>
          </div>
        </div>
        
        <div class="sep"></div>
        
        <!-- PA Sistólica -->
        <div class="vital" [class.has-value]="systolic" [class.warn]="isPressureWarning()" [class.crit]="isPressureCritical()">
          <label><app-icon name="activity" [size]="18" /> PA Sis</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="systolic" (ngModelChange)="onVitalChange()" placeholder="--">
            <span *ngIf="isProfessional" class="readonly">{{ systolic || '--' }}</span>
            <small>mmHg</small>
          </div>
        </div>
        
        <!-- PA Diastólica -->
        <div class="vital" [class.has-value]="diastolic" [class.warn]="isPressureWarning()" [class.crit]="isPressureCritical()">
          <label>PA Dia</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="diastolic" (ngModelChange)="onVitalChange()" placeholder="--">
            <span *ngIf="isProfessional" class="readonly">{{ diastolic || '--' }}</span>
            <small>mmHg</small>
          </div>
        </div>
        
        <div class="sep"></div>
        
        <!-- Temperatura -->
        <div class="vital" [class.has-value]="temperature" [class.warn]="temperature && temperature >= 37.5 && temperature < 38.5" [class.crit]="temperature && temperature >= 38.5">
          <label><app-icon name="thermometer" [size]="18" /> Temp</label>
          <div class="value-box">
            <input *ngIf="!isProfessional" type="number" [(ngModel)]="temperature" (ngModelChange)="onVitalChange()" placeholder="--" step="0.1">
            <span *ngIf="isProfessional" class="readonly">{{ temperature || '--' }}</span>
            <small>°C</small>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    /* ============ CONTAINER PRINCIPAL ============ */
    :host {
      display: block !important;
      width: 100% !important;
    }
    
    .vitals-bar {
      display: flex;
      flex-direction: column;
      width: 100%;
      background: #1e293b;
      color: #f1f5f9;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    
    /* ============ LINHA 1: PACIENTE + AÇÕES ============ */
    .row-1 {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 16px;
      padding: 14px 24px;
      background: linear-gradient(90deg, rgba(59,130,246,0.2) 0%, rgba(59,130,246,0.05) 40%, transparent 70%);
      border-bottom: 1px solid rgba(255,255,255,0.1);
      min-height: 60px;
    }
    
    .patient-info {
      display: flex;
      align-items: center;
      gap: 20px;
      flex-wrap: wrap;
    }
    
    .patient-badge {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 18px;
      background: rgba(59,130,246,0.25);
      border: 1px solid rgba(59,130,246,0.4);
      border-radius: 12px;
      
      app-icon { color: #60a5fa; }
      strong { font-size: 18px; color: #fff; }
    }
    
    .chip {
      font-size: 15px;
      color: #94a3b8;
      padding: 8px 14px;
      background: rgba(255,255,255,0.06);
      border-radius: 8px;
      
      b { color: #e2e8f0; font-weight: 600; }
    }
    
    .actions {
      display: flex;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
    }
    
    .btn-capture, .btn-analyze {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 14px 28px;
      border: none;
      border-radius: 12px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      color: white;
      
      &:hover:not(:disabled) { transform: translateY(-2px); }
      &:disabled { opacity: 0.5; cursor: not-allowed; }
    }
    
    .btn-capture {
      background: linear-gradient(135deg, #3b82f6, #2563eb);
      box-shadow: 0 4px 12px rgba(59,130,246,0.4);
    }
    
    .btn-analyze {
      background: linear-gradient(135deg, #8b5cf6, #7c3aed);
      box-shadow: 0 4px 12px rgba(139,92,246,0.4);
    }
    
    .spinner {
      width: 18px;
      height: 18px;
      border: 2px solid rgba(255,255,255,0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    
    @keyframes spin { to { transform: rotate(360deg); } }
    
    .msg {
      padding: 8px 16px;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 500;
      
      &.ok { background: rgba(16,185,129,0.2); color: #10b981; border: 1px solid rgba(16,185,129,0.4); }
      &.err { background: rgba(239,68,68,0.2); color: #ef4444; border: 1px solid rgba(239,68,68,0.4); }
    }
    
    .sync-info {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      color: #10b981;
      padding: 8px 14px;
      background: rgba(16,185,129,0.15);
      border-radius: 20px;
    }
    
    /* ============ LINHA 2: SINAIS VITAIS ============ */
    .row-2 {
      display: flex;
      align-items: center;
      gap: 20px;
      padding: 18px 24px;
      background: #0f172a;
      flex-wrap: wrap;
      min-height: 90px;
    }
    
    .sep {
      width: 2px;
      height: 60px;
      background: linear-gradient(180deg, transparent, rgba(255,255,255,0.2), transparent);
    }
    
    .vital {
      display: flex;
      flex-direction: column;
      gap: 8px;
      min-width: 110px;
      padding: 12px 16px;
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 14px;
      transition: all 0.2s;
      
      &:hover { background: rgba(255,255,255,0.08); }
      
      label {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 13px;
        font-weight: 700;
        color: #64748b;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        
        app-icon { color: #64748b; }
      }
      
      &.has-value {
        border-color: rgba(16,185,129,0.5);
        background: rgba(16,185,129,0.1);
        
        label { color: #10b981; app-icon { color: #10b981; } }
      }
      
      &.warn {
        border-color: rgba(245,158,11,0.5);
        background: rgba(245,158,11,0.12);
        
        label { color: #f59e0b; app-icon { color: #f59e0b; } }
        input, .readonly { color: #fbbf24 !important; }
      }
      
      &.crit {
        border-color: rgba(239,68,68,0.5);
        background: rgba(239,68,68,0.12);
        
        label { color: #ef4444; app-icon { color: #ef4444; } }
        input, .readonly { color: #f87171 !important; }
      }
    }
    
    .value-box {
      display: flex;
      align-items: baseline;
      gap: 6px;
      
      input {
        width: 80px;
        padding: 10px 12px;
        border: 1px solid rgba(255,255,255,0.2);
        border-radius: 10px;
        font-size: 20px;
        font-weight: 700;
        color: #f1f5f9;
        background: rgba(0,0,0,0.4);
        text-align: center;
        transition: all 0.2s;
        
        &:focus {
          outline: none;
          border-color: #3b82f6;
          box-shadow: 0 0 0 3px rgba(59,130,246,0.3);
          background: rgba(0,0,0,0.6);
        }
        
        &::placeholder { color: #475569; font-weight: 400; }
        
        /* Remove spinner */
        &::-webkit-outer-spin-button,
        &::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
        -moz-appearance: textfield;
      }
      
      .readonly {
        font-size: 22px;
        font-weight: 700;
        color: #f1f5f9;
        min-width: 60px;
        text-align: center;
        
        &.calc {
          padding: 8px 14px;
          background: rgba(255,255,255,0.1);
          border-radius: 10px;
        }
      }
      
      small {
        font-size: 14px;
        color: #64748b;
        font-weight: 500;
      }
    }
    
    /* ============ MODO PROFISSIONAL ============ */
    .vitals-bar.professional {
      .row-1 {
        background: linear-gradient(90deg, rgba(139,92,246,0.2) 0%, rgba(139,92,246,0.05) 40%, transparent 70%);
      }
      
      .patient-badge {
        background: rgba(139,92,246,0.25);
        border-color: rgba(139,92,246,0.4);
        
        app-icon { color: #a78bfa; }
      }
    }
    
    /* ============ RESPONSIVO ============ */
    @media (max-width: 1200px) {
      .vital { min-width: 95px; padding: 10px 12px; }
      .value-box input { width: 65px; font-size: 18px; }
      .value-box .readonly { font-size: 20px; }
    }
    
    @media (max-width: 900px) {
      .sep { display: none; }
      .row-1, .row-2 { padding: 12px 16px; gap: 12px; }
    }
    
    @media (max-width: 600px) {
      .chip { display: none; }
      .vital { min-width: 80px; }
      .vital label { font-size: 11px; }
      .value-box input { width: 55px; padding: 8px; font-size: 16px; }
      .btn-capture, .btn-analyze { padding: 12px 18px; font-size: 14px; }
    }
  `]
})
export class VitalsStatusBarComponent implements OnInit, OnDestroy, OnChanges {
  @Input() appointmentId: string | null = null;
  @Input() appointment: Appointment | null = null;
  @Input() userRole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' = 'PATIENT';

  // Dados do paciente
  patientName = '';
  patientGender = '';
  patientAge: number | null = null;

  // Sinais vitais
  weight: number | null = null;
  height: number | null = null;
  spo2: number | null = null;
  heartRate: number | null = null;
  systolic: number | null = null;
  diastolic: number | null = null;
  temperature: number | null = null;

  // IMC
  imc: number | null = null;
  imcStatus: 'normal' | 'warning' | 'critical' = 'normal';

  // Estados
  isCapturing = false;
  isAnalyzing = false;
  captureMessage = '';
  captureSuccess = false;
  lastSync: Date | null = null;

  private subscriptions = new Subscription();
  private patientData: User | null = null;
  private syncTimeout: any = null;

  get isProfessional(): boolean {
    return this.userRole === 'PROFESSIONAL';
  }

  constructor(
    private medicalDevicesSync: MedicalDevicesSyncService,
    private usersService: UsersService,
    private aiService: AIService,
    private modalService: ModalService,
    private http: HttpClient,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}

  ngOnInit(): void {
    this.setupSubscriptions();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['appointment'] && this.appointment) {
      this.loadPatientInfo();
    }
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
    if (this.syncTimeout) clearTimeout(this.syncTimeout);
  }

  private setupSubscriptions(): void {
    this.subscriptions.add(
      this.medicalDevicesSync.vitalSignsReceived$.subscribe((data: VitalSignsData) => {
        if (data.appointmentId === this.appointmentId) {
          this.updateFromRemote(data);
        }
      })
    );
  }

  private loadPatientInfo(): void {
    if (!this.appointment) return;
    this.patientName = this.appointment.patientName || '';

    if (this.appointment.patientId) {
      this.usersService.getUserById(this.appointment.patientId).subscribe({
        next: (user) => {
          this.patientData = user;
          if (user.patientProfile) {
            this.patientGender = user.patientProfile.gender || '';
            if (user.patientProfile.birthDate) {
              this.patientAge = this.calculateAge(new Date(user.patientProfile.birthDate));
            }
          }
        },
        error: (err) => console.error('[VitalsBar] Erro:', err)
      });
    }
  }

  private updateFromRemote(data: VitalSignsData): void {
    const v = data.vitals;
    if (v.weight != null) this.weight = v.weight;
    if (v.height != null) this.height = v.height;
    if (v.spo2 != null) this.spo2 = v.spo2;
    if (v.pulseRate != null) this.heartRate = v.pulseRate;
    if (v.heartRate != null) this.heartRate = v.heartRate;
    if (v.systolic != null) this.systolic = v.systolic;
    if (v.diastolic != null) this.diastolic = v.diastolic;
    if (v.temperature != null) this.temperature = v.temperature;
    if (v.gender) this.patientGender = v.gender;
    if (v.birthDate) this.patientAge = this.calculateAge(new Date(v.birthDate));

    this.calculateIMC();
    this.lastSync = new Date(data.timestamp);
  }

  onVitalChange(): void {
    this.calculateIMC();
    if (this.syncTimeout) clearTimeout(this.syncTimeout);
    this.syncTimeout = setTimeout(() => {
      if (this.hasAnyVitals()) this.sendVitalsToHub();
    }, 1000);
  }

  private sendVitalsToHub(): void {
    if (!this.appointmentId) return;
    
    const vitalsData: VitalSignsData = {
      appointmentId: this.appointmentId,
      senderRole: this.userRole,
      timestamp: new Date(),
      vitals: {
        weight: this.weight || undefined,
        height: this.height || undefined,
        spo2: this.spo2 || undefined,
        heartRate: this.heartRate || undefined,
        systolic: this.systolic || undefined,
        diastolic: this.diastolic || undefined,
        temperature: this.temperature || undefined,
        gender: this.patientGender || undefined,
        birthDate: this.patientData?.patientProfile?.birthDate || undefined
      }
    };

    this.medicalDevicesSync.sendVitalSigns(vitalsData);
    this.lastSync = new Date();
  }

  async capturarSinais(): Promise<void> {
    if (!this.appointmentId) return;
    this.isCapturing = true;
    this.captureMessage = '';

    try {
      const response = await this.http.get<any>(`${environment.apiUrl}/biometrics/ble-cache`).toPromise();
      if (response) {
        const captured: string[] = [];
        if (response.weight) { this.weight = response.weight; captured.push('Peso'); }
        if (response.systolic) { this.systolic = response.systolic; captured.push('PA Sis'); }
        if (response.diastolic) { this.diastolic = response.diastolic; captured.push('PA Dia'); }
        if (response.pulse || response.heartRate) { this.heartRate = response.pulse || response.heartRate; captured.push('FC'); }
        if (response.spo2) { this.spo2 = response.spo2; captured.push('SpO2'); }
        if (response.temperature) { this.temperature = response.temperature; captured.push('Temp'); }

        if (captured.length > 0) {
          this.calculateIMC();
          this.sendVitalsToHub();
          this.captureMessage = `✓ ${captured.join(', ')}`;
          this.captureSuccess = true;
        } else {
          this.captureMessage = 'Nenhum dado novo';
          this.captureSuccess = false;
        }
      }
    } catch (error) {
      console.error('[VitalsBar] Erro captura:', error);
      this.captureMessage = 'Erro conexão maleta';
      this.captureSuccess = false;
    } finally {
      this.isCapturing = false;
      setTimeout(() => this.captureMessage = '', 5000);
    }
  }

  async analisarSinais(): Promise<void> {
    if (!this.hasAnyVitals()) return;
    this.isAnalyzing = true;

    try {
      const request: AnalyzeVitalsRequest = {
        biometrics: {
          weight: this.weight || undefined,
          height: this.height || undefined,
          oxygenSaturation: this.spo2 || undefined,
          heartRate: this.heartRate || undefined,
          bloodPressureSystolic: this.systolic || undefined,
          bloodPressureDiastolic: this.diastolic || undefined,
          temperature: this.temperature || undefined
        },
        patientName: this.patientName || undefined,
        patientAge: this.patientAge || undefined,
        patientGender: this.patientGender || undefined
      };

      const response = await this.aiService.analyzeVitals(request).toPromise();
      if (response?.analysis) {
        this.modalService.alert({ 
          title: '🩺 Análise de Sinais Vitais', 
          message: response.analysis, 
          variant: 'info' 
        }).subscribe();
      }
    } catch (error) {
      console.error('[VitalsBar] Erro análise:', error);
      this.modalService.alert({ title: 'Erro', message: 'Não foi possível analisar.', variant: 'danger' }).subscribe();
    } finally {
      this.isAnalyzing = false;
    }
  }

  private calculateIMC(): void {
    if (this.weight && this.height && this.height > 0) {
      const hm = this.height / 100;
      this.imc = this.weight / (hm * hm);
      this.imcStatus = this.imc < 18.5 || this.imc >= 30 ? 'critical' : this.imc >= 25 ? 'warning' : 'normal';
    } else {
      this.imc = null;
      this.imcStatus = 'normal';
    }
  }

  private calculateAge(birthDate: Date): number {
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) age--;
    return age;
  }

  getGenderLabel(): string {
    if (!this.patientGender) return '--';
    const g = this.patientGender.toUpperCase();
    if (g === 'M' || g === 'MALE' || g === 'MASCULINO') return 'Masculino';
    if (g === 'F' || g === 'FEMALE' || g === 'FEMININO') return 'Feminino';
    return this.patientGender;
  }

  isPressureWarning(): boolean {
    if (!this.systolic || !this.diastolic) return false;
    return (this.systolic >= 130 && this.systolic < 140) || (this.diastolic >= 85 && this.diastolic < 90);
  }

  isPressureCritical(): boolean {
    if (!this.systolic || !this.diastolic) return false;
    return this.systolic >= 140 || this.diastolic >= 90 || this.systolic < 90 || this.diastolic < 60;
  }

  hasAnyVitals(): boolean {
    return !!(this.weight || this.height || this.spo2 || this.heartRate || this.systolic || this.diastolic || this.temperature);
  }
}
