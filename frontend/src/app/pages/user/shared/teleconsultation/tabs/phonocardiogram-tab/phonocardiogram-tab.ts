import { Component, Input, OnInit, OnDestroy, ElementRef, ViewChild, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { PcmAudioStreamingService, WaveformData } from '@core/services/pcm-audio-streaming.service';
import { MedicalDevicesSyncService } from '@core/services/medical-devices-sync.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-phonocardiogram-tab',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  templateUrl: './phonocardiogram-tab.html',
  styleUrls: ['./phonocardiogram-tab.scss']
})
export class PhonocardiogramTabComponent implements OnInit, OnDestroy {
  @Input() appointmentId: string | null = null;
  @Input() userrole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' = 'PATIENT';
  @Input() readonly = false;

  @ViewChild('waveformCanvas') waveformCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('receivedWaveformCanvas') receivedWaveformCanvas!: ElementRef<HTMLCanvasElement>;

  // Estado
  isStreaming = false;
  isReceiving = false;
  recordingDuration = 0;
  estimatedHeartRate: number | null = null;
  latency = 0;
  selectedDeviceId = 'default';
  
  // Dispositivos de áudio
  audioDevices: MediaDeviceInfo[] = [];
  
  // Visualização
  currentWaveform: WaveformData | null = null;
  receivedWaveform: WaveformData | null = null;
  
  private recordingInterval: any;
  private subscriptions = new Subscription();

  constructor(
    private pcmStreaming: PcmAudioStreamingService,
    private devicesSync: MedicalDevicesSyncService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAudioDevices();
    this.setupSubscriptions();
  }

  ngOnDestroy(): void {
    this.stopStreaming();
    this.subscriptions.unsubscribe();
    if (this.recordingInterval) {
      clearInterval(this.recordingInterval);
    }
  }

  private async loadAudioDevices(): Promise<void> {
    this.audioDevices = await this.pcmStreaming.getAudioDevices();
    this.cdr.detectChanges();
  }

  private setupSubscriptions(): void {
    // Estado de streaming local
    this.subscriptions.add(
      this.pcmStreaming.isStreaming$.subscribe(streaming => {
        this.isStreaming = streaming;
        this.cdr.detectChanges();
      })
    );

    // Estado de recepção
    this.subscriptions.add(
      this.pcmStreaming.isReceiving$.subscribe(receiving => {
        this.isReceiving = receiving;
        this.cdr.detectChanges();
      })
    );

    // Waveform local (transmitindo)
    this.subscriptions.add(
      this.pcmStreaming.waveformData$.subscribe(waveform => {
        this.currentWaveform = waveform;
        this.drawWaveform(waveform, 'local');
      })
    );

    // Waveform recebido (médico recebe do paciente)
    this.subscriptions.add(
      this.pcmStreaming.receivedWaveform$.subscribe(waveform => {
        this.receivedWaveform = waveform;
        this.drawWaveform(waveform, 'received');
      })
    );

    // Frequência cardíaca estimada
    this.subscriptions.add(
      this.pcmStreaming.estimatedHeartRate$.subscribe(hr => {
        this.estimatedHeartRate = hr;
        this.cdr.detectChanges();
      })
    );

    // Latência
    this.subscriptions.add(
      this.pcmStreaming.latency$.subscribe(lat => {
        this.latency = lat;
        this.cdr.detectChanges();
      })
    );

    // Erros
    this.subscriptions.add(
      this.pcmStreaming.error$.subscribe(error => {
        console.error('[Fonocardiograma] Erro:', error);
      })
    );
  }

  async startStreaming(): Promise<void> {
    if (!this.appointmentId) {
      console.error('[Fonocardiograma] appointmentId não definido');
      return;
    }

    console.log('[Fonocardiograma] Iniciando streaming...', {
      appointmentId: this.appointmentId,
      deviceId: this.selectedDeviceId
    });

    const success = await this.pcmStreaming.startStreaming(this.appointmentId, {
      deviceId: this.selectedDeviceId,
      enableCardiacFilter: true,
      enableVisualization: true
    });

    if (success) {
      this.recordingDuration = 0;
      this.recordingInterval = setInterval(() => {
        this.recordingDuration++;
        this.cdr.detectChanges();
      }, 1000);
    }
  }

  stopStreaming(): void {
    console.log('[Fonocardiograma] Parando streaming...');
    
    this.pcmStreaming.stopStreaming();
    
    if (this.recordingInterval) {
      clearInterval(this.recordingInterval);
      this.recordingInterval = null;
    }
    
    this.recordingDuration = 0;
  }

  private drawWaveform(data: WaveformData, type: 'local' | 'received'): void {
    const canvas = type === 'local' 
      ? this.waveformCanvas?.nativeElement 
      : this.receivedWaveformCanvas?.nativeElement;
    
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const width = canvas.width;
    const height = canvas.height;
    const centerY = height / 2;
    
    // Limpa canvas
    ctx.fillStyle = '#1a1a2e';
    ctx.fillRect(0, 0, width, height);

    // Desenha linha central
    ctx.strokeStyle = '#333355';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, centerY);
    ctx.lineTo(width, centerY);
    ctx.stroke();

    // Desenha waveform
    ctx.strokeStyle = type === 'local' ? '#22c55e' : '#3b82f6';
    ctx.lineWidth = 2;
    ctx.beginPath();

    const barWidth = width / data.peaks.length;
    
    for (let i = 0; i < data.peaks.length; i++) {
      const x = i * barWidth;
      const amplitude = data.peaks[i] * (height / 2) * 0.9;
      
      ctx.lineTo(x, centerY - amplitude);
    }
    
    ctx.stroke();

    // Desenha indicador de volume
    const volumeHeight = data.volume * height;
    ctx.fillStyle = type === 'local' ? 'rgba(34, 197, 94, 0.3)' : 'rgba(59, 130, 246, 0.3)';
    ctx.fillRect(width - 20, height - volumeHeight, 15, volumeHeight);
  }

  formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  get isPatient(): boolean {
    return this.userrole === 'PATIENT';
  }

  get isProfessional(): boolean {
    return this.userrole === 'PROFESSIONAL' || this.userrole === 'ADMIN';
  }
}
