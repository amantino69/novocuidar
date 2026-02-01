import { Component, Input, OnInit, OnDestroy, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Subscription, firstValueFrom } from 'rxjs';

import { IconComponent } from '@shared/components/atoms/icon/icon';
import { MedicalDevicesSyncService, VitalSignsData, PhonocardiogramData } from '@app/core/services/medical-devices-sync.service';
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
        <div class="header-left">
          <app-icon name="activity" [size]="16" />
          <span class="title">Sinais Vitais</span>
          @if (syncedPatientGender || syncedPatientAge) {
            <span class="patient-info-inline">
              @if (syncedPatientGender) {
                <span>{{ getGenderLabel(syncedPatientGender) }}</span>
              }
              @if (syncedPatientGender && syncedPatientAge) {
                <span class="sep">•</span>
              }
              @if (syncedPatientAge) {
                <span>{{ syncedPatientAge }} anos</span>
              }
            </span>
          }
        </div>
        <div class="header-right">
          <button class="btn-refresh" (click)="forceRefresh()" [disabled]="isRefreshing" title="Atualizar dados">
            <app-icon [name]="isRefreshing ? 'loader' : 'refresh-cw'" [size]="14" [class.spin]="isRefreshing" />
          </button>
          <span class="connection-indicator" [class.connected]="isConnected">
            <span class="indicator-dot"></span>
            {{ isConnected ? 'Sincronizado' : 'Conectando...' }}
          </span>
        </div>
      </div>

      @if (!hasAnyData) {
        <div class="waiting-state">
          <div class="waiting-icon">
            <app-icon name="bluetooth" [size]="32" />
          </div>
          <p>Aguardando dados do paciente...</p>
        </div>
      } @else {
        <div class="vitals-grid compact">
          @if (vitals['spo2']) {
            <div class="vital-card" [class]="getStatusClass(vitals['spo2'])">
              <div class="vital-icon spo2">
                <app-icon name="droplet" [size]="16" />
              </div>
              <div class="vital-info">
                <span class="vital-label">SPO₂</span>
                <span class="vital-value">{{ vitals['spo2'].value }}<small>{{ vitals['spo2'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['spo2'].status"></div>
            </div>
          }

          @if (vitals['pulseRate']) {
            <div class="vital-card" [class]="getStatusClass(vitals['pulseRate'])">
              <div class="vital-icon pulse">
                <app-icon name="heart" [size]="16" />
              </div>
              <div class="vital-info">
                <span class="vital-label">FREQ. CARDÍACA</span>
                <span class="vital-value">{{ vitals['pulseRate'].value }}<small>{{ vitals['pulseRate'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['pulseRate'].status"></div>
            </div>
          }

          @if (vitals['temperature']) {
            <div class="vital-card" [class]="getStatusClass(vitals['temperature'])">
              <div class="vital-icon temp">
                <app-icon name="thermometer" [size]="16" />
              </div>
              <div class="vital-info">
                <span class="vital-label">TEMPERATURA</span>
                <span class="vital-value">{{ vitals['temperature'].value }}<small>{{ vitals['temperature'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['temperature'].status"></div>
            </div>
          }

          @if (vitals['bloodPressure']) {
            <div class="vital-card" [class]="getStatusClass(vitals['bloodPressure'])">
              <div class="vital-icon bp">
                <app-icon name="activity" [size]="16" />
              </div>
              <div class="vital-info">
                <span class="vital-label">PRESSÃO ARTERIAL</span>
                <span class="vital-value">{{ vitals['bloodPressure'].value }}<small>{{ vitals['bloodPressure'].unit }}</small></span>
              </div>
              <div class="vital-indicator" [class]="vitals['bloodPressure'].status"></div>
            </div>
          }

          @if (vitals['weight']) {
            <div class="vital-card">
              <div class="vital-icon weight">
                <app-icon name="box" [size]="16" />
              </div>
              <div class="vital-info">
                <span class="vital-label">PESO</span>
                <span class="vital-value">{{ vitals['weight'].value }}<small>{{ vitals['weight'].unit }}</small></span>
              </div>
            </div>
          }

          @if (vitals['height']) {
            <div class="vital-card">
              <div class="vital-icon height">
                <app-icon name="maximize" [size]="16" />
              </div>
              <div class="vital-info">
                <span class="vital-label">ALTURA</span>
                <span class="vital-value">{{ vitals['height'].value }}<small>{{ vitals['height'].unit }}</small></span>
              </div>
            </div>
          }

          @if (imc) {
            <div class="vital-card" [class]="getImcStatusClass()">
              <div class="vital-icon imc">
                <app-icon name="scale" [size]="16" />
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

        <!-- Fonocardiograma do Estetoscópio Eko -->
        @if (phonocardiogram) {
          <div class="phonocardiogram-section">
            <div class="phonocardiogram-header">
              <app-icon name="activity" [size]="16" />
              <span class="phonocardiogram-title">🩺 Fonocardiograma - Estetoscópio Eko</span>
              @if (phonocardiogram.heartRate) {
                <span class="phonocardiogram-bpm">{{ phonocardiogram.heartRate }} BPM</span>
              }
            </div>
            <div class="phonocardiogram-player">
              <audio controls [src]="phonocardiogramAudioUrl" class="audio-player">
                Seu navegador não suporta áudio.
              </audio>
              <div class="phonocardiogram-info">
                <span>Duração: {{ phonocardiogram.durationSeconds?.toFixed(1) }}s</span>
                <span>•</span>
                @if (phonocardiogram.timestamp) {
                  <span>{{ formatTime(phonocardiogram.timestamp) }}</span>
                }
              </div>
            </div>
          </div>
        }

        <!-- Botão Análise IA -->
        <div class="ai-analysis-section">
          <button class="btn-ai-analysis" (click)="openAIAnalysis()" [disabled]="isAnalyzing">
            @if (isAnalyzing) {
              <app-icon name="loader" [size]="14" class="spin" />
              <span>Analisando...</span>
            } @else {
              <app-icon name="sparkles" [size]="14" />
              <span>Análise IA dos Sinais Vitais</span>
            }
          </button>
        </div>

        @if (lastUpdate) {
          <div class="last-update">
            <app-icon name="clock" [size]="12" />
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
      padding: 12px;
      height: 100%;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
      flex-shrink: 0;

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
          font-size: 12px;
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

      .header-right {
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .btn-refresh {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        border: none;
        border-radius: 6px;
        background: var(--primary-100, #e0f2fe);
        color: var(--primary-600, #0284c7);
        cursor: pointer;
        transition: all 0.2s ease;

        &:hover:not(:disabled) {
          background: var(--primary-200, #bae6fd);
          color: var(--primary-700, #0369a1);
        }

        &:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }

        .spin {
          animation: spin 1s linear infinite;
        }
      }

      .connection-indicator {
        display: flex;
        align-items: center;
        gap: 4px;
        font-size: 11px;
        color: var(--text-secondary);

        .indicator-dot {
          width: 6px;
          height: 6px;
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
      padding: 20px;
      color: var(--text-secondary);

      .waiting-icon {
        width: 60px;
        height: 60px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: var(--bg-secondary);
        border-radius: 50%;
        margin-bottom: 12px;
        animation: waiting-pulse 2s infinite;
      }

      p {
        margin: 0;
        font-size: 12px;
      }
    }

    .vitals-grid.compact {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8px;
      flex: 1;
      align-content: start;
    }

    .vital-card {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 10px;
      background: var(--bg-secondary);
      border-radius: 8px;
      position: relative;
      transition: all 0.3s ease;

      &.warning {
        background: var(--bg-warning-subtle);
      }

      &.critical {
        background: var(--bg-danger-subtle);
      }

      .vital-icon {
        width: 28px;
        height: 28px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 6px;
        
        &.spo2 { background: rgba(59, 130, 246, 0.15); color: #3b82f6; }
        &.pulse { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
        &.temp { background: rgba(249, 115, 22, 0.15); color: #f97316; }
        &.bp { background: rgba(16, 185, 129, 0.15); color: #10b981; }
        &.weight { background: rgba(139, 92, 246, 0.15); color: #8b5cf6; }
        &.height { background: rgba(6, 182, 212, 0.15); color: #06b6d4; }
        &.imc { background: rgba(236, 72, 153, 0.15); color: #ec4899; }
      }

      .vital-info {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 1px;
        min-width: 0;

        .vital-label {
          font-size: 9px;
          color: var(--text-secondary);
          text-transform: uppercase;
          letter-spacing: 0.3px;
          font-weight: 600;
        }

        .vital-value {
          font-size: 18px;
          font-weight: 700;
          color: var(--text-primary);
          line-height: 1.1;
          font-variant-numeric: tabular-nums;

          small {
            font-size: 10px;
            font-weight: 400;
            margin-left: 1px;
            color: var(--text-tertiary);
          }
        }

        .imc-classification {
          font-size: 9px;
          color: var(--text-secondary);
          font-weight: 500;
        }
      }

      .vital-indicator {
        position: absolute;
        top: 6px;
        right: 6px;
        width: 8px;
        height: 8px;
        border-radius: 50%;

        &.normal { background: #10b981; }
        &.warning { background: #f59e0b; }
        &.critical { background: #ef4444; animation: blink 0.5s infinite; }
      }
    }

    .phonocardiogram-section {
      margin-top: 12px;
      padding: 12px;
      background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
      border-radius: 10px;
      border: 1px solid #f59e0b;
      flex-shrink: 0;

      .phonocardiogram-header {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-bottom: 10px;

        .phonocardiogram-title {
          font-size: 13px;
          font-weight: 600;
          color: #92400e;
          flex: 1;
        }

        .phonocardiogram-bpm {
          font-size: 14px;
          font-weight: 700;
          color: #dc2626;
          background: white;
          padding: 2px 8px;
          border-radius: 12px;
        }
      }

      .phonocardiogram-player {
        .audio-player {
          width: 100%;
          height: 36px;
          border-radius: 6px;
        }

        .phonocardiogram-info {
          display: flex;
          gap: 8px;
          margin-top: 6px;
          font-size: 11px;
          color: #92400e;
          justify-content: center;
        }
      }
    }

    .ai-analysis-section {
      margin-top: 10px;
      flex-shrink: 0;

      .btn-ai-analysis {
        width: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        padding: 10px 16px;
        background: linear-gradient(135deg, #0ea5e9 0%, #3b82f6 100%);
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s ease;

        &:hover:not(:disabled) {
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(59, 130, 246, 0.35);
        }

        &:disabled {
          opacity: 0.7;
          cursor: not-allowed;
        }
      }
    }

    .last-update {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 4px;
      margin-top: 8px;
      font-size: 10px;
      color: var(--text-secondary);
      flex-shrink: 0;
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
  isRefreshing = false;
  
  // Cache key para sessionStorage
  private readonly CACHE_KEY_PREFIX = 'vitalsigns_cache_';
  
  vitals: Record<string, VitalDisplay> = {};
  
  // IMC
  imc: string | null = null;
  imcClassification: string = '';
  imcStatus: 'normal' | 'warning' | 'critical' = 'normal';
  
  // Dados do paciente recebidos via SignalR
  syncedPatientGender: string | null = null;
  syncedPatientAge: number | null = null;
  
  // Alertas médicos
  alerts: { type: 'warning' | 'critical'; icon: string; message: string }[] = [];
  
  // Modal de análise IA
  showAIModal = false;
  isAnalyzing = false;
  aiAnalysis: string = '';
  formattedAIAnalysis: string = '';
  aiAnalysisError: string = '';
  aiAnalysisGeneratedAt: Date | null = null;
  
  // Fonocardiograma do estetoscópio Eko
  phonocardiogram: { heartRate?: number; audioUrl?: string; durationSeconds?: number; timestamp?: Date } | null = null;
  phonocardiogramAudioUrl: string = '';
  
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
    // 1. Carrega do cache IMEDIATAMENTE (instantâneo)
    this.loadFromCache();
    
    // 2. Carrega dados do paciente
    this.loadPatientData();
    
    // 3. Conecta ao hub
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
        // MESCLA dados novos com existentes para persistir valores anteriores
        const mergedData = this.mergeWithCachedData(data);
        this.processVitalSigns(mergedData);
        this.saveToCache(mergedData);
      })
    );

    // Observa fonocardiograma do estetoscópio Eko
    this.subscriptions.add(
      this.syncService.phonocardiogramReceived$.subscribe(data => {
        console.log('[VitalSignsPanel] 🩺 Fonocardiograma recebido:', data);
        this.phonocardiogram = {
          heartRate: data.heartRate,
          audioUrl: data.audioUrl,
          durationSeconds: data.durationSeconds,
          timestamp: new Date(data.timestamp)
        };
        if (data.audioUrl) {
          this.phonocardiogramAudioUrl = environment.apiUrl.replace('/api', '') + data.audioUrl;
        }
        this.hasAnyData = true;
        this.lastUpdate = new Date();
      })
    );
    
    // 4. Carrega dados atualizados do servidor em background
    this.loadExistingData();
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
          // Preenche os dados para exibição no banner
          if (user.patientProfile?.gender) {
            this.syncedPatientGender = user.patientProfile.gender;
          }
          if (user.patientProfile?.birthDate) {
            this.syncedPatientAge = this.calculateAge(user.patientProfile.birthDate);
          }
          console.log('[VitalSignsPanel] Dados do paciente carregados:', user.name, this.syncedPatientGender, this.syncedPatientAge);
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
        // MESCLA dados do banco com cache existente
        const mergedData = this.mergeWithCachedData(vitalSignsData);
        this.processVitalSigns(mergedData);
        this.saveToCache(mergedData);
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
    console.log('[VitalSignsPanel] 🔄 processVitalSigns chamado com:', JSON.stringify(data, null, 2));
    
    this.hasAnyData = true;
    this.lastUpdate = new Date(data.timestamp);

    const v = data.vitals;
    console.log('[VitalSignsPanel] Vitals extraídos:', v);
    
    // Extrai dados do paciente enviados via SignalR
    if (v.gender) {
      this.syncedPatientGender = v.gender;
    }
    if (v.birthDate) {
      this.syncedPatientAge = this.calculateAge(v.birthDate);
    }
    
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
    // Prioriza idade recebida via SignalR
    if (this.syncedPatientAge) return this.syncedPatientAge;
    
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

  /**
   * Calcula a idade a partir de uma data de nascimento
   */
  private calculateAge(birthDate: string): number | null {
    if (!birthDate) return null;
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age > 0 ? age : null;
  }

  /**
   * Retorna o label do sexo para exibição
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

  /**
   * Mescla novos dados com dados existentes no cache.
   * Mantém valores anteriores se os novos forem null/undefined.
   * Isso garante que peso capturado antes não desapareça quando chegar pressão.
   */
  private mergeWithCachedData(newData: VitalSignsData): VitalSignsData {
    if (!this.appointmentId) return newData;

    try {
      const cached = sessionStorage.getItem(this.CACHE_KEY_PREFIX + this.appointmentId);
      if (!cached) return newData;

      const cachedData = JSON.parse(cached) as VitalSignsData;
      const cachedVitals = cachedData.vitals || {};
      const newVitals = newData.vitals || {};

      // Mescla: novos valores válidos sobrescrevem, senão mantém antigos
      const mergedVitals = {
        spo2: this.getValidValue(newVitals.spo2, cachedVitals.spo2),
        oxygenSaturation: this.getValidValue((newVitals as any).oxygenSaturation, (cachedVitals as any).oxygenSaturation),
        pulseRate: this.getValidValue(newVitals.pulseRate, cachedVitals.pulseRate),
        heartRate: this.getValidValue(newVitals.heartRate, cachedVitals.heartRate),
        systolic: this.getValidValue(newVitals.systolic, cachedVitals.systolic),
        diastolic: this.getValidValue(newVitals.diastolic, cachedVitals.diastolic),
        temperature: this.getValidValue(newVitals.temperature, cachedVitals.temperature),
        weight: this.getValidValue(newVitals.weight, cachedVitals.weight),
        height: this.getValidValue(newVitals.height, cachedVitals.height),
        gender: newVitals.gender || cachedVitals.gender,
        birthDate: newVitals.birthDate || cachedVitals.birthDate
      };

      console.log('[VitalSignsPanel] 🔀 Dados mesclados:', mergedVitals);

      return {
        ...newData,
        vitals: mergedVitals
      };
    } catch (e) {
      console.warn('[VitalSignsPanel] Erro ao mesclar com cache:', e);
      return newData;
    }
  }

  /**
   * Retorna o valor novo se for válido, senão retorna o antigo
   */
  private getValidValue(newVal: any, oldVal: any): any {
    if (newVal !== undefined && newVal !== null && newVal !== 0 && newVal !== '') {
      return newVal;
    }
    return oldVal;
  }

  /**
   * Carrega dados do cache local (instantâneo)
   */
  private loadFromCache(): void {
    if (!this.appointmentId) return;
    
    try {
      const cached = sessionStorage.getItem(this.CACHE_KEY_PREFIX + this.appointmentId);
      if (cached) {
        const data = JSON.parse(cached) as VitalSignsData;
        this.processVitalSigns(data);
        console.log('[VitalSignsPanel] Dados carregados do cache instantaneamente');
      }
    } catch (e) {
      console.warn('[VitalSignsPanel] Erro ao carregar cache:', e);
    }
  }

  /**
   * Salva dados no cache local
   */
  private saveToCache(data: VitalSignsData): void {
    if (!this.appointmentId) return;
    
    try {
      sessionStorage.setItem(
        this.CACHE_KEY_PREFIX + this.appointmentId,
        JSON.stringify(data)
      );
    } catch (e) {
      console.warn('[VitalSignsPanel] Erro ao salvar cache:', e);
    }
  }

  /**
   * Força atualização dos dados do servidor
   */
  async forceRefresh(): Promise<void> {
    if (!this.appointmentId || this.isRefreshing) return;
    
    this.isRefreshing = true;
    
    try {
      const apiUrl = `${environment.apiUrl}/appointments/${this.appointmentId}/biometrics`;
      const data = await firstValueFrom(this.http.get<any>(apiUrl));
      
      if (data && this.hasAnyVitalData(data)) {
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
        // MESCLA dados do banco com cache existente
        const mergedData = this.mergeWithCachedData(vitalSignsData);
        this.processVitalSigns(mergedData);
        this.saveToCache(mergedData);
      }
    } catch (error) {
      console.error('[VitalSignsPanel] Erro ao atualizar:', error);
    } finally {
      this.isRefreshing = false;
    }
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }
}
