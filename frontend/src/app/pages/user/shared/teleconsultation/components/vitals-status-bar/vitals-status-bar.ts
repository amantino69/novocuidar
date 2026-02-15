import { Component, Input, OnInit, OnDestroy, OnChanges, SimpleChanges, Inject, PLATFORM_ID, ViewChild, ElementRef, AfterViewChecked, ChangeDetectorRef } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { HttpClient } from '@angular/common/http';

import { IconComponent } from '@shared/components/atoms/icon/icon';
import { MedicalDevicesSyncService, VitalSignsData, PhonocardiogramData } from '@app/core/services/medical-devices-sync.service';
import { BluetoothDevicesService, VitalReading } from '@app/core/services/bluetooth-devices.service';
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
      <!-- GUIA DE DISPOSITIVOS - Aparece para paciente/operador -->
      <div class="device-guide" *ngIf="!isProfessional && showDeviceGuide">
        <div class="guide-header">
          <span>📋 Como usar os dispositivos</span>
          <button class="close-guide" (click)="showDeviceGuide = false">✕</button>
        </div>
        <div class="guide-items">
          <div class="guide-item">
            <span class="guide-icon">⚖️</span>
            <div><strong>Balança</strong><br>Suba na balança e aguarde estabilizar. O peso aparece automaticamente.</div>
          </div>
          <div class="guide-item">
            <span class="guide-icon">💓</span>
            <div><strong>Pressão (Omron)</strong><br>1) Coloque braçadeira e aperte START<br>2) Aguarde medição terminar (~30s)<br>3) <strong>Aperte botão 🔵 Bluetooth</strong> no aparelho</div>
          </div>
          <div class="guide-item">
            <span class="guide-icon">🌡️</span>
            <div><strong>Termômetro</strong><br>Posicione e aguarde o bip. A temperatura é enviada automaticamente.</div>
          </div>
        </div>
      </div>
      
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
          <label>
            <app-icon name="heart" [size]="18" /> Fono
          </label>
          <div class="phono-box">
            @if (phonocardiogram) {
              <div class="phono-waveform" [class.playing]="isPlayingPhono">
                <canvas #waveformCanvas width="200" height="40"></canvas>
                <!-- Linha de progresso animada durante reprodução -->
                @if (isPlayingPhono) {
                  <div class="playhead" [style.left.%]="phonoPlayProgress"></div>
                }
              </div>
              <button class="btn-play" (click)="playPhonocardiogram()" [title]="isPlayingPhono ? 'Pausar' : 'Ouvir fonocardiograma'">
                @if (isPlayingPhono) {
                  ⏸️
                } @else {
                  ▶️
                }
              </button>
              <!-- Tempo de reprodução -->
              @if (isPlayingPhono || phonoPlayProgress > 0) {
                <span class="phono-time">{{ phonoCurrentTime }}s / {{ phonoDuration }}s</span>
              }
              <!-- Seletor de saída de áudio -->
              @if (availableSpeakers.length > 1) {
                <select class="speaker-select" [(ngModel)]="selectedSpeakerId" (ngModelChange)="onSpeakerSelected($event)" title="Saída de áudio">
                  @for (speaker of availableSpeakers; track speaker.deviceId) {
                    <option [value]="speaker.deviceId">🔊 {{ speaker.label || 'Alto-falante ' + ($index + 1) }}</option>
                  }
                </select>
              }
              <audio #phonoAudio [src]="phonocardiogramAudioUrl" (ended)="onPhonogramEnded()" (timeupdate)="onPhonogramTimeUpdate()" style="display:none;"></audio>
              <!-- Análise automática da ausculta -->
              @if (phonoEstimatedBpm !== null) {
                <span class="phono-analysis" [class.good]="phonoBpmDiff !== null && phonoBpmDiff <= 10" [class.warning]="phonoBpmDiff !== null && phonoBpmDiff > 10 && phonoBpmDiff <= 20" [class.bad]="phonoBpmDiff !== null && phonoBpmDiff > 20" [title]="phonoAnalysisMessage">
                  ~{{ phonoEstimatedBpm }} BPM
                  @if (phonoBpmDiff !== null) {
                    <span class="diff">(Δ{{ phonoBpmDiff }})</span>
                  }
                </span>
              } @else if (phonoQuality === 'very_low' || phonoQuality === 'low') {
                <span class="phono-analysis bad" title="Nível de áudio muito baixo - refaça a captura">⚠️ Sinal fraco</span>
              }
              <!-- Botao Nova Captura para paciente/enfermagem -->
              @if (!isProfessional) {
                <button class="btn-nova-captura" (click)="solicitarNovaAusculta()" [disabled]="isCapturingAusculta" title="Nova captura (10s)">
                  @if (isCapturingAusculta) {
                    <span class="spinner-small"></span>
                  } @else {
                    +
                  }
                </button>
              }
            } @else if (!isProfessional) {
              <!-- Selector de tipo de ausculta (cardíaca/pulmonar) -->
              <select class="type-select" [(ngModel)]="auscultationType" title="Tipo de ausculta - define filtros de frequência">
                <option value="cardiac">❤️ Cardíaca (20-300 Hz)</option>
                <option value="pulmonary">🫁 Pulmonar (20-2000 Hz)</option>
              </select>
              <!-- Selector de duracao + Botao Capturar -->
              <select class="duration-select" [(ngModel)]="auscultaDuration" title="Duracao da captura">
                <option value="10">10s</option>
                <option value="15">15s</option>
                <option value="20">20s</option>
                <option value="30">30s</option>
              </select>
              <button class="btn-ausculta" (click)="solicitarAusculta()" [disabled]="isCapturingAusculta || auscultaCountdown > 0" [title]="'Captura ' + auscultaDuration + 's de audio'">
                @if (auscultaCountdown > 0) {
                  <span class="countdown">{{ auscultaCountdown }}</span> Prepare...
                } @else if (isCapturingAusculta) {
                  <span class="live-level" [class.low]="auscultaLiveLevel < 5" [class.good]="auscultaLiveLevel >= 5">{{ auscultaLiveLevel }}%</span> {{ auscultaProgress }}%
                } @else {
                  Capturar
                }
              </button>
            } @else {
              <span class="phono-mic waiting">Aguardando captura...</span>
            }
          </div>
        </div>
        
        <!-- Ações à direita - SIMPLIFICADO -->
        <div class="actions">
          <!-- OPERADOR: Botões BLE para conectar dispositivos via Web Bluetooth -->
          <div class="ble-buttons" *ngIf="!isProfessional">
            <button class="btn-ble" (click)="conectarPressao()" [disabled]="isConnectingBle" title="Conectar Omron (Pressão)">
              <span *ngIf="isConnectingBle && connectingDevice === 'pressure'" class="spinner-small"></span>
              <span *ngIf="!(isConnectingBle && connectingDevice === 'pressure')">💓</span>
              Pressão
            </button>
            <button class="btn-ble" (click)="conectarBalanca()" [disabled]="isConnectingBle" title="Conectar Balança">
              <span *ngIf="isConnectingBle && connectingDevice === 'scale'" class="spinner-small"></span>
              <span *ngIf="!(isConnectingBle && connectingDevice === 'scale')">⚖️</span>
              Balança
            </button>
            <button class="btn-ble btn-eko" (click)="conectarEko()" [disabled]="isConnectingBle" title="Conectar Littmann CORE / Eko">
              <span *ngIf="isConnectingBle && connectingDevice === 'stethoscope'" class="spinner-small"></span>
              <span *ngIf="!(isConnectingBle && connectingDevice === 'stethoscope')">🩺</span>
              Eko
            </button>
            <span *ngIf="!bluetoothAvailable" class="ble-warning" title="Web Bluetooth não disponível neste navegador">⚠️</span>
          </div>
          
          <!-- Indicador de sincronização -->
          <span *ngIf="lastSync" class="sync-info">
            <app-icon name="check-circle" [size]="16" />
            {{ lastSync | date:'HH:mm:ss' }}
          </span>
          
          <!-- Mensagem de captura (temporária) -->
          <span *ngIf="captureMessage" class="msg" [class.ok]="captureSuccess" [class.err]="!captureSuccess">
            {{ captureMessage }}
          </span>
          
          <!-- Botão DEBUG BLE (Android) -->
          <button *ngIf="!isProfessional" class="btn-debug" (click)="toggleBleDebug()" 
                  [class.active]="showBleDebug" title="Ver logs BLE">
            🔧
          </button>
          
          <!-- Botão de ajuda - abre guia de dispositivos -->
          <button *ngIf="!isProfessional && !showDeviceGuide" class="btn-help" (click)="showDeviceGuide = true" title="Como usar os dispositivos">
            ❓
          </button>
          
          <!-- MÉDICO: botão analisar -->
          <button *ngIf="isProfessional" class="btn-analyze" (click)="analisarSinais()" [disabled]="!hasAnyVitals() || isAnalyzing">
            <span *ngIf="isAnalyzing" class="spinner"></span>
            <app-icon *ngIf="!isAnalyzing" name="sparkles" [size]="20" />
            <span>🧠 Analisar</span>
          </button>
        </div>
      </div>
      
      <!-- TOAST DE NOTIFICAÇÃO - Feedback visual para paciente -->
      <div class="device-toast" *ngIf="deviceToast" [class]="'device-toast ' + deviceToast.type">
        <div class="toast-icon">{{ deviceToast.icon }}</div>
        <div class="toast-content">
          <strong>{{ deviceToast.title }}</strong>
          <span>{{ deviceToast.message }}</span>
        </div>
      </div>
      
      <!-- PAINEL DEBUG BLE (para Android sem F12) -->
      <div class="ble-debug-panel" *ngIf="showBleDebug">
        <div class="debug-header">
          <span>🔧 Debug BLE</span>
          <button class="btn-copy" (click)="copyBleDebug()">📋 Copiar</button>
          <button (click)="clearBleDebug()">Limpar</button>
          <button (click)="showBleDebug = false">✕</button>
        </div>
        <div class="debug-logs">
          <div *ngFor="let log of bleDebugLogs" class="debug-line" [class]="log.type">
            <span class="time">{{ log.time }}</span>
            <span class="msg">{{ log.msg }}</span>
          </div>
          <div *ngIf="bleDebugLogs.length === 0" class="debug-empty">
            Aguardando dados BLE...
          </div>
        </div>
        <!-- Mensagem de cópia -->
        <div class="copy-toast" *ngIf="bleCopyMessage">{{ bleCopyMessage }}</div>
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
    
    /* ============ GUIA DE DISPOSITIVOS ============ */
    .device-guide {
      background: linear-gradient(135deg, #1e3a5f, #1e293b);
      border-bottom: 2px solid #3b82f6;
      padding: 12px 24px;
      
      .guide-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 10px;
        font-size: 14px;
        font-weight: 600;
        color: #60a5fa;
        
        .close-guide {
          background: transparent;
          border: none;
          color: #94a3b8;
          font-size: 18px;
          cursor: pointer;
          padding: 4px 8px;
          border-radius: 4px;
          
          &:hover { background: rgba(255,255,255,0.1); color: white; }
        }
      }
      
      .guide-items {
        display: flex;
        gap: 24px;
        flex-wrap: wrap;
      }
      
      .guide-item {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        flex: 1;
        min-width: 200px;
        max-width: 300px;
        background: rgba(255,255,255,0.05);
        padding: 10px 14px;
        border-radius: 8px;
        font-size: 12px;
        line-height: 1.4;
        color: #cbd5e1;
        
        .guide-icon {
          font-size: 24px;
          line-height: 1;
        }
        
        strong {
          color: #f1f5f9;
          font-size: 13px;
        }
      }
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
    
    /* Indicador de Status (substituiu btn-acontecendo) */
    .status-indicator {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 16px;
      border: 2px solid #475569;
      border-radius: 20px;
      font-size: 14px;
      font-weight: 600;
      background: #334155;
      color: #94a3b8;
      
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
    
    /* Botões BLE para conectar dispositivos via Web Bluetooth */
    .ble-buttons {
      display: flex;
      gap: 8px;
      margin-right: 12px;
    }
    
    .btn-ble {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 8px 14px;
      border: none;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      color: white;
      background: linear-gradient(135deg, #3b82f6, #2563eb);
      box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
      
      &:hover:not(:disabled) {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
      }
      
      &:disabled {
        opacity: 0.6;
        cursor: not-allowed;
        transform: none !important;
      }
      
      .spinner-small {
        width: 14px;
        height: 14px;
        border: 2px solid rgba(255,255,255,0.3);
        border-top-color: white;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
      }
    }
    
    .ble-warning {
      font-size: 18px;
      cursor: help;
      opacity: 0.7;
    }
    
    /* Botão de ajuda - abre guia de dispositivos */
    .btn-help {
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 2px solid #3b82f6;
      border-radius: 50%;
      background: rgba(59, 130, 246, 0.2);
      font-size: 18px;
      cursor: pointer;
      transition: all 0.2s;
      
      &:hover {
        background: #3b82f6;
        transform: scale(1.1);
      }
    }
    
    /* Botão DEBUG BLE */
    .btn-debug {
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 2px solid #f59e0b;
      border-radius: 50%;
      background: rgba(245, 158, 11, 0.2);
      font-size: 16px;
      cursor: pointer;
      transition: all 0.2s;
      
      &:hover, &.active {
        background: #f59e0b;
        transform: scale(1.1);
      }
    }
    
    /* Painel Debug BLE (console visual para Android) */
    .ble-debug-panel {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      max-height: 40vh;
      background: #1a1a2e;
      border-top: 3px solid #f59e0b;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      font-family: monospace;
      font-size: 12px;
      
      .debug-header {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 8px 12px;
        background: #16213e;
        border-bottom: 1px solid #f59e0b;
        
        span {
          flex: 1;
          color: #f59e0b;
          font-weight: bold;
        }
        
        button {
          padding: 4px 12px;
          border: 1px solid #555;
          border-radius: 4px;
          background: #2a2a4a;
          color: #fff;
          cursor: pointer;
          
          &:hover {
            background: #3a3a5a;
          }
        }
      }
      
      .debug-logs {
        flex: 1;
        overflow-y: auto;
        padding: 8px;
        
        .debug-line {
          display: flex;
          gap: 8px;
          padding: 3px 6px;
          border-bottom: 1px solid #333;
          
          .time {
            color: #888;
            min-width: 70px;
          }
          
          .msg {
            color: #ddd;
            word-break: break-all;
          }
          
          &.info .msg { color: #60a5fa; }
          &.success .msg { color: #34d399; }
          &.warning .msg { color: #fbbf24; }
          &.error .msg { color: #f87171; }
          &.data .msg { color: #a78bfa; font-weight: bold; }
        }
        
        .debug-empty {
          color: #666;
          text-align: center;
          padding: 20px;
        }
      }
      
      .btn-copy {
        background: #10b981 !important;
        border-color: #10b981 !important;
        font-weight: bold;
      }
      
      .copy-toast {
        position: absolute;
        bottom: 100%;
        left: 50%;
        transform: translateX(-50%);
        background: #10b981;
        color: white;
        padding: 8px 16px;
        border-radius: 8px;
        font-size: 14px;
        font-weight: bold;
        animation: fadeInOut 3s ease;
        white-space: nowrap;
      }
      
      @keyframes fadeInOut {
        0% { opacity: 0; transform: translateX(-50%) translateY(10px); }
        10% { opacity: 1; transform: translateX(-50%) translateY(0); }
        80% { opacity: 1; }
        100% { opacity: 0; }
      }
    }
    
    /* Toast de notificação - Feedback visual para dispositivos BLE */
    .device-toast {
      position: fixed;
      top: 80px;
      right: 20px;
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px 20px;
      border-radius: 12px;
      background: #1e293b;
      color: white;
      box-shadow: 0 10px 40px rgba(0,0,0,0.4);
      z-index: 9999;
      animation: slideIn 0.3s ease-out, fadeOut 0.3s ease-in 4.7s;
      max-width: 350px;
      
      &.success {
        background: linear-gradient(135deg, #059669, #10b981);
        border-left: 4px solid #34d399;
      }
      &.info {
        background: linear-gradient(135deg, #0284c7, #0ea5e9);
        border-left: 4px solid #38bdf8;
      }
      &.warning {
        background: linear-gradient(135deg, #d97706, #f59e0b);
        border-left: 4px solid #fbbf24;
      }
      
      .toast-icon {
        font-size: 32px;
        line-height: 1;
      }
      
      .toast-content {
        display: flex;
        flex-direction: column;
        gap: 2px;
        
        strong {
          font-size: 15px;
          font-weight: 700;
        }
        span {
          font-size: 13px;
          opacity: 0.9;
        }
      }
    }
    
    @keyframes slideIn {
      from { transform: translateX(100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
    
    @keyframes fadeOut {
      from { opacity: 1; }
      to { opacity: 0; }
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
          position: relative;
          
          canvas {
            display: block;
          }
          
          .playhead {
            position: absolute;
            top: 0;
            width: 2px;
            height: 100%;
            background: #dc2626;
            box-shadow: 0 0 4px #dc2626;
            transition: left 0.1s linear;
          }
          
          &.playing {
            box-shadow: 0 0 8px rgba(220, 38, 38, 0.5);
          }
        }
        
        .phono-time {
          font-size: 10px;
          color: #64748b;
          font-family: monospace;
          min-width: 55px;
        }
        
        .speaker-select {
          padding: 3px 5px;
          border: 1px solid #475569;
          border-radius: 4px;
          background: #1e293b;
          color: white;
          font-size: 10px;
          max-width: 100px;
          cursor: pointer;
          
          &:focus {
            border-color: #3b82f6;
            outline: none;
          }
        }
        
        .phono-mic {
          font-size: 11px;
          font-weight: 500;
          color: #10b981;
          background: rgba(16, 185, 129, 0.1);
          padding: 2px 6px;
          border-radius: 4px;
        }

        .phono-mic.waiting {
          font-size: 11px;
          font-weight: 400;
          color: #92400e;
          background: transparent;
          opacity: 0.7;
        }
        
        .phono-analysis {
          font-size: 11px;
          font-weight: 600;
          padding: 2px 8px;
          border-radius: 4px;
          background: #475569;
          color: white;
          
          .diff {
            font-size: 10px;
            font-weight: 400;
            opacity: 0.8;
            margin-left: 2px;
          }
          
          &.good {
            background: #22c55e;
            color: white;
          }
          
          &.warning {
            background: #f59e0b;
            color: #1e293b;
          }
          
          &.bad {
            background: #dc2626;
            color: white;
          }
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
        
        .btn-ausculta {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 6px 12px;
          background: linear-gradient(135deg, #dc2626, #b91c1c);
          color: white;
          border: none;
          border-radius: 6px;
          font-size: 12px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          white-space: nowrap;
          
          &:hover:not(:disabled) {
            transform: scale(1.05);
            background: linear-gradient(135deg, #b91c1c, #991b1b);
          }
          
          &:disabled {
            opacity: 0.7;
            cursor: not-allowed;
          }
        }
        
        .spinner-small {
          width: 12px;
          height: 12px;
          border: 2px solid rgba(255,255,255,0.3);
          border-top-color: white;
          border-radius: 50%;
          animation: spin 0.8s linear infinite;
          display: inline-block;
        }
        
        .duration-select, .mic-select, .type-select {
          padding: 4px 6px;
          border: 1px solid #475569;
          border-radius: 4px;
          background: #1e293b;
          color: white;
          font-size: 11px;
          cursor: pointer;
          outline: none;
          
          &:focus {
            border-color: #3b82f6;
          }
        }
        
        .type-select {
          background: linear-gradient(135deg, #1e3a5f, #1e293b);
          border-color: #3b82f6;
          font-weight: 500;
        }
        
        .mic-select {
          max-width: 120px;
          text-overflow: ellipsis;
        }
        
        .btn-test-mic {
          padding: 4px 8px;
          background: #475569;
          color: white;
          border: none;
          border-radius: 4px;
          font-size: 10px;
          cursor: pointer;
          transition: all 0.2s;
          
          &:hover:not(:disabled) {
            background: #64748b;
          }
          
          &:disabled {
            opacity: 0.5;
            cursor: not-allowed;
          }
          
          &.testing {
            background: #22c55e;
            animation: pulse 0.5s ease-in-out infinite;
          }
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.6; }
        }
        
        .countdown {
          font-size: 16px;
          font-weight: bold;
          color: #fbbf24;
          animation: pulse 0.5s ease-in-out infinite;
        }
        
        .live-level {
          font-size: 11px;
          font-weight: bold;
          padding: 2px 4px;
          border-radius: 3px;
          
          &.low {
            background: #dc2626;
            color: white;
            animation: blink 0.3s ease-in-out infinite;
          }
          
          &.good {
            background: #22c55e;
            color: white;
          }
        }
        
        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.3; }
        }
        
        .btn-nova-captura {
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          border: none;
          border-radius: 50%;
          background: #475569;
          color: white;
          font-size: 12px;
          cursor: pointer;
          transition: all 0.2s;
          margin-left: 4px;
          
          &:hover:not(:disabled) {
            background: #64748b;
            transform: scale(1.1);
          }
          
          &:disabled {
            opacity: 0.5;
            cursor: not-allowed;
          }
        }
      }
      
      .mic-info {
        display: flex;
        align-items: center;
        gap: 6px;
        margin-top: 6px;
        padding: 4px 10px;
        background: rgba(30, 41, 59, 0.8);
        border-radius: 4px;
        border-left: 3px solid #3b82f6;
        
        .mic-icon {
          font-size: 10px;
          font-weight: 700;
          color: #64748b;
        }
        
        .mic-name {
          font-size: 11px;
          font-weight: 500;
          color: #10b981;
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
        flex-wrap: wrap;
        
        app-icon { color: #64748b; }
        
        .mic-label {
          display: block;
          width: 100%;
          font-size: 9px;
          font-weight: 500;
          color: #10b981;
          text-transform: none;
          letter-spacing: 0;
          margin-top: 2px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 120px;
        }
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
  @Input() userRole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' | 'REGULATOR' = 'PATIENT';

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
  isCapturingAusculta = false;
  isAnalyzing = false;
  captureMessage = '';
  captureSuccess = false;
  lastSync: Date | null = null;
  isAcontecendo = false;  // Controle interno (marcar automaticamente)
  isConnected = false;    // Indicador de conexão SignalR
  showDeviceGuide = true; // Guia de uso dos dispositivos (visível inicialmente)
  auscultaDuration = 10;  // Duração da captura de ausculta em segundos

  // DEBUG BLE (console visual para Android)
  showBleDebug = false;
  bleDebugLogs: { time: string; msg: string; type: 'info' | 'success' | 'warning' | 'error' | 'data' }[] = [];
  bleCopyMessage = '';  // Mensagem de feedback ao copiar

  // Toast de notificação para feedback visual de dispositivos
  deviceToast: { icon: string; title: string; message: string; type: 'success' | 'info' | 'warning' } | null = null;
  private toastTimeout: any = null;

  // Fonocardiograma - Estetoscópio Digital
  phonocardiogram: PhonocardiogramData | null = null;
  phonocardiogramAudioUrl = '';
  isPlayingPhono = false;
  private needsWaveformRedraw = false;

  // Reprodução de áudio - progresso e tempo
  phonoPlayProgress = 0;  // 0-100% para a linha animada
  phonoCurrentTime = 0;  // Tempo atual em segundos
  phonoDuration = 0;  // Duração total em segundos

  // Seletor de saída de áudio (speakers)
  availableSpeakers: MediaDeviceInfo[] = [];
  selectedSpeakerId = '';

  // Análise automática de FC do fonocardiograma
  phonoEstimatedBpm: number | null = null;
  phonoQuality: 'unknown' | 'very_low' | 'low' | 'good' | 'high' = 'unknown';
  phonoBpmDiff: number | null = null;  // Diferença com dispositivos
  phonoAnalysisMessage = '';  // Mensagem de comparação

  // Microfone atual do navegador (detectado dinamicamente)
  currentBrowserMicrophone = 'Detectando...';

  // Seletor de microfone para ausculta
  availableMicrophones: MediaDeviceInfo[] = [];
  selectedMicrophoneId = '';  // vazio = padrão do sistema
  selectedMicrophoneName = '';
  isTestingMic = false;  // Indica se está testando microfone
  micTestLevel = 0;  // Nível de áudio durante teste (0-100)

  // Feedback em tempo real durante captura
  auscultaCountdown = 0;  // Countdown antes de iniciar (3, 2, 1)
  auscultaProgress = 0;  // Progresso da gravação (0-100%)
  auscultaLiveLevel = 0;  // Nível de áudio em tempo real durante gravação
  auscultaMaxLevel = 0;  // Maior nível detectado durante gravação

  // Tipo de ausculta: cardíaca (20-300Hz) ou pulmonar (20-2000Hz)
  auscultationType: 'cardiac' | 'pulmonary' = 'cardiac';

  // Web Bluetooth
  bluetoothAvailable = false;
  isConnectingBle = false;
  connectingDevice: 'pressure' | 'scale' | 'stethoscope' | null = null;

  // Eko/Littmann CORE - serviços descobertos
  ekoConnected = false;
  ekoServices: string[] = [];

  private subscriptions = new Subscription();
  private patientData: User | null = null;
  private syncTimeout: any = null;

  get isProfessional(): boolean {
    return this.userRole === 'PROFESSIONAL';
  }

  constructor(
    private medicalDevicesSync: MedicalDevicesSyncService,
    private bluetoothService: BluetoothDevicesService,
    private usersService: UsersService,
    private aiService: AIService,
    private modalService: ModalService,
    private http: HttpClient,
    private cdr: ChangeDetectorRef,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    this.bluetoothAvailable = this.bluetoothService.isBluetoothAvailable();
  }

  ngOnInit(): void {
    this.setupSubscriptions();

    // Subscreve ao status de conexão SignalR
    const connectionSub = this.medicalDevicesSync.isConnected$.subscribe(
      connected => {
        this.isConnected = connected;
        console.log('[VitalsBar] SignalR conectado:', connected);

        // Ao reconectar (ex: após refresh), recarrega biometrics do backend
        if (connected && this.appointmentId) {
          this.loadBiometricsFromBackend();
        }
      }
    );
    this.subscriptions.add(connectionSub);

    // Subscreve aos logs de debug do Bluetooth (para painel visual no Android)
    const debugSub = this.bluetoothService.debugLog$.subscribe(log => {
      this.addBleDebug(log.msg, log.type);
    });
    this.subscriptions.add(debugSub);

    // Carrega biometrics salvos do backend (para refresh da página)
    if (this.appointmentId) {
      this.loadBiometricsFromBackend();
    }

    // AUTO-MARCAR como "acontecendo" quando entrar (não-profissional)
    if (!this.isProfessional && this.appointmentId) {
      this.autoMarcarAcontecendo();
    }

    // Detecta microfone do navegador (para mostrar ao lado do fono)
    this.detectBrowserMicrophone();
    this.listenMicrophoneChanges();
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
        console.log('[VitalsBar] Fonocardiograma chegou! data.appointmentId:', data.appointmentId, 'this.appointmentId:', this.appointmentId);
        // Aceita o fonocardiograma se for da consulta atual OU se não tiver appointmentId definido
        if (data.appointmentId === this.appointmentId || !this.appointmentId) {
          console.log('[VitalsBar] Fonocardiograma aceito:', data);
          this.phonocardiogram = data;
          if (data.audioUrl) {
            this.phonocardiogramAudioUrl = environment.apiUrl.replace('/api', '') + data.audioUrl;
          }
          // NOTA: NÃO atualiza FC com heartRate da ausculta - cálculo impreciso
          // O médico avalia o som diretamente

          // Marcar para redesenhar waveform após Angular criar o canvas (próximo ciclo)
          if (data.waveform && data.waveform.length > 0) {
            // Timeout para aguardar o @if criar o canvas no DOM
            setTimeout(() => {
              this.needsWaveformRedraw = true;
              this.cdr.detectChanges();
            }, 100);

            // Análise automática do waveform
            this.analyzePhonoBpm(data.waveform, data.durationSeconds || 10);
          }
          this.lastSync = new Date();
          this.isCapturingAusculta = false; // Parar spinner do botão
          this.cdr.detectChanges();
        }
      })
    );
  }

  /**
   * Analisa o waveform do fonocardiograma para estimar FC
   * Compara com a FC de dispositivos médicos
   */
  private analyzePhonoBpm(waveform: number[], durationSeconds: number): void {
    if (!waveform || waveform.length < 50) {
      this.phonoEstimatedBpm = null;
      this.phonoQuality = 'unknown';
      return;
    }

    // Calcula RMS para avaliar qualidade
    const rms = Math.sqrt(waveform.reduce((sum, v) => sum + v * v, 0) / waveform.length);

    if (rms < 0.01) {
      this.phonoQuality = 'very_low';
      this.phonoEstimatedBpm = null;
      this.phonoAnalysisMessage = 'Nível de áudio muito baixo - estetoscópio mal posicionado?';
      return;
    } else if (rms < 0.03) {
      this.phonoQuality = 'low';
    } else if (rms < 0.15) {
      this.phonoQuality = 'good';
    } else {
      this.phonoQuality = 'high';
    }

    // Detecção de picos (batimentos) simplificada
    const mean = waveform.reduce((a, b) => a + b, 0) / waveform.length;
    const std = Math.sqrt(waveform.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / waveform.length);
    const threshold = mean + 0.5 * std;

    // Encontra picos
    const peaks: number[] = [];
    const minDistance = Math.floor(waveform.length / (durationSeconds * 3.3));  // Max 200 BPM
    let lastPeak = -minDistance;

    for (let i = 1; i < waveform.length - 1; i++) {
      if (waveform[i] > waveform[i - 1] &&
        waveform[i] > waveform[i + 1] &&
        waveform[i] > threshold &&
        i - lastPeak >= minDistance) {
        peaks.push(i);
        lastPeak = i;
      }
    }

    console.log(`[VitalsBar] Análise ausculta: RMS=${rms.toFixed(3)}, Picos=${peaks.length}, Duração=${durationSeconds}s`);

    if (peaks.length >= 2) {
      // Calcula intervalo médio entre picos
      const intervals: number[] = [];
      for (let i = 1; i < peaks.length; i++) {
        intervals.push(peaks[i] - peaks[i - 1]);
      }

      const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
      const samplesPerSecond = waveform.length / durationSeconds;
      const avgIntervalSeconds = avgInterval / samplesPerSecond;

      const estimatedBpm = Math.round(60 / avgIntervalSeconds);

      // Validação: FC deve estar entre 40-180 BPM
      if (estimatedBpm >= 40 && estimatedBpm <= 180) {
        this.phonoEstimatedBpm = estimatedBpm;

        // Compara com FC de dispositivos
        if (this.heartRate) {
          this.phonoBpmDiff = Math.abs(estimatedBpm - this.heartRate);

          if (this.phonoBpmDiff <= 10) {
            this.phonoAnalysisMessage = `FC ausculta ~${estimatedBpm} BPM - Compatível com dispositivo (${this.heartRate} BPM). Diferença: ${this.phonoBpmDiff} BPM ✓`;
          } else if (this.phonoBpmDiff <= 20) {
            this.phonoAnalysisMessage = `FC ausculta ~${estimatedBpm} BPM - Diferença moderada com dispositivo (${this.heartRate} BPM). Δ${this.phonoBpmDiff} BPM`;
          } else {
            this.phonoAnalysisMessage = `FC ausculta ~${estimatedBpm} BPM - Diferença alta com dispositivo (${this.heartRate} BPM). Δ${this.phonoBpmDiff} BPM - Considere refazer`;
          }
        } else {
          this.phonoBpmDiff = null;
          this.phonoAnalysisMessage = `FC ausculta estimada: ~${estimatedBpm} BPM (sem medição de dispositivo para comparar)`;
        }

        console.log(`[VitalsBar] ${this.phonoAnalysisMessage}`);
      } else {
        this.phonoEstimatedBpm = null;
        this.phonoAnalysisMessage = `FC fora do esperado (${estimatedBpm} BPM) - possível ruído ou posicionamento`;
      }
    } else {
      this.phonoEstimatedBpm = null;
      this.phonoAnalysisMessage = 'Poucos batimentos detectados - verifique posicionamento do estetoscópio';
    }
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

    // Detecta quais medições chegaram para mostrar notificação
    const newMeasurements: string[] = [];

    if (v.weight != null && v.weight !== this.weight) {
      this.weight = v.weight;
      newMeasurements.push(`Peso: ${v.weight} kg`);
    }
    if (v.height != null) this.height = v.height;
    if (v.spo2 != null && v.spo2 !== this.spo2) {
      this.spo2 = v.spo2;
      newMeasurements.push(`SpO₂: ${v.spo2}%`);
    }
    if (v.pulseRate != null && v.pulseRate !== this.heartRate) {
      this.heartRate = v.pulseRate;
      newMeasurements.push(`FC: ${v.pulseRate} bpm`);
    }
    if (v.heartRate != null && v.heartRate !== this.heartRate) {
      this.heartRate = v.heartRate;
      if (!newMeasurements.some(m => m.includes('FC'))) {
        newMeasurements.push(`FC: ${v.heartRate} bpm`);
      }
    }
    if (v.systolic != null && v.systolic !== this.systolic) {
      this.systolic = v.systolic;
      if (v.diastolic != null) {
        this.diastolic = v.diastolic;
        newMeasurements.push(`PA: ${v.systolic}/${v.diastolic} mmHg`);
      }
    } else if (v.diastolic != null) {
      this.diastolic = v.diastolic;
    }
    if (v.temperature != null && v.temperature !== this.temperature) {
      this.temperature = v.temperature;
      newMeasurements.push(`Temp: ${v.temperature}°C`);
    }
    if (v.gender) this.patientGender = v.gender;
    if (v.birthDate) this.patientAge = this.calculateAge(new Date(v.birthDate));

    this.calculateIMC();
    this.lastSync = new Date(data.timestamp);

    // Mostra notificação visual se chegaram novas medições
    if (newMeasurements.length > 0 && !this.isProfessional) {
      this.showDeviceToast('⚕️', 'Medição Recebida!', newMeasurements.join(' • '), 'success');
    }
  }

  /** Mostra toast de notificação para o paciente */
  private showDeviceToast(icon: string, title: string, message: string, type: 'success' | 'info' | 'warning'): void {
    // Limpa timeout anterior
    if (this.toastTimeout) {
      clearTimeout(this.toastTimeout);
    }

    // Mostra o toast
    this.deviceToast = { icon, title, message, type };

    // Remove após 5 segundos
    this.toastTimeout = setTimeout(() => {
      this.deviceToast = null;
    }, 5000);
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
   * Carrega os biometrics salvos do backend (para restaurar após refresh)
   */
  private loadBiometricsFromBackend(): void {
    if (!this.appointmentId) return;

    const url = `${environment.apiUrl}/biometrics?appointmentId=${this.appointmentId}`;
    console.log('[VitalsBar] 📥 Carregando biometrics do backend...');

    this.http.get<any>(url).subscribe({
      next: (biometrics) => {
        if (biometrics) {
          console.log('[VitalsBar] ✅ Biometrics carregados:', biometrics);

          // Aplica os valores carregados
          if (biometrics.weight) this.weight = biometrics.weight;
          if (biometrics.height) this.height = biometrics.height;
          if (biometrics.bloodPressureSystolic) this.systolic = biometrics.bloodPressureSystolic;
          if (biometrics.bloodPressureDiastolic) this.diastolic = biometrics.bloodPressureDiastolic;
          if (biometrics.heartRate) this.heartRate = biometrics.heartRate;
          if (biometrics.oxygenSaturation) this.spo2 = biometrics.oxygenSaturation;
          if (biometrics.temperature) this.temperature = biometrics.temperature;

          this.calculateIMC();
          this.cdr.detectChanges();
        }
      },
      error: (err) => {
        console.warn('[VitalsBar] Erro ao carregar biometrics:', err);
      }
    });
  }

  /**
   * Marca automaticamente a consulta como "Acontecendo" ao entrar na teleconsulta
   * Isso permite que a maleta envie sinais para esta consulta automaticamente
   */
  private async autoMarcarAcontecendo(): Promise<void> {
    if (!this.appointmentId) return;

    try {
      await this.http.post(`${environment.apiUrl}/biometrics/acontecendo/${this.appointmentId}`, {}).toPromise();
      this.isAcontecendo = true;
      console.log('[VitalsBar] 🟢 AUTO: Consulta marcada como acontecendo:', this.appointmentId);
    } catch (error) {
      console.error('[VitalsBar] Erro ao auto-marcar acontecendo:', error);
    }
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
      // SEGURANÇA: Passa appointmentId para garantir dados são desta consulta
      const url = `${environment.apiUrl}/biometrics/ble-cache?appointmentId=${this.appointmentId}`;
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
        this.onPhonogramEnded();
      };
      this.phonoAudioPlayer.ontimeupdate = () => {
        this.onPhonogramTimeUpdate();
        this.cdr.detectChanges();  // Força atualização da UI
      };
      this.phonoAudioPlayer.onerror = (e) => {
        console.error('[VitalsBar] Erro no áudio:', e);
        this.isPlayingPhono = false;
      };

      // Configura saída de áudio selecionada (se suportado)
      if (this.selectedSpeakerId && 'setSinkId' in this.phonoAudioPlayer) {
        (this.phonoAudioPlayer as any).setSinkId(this.selectedSpeakerId)
          .then(() => console.log('[VitalsBar] Saída de áudio configurada:', this.selectedSpeakerId))
          .catch((e: any) => console.warn('[VitalsBar] Não foi possível configurar saída:', e));
      }
    }

    // Atualiza URL e toca
    this.phonoAudioPlayer.src = this.phonocardiogramAudioUrl;

    // Força interação do usuário para permitir play
    this.phonoAudioPlayer.muted = false;
    this.phonoAudioPlayer.volume = 1.0;

    this.phonoAudioPlayer.play().then(() => {
      this.isPlayingPhono = true;
      this.phonoDuration = Math.round(this.phonoAudioPlayer!.duration || 0);
      console.log('[VitalsBar] ▶️ Tocando fonocardiograma');
    }).catch(err => {
      console.error('[VitalsBar] Erro ao reproduzir:', err);
      // Pergunta se quer abrir em nova aba
      if (confirm('O áudio não pôde ser reproduzido diretamente.\n\nDeseja abrir em uma nova aba?')) {
        window.open(this.phonocardiogramAudioUrl, '_blank');
      }
    });
  }

  /**
   * Handler quando o fonocardiograma termina de tocar
   */
  onPhonogramEnded(): void {
    this.isPlayingPhono = false;
    this.phonoPlayProgress = 0;
    this.phonoCurrentTime = 0;
    console.log('[VitalsBar] ⏹️ Fonocardiograma terminou');
  }

  /**
   * Handler para atualização de tempo do fonocardiograma
   */
  onPhonogramTimeUpdate(): void {
    if (this.phonoAudioPlayer) {
      const current = this.phonoAudioPlayer.currentTime || 0;
      const duration = this.phonoAudioPlayer.duration || 1;
      this.phonoCurrentTime = Math.round(current);
      this.phonoDuration = Math.round(duration);
      this.phonoPlayProgress = (current / duration) * 100;
    }
  }

  /**
   * Handler quando usuário seleciona um alto-falante para saída de áudio
   */
  async onSpeakerSelected(deviceId: string): Promise<void> {
    this.selectedSpeakerId = deviceId;
    console.log('[VitalsBar] Alto-falante selecionado:', deviceId);

    // Se tiver um player de áudio ativo, muda a saída
    if (this.phonoAudioPlayer && 'setSinkId' in this.phonoAudioPlayer) {
      try {
        await (this.phonoAudioPlayer as any).setSinkId(deviceId);
        console.log('[VitalsBar] Saída de áudio alterada para:', deviceId);
      } catch (err) {
        console.error('[VitalsBar] Erro ao mudar saída de áudio:', err);
      }
    }
  }

  /**
   * Solicita captura de ausculta on-demand.
   * Envia requisição para o backend, que fica aguardando o script Python buscar.
   */
  solicitarAusculta(): void {
    const duration = parseInt(String(this.auscultaDuration), 10) || 10;
    this.executarSolicitacaoAusculta(duration);
  }

  /**
   * Solicita nova captura - limpa estado e volta ao modo inicial
   * Permite escolher nova duração antes de iniciar
   */
  solicitarNovaAusculta(): void {
    // Limpa o fonocardiograma atual para voltar ao estado inicial
    this.phonocardiogram = null;
    this.phonocardiogramAudioUrl = '';
    this.isPlayingPhono = false;
    // Não executa automaticamente - usuário escolhe duração e clica em Capturar
  }

  /**
   * Executa a captura de ausculta DIRETAMENTE do microfone do navegador
   * Usado quando não há PC - tablet captura direto do microfone
   */
  private async executarSolicitacaoAusculta(duration: number): Promise<void> {
    if (!this.appointmentId) {
      console.error('[VitalsBar] appointmentId não definido');
      return;
    }

    // Countdown 3-2-1 antes de iniciar
    this.auscultaCountdown = 3;
    this.auscultaMaxLevel = 0;
    this.showDeviceToast('⏱️', 'Preparar', 'Posicione o estetoscópio...', 'info');

    for (let i = 3; i > 0; i--) {
      this.auscultaCountdown = i;
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    this.auscultaCountdown = 0;

    this.isCapturingAusculta = true;
    this.auscultaProgress = 0;
    this.auscultaLiveLevel = 0;
    console.log(`[VitalsBar] Iniciando captura de ausculta do microfone (${duration}s)...`);
    this.showDeviceToast('🔴', 'GRAVANDO', `Mantenha o estetoscópio posicionado...`, 'warning');

    try {
      // 1. Solicita acesso ao microfone (usa selecionado ou padrão)
      const audioConstraints: MediaTrackConstraints = {
        echoCancellation: false,
        noiseSuppression: false,
        autoGainControl: false,
        sampleRate: 8000,
        channelCount: 1
      };

      // Se usuário selecionou microfone específico para ausculta, usa ele
      if (this.selectedMicrophoneId) {
        audioConstraints.deviceId = { exact: this.selectedMicrophoneId };
        console.log(`[VitalsBar] Usando microfone específico: ${this.selectedMicrophoneName}`);
      } else {
        console.log('[VitalsBar] Usando microfone padrão');
      }

      const stream = await navigator.mediaDevices.getUserMedia({ audio: audioConstraints });

      // 2. Configura AudioContext para captura em PCM
      const audioContext = new AudioContext({ sampleRate: 8000 });
      const source = audioContext.createMediaStreamSource(stream);

      // Configuração de filtros baseada no tipo de ausculta
      // - Cardíaca: 20-300 Hz (S1, S2, S3, S4, murmúrios básicos)
      // - Pulmonar: 20-2000 Hz (roncos <200Hz, sibilos >400Hz, crepitações)
      const isCardiac = this.auscultationType === 'cardiac';
      const lowpassFreq = isCardiac ? 300 : 2000;  // Hz

      console.log(`[VitalsBar] Tipo de ausculta: ${this.auscultationType} - Lowpass: ${lowpassFreq} Hz`);

      // Filtro passa-alta para remover ruído de baixa frequência (movimento, vento)
      const highpass = audioContext.createBiquadFilter();
      highpass.type = 'highpass';
      highpass.frequency.value = 20; // Corta abaixo de 20 Hz
      highpass.Q.value = 0.7;

      // Filtro passa-baixa: frequência varia conforme tipo de ausculta
      const lowpass = audioContext.createBiquadFilter();
      lowpass.type = 'lowpass';
      lowpass.frequency.value = lowpassFreq;
      lowpass.Q.value = 0.7;

      // Filtro notch para remover ruído de rede elétrica (60 Hz Brasil + harmônicos)
      // Aplicado em ambos os modos para remover interferência elétrica
      const notch60 = audioContext.createBiquadFilter();
      notch60.type = 'notch';
      notch60.frequency.value = 60;
      notch60.Q.value = 30; // Q alto = corte mais estreito

      const notch120 = audioContext.createBiquadFilter();
      notch120.type = 'notch';
      notch120.frequency.value = 120; // Segundo harmônico
      notch120.Q.value = 30;

      const notch180 = audioContext.createBiquadFilter();
      notch180.type = 'notch';
      notch180.frequency.value = 180; // Terceiro harmônico
      notch180.Q.value = 30;

      console.log(`[VitalsBar] Filtros aplicados: highpass 20Hz, lowpass ${lowpassFreq}Hz, notch 60/120/180 Hz`);

      const processor = audioContext.createScriptProcessor(4096, 1, 1);

      const audioChunks: Float32Array[] = [];
      let samplesCollected = 0;
      const targetSamples = duration * 8000; // 8kHz por X segundos

      processor.onaudioprocess = (e) => {
        if (samplesCollected >= targetSamples) return;

        const inputData = e.inputBuffer.getChannelData(0);
        audioChunks.push(new Float32Array(inputData));
        samplesCollected += inputData.length;

        // Calcula nível de áudio em tempo real (RMS)
        let sum = 0;
        for (let i = 0; i < inputData.length; i++) {
          sum += inputData[i] * inputData[i];
        }
        const rms = Math.sqrt(sum / inputData.length);
        const level = Math.min(100, Math.round(rms * 500)); // Escala para 0-100
        this.auscultaLiveLevel = level;
        if (level > this.auscultaMaxLevel) {
          this.auscultaMaxLevel = level;
        }

        // Atualiza progresso
        this.auscultaProgress = Math.min(100, Math.round((samplesCollected / targetSamples) * 100));
      };

      // Encadeia filtros: source -> highpass -> lowpass -> notch60 -> notch120 -> notch180 -> processor
      source.connect(highpass);
      highpass.connect(lowpass);
      lowpass.connect(notch60);
      notch60.connect(notch120);
      notch120.connect(notch180);
      notch180.connect(processor);
      processor.connect(audioContext.destination);

      // 3. Aguarda duração da gravação
      await new Promise(resolve => setTimeout(resolve, duration * 1000));

      // 4. Para a gravação
      processor.disconnect();
      source.disconnect();
      stream.getTracks().forEach(track => track.stop());
      await audioContext.close();

      console.log(`[VitalsBar] Captura concluída. Processando ${audioChunks.length} chunks... Max level: ${this.auscultaMaxLevel}%`);

      // Verifica qualidade da captura
      if (this.auscultaMaxLevel < 5) {
        this.showDeviceToast('⚠️', 'Nível Baixo', 'Estetoscópio mal posicionado? Tente novamente.', 'warning');
        console.warn('[VitalsBar] Gravação com nível muito baixo - possível problema de posicionamento');
      } else {
        this.showDeviceToast('⏳', 'Processando', `Nível máx: ${this.auscultaMaxLevel}% - Enviando...`, 'info');
      }

      // 5. Combina chunks em um único array
      const totalSamples = audioChunks.reduce((sum, chunk) => sum + chunk.length, 0);
      const combinedAudio = new Float32Array(totalSamples);
      let offset = 0;
      for (const chunk of audioChunks) {
        combinedAudio.set(chunk, offset);
        offset += chunk.length;
      }

      // 6. Converte Float32 (-1 a 1) para Int16 (PCM 16-bit)
      const pcmData = new Int16Array(combinedAudio.length);
      for (let i = 0; i < combinedAudio.length; i++) {
        const s = Math.max(-1, Math.min(1, combinedAudio[i]));
        pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
      }

      // 7. Converte para Base64
      const pcmBytes = new Uint8Array(pcmData.buffer);
      const base64Audio = this.arrayBufferToBase64(pcmBytes);

      // 8. Gera waveform simplificado (500 pontos)
      const waveform = this.generateWaveform(combinedAudio, 500);

      // 9. Envia para o backend
      await this.enviarFonocardiograma(base64Audio, 8000, duration, waveform);

    } catch (error: any) {
      console.error('[VitalsBar] Erro ao capturar ausculta:', error);
      this.showDeviceToast('❌', 'Erro', error.message || 'Falha ao acessar microfone', 'warning');
    } finally {
      this.isCapturingAusculta = false;
    }
  }

  /**
   * Converte ArrayBuffer para Base64
   */
  private arrayBufferToBase64(buffer: Uint8Array): string {
    let binary = '';
    const len = buffer.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(buffer[i]);
    }
    return btoa(binary);
  }

  /**
   * Gera waveform simplificado para visualização
   */
  private generateWaveform(samples: Float32Array, numPoints: number): number[] {
    const waveform: number[] = [];
    const samplesPerPoint = Math.floor(samples.length / numPoints);

    for (let i = 0; i < numPoints; i++) {
      let sum = 0;
      const start = i * samplesPerPoint;
      const end = Math.min(start + samplesPerPoint, samples.length);

      for (let j = start; j < end; j++) {
        sum += Math.abs(samples[j]);
      }

      waveform.push(sum / (end - start));
    }

    // Normaliza para 0-1
    const max = Math.max(...waveform);
    return waveform.map(v => max > 0 ? v / max : 0);
  }

  /**
   * Envia fonocardiograma para o backend
   */
  private async enviarFonocardiograma(audioBase64: string, sampleRate: number, duration: number, waveform: number[]): Promise<void> {
    const payload = {
      appointmentId: this.appointmentId,
      deviceType: 'stethoscope',
      audioData: audioBase64,
      sampleRate: sampleRate,
      format: 'pcm_s16le',
      durationSeconds: duration,
      waveform: waveform,
      values: {
        quality: 3  // Qualidade média (microfone comum)
      },
      timestamp: new Date().toISOString()
    };

    try {
      const response = await this.http.post(`${environment.apiUrl}/biometrics/phonocardiogram`, payload).toPromise();
      console.log('[VitalsBar] Fonocardiograma enviado:', response);
      this.showDeviceToast('✅', 'Ausculta Enviada', `${duration}s de áudio capturado`, 'success');
    } catch (error: any) {
      console.error('[VitalsBar] Erro ao enviar fonocardiograma:', error);
      throw error;
    }
  }

  /**
   * Detecta o microfone padrão do navegador e carrega lista de microfones disponíveis
   */
  private async detectBrowserMicrophone(): Promise<void> {
    if (!isPlatformBrowser(this.platformId)) {
      this.currentBrowserMicrophone = 'N/A (SSR)';
      return;
    }

    try {
      // Solicita permissão de microfone (necessário para listar dispositivos)
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach(track => track.stop()); // Para o stream imediatamente

      const devices = await navigator.mediaDevices.enumerateDevices();
      const audioInputs = devices.filter(d => d.kind === 'audioinput');

      // Salva lista de microfones disponíveis para o seletor
      this.availableMicrophones = audioInputs.filter(d => d.deviceId !== 'default');
      console.log('[VitalsBar] Microfones disponíveis:', this.availableMicrophones.length);

      if (audioInputs.length === 0) {
        this.currentBrowserMicrophone = 'Nenhum';
        return;
      }

      // Encontra o microfone padrão (geralmente o primeiro ou o marcado como default)
      const defaultMic = audioInputs.find(d => d.deviceId === 'default') || audioInputs[0];

      // Formata o nome para exibição
      let micName = defaultMic.label || 'Microfone ' + (audioInputs.indexOf(defaultMic) + 1);

      // Remove prefixo "Default - " mas mantém o resto
      micName = micName.replace(/^Default\s*-\s*/i, '');

      // Se o nome é genérico como "Microfone" mas tem info entre parênteses, usa ela
      // Ex: "Microfone (KT USB Audio)" -> "KT USB Audio"
      const parenthesesMatch = micName.match(/\(([^)]+)\)/);
      if (parenthesesMatch && parenthesesMatch[1]) {
        const inParentheses = parenthesesMatch[1].trim();
        // Se tem conteúdo útil entre parênteses, usa como nome principal
        if (inParentheses.length > 3 && !inParentheses.match(/^\d+$/)) {
          micName = inParentheses;
        }
      }

      // Limita tamanho
      if (micName.length > 30) {
        micName = micName.substring(0, 27) + '...';
      }

      this.currentBrowserMicrophone = micName;
      console.log('[VitalsBar] Microfone detectado:', micName);

      // Carrega também lista de alto-falantes (saída de áudio)
      const audioOutputs = devices.filter(d => d.kind === 'audiooutput');
      this.availableSpeakers = audioOutputs.filter(d => d.deviceId !== 'default' && d.deviceId !== 'communications');
      console.log('[VitalsBar] Alto-falantes disponíveis:', this.availableSpeakers.length);

      // Se tiver speakers disponíveis, seleciona o primeiro por padrão
      if (this.availableSpeakers.length > 0 && !this.selectedSpeakerId) {
        this.selectedSpeakerId = this.availableSpeakers[0].deviceId;
      }
    } catch (error) {
      console.warn('[VitalsBar] Erro ao detectar microfone:', error);
      this.currentBrowserMicrophone = 'Sem permissao';
    }
  }

  /**
   * Handler quando usuário seleciona um microfone para ausculta
   */
  onMicrophoneSelected(deviceId: string): void {
    this.selectedMicrophoneId = deviceId;

    if (deviceId) {
      const mic = this.availableMicrophones.find(m => m.deviceId === deviceId);
      if (mic) {
        let name = mic.label || 'Microfone';
        // Simplifica o nome
        const match = name.match(/\(([^)]+)\)/);
        if (match && match[1] && match[1].length > 3) {
          name = match[1];
        }
        if (name.length > 25) {
          name = name.substring(0, 22) + '...';
        }
        this.selectedMicrophoneName = name;
        console.log('[VitalsBar] Microfone selecionado para ausculta:', name);
      }
    } else {
      this.selectedMicrophoneName = '';
      console.log('[VitalsBar] Usando microfone padrão para ausculta');
    }
  }

  /**
   * Testa o microfone selecionado para verificar se está capturando áudio
   * Mostra nível de áudio em tempo real por 3 segundos
   */
  async testarMicrofone(): Promise<void> {
    if (this.isTestingMic) return;

    this.isTestingMic = true;
    this.micTestLevel = 0;

    const micName = this.selectedMicrophoneName || this.currentBrowserMicrophone;
    console.log(`[VitalsBar] Testando microfone: ${micName}`);
    this.showDeviceToast('🎤', 'Testando Microfone', `${micName} - Fale ou faça som...`, 'info');

    try {
      // Configura constraints do microfone
      const audioConstraints: MediaTrackConstraints = {
        echoCancellation: false,
        noiseSuppression: false,
        autoGainControl: false
      };

      if (this.selectedMicrophoneId) {
        audioConstraints.deviceId = { exact: this.selectedMicrophoneId };
      }

      // Obtém stream do microfone
      const stream = await navigator.mediaDevices.getUserMedia({ audio: audioConstraints });

      // Cria analisador de áudio
      const audioContext = new AudioContext();
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);

      const dataArray = new Uint8Array(analyser.frequencyBinCount);

      // Monitora nível de áudio por 3 segundos
      const startTime = Date.now();
      const testDuration = 3000; // 3 segundos

      const updateLevel = () => {
        if (Date.now() - startTime >= testDuration) {
          // Finaliza teste
          stream.getTracks().forEach(track => track.stop());
          audioContext.close();
          this.isTestingMic = false;

          if (this.micTestLevel > 10) {
            this.showDeviceToast('✅', 'Microfone OK', `${micName} está funcionando!`, 'success');
          } else {
            this.showDeviceToast('⚠️', 'Sem áudio', `${micName} não captou som. Verifique conexão.`, 'warning');
          }
          return;
        }

        // Calcula nível de áudio (RMS)
        analyser.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i] * dataArray[i];
        }
        const rms = Math.sqrt(sum / dataArray.length);
        const level = Math.min(100, Math.round((rms / 128) * 100));

        // Mantém o maior nível detectado
        if (level > this.micTestLevel) {
          this.micTestLevel = level;
        }

        requestAnimationFrame(updateLevel);
      };

      updateLevel();

    } catch (error: any) {
      console.error('[VitalsBar] Erro ao testar microfone:', error);
      this.showDeviceToast('❌', 'Erro', error.message || 'Falha ao acessar microfone', 'warning');
      this.isTestingMic = false;
    }
  }

  /**
   * Escuta mudanças nos dispositivos de mídia (quando usuário troca microfone)
   */
  private listenMicrophoneChanges(): void {
    if (!isPlatformBrowser(this.platformId)) return;

    navigator.mediaDevices.addEventListener('devicechange', () => {
      console.log('[VitalsBar] Dispositivos de midia alterados - redetectando microfone...');
      this.detectBrowserMicrophone();
    });
  }

  // ========== WEB BLUETOOTH (TABLET ANDROID) ==========

  /**
   * Conecta ao monitor de pressão via Web Bluetooth
   * Usa reconexão rápida se já pareou anteriormente (evita picker de 2 minutos)
   */
  async conectarPressao(): Promise<void> {
    if (!this.bluetoothAvailable) {
      this.showDeviceToast('⚠️', 'Bluetooth indisponível', 'Use Chrome no tablet Android', 'warning');
      return;
    }

    this.isConnectingBle = true;
    this.connectingDevice = 'pressure';

    // Verifica se já conhece o dispositivo (pareado antes)
    const knownName = this.bluetoothService.getKnownDeviceName('blood_pressure');
    if (knownName) {
      this.showDeviceToast('🔄', 'Reconectando...', knownName, 'info');
    }

    try {
      // Usa connectOrReconnect que tenta reconexão rápida primeiro
      const device = await this.bluetoothService.connectOrReconnect('blood_pressure');
      if (device) {
        this.showDeviceToast('💓', 'Omron conectado', 'Aguarde a medição...', 'success');

        // Subscreve às leituras
        const sub = this.bluetoothService.readings$.subscribe((reading: VitalReading) => {
          if (reading.deviceType === 'blood_pressure') {
            this.systolic = reading.values.systolic ?? null;
            this.diastolic = reading.values.diastolic ?? null;
            this.heartRate = reading.values.heartRate ?? null;
            this.onVitalChange();
            this.showDeviceToast('✅', 'Pressão capturada', `${this.systolic}/${this.diastolic} mmHg`, 'success');
          }
        });
        this.subscriptions.add(sub);
      } else {
        this.showDeviceToast('❌', 'Conexão cancelada', 'Tente novamente', 'warning');
      }
    } catch (error: any) {
      console.error('[VitalsBar] Erro ao conectar pressão:', error);
      this.showDeviceToast('❌', 'Erro de conexão', error.message || 'Falha no Bluetooth', 'warning');
    } finally {
      this.isConnectingBle = false;
      this.connectingDevice = null;
    }
  }

  /**
   * Conecta à balança via Web Bluetooth
   * Usa reconexão rápida se já pareou anteriormente (evita picker de 2 minutos)
   */
  async conectarBalanca(): Promise<void> {
    if (!this.bluetoothAvailable) {
      this.showDeviceToast('⚠️', 'Bluetooth indisponível', 'Use Chrome no tablet Android', 'warning');
      this.addBleDebug('BLE não disponível neste navegador', 'error');
      return;
    }

    this.isConnectingBle = true;
    this.connectingDevice = 'scale';
    this.addBleDebug('Iniciando conexão com balança...', 'info');

    // Verifica se já conhece o dispositivo (pareado antes)
    const knownName = this.bluetoothService.getKnownDeviceName('scale');
    if (knownName) {
      this.showDeviceToast('🔄', 'Reconectando...', knownName, 'info');
      this.addBleDebug(`Dispositivo conhecido: ${knownName}`, 'info');
    }

    try {
      // Usa connectOrReconnect que tenta reconexão rápida primeiro
      this.addBleDebug('Abrindo picker de dispositivos...', 'info');
      const device = await this.bluetoothService.connectOrReconnect('scale');

      if (device) {
        this.addBleDebug(`CONECTADO: ${device.name} (${device.id})`, 'success');
        this.showDeviceToast('⚖️', 'Balança conectada', 'Suba na balança...', 'success');

        // Subscreve às leituras
        this.addBleDebug('Aguardando dados da balança...', 'info');
        const sub = this.bluetoothService.readings$.subscribe((reading: VitalReading) => {
          if (reading.deviceType === 'scale') {
            this.addBleDebug(`>>> PESO: ${reading.values.weight} kg`, 'data');
            this.weight = reading.values.weight ?? null;
            this.calculateIMC();
            this.onVitalChange();
            this.showDeviceToast('✅', 'Peso capturado', `${this.weight} kg`, 'success');
          }
        });
        this.subscriptions.add(sub);
      } else {
        this.addBleDebug('Conexão cancelada pelo usuário', 'warning');
        this.showDeviceToast('❌', 'Conexão cancelada', 'Tente novamente', 'warning');
      }
    } catch (error: any) {
      this.addBleDebug(`ERRO: ${error.message}`, 'error');
      console.error('[VitalsBar] Erro ao conectar balança:', error);
      this.showDeviceToast('❌', 'Erro de conexão', error.message || 'Falha no Bluetooth', 'warning');
    } finally {
      this.isConnectingBle = false;
      this.connectingDevice = null;
    }
  }

  /**
   * Conecta ao estetoscópio Littmann CORE / Eko via Web Bluetooth
   * Descobre os serviços disponíveis e prepara para captura de áudio
   * Tenta reconectar se já pareado anteriormente
   */
  async conectarEko(): Promise<void> {
    if (!this.bluetoothAvailable) {
      this.showDeviceToast('⚠️', 'Bluetooth indisponível', 'Use Chrome no tablet Android', 'warning');
      return;
    }

    // Se já está conectado, mostra mensagem e retorna
    if (this.bluetoothService.isDeviceConnected('stethoscope')) {
      this.showDeviceToast('✅', 'Já conectado', 'Littmann CORE pronto', 'success');
      return;
    }

    this.isConnectingBle = true;
    this.connectingDevice = 'stethoscope';

    // Verifica se já conhece o dispositivo (pareado antes)
    const knownName = this.bluetoothService.getKnownDeviceName('stethoscope');
    if (knownName) {
      this.showDeviceToast('🔄', 'Reconnectando...', knownName, 'info');

      // Tenta reconexão rápida primeiro
      try {
        const device = await this.bluetoothService.reconnect('stethoscope');
        if (device) {
          this.ekoConnected = true;
          this.showDeviceToast('🩺', 'Littmann CORE Reconectado', device.name, 'success');
          this.isConnectingBle = false;
          this.connectingDevice = null;
          return;
        }
      } catch (e) {
        console.log('[VitalsBar] Reconexão Eko falhou, abrindo picker...');
      }
    }

    try {
      const result = await this.bluetoothService.connectStethoscope();

      if (result.device) {
        this.ekoConnected = true;
        this.ekoServices = result.services;

        // Mostra os serviços descobertos no console para debug
        console.log('[VitalsBar] Eko conectado! Serviços:', result.services);

        if (result.services.length > 0) {
          this.showDeviceToast('🩺', 'Littmann CORE Conectado',
            `${result.services.length} serviços encontrados. Veja console (F12) para UUIDs.`, 'success');

          // Instrução para o usuário
          alert(`Littmann CORE conectado!\n\nServiços encontrados: ${result.services.length}\n\n` +
            `Para capturar áudio, precisamos identificar qual serviço transmite o áudio.\n\n` +
            `Abra o Console do Chrome (F12 → Console) e veja os UUIDs listados.\n\n` +
            `Serviços: ${result.services.join('\n')}`);
        } else {
          this.showDeviceToast('⚠️', 'Eko conectado', 'Nenhum serviço de áudio encontrado', 'warning');
        }
      } else {
        this.showDeviceToast('❌', 'Conexão cancelada', 'Tente novamente', 'warning');
      }
    } catch (error: any) {
      console.error('[VitalsBar] Erro ao conectar Eko:', error);
      this.showDeviceToast('❌', 'Erro de conexão', error.message || 'Falha no Bluetooth', 'warning');
    } finally {
      this.isConnectingBle = false;
      this.connectingDevice = null;
    }
  }

  // ========== DEBUG BLE (Console Visual Android) ==========

  toggleBleDebug(): void {
    this.showBleDebug = !this.showBleDebug;
    if (this.showBleDebug) {
      this.addBleDebug('Painel debug ativado', 'info');
    }
  }

  clearBleDebug(): void {
    this.bleDebugLogs = [];
  }

  copyBleDebug(): void {
    if (this.bleDebugLogs.length === 0) {
      this.bleCopyMessage = 'Nenhum log para copiar';
      setTimeout(() => this.bleCopyMessage = '', 2000);
      return;
    }

    // Formata os logs para texto
    const text = this.bleDebugLogs
      .map(log => `${log.time} [${log.type.toUpperCase()}] ${log.msg}`)
      .join('\n');

    // Copia para clipboard
    navigator.clipboard.writeText(text).then(() => {
      this.bleCopyMessage = '✅ Copiado! Cole no chat.';
      setTimeout(() => this.bleCopyMessage = '', 3000);
    }).catch(err => {
      // Fallback para Android antigo
      const textarea = document.createElement('textarea');
      textarea.value = text;
      textarea.style.position = 'fixed';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      this.bleCopyMessage = '✅ Copiado! Cole no chat.';
      setTimeout(() => this.bleCopyMessage = '', 3000);
    });
  }

  addBleDebug(msg: string, type: 'info' | 'success' | 'warning' | 'error' | 'data' = 'info'): void {
    const now = new Date();
    const time = now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });

    this.bleDebugLogs.push({ time, msg, type });

    // Limita a 100 linhas
    if (this.bleDebugLogs.length > 100) {
      this.bleDebugLogs.shift();
    }
  }
}
