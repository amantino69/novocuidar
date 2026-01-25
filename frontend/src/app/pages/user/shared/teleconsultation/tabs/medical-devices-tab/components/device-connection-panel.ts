import { Component, Input, OnInit, OnDestroy, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Subscription, firstValueFrom, Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

import { IconComponent } from '@shared/components/atoms/icon/icon';
import { 
  BluetoothDevicesService, 
  BluetoothDevice, 
  DeviceType,
  VitalReading 
} from '@app/core/services/bluetooth-devices.service';
import { MedicalDevicesSyncService } from '@app/core/services/medical-devices-sync.service';
import { AuthService } from '@app/core/services/auth.service';
import { Appointment } from '@core/services/appointments.service';
import { environment } from '@env/environment';

@Component({
  selector: 'app-device-connection-panel',
  standalone: true,
  imports: [CommonModule, IconComponent, ReactiveFormsModule],
  providers: [],
  template: `
    <div class="device-connection-panel">
      <div class="panel-header">
        <h4>
          <app-icon name="activity" [size]="20" />
          Sinais Vitais
        </h4>
        <span class="connection-status" [class.connected]="isHubConnected">
          {{ isHubConnected ? 'Sincronizado' : 'Offline' }}
        </span>
      </div>

      <p class="description">
        Digite os valores manualmente ou conecte os dispositivos Bluetooth para captura automática.
      </p>

      <!-- Dados do Paciente (somente leitura, carregados do perfil) -->
      @if (patientGender || patientBirthDate) {
        <div class="patient-info-card">
          <div class="patient-info-header">
            <app-icon name="user" [size]="18" />
            <span>Dados do Paciente</span>
          </div>
          <div class="patient-info-content">
            @if (patientGender) {
              <div class="patient-info-item">
                <label>Sexo</label>
                <span>{{ getGenderLabel(patientGender) }}</span>
              </div>
            }
            @if (patientBirthDate) {
              <div class="patient-info-item">
                <label>Idade</label>
                <span>{{ getPatientAge() }} anos</span>
              </div>
            }
          </div>
        </div>
      }

      @if (!bluetoothAvailable) {
        <div class="warning-banner">
          <app-icon name="alert-triangle" [size]="18" />
          <span>Web Bluetooth não disponível. Use Chrome/Edge em HTTPS.</span>
        </div>
      }

      <form [formGroup]="vitalsForm" class="vitals-form">
        
        <!-- SpO2 e Frequência Cardíaca (Oxímetro) -->
        <div class="vital-card">
          <div class="vital-icon spo2">
            <app-icon name="heart" [size]="24" />
          </div>
          <div class="vital-fields">
            <div class="field-row">
              <div class="field-group">
                <label>SpO₂</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="spo2" placeholder="--" min="0" max="100">
                  <span class="unit">%</span>
                </div>
              </div>
              <div class="field-group">
                <label>Freq. Cardíaca</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="heartRate" placeholder="--" min="0" max="300">
                  <span class="unit">bpm</span>
                </div>
              </div>
            </div>
          </div>
          <button type="button" class="btn-connect" 
                  [class.connected]="isDeviceConnected('oximeter')"
                  [disabled]="!bluetoothAvailable || isConnecting"
                  [title]="!bluetoothAvailable ? 'Bluetooth não disponível' : 'Conectar oxímetro'"
                  (click)="connectDevice('oximeter')">
            @if (connectingType === 'oximeter') {
              <app-icon name="loader" [size]="16" class="spin" />
            } @else {
              <app-icon [name]="isDeviceConnected('oximeter') ? 'check' : 'bluetooth'" [size]="16" />
            }
            {{ isDeviceConnected('oximeter') ? 'Conectado' : 'Conectar' }}
          </button>
        </div>

        <!-- Pressão Arterial -->
        <div class="vital-card">
          <div class="vital-icon pressure">
            <app-icon name="activity" [size]="24" />
          </div>
          <div class="vital-fields">
            <div class="field-row">
              <div class="field-group">
                <label>Sistólica</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="systolic" placeholder="--" min="0" max="300">
                  <span class="unit">mmHg</span>
                </div>
              </div>
              <div class="field-group">
                <label>Diastólica</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="diastolic" placeholder="--" min="0" max="200">
                  <span class="unit">mmHg</span>
                </div>
              </div>
            </div>
          </div>
          <button type="button" class="btn-connect" 
                  [class.connected]="isDeviceConnected('blood_pressure')"
                  [disabled]="!bluetoothAvailable || isConnecting"
                  [title]="!bluetoothAvailable ? 'Bluetooth não disponível' : 'Conectar medidor de pressão'"
                  (click)="connectDevice('blood_pressure')">
            @if (connectingType === 'blood_pressure') {
              <app-icon name="loader" [size]="16" class="spin" />
            } @else {
              <app-icon [name]="isDeviceConnected('blood_pressure') ? 'check' : 'bluetooth'" [size]="16" />
            }
            {{ isDeviceConnected('blood_pressure') ? 'Conectado' : 'Conectar' }}
          </button>
        </div>

        <!-- Temperatura -->
        <div class="vital-card">
          <div class="vital-icon temp">
            <app-icon name="thermometer" [size]="24" />
          </div>
          <div class="vital-fields">
            <div class="field-row">
              <div class="field-group full">
                <label>Temperatura</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="temperature" placeholder="--" min="30" max="45" step="0.1">
                  <span class="unit">°C</span>
                </div>
              </div>
            </div>
          </div>
          <button type="button" class="btn-connect" 
                  [class.connected]="isDeviceConnected('thermometer')"
                  [disabled]="!bluetoothAvailable || isConnecting"
                  [title]="!bluetoothAvailable ? 'Bluetooth não disponível' : 'Conectar termômetro'"
                  (click)="connectDevice('thermometer')">
            @if (connectingType === 'thermometer') {
              <app-icon name="loader" [size]="16" class="spin" />
            } @else {
              <app-icon [name]="isDeviceConnected('thermometer') ? 'check' : 'bluetooth'" [size]="16" />
            }
            {{ isDeviceConnected('thermometer') ? 'Conectado' : 'Conectar' }}
          </button>
        </div>

        <!-- Peso e Altura -->
        <div class="vital-card">
          <div class="vital-icon weight">
            <app-icon name="scale" [size]="24" />
          </div>
          <div class="vital-fields">
            <div class="field-row">
              <div class="field-group">
                <label>Peso</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="weight" placeholder="--" min="0" max="500" step="0.1">
                  <span class="unit">kg</span>
                </div>
              </div>
              <div class="field-group">
                <label>Altura</label>
                <div class="input-wrapper">
                  <input type="number" formControlName="height" placeholder="--" min="0" max="300">
                  <span class="unit">cm</span>
                </div>
              </div>
            </div>
          </div>
          <button type="button" class="btn-connect" 
                  [class.connected]="isDeviceConnected('scale')"
                  [disabled]="!bluetoothAvailable || isConnecting"
                  [title]="!bluetoothAvailable ? 'Bluetooth não disponível' : 'Conectar balança'"
                  (click)="connectDevice('scale')">
            @if (connectingType === 'scale') {
              <app-icon name="loader" [size]="16" class="spin" />
            } @else {
              <app-icon [name]="isDeviceConnected('scale') ? 'check' : 'bluetooth'" [size]="16" />
            }
            {{ isDeviceConnected('scale') ? 'Conectado' : 'Conectar' }}
          </button>
        </div>

        <!-- Status de Sincronização -->
        <div class="sync-section">
          @if (isSending) {
            <span class="sync-status sending">
              <app-icon name="loader" [size]="14" class="spin" />
              Enviando...
            </span>
          } @else if (lastSent) {
            <span class="sync-status sent">
              <app-icon name="check-circle" [size]="14" />
              Sincronizado às {{ lastSent | date:'HH:mm:ss' }}
            </span>
          } @else if (hasAnyValue()) {
            <span class="sync-status waiting">
              <app-icon name="radio" [size]="14" />
              Pronto para sincronizar
            </span>
          }
        </div>

      </form>
    </div>
  `,
  styles: [`
    .device-connection-panel {
      padding: 16px;
      height: 100%;
      overflow-y: auto;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;

      h4 {
        display: flex;
        align-items: center;
        gap: 8px;
        margin: 0;
        font-size: 18px;
        font-weight: 600;
        color: var(--text-primary);
      }

      .connection-status {
        font-size: 12px;
        padding: 4px 10px;
        border-radius: 12px;
        background: var(--bg-danger);
        color: var(--text-danger);

        &.connected {
          background: var(--bg-success);
          color: var(--text-success);
        }
      }
    }

    .description {
      font-size: 13px;
      color: var(--text-secondary);
      margin: 0 0 16px 0;
    }

    .patient-info-card {
      background: linear-gradient(135deg, #e0f2fe 0%, #f0f9ff 100%);
      border: 1px solid #bae6fd;
      border-radius: 12px;
      padding: 12px 16px;
      margin-bottom: 16px;

      .patient-info-header {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 14px;
        font-weight: 600;
        color: #0369a1;
        margin-bottom: 10px;
      }

      .patient-info-content {
        display: flex;
        gap: 24px;
        flex-wrap: wrap;
      }

      .patient-info-item {
        display: flex;
        flex-direction: column;
        gap: 2px;

        label {
          font-size: 11px;
          color: #0284c7;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        span {
          font-size: 15px;
          font-weight: 600;
          color: #0c4a6e;
        }
      }
    }

    .warning-banner {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px;
      background: var(--bg-warning);
      color: var(--text-warning);
      border-radius: 8px;
      margin-bottom: 16px;
      font-size: 13px;
    }

    .vitals-form {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .vital-card {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: var(--bg-secondary);
      border-radius: 12px;
      border: 1px solid var(--border-color);
    }

    .vital-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 48px;
      height: 48px;
      min-width: 48px;
      border-radius: 12px;
      background: var(--bg-tertiary);

      &.spo2 { color: #ef4444; }
      &.pressure { color: #8b5cf6; }
      &.temp { color: #f97316; }
      &.weight { color: #3b82f6; }
    }

    .vital-fields {
      flex: 1;
    }

    .field-row {
      display: flex;
      gap: 12px;
    }

    .field-group {
      flex: 1;
      
      &.full {
        max-width: 180px;
      }

      label {
        display: block;
        font-size: 12px;
        font-weight: 500;
        color: var(--text-secondary);
        margin-bottom: 4px;
      }
    }

    .input-wrapper {
      display: flex;
      align-items: center;
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      overflow: hidden;

      input {
        flex: 1;
        width: 100%;
        min-width: 60px;
        padding: 8px 12px;
        border: none;
        background: transparent;
        font-size: 16px;
        font-weight: 600;
        color: var(--text-primary);
        outline: none;

        &::placeholder {
          color: var(--text-tertiary);
          font-weight: 400;
        }

        &::-webkit-inner-spin-button,
        &::-webkit-outer-spin-button {
          -webkit-appearance: none;
          margin: 0;
        }
      }

      .unit {
        padding: 8px 12px;
        font-size: 13px;
        color: var(--text-secondary);
        background: var(--bg-tertiary);
        border-left: 1px solid var(--border-color);
      }
    }

    .btn-connect {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 10px 16px;
      border: 1px solid #3b82f6;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
      background: #3b82f6;
      color: white;
      white-space: nowrap;
      min-width: 110px;

      &:hover:not(:disabled) {
        background: #2563eb;
        border-color: #2563eb;
      }

      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;
        background: var(--bg-tertiary);
        border-color: var(--border-color);
        color: var(--text-secondary);
      }

      &.connected {
        background: #10b981;
        border-color: #10b981;
      }
    }

    .save-section {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-top: 8px;
      padding-top: 16px;
      border-top: 1px solid var(--border-color);
    }

    .btn-save {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 12px 24px;
      border: none;
      border-radius: 8px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      background: #10b981;
      color: white;

      &:hover:not(:disabled) {
        background: #059669;
        transform: translateY(-1px);
      }

      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;
        transform: none;
      }
    }

    .sync-section {
      padding: 8px 0;
    }

    .sync-status {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 13px;
      padding: 8px 12px;
      border-radius: 8px;

      &.sending {
        color: #3b82f6;
        background: rgba(59, 130, 246, 0.1);
      }

      &.sent {
        color: #10b981;
        background: rgba(16, 185, 129, 0.1);
      }

      &.waiting {
        color: var(--text-secondary);
        background: var(--bg-tertiary);
      }
    }

    .spin {
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }
  `]
})
export class DeviceConnectionPanelComponent implements OnInit, OnDestroy, OnChanges {
  @Input() appointmentId: string | null = null;
  @Input() appointment: Appointment | null = null;
  @Input() userrole: string = '';

  vitalsForm: FormGroup;
  
  bluetoothAvailable = false;
  isHubConnected = false;
  isConnecting = false;
  isSending = false;
  connectingType: DeviceType | null = null;
  connectedDevices: BluetoothDevice[] = [];
  lastSent: Date | null = null;

  // Dados do paciente (carregados do perfil)
  patientGender: string | null = null;
  patientBirthDate: string | null = null;
  private patientProfileLoaded = false;

  private subscriptions = new Subscription();
  private formChanged$ = new Subject<void>();
  private saveTimeout: any = null;
  
  // Cache key para persistir valores entre mudanças de aba
  private get cacheKey(): string {
    return `vitals_cache_${this.appointmentId}`;
  }

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private bluetoothService: BluetoothDevicesService,
    private syncService: MedicalDevicesSyncService,
    private authService: AuthService
  ) {
    this.vitalsForm = this.fb.group({
      spo2: [null],
      heartRate: [null],
      systolic: [null],
      diastolic: [null],
      temperature: [null],
      weight: [null],
      height: [null]
    });
  }

  ngOnInit(): void {
    this.bluetoothAvailable = this.bluetoothService.isBluetoothAvailable();

    // Carrega do cache local primeiro (instantâneo)
    this.loadFromCache();
    
    // Tenta carregar dados do perfil do paciente se appointment já estiver disponível
    if (this.appointment?.patientId && !this.patientProfileLoaded) {
      this.loadPatientProfile();
    }
    
    // Depois carrega dados existentes do banco (pode sobrescrever se mais recente)
    this.loadExistingData();

    // Conecta ao hub
    if (this.appointmentId) {
      this.syncService.connect(this.appointmentId);
    }

    // Observa estado da conexão
    this.subscriptions.add(
      this.syncService.isConnected$.subscribe(connected => {
        this.isHubConnected = connected;
      })
    );

    // Observa dispositivos conectados
    this.subscriptions.add(
      this.bluetoothService.devices$.subscribe(devices => {
        this.connectedDevices = devices.filter(d => d.connected);
      })
    );

    // Observa leituras do Bluetooth e preenche o formulário
    this.subscriptions.add(
      this.bluetoothService.readings$.subscribe(reading => {
        this.processReading(reading);
      })
    );

    // *** ENVIO INSTANTÂNEO: Observa mudanças no formulário ***
    this.subscriptions.add(
      this.vitalsForm.valueChanges.subscribe(() => {
        this.saveToCache(); // Cache local instantâneo
        this.formChanged$.next(); // Trigger debounce
      })
    );

    // Debounce de 300ms para enviar via SignalR (instantâneo para o médico)
    this.subscriptions.add(
      this.formChanged$.pipe(
        debounceTime(300)
      ).subscribe(() => {
        this.sendVitalsRealtime();
      })
    );
  }

  ngOnChanges(changes: SimpleChanges): void {
    // Quando o appointment chegar/mudar, carregar dados do paciente
    if (changes['appointment'] && this.appointment?.patientId && !this.patientProfileLoaded) {
      console.log('[DeviceConnectionPanel] Appointment mudou, carregando perfil do paciente');
      this.loadPatientProfile();
    }
  }

  private async loadExistingData(): Promise<void> {
    if (!this.appointmentId) return;

    try {
      const apiUrl = `${environment.apiUrl}/appointments/${this.appointmentId}/biometrics`;
      const data = await firstValueFrom(this.http.get<any>(apiUrl));
      
      if (data) {
        this.vitalsForm.patchValue({
          spo2: data.oxygenSaturation,
          heartRate: data.heartRate,
          systolic: data.bloodPressureSystolic,
          diastolic: data.bloodPressureDiastolic,
          temperature: data.temperature,
          weight: data.weight,
          height: data.height
        }, { emitEvent: false }); // Não dispara envio automático ao carregar
        
        if (data.lastUpdated) {
          this.lastSent = new Date(data.lastUpdated);
        }
      }
    } catch (error) {
      console.warn('[DeviceConnectionPanel] Erro ao carregar dados existentes:', error);
    }
  }

  /**
   * Carrega dados do perfil do paciente da consulta via API
   */
  private async loadPatientProfile(): Promise<void> {
    try {
      // Primeiro tenta obter do appointment (se disponível)
      const patientId = this.appointment?.patientId;
      
      if (!patientId) {
        console.log('[DeviceConnectionPanel] Nenhum patientId disponível no appointment');
        return;
      }
      
      console.log('[DeviceConnectionPanel] Buscando dados do paciente:', patientId);
      
      // Busca dados do paciente via API
      const apiUrl = `${environment.apiUrl}/users/${patientId}`;
      const user = await firstValueFrom(this.http.get<any>(apiUrl));
      
      if (user?.patientProfile) {
        this.patientGender = user.patientProfile.gender || null;
        this.patientBirthDate = user.patientProfile.birthDate || null;
        this.patientProfileLoaded = true;
        console.log('[DeviceConnectionPanel] Perfil do paciente carregado:', {
          name: user.name,
          gender: this.patientGender,
          birthDate: this.patientBirthDate
        });
      } else {
        console.log('[DeviceConnectionPanel] Usuário não tem patientProfile');
      }
    } catch (error) {
      console.warn('[DeviceConnectionPanel] Erro ao carregar perfil do paciente:', error);
    }
  }

  /**
   * Retorna o label do sexo
   */
  getGenderLabel(gender: string | null): string {
    if (!gender) return 'Não informado';
    switch (gender) {
      case 'M': return 'Masculino';
      case 'F': return 'Feminino';
      case 'O': return 'Outro';
      default: return gender;
    }
  }

  /**
   * Calcula a idade do paciente
   */
  getPatientAge(): number | null {
    if (!this.patientBirthDate) return null;
    const today = new Date();
    const birth = new Date(this.patientBirthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age > 0 ? age : null;
  }

  isDeviceConnected(type: DeviceType): boolean {
    return this.connectedDevices.some(d => d.type === type);
  }

  async connectDevice(type: DeviceType): Promise<void> {
    if (!this.bluetoothAvailable) {
      alert('Web Bluetooth não está disponível. Use Chrome ou Edge em HTTPS.');
      return;
    }

    this.isConnecting = true;
    this.connectingType = type;

    try {
      switch (type) {
        case 'oximeter':
          await this.bluetoothService.connectOximeter();
          break;
        case 'thermometer':
          await this.bluetoothService.connectThermometer();
          break;
        case 'scale':
          await this.bluetoothService.connectScale();
          break;
        case 'blood_pressure':
          await this.bluetoothService.connectBloodPressure();
          break;
      }
    } catch (error) {
      console.error('Erro ao conectar dispositivo:', error);
      alert('Erro ao conectar dispositivo. Verifique se está ligado e próximo.');
    } finally {
      this.isConnecting = false;
      this.connectingType = null;
    }
  }

  private processReading(reading: VitalReading): void {
    const values = reading.values;
    console.log(`[DeviceConnectionPanel] Leitura Bluetooth (${reading.deviceType}):`, values);
    
    // Preenche os campos do formulário com os dados do Bluetooth
    // Os dados do Bluetooth sobrescrevem os digitados manualmente
    
    if (values.spo2 !== undefined) {
      this.vitalsForm.patchValue({ spo2: values.spo2 });
    }
    
    // Heart Rate pode vir do oxímetro (pulseRate) ou do medidor de pressão (heartRate)
    if (values.pulseRate !== undefined || values.heartRate !== undefined) {
      this.vitalsForm.patchValue({ heartRate: values.pulseRate ?? values.heartRate });
    }
    
    if (values.temperature !== undefined) {
      this.vitalsForm.patchValue({ temperature: values.temperature });
    }
    
    if (values.weight !== undefined) {
      this.vitalsForm.patchValue({ weight: values.weight });
    }
    
    // Pressão arterial (OMRON e outros)
    if (values.systolic !== undefined) {
      this.vitalsForm.patchValue({ systolic: values.systolic });
    }
    if (values.diastolic !== undefined) {
      this.vitalsForm.patchValue({ diastolic: values.diastolic });
    }
  }

  hasAnyValue(): boolean {
    const values = this.vitalsForm.value;
    return Object.values(values).some(v => v !== null && v !== '' && v !== undefined);
  }

  /**
   * Salva valores no cache local (sessionStorage)
   */
  private saveToCache(): void {
    if (!this.appointmentId) return;
    try {
      const values = this.vitalsForm.value;
      sessionStorage.setItem(this.cacheKey, JSON.stringify({
        values,
        timestamp: new Date().toISOString()
      }));
    } catch (e) {
      // Ignora erros de storage
    }
  }

  /**
   * Carrega valores do cache local
   */
  private loadFromCache(): void {
    if (!this.appointmentId) return;
    try {
      const cached = sessionStorage.getItem(this.cacheKey);
      if (cached) {
        const { values, timestamp } = JSON.parse(cached);
        // Só usa cache se for da última hora
        const cacheTime = new Date(timestamp).getTime();
        const now = Date.now();
        if (now - cacheTime < 60 * 60 * 1000) { // 1 hora
          this.vitalsForm.patchValue(values, { emitEvent: false });
          console.log('[DeviceConnectionPanel] Dados carregados do cache');
        }
      }
    } catch (e) {
      // Ignora erros de storage
    }
  }

  /**
   * Envia sinais vitais em tempo real via SignalR (instantâneo para o médico)
   * E agenda salvamento em background no banco de dados
   */
  private async sendVitalsRealtime(): Promise<void> {
    if (!this.hasAnyValue() || !this.appointmentId) return;

    const formValues = this.vitalsForm.value;
    const biometrics = {
      oxygenSaturation: formValues.spo2 ? Number(formValues.spo2) : null,
      heartRate: formValues.heartRate ? Number(formValues.heartRate) : null,
      bloodPressureSystolic: formValues.systolic ? Number(formValues.systolic) : null,
      bloodPressureDiastolic: formValues.diastolic ? Number(formValues.diastolic) : null,
      temperature: formValues.temperature ? Number(formValues.temperature) : null,
      weight: formValues.weight ? Number(formValues.weight) : null,
      height: formValues.height ? Number(formValues.height) : null,
      // Dados do paciente (somente leitura, do perfil)
      gender: this.patientGender,
      birthDate: this.patientBirthDate
    };

    // 1. Envia IMEDIATAMENTE via SignalR (instantâneo para o médico)
    this.isSending = true;
    try {
      await this.syncService.sendVitalSigns(biometrics);
      this.lastSent = new Date();
      console.log('[DeviceConnectionPanel] ✓ Sinais vitais enviados via SignalR');
    } catch (error) {
      console.warn('[DeviceConnectionPanel] Erro no SignalR:', error);
    } finally {
      this.isSending = false;
    }

    // 2. Agenda salvamento em BACKGROUND no banco (não bloqueia UI)
    // Usa debounce de 2 segundos para evitar muitas requisições
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    this.saveTimeout = setTimeout(() => {
      this.saveToDatabase(biometrics);
    }, 2000);
  }

  /**
   * Salva no banco de dados em background (não bloqueia UI)
   */
  private async saveToDatabase(biometrics: any): Promise<void> {
    if (!this.appointmentId) return;
    
    try {
      const apiUrl = `${environment.apiUrl}/appointments/${this.appointmentId}/biometrics`;
      await firstValueFrom(this.http.put(apiUrl, biometrics));
      console.log('[DeviceConnectionPanel] ✓ Dados persistidos no banco');
    } catch (error) {
      console.warn('[DeviceConnectionPanel] Erro ao salvar no banco (dados já enviados via SignalR):', error);
    }
  }

  ngOnDestroy(): void {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    this.subscriptions.unsubscribe();
    this.formChanged$.complete();
  }
}


