import { Component, Input, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { BiometricsService, BiometricsData } from '@core/services/biometrics.service';
import { TeleconsultationRealTimeService, DataUpdatedEvent } from '@core/services/teleconsultation-realtime.service';
import { BluetoothDevicesService, VitalReading } from '@core/services/bluetooth-devices.service';
import { Appointment } from '@core/services/appointments.service';
import { Subject, takeUntil } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { environment } from '@env/environment';

@Component({
  selector: 'app-biometrics-tab',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, IconComponent],
  templateUrl: './biometrics-tab.html',
  styleUrls: ['./biometrics-tab.scss']
})
export class BiometricsTabComponent implements OnInit, OnDestroy {
  @Input() appointmentId: string | null = null;
  @Input() appointment: Appointment | null = null;
  @Input() userrole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' = 'PATIENT';
  @Input() readonly = false;

  biometricsForm: FormGroup;
  lastUpdated: Date | null = null;
  private destroy$ = new Subject<void>();
  isSaving = false;
  isRefreshing = false;

  // Captura de sinais da maleta
  isCapturing = false;
  captureMessage = '';
  captureSuccess = false;

  // Bluetooth
  bluetoothAvailable = false;
  isConnecting = false;
  oxConnected = false;
  bpConnected = false;
  thermConnected = false;
  scaleConnected = false;

  // Modo Maleta Itinerante - quando ativo, oculta botões de conexão manual
  // pois os dados chegam automaticamente via BLE Bridge
  maletaMode = true; // Por padrão, assume que está no modo maleta

  constructor(
    private fb: FormBuilder,
    private biometricsService: BiometricsService,
    private teleconsultationRealTime: TeleconsultationRealTimeService,
    private bluetoothService: BluetoothDevicesService,
    private cdr: ChangeDetectorRef,
    private http: HttpClient
  ) {
    this.biometricsForm = this.fb.group({
      heartRate: [null, [Validators.min(0), Validators.max(300)]],
      bloodPressureSystolic: [null, [Validators.min(0), Validators.max(300)]],
      bloodPressureDiastolic: [null, [Validators.min(0), Validators.max(300)]],
      oxygenSaturation: [null, [Validators.min(0), Validators.max(100)]],
      temperature: [null, [Validators.min(30), Validators.max(45)]],
      respiratoryRate: [null, [Validators.min(0), Validators.max(100)]],
      glucose: [null, [Validators.min(0), Validators.max(1000)]],
      weight: [null, [Validators.min(0), Validators.max(500)]],
      height: [null, [Validators.min(0), Validators.max(300)]]
    });
  }

  ngOnInit() {
    // Verifica disponibilidade do Bluetooth
    this.bluetoothAvailable = this.bluetoothService.isBluetoothAvailable();

    if (this.appointmentId) {
      // 1. Carregar do cache IMEDIATAMENTE (síncrono)
      this.loadFromCacheImmediately();
      
      // 2. Configurar subscriptions para atualizações em tempo real
      this.setupRealTimeSubscriptions();
      this.setupBluetoothSubscriptions();
      
      // 3. Buscar dados atualizados da API em background
      this.loadData();
      
      if (this.readonly || this.isProfessional) {
        this.biometricsForm.disable();
      }
    }
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Carrega dados do cache de forma síncrona - aparece instantaneamente
   */
  private loadFromCacheImmediately(): void {
    if (!this.appointmentId) return;
    
    const cached = this.biometricsService.getCachedBiometrics(this.appointmentId);
    if (cached) {
      this.biometricsForm.patchValue(cached, { emitEvent: false });
      if (cached.lastUpdated) {
        this.lastUpdated = new Date(cached.lastUpdated);
      }
      this.cdr.detectChanges();
      console.log('[Biometrics] Dados carregados do cache instantaneamente:', cached);
    }
  }

  /**
   * Força atualização dos dados do servidor
   */
  forceRefresh(): void {
    if (!this.appointmentId) return;
    this.isRefreshing = true;
    this.cdr.detectChanges();
    
    this.biometricsService.forceRefresh(this.appointmentId).subscribe({
      next: (data) => {
        if (data) {
          this.biometricsForm.patchValue(data, { emitEvent: false });
          if (data.lastUpdated) {
            this.lastUpdated = new Date(data.lastUpdated);
          }
        }
        this.isRefreshing = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isRefreshing = false;
        this.cdr.detectChanges();
      }
    });
  }

  get isProfessional(): boolean {
    return this.userrole === 'PROFESSIONAL';
  }

  private setupRealTimeSubscriptions(): void {
    this.teleconsultationRealTime.getDataUpdates$('biometrics')
      .pipe(takeUntil(this.destroy$))
      .subscribe((event: DataUpdatedEvent) => {
        if (event.data) {
          this.biometricsForm.patchValue(event.data, { emitEvent: false });
          if (event.data.lastUpdated) {
            this.lastUpdated = new Date(event.data.lastUpdated);
          }
          // Salvar no cache do serviço para persistir entre mudanças de aba
          if (this.appointmentId) {
            this.biometricsService.updateCache(this.appointmentId, event.data);
          }
          this.cdr.detectChanges();
        }
      });
  }

  private setupBluetoothSubscriptions(): void {
    // Escuta leituras dos dispositivos Bluetooth
    this.bluetoothService.readings$
      .pipe(takeUntil(this.destroy$))
      .subscribe((reading: VitalReading) => {
        this.handleBluetoothReading(reading);
      });

    // Escuta estado dos dispositivos
    this.bluetoothService.devices$
      .pipe(takeUntil(this.destroy$))
      .subscribe(devices => {
        this.oxConnected = devices.some(d => d.type === 'oximeter' && d.connected);
        this.bpConnected = devices.some(d => d.type === 'blood_pressure' && d.connected);
        this.thermConnected = devices.some(d => d.type === 'thermometer' && d.connected);
        this.scaleConnected = devices.some(d => d.type === 'scale' && d.connected);
        this.cdr.detectChanges();
      });
  }

  private handleBluetoothReading(reading: VitalReading): void {
    const values = reading.values;
    const updates: Partial<BiometricsData> = {};

    if (values.spo2 !== undefined) {
      updates.oxygenSaturation = values.spo2;
    }
    if (values.pulseRate !== undefined) {
      updates.heartRate = values.pulseRate;
    }
    if (values.heartRate !== undefined) {
      updates.heartRate = values.heartRate;
    }
    if (values.temperature !== undefined) {
      updates.temperature = values.temperature;
    }
    if (values.weight !== undefined) {
      updates.weight = values.weight;
    }
    if (values.systolic !== undefined) {
      updates.bloodPressureSystolic = values.systolic;
    }
    if (values.diastolic !== undefined) {
      updates.bloodPressureDiastolic = values.diastolic;
    }

    // Atualiza o formulário com os valores capturados
    this.biometricsForm.patchValue(updates);
    this.cdr.detectChanges();
  }

  // === Conexão Bluetooth ===

  async connectOximeter(): Promise<void> {
    if (this.isConnecting) return;
    this.isConnecting = true;
    try {
      await this.bluetoothService.connectOximeter();
    } catch (error) {
      console.error('Erro ao conectar oxímetro:', error);
    } finally {
      this.isConnecting = false;
      this.cdr.detectChanges();
    }
  }

  async connectBloodPressure(): Promise<void> {
    if (this.isConnecting) return;
    this.isConnecting = true;
    try {
      await this.bluetoothService.connectBloodPressure();
    } catch (error) {
      console.error('Erro ao conectar medidor de pressão:', error);
    } finally {
      this.isConnecting = false;
      this.cdr.detectChanges();
    }
  }

  async connectThermometer(): Promise<void> {
    if (this.isConnecting) return;
    this.isConnecting = true;
    try {
      await this.bluetoothService.connectThermometer();
    } catch (error) {
      console.error('Erro ao conectar termômetro:', error);
    } finally {
      this.isConnecting = false;
      this.cdr.detectChanges();
    }
  }

  async connectScale(): Promise<void> {
    if (this.isConnecting) return;
    this.isConnecting = true;
    try {
      await this.bluetoothService.connectScale();
    } catch (error) {
      console.error('Erro ao conectar balança:', error);
    } finally {
      this.isConnecting = false;
      this.cdr.detectChanges();
    }
  }

  // === Dados ===

  loadData() {
    if (!this.appointmentId) return;

    this.biometricsService.getBiometrics(this.appointmentId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(data => {
        if (data) {
          this.biometricsForm.patchValue(data, { emitEvent: false });
          if (data.lastUpdated) {
            this.lastUpdated = new Date(data.lastUpdated);
          }
        }
        this.cdr.detectChanges();
      });
  }

  onSave(): void {
    if (!this.appointmentId || !this.biometricsForm.valid) return;
    
    const data = this.biometricsForm.value;
    this.saveData(data);
  }

  /**
   * Busca os dados do cache da maleta e aplica no formulário desta consulta.
   * Resolve o problema de múltiplas consultas "Em Andamento".
   */
  capturarSinais(): void {
    this.isCapturing = true;
    this.captureMessage = '';
    this.cdr.detectChanges();

    this.http.get<any>(`${environment.apiUrl}/biometrics/ble-cache`)
      .subscribe({
        next: (response) => {
          const devices = response.devices || {};
          const updates: Partial<BiometricsData> = {};
          let capturedCount = 0;

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
              updates.bloodPressureSystolic = bp.systolic;
              capturedCount++;
            }
            if (bp.diastolic !== undefined) {
              updates.bloodPressureDiastolic = bp.diastolic;
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
              updates.oxygenSaturation = ox.spo2;
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
            this.biometricsForm.patchValue(updates);
            this.cdr.detectChanges();

            // Salva automaticamente
            this.saveData(this.biometricsForm.value);

            this.captureSuccess = true;
            this.captureMessage = `✓ ${capturedCount} medição(ões) capturada(s)!`;
          } else {
            this.captureSuccess = false;
            this.captureMessage = 'Nenhuma leitura recente. Faça a medição no dispositivo.';
          }

          this.isCapturing = false;
          this.cdr.detectChanges();

          // Limpa mensagem após 5 segundos
          setTimeout(() => {
            this.captureMessage = '';
            this.cdr.detectChanges();
          }, 5000);
        },
        error: (err) => {
          console.error('[Capturar] Erro:', err);
          this.captureSuccess = false;
          this.captureMessage = 'Erro ao buscar dados da maleta';
          this.isCapturing = false;
          this.cdr.detectChanges();
        }
      });
  }

  saveData(data: BiometricsData) {
    if (!this.appointmentId) return;
    
    this.isSaving = true;
    this.cdr.detectChanges();
    
    this.biometricsService.saveBiometrics(this.appointmentId, data);
    this.lastUpdated = new Date();
    
    // Notifica o outro participante via SignalR
    this.teleconsultationRealTime.notifyDataUpdated(
      this.appointmentId,
      'biometrics',
      { ...data, lastUpdated: this.lastUpdated.toISOString() }
    );
    
    setTimeout(() => {
      this.isSaving = false;
      this.cdr.detectChanges();
    }, 500);
  }
}
