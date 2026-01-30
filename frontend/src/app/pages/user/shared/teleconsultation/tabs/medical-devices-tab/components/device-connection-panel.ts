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
        <div class="header-left">
          <app-icon name="activity" [size]="16" />
          <span class="title">Sinais Vitais</span>
          @if (patientGender || patientBirthDate) {
            <span class="patient-info-inline">
              @if (patientGender) {
                <span>{{ getGenderLabel(patientGender) }}</span>
              }
              @if (patientGender && patientBirthDate) {
                <span class="sep">•</span>
              }
              @if (patientBirthDate) {
                <span>{{ getPatientAge() }} anos</span>
              }
            </span>
          }
        </div>
        <span class="connection-status" [class.connected]="isHubConnected">
          {{ isHubConnected ? 'Sincronizado' : 'Offline' }}
        </span>
      </div>

      <p class="description">
        Os valores são capturados automaticamente da maleta ou podem ser digitados manualmente.
      </p>

      <!-- Botão para buscar dados do cache da maleta -->
      <div class="capture-section">
        <button type="button" class="btn-capture" 
                [disabled]="isCapturing" 
                (click)="capturarSinais()"
                title="Busca os últimos dados capturados pela maleta e aplica nesta consulta">
          @if (isCapturing) {
            <app-icon name="loader" [size]="16" class="spin" />
            <span>Buscando...</span>
          } @else {
            <app-icon name="radio" [size]="16" />
            <span>📡 Capturar Sinais</span>
          }
        </button>
        @if (captureMessage) {
          <span class="capture-message" [class.success]="captureSuccess" [class.error]="!captureSuccess">
            {{ captureMessage }}
          </span>
        }
      </div>

      @if (!bluetoothAvailable) {
        <div class="warning-banner">
          <app-icon name="alert-triangle" [size]="16" />
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
      padding: 12px;
      height: 100%;
      overflow-y: auto;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;

      .header-left {
        display: flex;
        align-items: center;
        gap: 6px;
        
        .title {
          font-size: 14px;
          font-weight: 600;
          color: var(--text-primary);
        }

        .patient-info-inline {
          display: flex;
          align-items: center;
          gap: 4px;
          font-size: 11px;
          color: #0369a1;
          background: #e0f2fe;
          padding: 2px 8px;
          border-radius: 10px;
          margin-left: 6px;

          .sep {
            color: #7dd3fc;
          }
        }
      }

      .connection-status {
        font-size: 10px;
        padding: 2px 8px;
        border-radius: 10px;
        background: var(--bg-danger);
        color: var(--text-danger);

        &.connected {
          background: var(--bg-success);
          color: var(--text-success);
        }
      }
    }

    .description {
      font-size: 11px;
      color: var(--text-secondary);
      margin: 0 0 10px 0;
    }

    .capture-section {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 12px;
      padding: 10px;
      background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(16, 185, 129, 0.1));
      border: 1px dashed #3b82f6;
      border-radius: 8px;
    }

    .btn-capture {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 8px 14px;
      background: linear-gradient(135deg, #3b82f6, #2563eb);
      color: white;
      border: none;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      box-shadow: 0 2px 4px rgba(59, 130, 246, 0.3);

      &:hover:not(:disabled) {
        background: linear-gradient(135deg, #2563eb, #1d4ed8);
        transform: translateY(-1px);
        box-shadow: 0 4px 8px rgba(59, 130, 246, 0.4);
      }

      &:disabled {
        opacity: 0.6;
        cursor: not-allowed;
        transform: none;
      }
    }

    .capture-message {
      font-size: 12px;
      font-weight: 500;
      
      &.success {
        color: #10b981;
      }
      
      &.error {
        color: #ef4444;
      }
    }

    .warning-banner {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 8px;
      background: var(--bg-warning);
      color: var(--text-warning);
      border-radius: 6px;
      margin-bottom: 10px;
      font-size: 11px;
    }

    .vitals-form {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .vital-card {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 12px;
      background: var(--bg-secondary);
      border-radius: 10px;
      border: 1px solid var(--border-color);
    }

    .vital-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      min-width: 36px;
      border-radius: 8px;
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
      gap: 10px;
    }

    .field-group {
      flex: 1;
      
      &.full {
        max-width: 140px;
      }

      label {
        display: block;
        font-size: 10px;
        font-weight: 500;
        color: var(--text-secondary);
        margin-bottom: 2px;
        text-transform: uppercase;
      }
    }

    .input-wrapper {
      display: flex;
      align-items: center;
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      overflow: hidden;

      input {
        flex: 1;
        width: 100%;
        min-width: 50px;
        padding: 6px 8px;
        border: none;
        background: transparent;
        font-size: 14px;
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
      gap: 4px;
      padding: 6px 10px;
      border: 1px solid #3b82f6;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
      background: #3b82f6;
      color: white;
      white-space: nowrap;
      min-width: 90px;

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
      gap: 12px;
      margin-top: 6px;
      padding-top: 10px;
      border-top: 1px solid var(--border-color);
    }

    .btn-save {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 8px 16px;
      border: none;
      border-radius: 6px;
      font-size: 13px;
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
      padding: 6px 0;
    }

    .sync-status {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
      padding: 6px 10px;
      border-radius: 6px;

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

  // Captura de sinais da maleta
  isCapturing = false;
  captureMessage = '';
  captureSuccess = false;

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

  /**
   * Busca os dados do cache da maleta e aplica no formulário desta consulta.
   * Resolve o problema de múltiplas consultas "Em Andamento".
   */
  capturarSinais(): void {
    this.isCapturing = true;
    this.captureMessage = '';

    this.http.get<any>(`${environment.apiUrl}/biometrics/ble-cache`)
      .subscribe({
        next: (response) => {
          const devices = response.devices || {};
          let capturedCount = 0;
          const updates: any = {};

          // Processa balança
          if (devices['scale']?.values) {
            const weight = devices['scale'].values.weight;
            if (weight !== undefined) {
              updates.weight = weight;
              capturedCount++;
              console.log('[Capturar] Peso:', weight, 'kg');
            }
          }

          // Processa pressão arterial
          if (devices['blood_pressure']?.values) {
            const bp = devices['blood_pressure'].values;
            if (bp.systolic !== undefined) {
              updates.systolic = bp.systolic;
              capturedCount++;
            }
            if (bp.diastolic !== undefined) {
              updates.diastolic = bp.diastolic;
              capturedCount++;
            }
            if (bp.pulse !== undefined) {
              updates.heartRate = bp.pulse;
              capturedCount++;
            }
            console.log('[Capturar] Pressão:', bp.systolic, '/', bp.diastolic);
          }

          // Processa oxímetro
          if (devices['oximeter']?.values) {
            const ox = devices['oximeter'].values;
            if (ox.spo2 !== undefined) {
              updates.spo2 = ox.spo2;
              capturedCount++;
            }
            if (ox.pulseRate !== undefined) {
              updates.heartRate = ox.pulseRate;
              capturedCount++;
            }
            console.log('[Capturar] SpO2:', ox.spo2, '%');
          }

          // Processa termômetro
          if (devices['thermometer']?.values) {
            const temp = devices['thermometer'].values.temperature;
            if (temp !== undefined) {
              updates.temperature = temp;
              capturedCount++;
              console.log('[Capturar] Temperatura:', temp, '°C');
            }
          }

          if (capturedCount > 0) {
            // Atualiza formulário
            this.vitalsForm.patchValue(updates);

            this.captureSuccess = true;
            this.captureMessage = `✓ ${capturedCount} medição(ões) capturada(s)!`;
          } else {
            this.captureSuccess = false;
            this.captureMessage = 'Nenhuma leitura recente. Faça a medição.';
          }

          this.isCapturing = false;

          // Limpa mensagem após 5 segundos
          setTimeout(() => {
            this.captureMessage = '';
          }, 5000);
        },
        error: (err) => {
          console.error('[Capturar] Erro:', err);
          this.captureSuccess = false;
          this.captureMessage = 'Erro ao buscar dados da maleta';
          this.isCapturing = false;
        }
      });
  }

  ngOnDestroy(): void {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    this.subscriptions.unsubscribe();
    this.formChanged$.complete();
  }
}


