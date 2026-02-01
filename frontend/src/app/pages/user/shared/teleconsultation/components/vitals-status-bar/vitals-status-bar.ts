import { Component, Input, OnInit, OnDestroy, OnChanges, SimpleChanges, Inject, PLATFORM_ID, ViewChild, ElementRef, AfterViewChecked } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { HttpClient } from '@angular/common/http';

import { IconComponent } from '@shared/components/atoms/icon/icon';
import { MedicalDevicesSyncService, VitalSignsData, PhonocardiogramData } from '@app/core/services/medical-devices-sync.service';
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
      <!-- LINHA 1: Info Profissional (esq) + Paciente (dir) -->
      <div class="row-1">
        <div class="left-info">
          <span class="chip"><span class="label">Profissional:</span> <strong>{{ professionalName || '--' }}</strong></span>
          <span class="chip"><span class="label">Especialidade:</span> <strong>{{ specialtyName || '--' }}</strong></span>
          <span class="chip"><span class="label">Data:</span> <strong>{{ appointmentDate || '--' }}</strong></span>
          <span class="chip"><span class="label">Hora:</span> <strong>{{ appointmentTime || '--' }}</strong></span>
        </div>
        
        <div class="right-info">
          <span class="chip"><span class="label">Paciente:</span> <strong>{{ patientName || '--' }}</strong></span>
          <span class="chip"><span class="label">Sexo:</span> <strong>{{ getGenderLabel() }}</strong></span>
          <span class="chip"><span class="label">Idade:</span> <strong>{{ patientAge ? patientAge + ' anos' : '--' }}</strong></span>
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
        
        <!-- Fonocardiograma - Esteto. Digital -->
        <div class="vital phono" [class.has-value]="phonocardiogram">
          <label><app-icon name="heart" [size]="18" /> 🩺 Fono</label>
          <div class="phono-box">
            @if (phonocardiogram) {
              <div class="phono-waveform">
                <canvas #waveformCanvas width="200" height="40"></canvas>
              </div>
              <span class="phono-bpm">{{ phonocardiogram.heartRate || '--' }} bpm</span>
              <button class="btn-play" (click)="playPhonocardiogram()" [title]="'Ouvir fonocardiograma'">
                <app-icon [name]="isPlayingPhono ? 'pause' : 'play'" [size]="16" />
              </button>
              <audio #phonoAudio [src]="phonocardiogramAudioUrl" (ended)="isPlayingPhono = false" style="display:none;"></audio>
            } @else {
              <span class="phono-bpm waiting">Aguardando...</span>
            }
          </div>
        </div>
        
        <!-- Ações à direita -->
        <div class="actions">
          <span *ngIf="lastSync" class="sync-info">
            <app-icon name="check-circle" [size]="16" />
            {{ lastSync | date:'HH:mm:ss' }}
          </span>
          
          <span *ngIf="captureMessage" class="msg" [class.ok]="captureSuccess" [class.err]="!captureSuccess">
            {{ captureMessage }}
          </span>
          
          <!-- OPERADOR: botão "Acontecendo" para marcar consulta ativa -->
          <button *ngIf="!isProfessional" class="btn-acontecendo" 
                  [class.active]="isAcontecendo" 
                  (click)="toggleAcontecendo()"
                  [title]="isAcontecendo ? 'Clique para desmarcar' : 'Clique para ativar captura de sinais'">
            <span class="status-dot" [class.active]="isAcontecendo"></span>
            <span>{{ isAcontecendo ? '🟢 Acontecendo' : '⚪ Iniciar Captura' }}</span>
          </button>
          
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
            <span>🧠 Analisar</span>
          </button>
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
    
    /* ============ LINHA 1: INFO PROFISSIONAL (ESQ) + PACIENTE (DIR) ============ */
    .row-1 {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      padding: 10px 24px;
      background: linear-gradient(90deg, rgba(59,130,246,0.15) 0%, rgba(59,130,246,0.05) 40%, transparent 70%);
      border-bottom: 1px solid rgba(255,255,255,0.1);
      min-height: 50px;
    }
    
    .left-info, .right-info {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }
    
    .chip {
      font-size: 14px;
      color: #94a3b8;
      padding: 6px 12px;
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 8px;
      
      .label { color: #60a5fa; font-weight: 500; margin-right: 4px; }
      strong { color: #f1f5f9; font-weight: 700; font-size: 15px; }
      b { color: #60a5fa; font-weight: 600; margin-right: 4px; }
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
    
    /* Botão Acontecendo */
    .btn-acontecendo {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 16px;
      border: 2px solid #475569;
      border-radius: 20px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
      background: #334155;
      color: #94a3b8;
      
      &:hover { 
        border-color: #22c55e;
        color: #22c55e;
      }
      
      &.active {
        background: linear-gradient(135deg, #22c55e, #16a34a);
        border-color: #22c55e;
        color: white;
        box-shadow: 0 0 20px rgba(34, 197, 94, 0.5);
        animation: pulse-green 2s infinite;
      }
      
      .status-dot {
        width: 10px;
        height: 10px;
        border-radius: 50%;
        background: #475569;
        transition: all 0.3s;
        
        &.active {
          background: white;
          box-shadow: 0 0 8px white;
        }
      }
    }
    
    @keyframes pulse-green {
      0%, 100% { box-shadow: 0 0 20px rgba(34, 197, 94, 0.5); }
      50% { box-shadow: 0 0 30px rgba(34, 197, 94, 0.8); }
    }

    /* Fonocardiograma - Estetoscópio Digital */
    .vital.phono {
      background: linear-gradient(135deg, #fef3c7, #fde68a);
      border: 1px solid #f59e0b;
      border-radius: 8px;
      padding: 6px 10px;
      min-width: auto;
      
      label {
        color: #92400e;
        font-weight: 600;
      }
      
      .phono-box {
        display: flex;
        align-items: center;
        gap: 8px;
        
        .phono-waveform {
          width: 200px;
          height: 40px;
          border-radius: 4px;
          overflow: hidden;
          background: #1a1a2e;
          
          canvas {
            display: block;
          }
        }
        
        .phono-bpm {
          font-size: 16px;
          font-weight: 700;
          color: #dc2626;
        }

        .phono-bpm.waiting {
          font-size: 11px;
          font-weight: 400;
          color: #92400e;
          opacity: 0.7;
        }
        
        .btn-play {
          width: 28px;
          height: 28px;
          display: flex;
          align-items: center;
          justify-content: center;
          border: none;
          border-radius: 50%;
          background: #dc2626;
          color: white;
          cursor: pointer;
          transition: all 0.2s;
          
          &:hover {
            transform: scale(1.1);
            background: #b91c1c;
          }
        }
      }
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
      align-items: flex-end;
      gap: 12px;
      padding: 8px 16px;
      background: #0f172a;
      flex-wrap: wrap;
      min-height: 60px;
    }
    
    .sep {
      width: 1px;
      height: 40px;
      background: linear-gradient(180deg, transparent, rgba(255,255,255,0.2), transparent);
    }
    
    .vital {
      display: flex;
      flex-direction: column;
      gap: 4px;
      min-width: 85px;
      padding: 6px 10px;
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 10px;
      transition: all 0.2s;
      
      &:hover { background: rgba(255,255,255,0.08); }
      
      label {
        display: flex;
        align-items: center;
        gap: 5px;
        font-size: 11px;
        font-weight: 700;
        color: #64748b;
        text-transform: uppercase;
        letter-spacing: 0.3px;
        
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
      gap: 4px;
      
      input {
        width: 65px;
        padding: 6px 8px;
        border: 1px solid rgba(255,255,255,0.2);
        border-radius: 8px;
        font-size: 16px;
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
        font-size: 17px;
        font-weight: 700;
        color: #f1f5f9;
        min-width: 50px;
        text-align: center;
        
        &.calc {
          padding: 5px 10px;
          background: rgba(255,255,255,0.1);
          border-radius: 8px;
        }
      }
      
      small {
        font-size: 12px;
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
export class VitalsStatusBarComponent implements OnInit, OnDestroy, OnChanges, AfterViewChecked {
  @Input() appointmentId: string | null = null;
  @Input() appointment: Appointment | null = null;
  @Input() userRole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' = 'PATIENT';

  @ViewChild('waveformCanvas') waveformCanvasRef!: ElementRef<HTMLCanvasElement>;

  // Dados do paciente
  patientName = '';
  patientGender = '';
  patientAge: number | null = null;

  // Dados do profissional/consulta
  professionalName = '';
  specialtyName = '';
  appointmentDate = '';
  appointmentTime = '';

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
  isAcontecendo = false;  // Botão "Acontecendo" para maleta itinerante

  // Fonocardiograma - Estetoscópio Digital
  phonocardiogram: PhonocardiogramData | null = null;
  phonocardiogramAudioUrl = '';
  isPlayingPhono = false;
  private needsWaveformRedraw = false;

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
    this.checkAcontecendoStatus();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['appointment'] && this.appointment) {
      this.loadPatientInfo();
      this.checkAcontecendoStatus();
    }
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
    if (this.syncTimeout) clearTimeout(this.syncTimeout);
    // Desmarcar "acontecendo" ao sair da teleconsulta
    if (this.isAcontecendo) {
      this.http.delete(`${environment.apiUrl}/biometrics/acontecendo`).subscribe();
    }
  }

  ngAfterViewChecked(): void {
    if (this.needsWaveformRedraw && this.waveformCanvasRef) {
      this.drawWaveform();
      this.needsWaveformRedraw = false;
    }
  }

  private drawWaveform(): void {
    if (!this.phonocardiogram?.waveform || !this.waveformCanvasRef) return;
    
    const canvas = this.waveformCanvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const waveform = this.phonocardiogram.waveform;
    const width = canvas.width;
    const height = canvas.height;
    
    // Limpar canvas
    ctx.fillStyle = '#1a1a2e';
    ctx.fillRect(0, 0, width, height);
    
    // Linha de base
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, height / 2);
    ctx.lineTo(width, height / 2);
    ctx.stroke();
    
    // Desenhar waveform
    ctx.strokeStyle = '#00ff88';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    
    const stepX = width / (waveform.length - 1);
    const midY = height / 2;
    const amplitudeScale = height / 2 * 0.9;  // 90% da altura
    
    for (let i = 0; i < waveform.length; i++) {
      const x = i * stepX;
      const y = midY - (waveform[i] * amplitudeScale);
      
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    
    ctx.stroke();
    console.log('[VitalsBar] Waveform desenhado:', waveform.length, 'pontos');
  }

  /** Verifica se esta consulta está marcada como "acontecendo" */
  private async checkAcontecendoStatus(): Promise<void> {
    if (!this.appointmentId) return;
    try {
      const response = await this.http.get<any>(`${environment.apiUrl}/biometrics/acontecendo`).toPromise();
      this.isAcontecendo = response?.appointmentId === this.appointmentId;
    } catch {
      this.isAcontecendo = false;
    }
  }

  private setupSubscriptions(): void {
    this.subscriptions.add(
      this.medicalDevicesSync.vitalSignsReceived$.subscribe((data: VitalSignsData) => {
        if (data.appointmentId === this.appointmentId) {
          this.updateFromRemote(data);
        }
      })
    );

    // Subscription para fonocardiograma (Estetoscópio Digital)
    this.subscriptions.add(
      this.medicalDevicesSync.phonocardiogramReceived$.subscribe((data: PhonocardiogramData) => {
        console.log('[VitalsBar] 🩺 Fonocardiograma chegou! data.appointmentId:', data.appointmentId, 'this.appointmentId:', this.appointmentId);
        // Aceita o fonocardiograma se for da consulta atual OU se não tiver appointmentId definido
        if (data.appointmentId === this.appointmentId || !this.appointmentId) {
          console.log('[VitalsBar] 🩺 Fonocardiograma aceito:', data);
          this.phonocardiogram = data;
          if (data.audioUrl) {
            this.phonocardiogramAudioUrl = environment.apiUrl.replace('/api', '') + data.audioUrl;
          }
          // Atualiza FC se detectada
          if (data.heartRate) {
            this.heartRate = data.heartRate;
          }
          // Marcar para redesenhar waveform
          if (data.waveform && data.waveform.length > 0) {
            this.needsWaveformRedraw = true;
          }
          this.lastSync = new Date();
        }
      })
    );
  }

  private loadPatientInfo(): void {
    if (!this.appointment) return;
    
    // Info do paciente
    this.patientName = this.appointment.patientName || '';
    
    // Info do profissional/consulta
    this.professionalName = this.appointment.professionalName || '';
    this.specialtyName = this.appointment.specialtyName || '';
    
    // Formatar data e hora
    if (this.appointment.date) {
      const date = new Date(this.appointment.date);
      this.appointmentDate = date.toLocaleDateString('pt-BR');
    }
    this.appointmentTime = this.appointment.time || '';

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

  /**
   * Marca/desmarca a consulta como "Acontecendo" para a maleta itinerante
   * Quando marcada, a maleta vai enviar os sinais vitais para ESTA consulta
   */
  async toggleAcontecendo(): Promise<void> {
    if (!this.appointmentId) return;
    
    try {
      if (this.isAcontecendo) {
        // Desmarcar
        await this.http.delete(`${environment.apiUrl}/biometrics/acontecendo`).toPromise();
        this.isAcontecendo = false;
        console.log('[VitalsBar] ⚪ Consulta desmarcada como acontecendo');
      } else {
        // Marcar
        await this.http.post(`${environment.apiUrl}/biometrics/acontecendo/${this.appointmentId}`, {}).toPromise();
        this.isAcontecendo = true;
        console.log('[VitalsBar] 🟢 Consulta marcada como acontecendo:', this.appointmentId);
      }
    } catch (error) {
      console.error('[VitalsBar] Erro ao alterar status acontecendo:', error);
    }
  }

  async capturarSinais(): Promise<void> {
    console.log('[VitalsBar] 🔍 capturarSinais chamado, appointmentId:', this.appointmentId);
    if (!this.appointmentId) return;
    this.isCapturing = true;
    this.captureMessage = '';

    try {
      const url = `${environment.apiUrl}/biometrics/ble-cache`;
      console.log('[VitalsBar] Buscando cache de:', url);
      const response = await this.http.get<any>(url).toPromise();
      console.log('[VitalsBar] Resposta do cache:', JSON.stringify(response, null, 2));
      
      if (response) {
        const captured: string[] = [];
        const devices = response.devices || {};
        console.log('[VitalsBar] Devices encontrados:', Object.keys(devices));
        
        // Extrai dados da balança (scale)
        const scale = devices.scale?.values || {};
        console.log('[VitalsBar] Scale values:', scale);
        if (scale.weight) { 
          this.weight = Number(scale.weight); 
          captured.push('Peso'); 
          console.log('[VitalsBar] ✅ Peso capturado:', this.weight);
        }
        
        // Extrai dados do aparelho de pressão (blood_pressure)
        const bp = devices.blood_pressure?.values || {};
        if (bp.systolic) { 
          this.systolic = Number(bp.systolic); 
          captured.push('PA Sis'); 
        }
        if (bp.diastolic) { 
          this.diastolic = Number(bp.diastolic); 
          captured.push('PA Dia'); 
        }
        if (bp.heartRate || bp.pulse) { 
          this.heartRate = Number(bp.heartRate || bp.pulse); 
          captured.push('FC'); 
        }
        
        // Extrai dados do oxímetro
        const oximeter = devices.oximeter?.values || {};
        if (oximeter.spo2) { 
          this.spo2 = Number(oximeter.spo2); 
          captured.push('SpO2'); 
        }
        if (oximeter.pulseRate && !this.heartRate) { 
          this.heartRate = Number(oximeter.pulseRate); 
          captured.push('FC'); 
        }
        
        // Extrai dados do termômetro
        const thermo = devices.thermometer?.values || {};
        if (thermo.temperature) { 
          this.temperature = Number(thermo.temperature); 
          captured.push('Temp'); 
        }

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

  // Fonocardiograma - reproduzir áudio
  private phonoAudioPlayer: HTMLAudioElement | null = null;
  
  playPhonocardiogram(): void {
    if (!isPlatformBrowser(this.platformId)) return;
    
    console.log('[VitalsBar] playPhonocardiogram() chamado, URL:', this.phonocardiogramAudioUrl);
    
    if (!this.phonocardiogramAudioUrl) {
      console.error('[VitalsBar] Nenhuma URL de áudio disponível');
      return;
    }
    
    // Se já está tocando, pausa
    if (this.isPlayingPhono && this.phonoAudioPlayer) {
      this.phonoAudioPlayer.pause();
      this.isPlayingPhono = false;
      return;
    }
    
    // Cria novo player se não existir
    if (!this.phonoAudioPlayer) {
      this.phonoAudioPlayer = new Audio();
      this.phonoAudioPlayer.onended = () => {
        this.isPlayingPhono = false;
        console.log('[VitalsBar] Áudio terminou');
      };
      this.phonoAudioPlayer.onerror = (e) => {
        console.error('[VitalsBar] Erro no áudio:', e);
        this.isPlayingPhono = false;
      };
    }
    
    // Atualiza URL e toca
    this.phonoAudioPlayer.src = this.phonocardiogramAudioUrl;
    
    // Força interação do usuário para permitir play
    this.phonoAudioPlayer.muted = false;
    this.phonoAudioPlayer.volume = 1.0;
    
    this.phonoAudioPlayer.play().then(() => {
      this.isPlayingPhono = true;
      console.log('[VitalsBar] ▶️ Tocando fonocardiograma');
    }).catch(err => {
      console.error('[VitalsBar] Erro ao reproduzir:', err);
      // Pergunta se quer abrir em nova aba
      if (confirm('O áudio não pôde ser reproduzido diretamente.\n\nDeseja abrir em uma nova aba?')) {
        window.open(this.phonocardiogramAudioUrl, '_blank');
      }
    });
  }
}
