import { 
  Component, 
  Input, 
  OnInit, 
  OnDestroy, 
  ViewChild, 
  ElementRef, 
  AfterViewInit,
  Inject,
  PLATFORM_ID,
  ChangeDetectorRef
} from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { 
  PhonocardiogramService, 
  PhonocardiogramFrame 
} from '@core/services/phonocardiogram.service';
import { TeleconsultationRealTimeService } from '@core/services/teleconsultation-realtime.service';

@Component({
  selector: 'app-phonocardiogram-tab',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  template: `
    <div class="phonocardiogram-tab">
      <div class="panel-header">
        <h4>
          <app-icon name="heart" [size]="20" />
          Fonocardiograma em Tempo Real
        </h4>
        <div class="status-badge" [class.active]="isCapturing" [class.receiving]="isReceiving">
          <span class="dot"></span>
          @if (isCapturing) {
            Transmitindo
          } @else if (isReceiving) {
            Recebendo
          } @else {
            Aguardando
          }
        </div>
      </div>

      <div class="panel-content">
        <!-- Controles do Paciente -->
        @if (isOperator) {
          <div class="controls-section">
            <!-- Seletor de Microfone -->
            <div class="microphone-selector">
              <label>
                <app-icon name="mic" [size]="16" />
                Microfone:
              </label>
              <select [(ngModel)]="selectedMicrophone" [disabled]="isCapturing">
                @for (mic of availableMicrophones; track mic.deviceId) {
                  <option [value]="mic.deviceId">{{ mic.label || 'Microfone ' + ($index + 1) }}</option>
                }
                @if (availableMicrophones.length === 0) {
                  <option value="">Carregando...</option>
                }
              </select>
            </div>

            <!-- Botões de Controle -->
            <div class="action-buttons">
              @if (!isCapturing) {
                <button class="btn-start" (click)="startCapture()">
                  <app-icon name="play" [size]="18" />
                  Iniciar Captura
                </button>
              } @else {
                <button class="btn-stop" (click)="stopCapture()">
                  <app-icon name="square" [size]="18" />
                  Parar
                </button>
              }
            </div>

            <!-- Dica de uso -->
            <div class="hint-box">
              <app-icon name="info" [size]="14" />
              <span>Posicione o microfone (ou estetoscópio digital) próximo ao tórax do paciente.</span>
            </div>
          </div>
        }

        <!-- Visualização do Fonocardiograma -->
        <div class="visualization-section">
          <!-- Canvas do Traçado -->
          <div class="waveform-container">
            <canvas #waveformCanvas width="600" height="180"></canvas>
            @if (!isCapturing && !isReceiving) {
              <div class="canvas-placeholder">
                <app-icon name="activity" [size]="40" />
                <span>Aguardando dados do fonocardiograma...</span>
              </div>
            }
          </div>
        </div>

        <!-- Status de Conexão -->
        @if (isOperator && isCapturing) {
          <div class="connection-status">
            <app-icon name="activity" [size]="14" />
            <span>Transmitindo para o médico via SignalR</span>
          </div>
        }


      </div>
    </div>
  `,
  styles: [`
    .phonocardiogram-tab {
      height: 100%;
      display: flex;
      flex-direction: column;
      background: var(--bg-primary);
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border-color);
      background: var(--bg-secondary);

      h4 {
        display: flex;
        align-items: center;
        gap: 8px;
        margin: 0;
        font-size: 14px;
        font-weight: 600;
        color: var(--text-primary);
      }
    }

    .status-badge {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 500;
      background: var(--bg-tertiary);
      color: var(--text-secondary);

      .dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: var(--text-tertiary);
      }

      &.active {
        background: rgba(239, 68, 68, 0.1);
        color: #ef4444;
        .dot { background: #ef4444; animation: pulse 1s infinite; }
      }

      &.receiving {
        background: rgba(34, 197, 94, 0.1);
        color: #22c55e;
        .dot { background: #22c55e; animation: pulse 1s infinite; }
      }
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }

    .panel-content {
      flex: 1;
      padding: 16px;
      overflow-y: auto;
    }

    .controls-section {
      margin-bottom: 20px;
    }

    .microphone-selector {
      margin-bottom: 12px;

      label {
        display: flex;
        align-items: center;
        gap: 6px;
        margin-bottom: 6px;
        font-size: 12px;
        font-weight: 500;
        color: var(--text-secondary);
      }

      select {
        width: 100%;
        padding: 8px 12px;
        border: 1px solid var(--border-color);
        border-radius: 6px;
        background: var(--bg-secondary);
        color: var(--text-primary);
        font-size: 13px;

        &:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
      }
    }

    .action-buttons {
      display: flex;
      gap: 10px;
      margin-bottom: 12px;

      button {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        padding: 12px 16px;
        border: none;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
      }

      .btn-start {
        background: #ef4444;
        color: white;
        &:hover { background: #dc2626; }
      }

      .btn-stop {
        background: var(--bg-tertiary);
        color: var(--text-primary);
        border: 1px solid var(--border-color);
        &:hover { background: var(--bg-secondary); }
      }
    }

    .hint-box {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      padding: 10px 12px;
      border-radius: 6px;
      background: var(--bg-info-subtle, rgba(59, 130, 246, 0.1));
      color: var(--color-info, #3b82f6);
      font-size: 11px;
      line-height: 1.4;
    }

    .visualization-section {
      background: #0d0d1a;
      border-radius: 12px;
      padding: 16px;
      color: white;
    }

    .metrics-row {
      display: flex;
      gap: 12px;
      margin-bottom: 16px;
    }

    .metric-card {
      flex: 1;
      text-align: center;
      padding: 12px;
      border-radius: 8px;
      background: rgba(255, 255, 255, 0.05);

      .metric-value {
        font-size: 24px;
        font-weight: bold;
        line-height: 1;
      }

      .metric-label {
        font-size: 11px;
        color: rgba(255, 255, 255, 0.6);
        margin-top: 4px;
      }

      &.bpm .metric-value { color: #ef4444; }
      &.s1 .metric-value { color: #22c55e; }
      &.s2 .metric-value { color: #3b82f6; }
    }

    .waveform-container {
      position: relative;
      border-radius: 8px;
      overflow: hidden;
      background: #0a0a14;

      canvas {
        display: block;
        width: 100%;
        height: 180px;
      }

      .canvas-placeholder {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 12px;
        color: rgba(255, 255, 255, 0.3);
        font-size: 12px;
      }
    }

    .waveform-legend {
      display: flex;
      justify-content: center;
      gap: 20px;
      margin-top: 12px;
      font-size: 10px;
      color: rgba(255, 255, 255, 0.5);

      .legend-item {
        display: flex;
        align-items: center;
        gap: 6px;
      }

      .legend-color {
        width: 10px;
        height: 10px;
        border-radius: 2px;
        &.s1 { background: #22c55e; }
        &.s2 { background: #3b82f6; }
      }
    }

    /* Envelope Section Styles */
    .envelope-section {
      margin-top: 20px;
      padding: 16px;
      background: var(--bg-secondary);
      border-radius: 8px;
      border: 1px solid var(--border-color);
    }

    .envelope-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;

      h5 {
        display: flex;
        align-items: center;
        gap: 8px;
        margin: 0;
        font-size: 13px;
        font-weight: 600;
        color: var(--text-primary);
      }
    }

    .envelope-controls {
      display: flex;
      gap: 8px;
    }

    .btn-envelope-start, .btn-envelope-stop {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border: none;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-envelope-start {
      background: #ef4444;
      color: white;
      &:hover { background: #dc2626; }
    }

    .btn-envelope-stop {
      background: var(--bg-tertiary);
      color: var(--text-primary);
      &:hover { background: var(--bg-hover); }
    }

    .envelope-canvas-container {
      position: relative;
      background: #0a0a14;
      border-radius: 6px;
      overflow: hidden;

      canvas {
        display: block;
        width: 100%;
        height: 150px;
      }
    }

    .envelope-placeholder {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 8px;
      color: var(--text-tertiary);
      font-size: 12px;
    }

    .envelope-legend {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-top: 10px;
      padding-top: 10px;
      border-top: 1px solid var(--border-color);
    }

    .legend-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 11px;
      color: var(--text-secondary);
    }

    .legend-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      &.s1 { background: #22c55e; }
      &.s2 { background: #3b82f6; }
    }

    .bpm-display {
      margin-left: auto;
      font-size: 14px;
      font-weight: 600;
      color: #ef4444;
    }

    .connection-status {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      margin-top: 16px;
      padding: 8px;
      border-radius: 6px;
      background: rgba(34, 197, 94, 0.1);
      color: #22c55e;
      font-size: 11px;
    }

    .debug-area {
      margin-top: 16px;
      padding: 12px;
      background: #1a1a2e;
      border-radius: 8px;
      border: 1px solid #333;
    }

    .debug-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 8px;
      color: #fbbf24;
      font-size: 12px;
    }

    .btn-copy, .btn-clear {
      padding: 4px 8px;
      border: none;
      border-radius: 4px;
      font-size: 11px;
      cursor: pointer;
    }

    .btn-copy {
      background: #3b82f6;
      color: white;
    }

    .btn-clear {
      background: #6b7280;
      color: white;
    }

    .debug-log {
      width: 100%;
      height: 120px;
      padding: 8px;
      background: #0d0d1a;
      border: 1px solid #444;
      border-radius: 4px;
      color: #22c55e;
      font-family: monospace;
      font-size: 10px;
      resize: vertical;
    }
  `]
})
export class PhonocardiogramTabComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild('waveformCanvas', { static: false }) canvasRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('envelopeCanvas', { static: false }) envelopeCanvasRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('debugTextarea', { static: false }) debugTextareaRef!: ElementRef<HTMLTextAreaElement>;
  
  @Input() appointmentId: string | null = null;
  @Input() userrole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' | 'REGULATOR' = 'PATIENT';

  // Estados
  isCapturing = false;
  isReceiving = false;
  currentHeartRate = 0;
  s1Amplitude = 0;
  s2Amplitude = 0;

  // Fonocardiograma do Áudio Remoto
  isEnvelopeActive = false;
  envelopeBPM = 0;
  private envelopeCtx: CanvasRenderingContext2D | null = null;
  private envelopeAnimationId: number | null = null;
  private audioContext: AudioContext | null = null;
  private analyser: AnalyserNode | null = null;
  private dataArray: Uint8Array<ArrayBuffer> | null = null;
  private envelopeHistory: number[] = [];
  private readonly ENVELOPE_HISTORY_SIZE = 300;
  private lastBeatTime = 0;
  private peakHistory: { time: number; index: number; amplitude: number }[] = [];

  // DEBUG
  debugLogText = '';
  private debugLogs: string[] = [];
  private startTime = Date.now();

  // Microfones
  availableMicrophones: MediaDeviceInfo[] = [];
  selectedMicrophone = '';

  // Canvas
  private ctx: CanvasRenderingContext2D | null = null;
  private waveformHistory: number[][] = [];
  private maxHistory = 50; // ~5 segundos a 10fps
  private animationFrameId: number | null = null;
  private isBrowser: boolean;
  
  // Scrolling contínuo estilo ECG
  private scrollOffset = 0;
  private lastAnimationTime = 0;
  private readonly SCROLL_SPEED = 80; // pixels por segundo

  // Subscriptions
  private subscriptions: Subscription[] = [];

  constructor(
    @Inject(PLATFORM_ID) private platformId: Object,
    private phonoService: PhonocardiogramService,
    private realtimeService: TeleconsultationRealTimeService,
    private cdr: ChangeDetectorRef
  ) {
    this.isBrowser = isPlatformBrowser(this.platformId);
  }

  get isOperator(): boolean {
    return this.userrole === 'PATIENT' || this.userrole === 'ASSISTANT' || this.userrole === 'ADMIN';
  }

  ngOnInit(): void {
    if (this.isBrowser) {
      this.addDebugLog('INIT', `Componente iniciado | Role: ${this.userrole} | AppointmentId: ${this.appointmentId}`);
      this.loadMicrophones();
      this.setupSubscriptions();
    }
  }

  ngAfterViewInit(): void {
    if (this.isBrowser && this.canvasRef) {
      this.ctx = this.canvasRef.nativeElement.getContext('2d');
      this.addDebugLog('CANVAS', `Canvas inicializado: ${this.ctx ? 'OK' : 'FALHOU'}`);
      this.startAnimation();
    }
  }

  ngOnDestroy(): void {
    this.stopCapture();
    this.subscriptions.forEach(sub => sub.unsubscribe());
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
    }
  }

  private async loadMicrophones(): Promise<void> {
    try {
      this.availableMicrophones = await this.phonoService.getAvailableMicrophones();
      if (this.availableMicrophones.length > 0) {
        this.selectedMicrophone = this.availableMicrophones[0].deviceId;
      }
      this.cdr.detectChanges();
    } catch (error) {
      console.error('[Fono Tab] Erro ao carregar microfones:', error);
    }
  }

  private remoteFrameCount = 0;
  private localFrameCount = 0;
  private lastFrameTime = 0;

  private setupSubscriptions(): void {
    this.addDebugLog('SUB', 'Configurando subscriptions...');

    // Frames locais (paciente)
    this.subscriptions.push(
      this.phonoService.localFrame$.subscribe(frame => {
        this.localFrameCount++;
        const now = Date.now();
        const delta = this.lastFrameTime ? now - this.lastFrameTime : 0;
        this.lastFrameTime = now;
        
        // Log a cada 30 frames (~1 segundo)
        if (this.localFrameCount % 30 === 0) {
          this.addDebugLog('LOCAL', `Frame #${this.localFrameCount} | BPM: ${frame.heartRate} | Delta: ${delta}ms | History: ${this.waveformHistory.length}`);
        }
        this.processFrame(frame);
      })
    );

    // Frames remotos (médico recebe do paciente)
    this.subscriptions.push(
      this.realtimeService.phonocardiogramFrame$.subscribe(frame => {
        this.isReceiving = true;
        this.remoteFrameCount++;
        const now = Date.now();
        const delta = this.lastFrameTime ? now - this.lastFrameTime : 0;
        this.lastFrameTime = now;
        
        // Log a cada frame nos primeiros 10, depois a cada 30
        if (this.remoteFrameCount <= 10 || this.remoteFrameCount % 30 === 0) {
          this.addDebugLog('REMOTE', `Frame #${this.remoteFrameCount} | BPM: ${frame.heartRate} | Waveform: ${frame.waveform?.length || 0}pts | Delta: ${delta}ms | History: ${this.waveformHistory.length}`);
        }
        
        this.processFrame(frame);
        this.cdr.detectChanges();
      })
    );

    // Status de captura
    this.subscriptions.push(
      this.phonoService.isCapturing$.subscribe(capturing => {
        this.isCapturing = capturing;
        this.addDebugLog('STATUS', `Captura: ${capturing ? 'ATIVA' : 'PARADA'}`);
        this.cdr.detectChanges();
      })
    );

    this.addDebugLog('SUB', 'Subscriptions configuradas OK');
  }

  private processFrame(frame: PhonocardiogramFrame): void {
    this.currentHeartRate = frame.heartRate;
    this.s1Amplitude = frame.s1Amplitude;
    this.s2Amplitude = frame.s2Amplitude;

    // Adicionar ao histórico
    this.waveformHistory.push(frame.waveform);
    if (this.waveformHistory.length > this.maxHistory) {
      this.waveformHistory.shift();
    }
  }

  async startCapture(): Promise<void> {
    if (!this.appointmentId) {
      console.error('[Fono Tab] ID da consulta não definido');
      return;
    }

    try {
      await this.phonoService.startCapture(this.appointmentId, this.selectedMicrophone);
    } catch (error) {
      console.error('[Fono Tab] Erro ao iniciar captura:', error);
    }
  }

  stopCapture(): void {
    this.phonoService.stopCapture();
    this.waveformHistory = [];
  }

  private startAnimation(): void {
    this.lastAnimationTime = performance.now();
    
    const animate = (currentTime: number) => {
      // Calcular delta time para animação suave
      const deltaTime = (currentTime - this.lastAnimationTime) / 1000;
      this.lastAnimationTime = currentTime;
      
      // Scroll contínuo (mesmo sem novos dados)
      this.scrollOffset += this.SCROLL_SPEED * deltaTime;
      
      this.drawWaveform();
      this.animationFrameId = requestAnimationFrame(animate);
    };
    
    requestAnimationFrame(animate);
  }

  private drawWaveform(): void {
    if (!this.ctx || !this.canvasRef) return;

    const canvas = this.canvasRef.nativeElement;
    const ctx = this.ctx;
    const width = canvas.width;
    const height = canvas.height;
    const baseline = height / 2;

    // Limpar com fundo escuro estilo monitor médico
    ctx.fillStyle = 'rgb(10, 10, 20)';
    ctx.fillRect(0, 0, width, height);

    // Desenhar grade de fundo
    ctx.strokeStyle = 'rgba(34, 197, 94, 0.08)';
    ctx.lineWidth = 0.5;
    for (let y = 0; y < height; y += 20) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }
    
    // Grade vertical com scroll
    const gridOffset = this.scrollOffset % 40;
    for (let x = -gridOffset; x < width; x += 40) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }

    // Desenhar linha base central
    ctx.strokeStyle = 'rgba(34, 197, 94, 0.3)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, baseline);
    ctx.lineTo(width, baseline);
    ctx.stroke();

    // ========== USAR DADOS REAIS DO WAVEFORM HISTORY ==========
    
    // Se não há dados, mostrar linha plana
    if (this.waveformHistory.length === 0 || !this.isReceiving) {
      ctx.strokeStyle = 'rgba(34, 197, 94, 0.3)';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(0, baseline);
      ctx.lineTo(width, baseline);
      ctx.stroke();
      return;
    }

    // Flatten todos os pontos de waveform em um array contínuo
    const flatData = this.waveformHistory.flat();
    if (flatData.length === 0) return;

    // Calcular o offset baseado no tempo para scroll contínuo
    const now = performance.now();
    const pixelsPerSecond = 100; // Velocidade mais lenta para melhor visualização
    const timeOffset = (now / 1000) * pixelsPerSecond;
    
    // Calcular quantos pontos de dados correspondem a um pixel
    const totalDataPoints = flatData.length;
    const dataPointsPerPixel = Math.max(1, totalDataPoints / width);
    
    // Offset do scroll no array de dados
    const scrollDataOffset = Math.floor((timeOffset * dataPointsPerPixel) / pixelsPerSecond);

    // Encontrar min/max para normalização dinâmica
    let minVal = Infinity, maxVal = -Infinity;
    for (const val of flatData) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    const range = Math.max(0.01, maxVal - minVal);
    
    // Calcular média para threshold
    let sum = 0;
    for (const val of flatData) {
      sum += val;
    }
    const average = sum / flatData.length;

    // ========== DESENHAR O TRAÇADO COM PICOS DESTACADOS ==========
    ctx.strokeStyle = '#22c55e';
    ctx.lineWidth = 2.5;
    ctx.beginPath();

    let firstPoint = true;
    let prevY = baseline;
    
    // Threshold: valores abaixo ficam na linha base
    const noiseThreshold = 0.25; // 25% da amplitude máxima é considerado ruído
    
    // Fator de amplificação dos picos
    const peakAmplification = 0.55; // Maior altura dos picos

    for (let x = 0; x < width; x++) {
      // Calcular índice no array de dados com wrap-around
      const dataIndex = (Math.floor(x * dataPointsPerPixel) + scrollDataOffset) % totalDataPoints;
      const rawValue = flatData[dataIndex] || 0;
      
      // Normalizar valor para 0 a 1
      const normalized = (rawValue - minVal) / range;
      
      // Aplicar threshold: se abaixo do limiar, fica na linha base
      let amplitude = 0;
      if (normalized > noiseThreshold) {
        // Acima do threshold: amplificar o pico
        // Remapear de [threshold, 1] para [0, 1] e depois amplificar
        const peakValue = (normalized - noiseThreshold) / (1 - noiseThreshold);
        amplitude = Math.pow(peakValue, 0.7) * peakAmplification; // Curva para destacar picos
      }
      
      // Calcular posição Y (picos vão para cima)
      const targetY = baseline - (amplitude * height);
      
      // Suavização leve para transições naturais
      const smoothingFactor = 0.4;
      const smoothedY = prevY + (targetY - prevY) * (1 - smoothingFactor);
      prevY = smoothedY;
      
      if (firstPoint) {
        ctx.moveTo(x, smoothedY);
        firstPoint = false;
      } else {
        ctx.lineTo(x, smoothedY);
      }
    }
    ctx.stroke();

    // Glow effect para visual de monitor
    ctx.shadowColor = '#22c55e';
    ctx.shadowBlur = 10;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Indicador de posição atual (linha de scan vertical)
    const scanX = (timeOffset % width);
    
    // Apagar área à frente do scan (efeito de "limpeza")
    ctx.fillStyle = 'rgb(10, 10, 20)';
    ctx.fillRect(scanX, 0, 25, height);
    
    // Linha de scan
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.5)';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(scanX, 0);
    ctx.lineTo(scanX, height);
    ctx.stroke();
  }

  // ======== DEBUG METHODS ========
  
  // ========== FONOCARDIOGRAMA DO ÁUDIO REMOTO ==========
  
  async startEnvelopeCapture(): Promise<void> {
    if (!this.isBrowser) return;

    this.addDebugLog('ENVELOPE', 'Iniciando captura do áudio remoto...');

    try {
      // Tenta encontrar o elemento de áudio/vídeo do Jitsi
      let audioElement: HTMLMediaElement | null = null;
      
      // Procura por elementos de vídeo/áudio do Jitsi
      const jitsiFrame = document.querySelector('iframe[src*="meet"]') as HTMLIFrameElement;
      if (jitsiFrame && jitsiFrame.contentDocument) {
        audioElement = jitsiFrame.contentDocument.querySelector('audio, video') as HTMLMediaElement;
      }
      
      // Se não encontrar no iframe, procura na página
      if (!audioElement) {
        audioElement = document.querySelector('audio[autoplay], video[autoplay]') as HTMLMediaElement;
      }
      
      // Se ainda não encontrar, usa getDisplayMedia como fallback
      if (!audioElement) {
        this.addDebugLog('ENVELOPE', 'Elemento de áudio não encontrado. Usando captura do sistema...');
        await this.startDisplayMediaCapture();
        return;
      }

      this.addDebugLog('ENVELOPE', `Elemento de áudio encontrado: ${audioElement.tagName}`);

      // Cria contexto de áudio
      this.audioContext = new AudioContext();
      const source = this.audioContext.createMediaElementSource(audioElement);
      
      // Cria analisador
      this.analyser = this.audioContext.createAnalyser();
      this.analyser.fftSize = 512;
      this.analyser.smoothingTimeConstant = 0.85;
      
      // Conecta: source -> analyser -> destination (para continuar ouvindo)
      source.connect(this.analyser);
      this.analyser.connect(this.audioContext.destination);

      // Buffer para dados de frequência (foco em baixas frequências - som cardíaco)
      this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);
      
      // Inicializa histórico de amplitude
      this.envelopeHistory = [];
      this.peakHistory = [];

      // Inicializa canvas
      if (this.envelopeCanvasRef) {
        this.envelopeCtx = this.envelopeCanvasRef.nativeElement.getContext('2d');
      }

      this.isEnvelopeActive = true;
      this.lastBeatTime = 0;
      this.addDebugLog('ENVELOPE', 'Captura de áudio remoto iniciada!');
      
      // Inicia animação do fonocardiograma
      this.startEnvelopeAnimation();
      this.cdr.detectChanges();

    } catch (error: any) {
      console.error('[Envelope] Erro ao iniciar captura:', error);
      this.addDebugLog('ENVELOPE', `ERRO: ${error.message}`);
      // Fallback para getDisplayMedia
      await this.startDisplayMediaCapture();
    }
  }

  private async startDisplayMediaCapture(): Promise<void> {
    try {
      this.addDebugLog('ENVELOPE', 'Iniciando captura via compartilhamento de tela...');
      
      const displayStream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: {
          // @ts-ignore
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false
        }
      });

      const audioTracks = displayStream.getAudioTracks();
      if (audioTracks.length === 0) {
        this.addDebugLog('ENVELOPE', 'ERRO: Marque "Compartilhar áudio do sistema" na janela de compartilhamento.');
        displayStream.getTracks().forEach(t => t.stop());
        return;
      }

      this.addDebugLog('ENVELOPE', `Áudio capturado: ${audioTracks[0].label}`);
      displayStream.getVideoTracks().forEach(t => t.stop());

      this.audioContext = new AudioContext();
      const source = this.audioContext.createMediaStreamSource(new MediaStream(audioTracks));
      
      this.analyser = this.audioContext.createAnalyser();
      this.analyser.fftSize = 512;
      this.analyser.smoothingTimeConstant = 0.85;
      source.connect(this.analyser);

      this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);
      this.envelopeHistory = [];
      this.peakHistory = [];

      if (this.envelopeCanvasRef) {
        this.envelopeCtx = this.envelopeCanvasRef.nativeElement.getContext('2d');
      }

      this.isEnvelopeActive = true;
      this.lastBeatTime = 0;
      this.addDebugLog('ENVELOPE', 'Captura iniciada com sucesso!');
      
      this.startEnvelopeAnimation();
      this.cdr.detectChanges();

    } catch (error: any) {
      this.addDebugLog('ENVELOPE', `ERRO: ${error.message || 'Falha ao capturar áudio'}`);
    }
  }

  stopEnvelopeCapture(): void {
    this.addDebugLog('ENVELOPE', 'Parando captura...');
    
    if (this.envelopeAnimationId) {
      cancelAnimationFrame(this.envelopeAnimationId);
      this.envelopeAnimationId = null;
    }

    if (this.audioContext) {
      this.audioContext.close();
      this.audioContext = null;
    }

    this.analyser = null;
    this.dataArray = null;
    this.isEnvelopeActive = false;
    this.envelopeBPM = 0;
    this.envelopeHistory = [];
    this.peakHistory = [];
    
    this.cdr.detectChanges();
  }

  private startEnvelopeAnimation(): void {
    if (!this.isBrowser || !this.analyser || !this.dataArray) return;

    const animate = () => {
      if (!this.isEnvelopeActive) return;
      
      this.drawPhonocardiogram();
      this.envelopeAnimationId = requestAnimationFrame(animate);
    };

    animate();
  }

  private drawPhonocardiogram(): void {
    if (!this.analyser || !this.dataArray || !this.envelopeCtx) return;

    const canvas = this.envelopeCanvasRef.nativeElement;
    const ctx = this.envelopeCtx;
    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;
    const BASELINE = HEIGHT / 2;

    // Obtém dados de frequência (foco em baixas frequências para som cardíaco)
    this.analyser.getByteFrequencyData(this.dataArray);

    // Calcula amplitude focando em baixas frequências (20-200 Hz) - som cardíaco
    let lowFreqSum = 0;
    const lowFreqBins = Math.floor(this.dataArray.length * 0.15); // ~15% inferiores
    for (let i = 0; i < lowFreqBins; i++) {
      lowFreqSum += this.dataArray[i];
    }
    const amplitude = lowFreqSum / (lowFreqBins * 255); // 0 a 1

    // Adiciona ao histórico
    this.envelopeHistory.push(amplitude);
    if (this.envelopeHistory.length > this.ENVELOPE_HISTORY_SIZE) {
      this.envelopeHistory.shift();
    }

    // Detecta picos (batimentos)
    this.detectBeats(amplitude);

    // === DESENHO DO FONOCARDIOGRAMA ===
    
    // Limpa canvas com fundo escuro estilo monitor médico
    ctx.fillStyle = 'rgb(10, 15, 12)';
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    // Grade de fundo
    ctx.strokeStyle = 'rgba(40, 80, 60, 0.3)';
    ctx.lineWidth = 0.5;
    for (let x = 0; x < WIDTH; x += 40) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, HEIGHT);
      ctx.stroke();
    }
    for (let y = 0; y < HEIGHT; y += 40) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(WIDTH, y);
      ctx.stroke();
    }

    // Linha base horizontal
    ctx.strokeStyle = 'rgba(40, 100, 70, 0.6)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, BASELINE);
    ctx.lineTo(WIDTH, BASELINE);
    ctx.stroke();

    // Desenha o traçado do fonocardiograma
    if (this.envelopeHistory.length > 1) {
      const step = WIDTH / this.ENVELOPE_HISTORY_SIZE;

      // Traçado principal verde brilhante
      ctx.strokeStyle = 'rgb(0, 255, 120)';
      ctx.lineWidth = 2.5;
      ctx.beginPath();

      for (let i = 0; i < this.envelopeHistory.length; i++) {
        const x = i * step;
        // Amplitude para cima e para baixo da linha base
        const amp = this.envelopeHistory[i];
        const deviation = amp * HEIGHT * 0.4;
        
        // Cria formato de onda cardíaca (picos para cima)
        const y = BASELINE - deviation;
        
        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();

      // Glow effect
      ctx.strokeStyle = 'rgba(0, 255, 120, 0.3)';
      ctx.lineWidth = 6;
      ctx.beginPath();
      for (let i = 0; i < this.envelopeHistory.length; i++) {
        const x = i * step;
        const amp = this.envelopeHistory[i];
        const y = BASELINE - (amp * HEIGHT * 0.4);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();

      // Marcadores de picos S1/S2
      this.drawBeatMarkers(ctx, step, BASELINE, HEIGHT);
    }

    // Indicador de nível atual (barra vertical à direita)
    const currentLevel = this.envelopeHistory[this.envelopeHistory.length - 1] || 0;
    const barHeight = currentLevel * HEIGHT * 0.8;
    ctx.fillStyle = `rgba(0, ${Math.floor(180 + currentLevel * 75)}, 100, 0.8)`;
    ctx.fillRect(WIDTH - 20, HEIGHT - barHeight - 10, 15, barHeight);

    // Atualiza BPM periodicamente
    if (this.envelopeHistory.length % 30 === 0) {
      this.calculateBPM();
    }
  }

  private detectBeats(amplitude: number): void {
    const now = performance.now();
    const threshold = 0.25; // Limiar de detecção
    const minInterval = 300; // Mínimo 300ms entre batimentos (~200 BPM máximo)

    // Detecta pico
    if (amplitude > threshold && (now - this.lastBeatTime) > minInterval) {
      const histLen = this.envelopeHistory.length;
      if (histLen >= 2) {
        const prev = this.envelopeHistory[histLen - 2];
        // É um pico se subiu em relação ao anterior
        if (amplitude > prev * 1.2) {
          this.lastBeatTime = now;
          this.peakHistory.push({
            time: now,
            index: histLen - 1,
            amplitude: amplitude
          });
          // Mantém apenas últimos 20 picos
          if (this.peakHistory.length > 20) {
            this.peakHistory.shift();
          }
        }
      }
    }
  }

  private drawBeatMarkers(ctx: CanvasRenderingContext2D, step: number, baseline: number, height: number): void {
    if (!this.peakHistory || this.peakHistory.length === 0) return;

    const currentHistoryStart = this.envelopeHistory.length - this.ENVELOPE_HISTORY_SIZE;

    for (const peak of this.peakHistory) {
      const relativeIndex = peak.index - currentHistoryStart;
      if (relativeIndex >= 0 && relativeIndex < this.envelopeHistory.length) {
        const x = relativeIndex * step;
        const y = baseline - (peak.amplitude * height * 0.4);

        // Marcador S1 (pico principal)
        ctx.fillStyle = 'rgba(0, 255, 120, 0.8)';
        ctx.beginPath();
        ctx.arc(x, y - 10, 4, 0, Math.PI * 2);
        ctx.fill();

        // Label S1
        ctx.fillStyle = 'rgba(0, 255, 120, 0.6)';
        ctx.font = '10px monospace';
        ctx.fillText('S1', x - 6, y - 18);
      }
    }
  }

  private calculateBPM(): void {
    if (this.peakHistory.length < 3) {
      this.envelopeBPM = 0;
      return;
    }

    // Calcula intervalos entre os últimos picos
    const intervals: number[] = [];
    for (let i = 1; i < this.peakHistory.length; i++) {
      const interval = this.peakHistory[i].time - this.peakHistory[i - 1].time;
      if (interval > 300 && interval < 2000) { // Entre 30 e 200 BPM
        intervals.push(interval);
      }
    }

    if (intervals.length === 0) {
      this.envelopeBPM = 0;
      return;
    }

    // Média dos intervalos
    const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
    this.envelopeBPM = Math.round(60000 / avgInterval);

    // Limita a valores razoáveis
    if (this.envelopeBPM < 40 || this.envelopeBPM > 180) {
      this.envelopeBPM = 0;
    }
  }

  private addDebugLog(tag: string, message: string): void {
    const elapsed = ((Date.now() - this.startTime) / 1000).toFixed(1);
    const timestamp = new Date().toLocaleTimeString('pt-BR');
    const logLine = `[${timestamp}][+${elapsed}s][${tag}] ${message}`;
    
    this.debugLogs.push(logLine);
    
    // Manter apenas os últimos 50 logs
    if (this.debugLogs.length > 50) {
      this.debugLogs.shift();
    }
    
    this.debugLogText = this.debugLogs.join('\n');
    
    // Auto-scroll para o final
    setTimeout(() => {
      if (this.debugTextareaRef?.nativeElement) {
        this.debugTextareaRef.nativeElement.scrollTop = this.debugTextareaRef.nativeElement.scrollHeight;
      }
    });
  }

  copyDebugLog(): void {
    if (this.isBrowser && navigator.clipboard) {
      const header = `=== FONO DEBUG LOG ===\nData: ${new Date().toISOString()}\nRole: ${this.userrole}\nAppointmentId: ${this.appointmentId}\nFrames Locais: ${this.localFrameCount}\nFrames Remotos: ${this.remoteFrameCount}\nHistory Size: ${this.waveformHistory.length}\n\n`;
      navigator.clipboard.writeText(header + this.debugLogText);
      this.addDebugLog('COPY', 'Log copiado para clipboard!');
    }
  }

  clearDebugLog(): void {
    this.debugLogs = [];
    this.debugLogText = '';
    this.startTime = Date.now();
    this.addDebugLog('CLEAR', 'Log limpo');
  }
}
