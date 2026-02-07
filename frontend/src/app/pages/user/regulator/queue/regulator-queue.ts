import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { AuthService } from '@app/core/services/auth.service';
import { RegulatorService, RegulatorPatient, Specialty } from '@app/core/services/regulator.service';

interface QueuePatient extends RegulatorPatient {
  urgency: 'normal' | 'priority' | 'urgent';
  requestedSpecialty?: string;
  waitingSince?: string;
  notes?: string;
}

@Component({
  selector: 'app-regulator-queue',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, IconComponent],
  template: `
    <div class="page-container">
      <header class="page-header">
        <button class="back-btn" routerLink="/painel">
          <app-icon name="arrow-left" [size]="20" />
          Voltar
        </button>
        <h1>
          <app-icon name="clock" [size]="28" />
          Fila de Espera
        </h1>
        <p class="subtitle">Pacientes aguardando alocação em {{ municipioNome }}</p>
      </header>

      <!-- Filtros e Ações -->
      <div class="toolbar">
        <div class="filters">
          <div class="search-box">
            <app-icon name="search" [size]="18" />
            <input 
              type="text" 
              placeholder="Buscar paciente..." 
              [(ngModel)]="searchTerm"
              (input)="onSearch()"
            />
          </div>
          <select [(ngModel)]="filtroUrgencia" (change)="aplicarFiltros()">
            <option value="">Todas Urgências</option>
            <option value="urgent">Urgente</option>
            <option value="priority">Prioritário</option>
            <option value="normal">Normal</option>
          </select>
          <select [(ngModel)]="filtroEspecialidade" (change)="aplicarFiltros()">
            <option value="">Todas Especialidades</option>
            @for (esp of specialties; track esp.id) {
              <option [value]="esp.name">{{ esp.name }}</option>
            }
          </select>
        </div>
        <div class="actions">
          <button class="btn-refresh" (click)="loadPatients()">
            <app-icon name="refresh-cw" [size]="18" />
            Atualizar
          </button>
        </div>
      </div>

      <!-- Resumo da Fila -->
      <div class="queue-summary">
        <div class="summary-card urgent">
          <app-icon name="alert-triangle" [size]="24" />
          <div class="info">
            <span class="count">{{ countUrgent }}</span>
            <span class="label">Urgentes</span>
          </div>
        </div>
        <div class="summary-card priority">
          <app-icon name="alert-circle" [size]="24" />
          <div class="info">
            <span class="count">{{ countPriority }}</span>
            <span class="label">Prioritários</span>
          </div>
        </div>
        <div class="summary-card normal">
          <app-icon name="users" [size]="24" />
          <div class="info">
            <span class="count">{{ countNormal }}</span>
            <span class="label">Normal</span>
          </div>
        </div>
        <div class="summary-card total">
          <app-icon name="file" [size]="24" />
          <div class="info">
            <span class="count">{{ queueFiltered.length }}</span>
            <span class="label">Total na Fila</span>
          </div>
        </div>
      </div>

      <!-- Loading -->
      @if (loading) {
        <div class="loading-container">
          <div class="spinner"></div>
          <p>Carregando fila...</p>
        </div>
      }

      <!-- Erro -->
      @if (error && !loading) {
        <div class="error-message">
          <app-icon name="alert-circle" [size]="24" />
          <p>{{ error }}</p>
          <button (click)="loadPatients()">Tentar novamente</button>
        </div>
      }

      <!-- Lista da Fila -->
      @if (!loading && !error) {
        @if (queueFiltered.length === 0) {
          <div class="empty-state">
            <app-icon name="check-circle" [size]="64" />
            <h2>Fila vazia</h2>
            <p>Não há pacientes aguardando alocação no momento.</p>
          </div>
        } @else {
          <div class="queue-list">
            @for (patient of queueFiltered; track patient.id; let i = $index) {
              <div class="queue-item" [class]="patient.urgency">
                <div class="position">
                  <span class="number">{{ i + 1 }}</span>
                </div>
                
                <div class="patient-info">
                  <div class="avatar" [style.background]="getAvatarColor(patient.urgency)">
                    {{ getInitials(patient.fullName) }}
                  </div>
                  <div class="details">
                    <h3>{{ patient.fullName }}</h3>
                    <div class="meta">
                      <span><app-icon name="user" [size]="14" /> {{ formatCpf(patient.cpf) }}</span>
                      @if (patient.phone) {
                        <span><app-icon name="phone" [size]="14" /> {{ patient.phone }}</span>
                      }
                    </div>
                  </div>
                </div>

                <div class="specialty-info">
                  <span class="label">Especialidade</span>
                  <span class="value">{{ patient.requestedSpecialty || 'Clínica Geral' }}</span>
                </div>

                <div class="urgency-badge" [class]="patient.urgency">
                  @switch (patient.urgency) {
                    @case ('urgent') {
                      <app-icon name="alert-triangle" [size]="16" />
                      Urgente
                    }
                    @case ('priority') {
                      <app-icon name="alert-circle" [size]="16" />
                      Prioritário
                    }
                    @default {
                      <app-icon name="clock" [size]="16" />
                      Normal
                    }
                  }
                </div>

                <div class="item-actions">
                  <button class="btn-icon" title="Alterar prioridade" (click)="alterarPrioridade(patient)">
                    <app-icon name="chevrons-up-down" [size]="18" />
                  </button>
                  <button class="btn-icon" title="Ver detalhes" (click)="verDetalhes(patient)">
                    <app-icon name="eye" [size]="18" />
                  </button>
                  <button class="btn-primary" (click)="alocarPaciente(patient)">
                    <app-icon name="plus-circle" [size]="16" />
                    Alocar
                  </button>
                </div>
              </div>
            }
          </div>
        }
      }
    </div>

    <!-- Modal de Detalhes -->
    @if (selectedPatient) {
      <div class="modal-overlay" (click)="closeModal()">
        <div class="modal-content" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>Detalhes do Paciente</h2>
            <button class="close-btn" (click)="closeModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <div class="patient-header">
              <div class="avatar large" [style.background]="getAvatarColor(selectedPatient.urgency)">
                {{ getInitials(selectedPatient.fullName) }}
              </div>
              <div>
                <h3>{{ selectedPatient.fullName }}</h3>
                <p class="urgency-badge inline" [class]="selectedPatient.urgency">
                  @switch (selectedPatient.urgency) {
                    @case ('urgent') { Urgente }
                    @case ('priority') { Prioritário }
                    @default { Normal }
                  }
                </p>
              </div>
            </div>
            
            <div class="detail-grid">
              <div class="detail-item">
                <label>CPF</label>
                <span>{{ formatCpf(selectedPatient.cpf) }}</span>
              </div>
              <div class="detail-item">
                <label>E-mail</label>
                <span>{{ selectedPatient.email }}</span>
              </div>
              <div class="detail-item">
                <label>Telefone</label>
                <span>{{ selectedPatient.phone || 'Não informado' }}</span>
              </div>
              <div class="detail-item">
                <label>CNS</label>
                <span>{{ selectedPatient.cns || 'Não informado' }}</span>
              </div>
              <div class="detail-item">
                <label>Data de Nascimento</label>
                <span>{{ selectedPatient.birthDate ? formatDate(selectedPatient.birthDate) : 'Não informada' }}</span>
              </div>
              <div class="detail-item">
                <label>Sexo</label>
                <span>{{ formatGender(selectedPatient.gender) }}</span>
              </div>
              <div class="detail-item">
                <label>Cidade</label>
                <span>{{ selectedPatient.city || 'Não informada' }}</span>
              </div>
              <div class="detail-item">
                <label>Especialidade Solicitada</label>
                <span>{{ selectedPatient.requestedSpecialty || 'Clínica Geral' }}</span>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closeModal()">Fechar</button>
            <button class="btn-primary" (click)="alocarPaciente(selectedPatient); closeModal()">
              <app-icon name="plus-circle" [size]="16" />
              Alocar Paciente
            </button>
          </div>
        </div>
      </div>
    }

    <!-- Modal de Prioridade -->
    @if (showPriorityModal && patientForPriority) {
      <div class="modal-overlay" (click)="closePriorityModal()">
        <div class="modal-content small" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>Alterar Prioridade</h2>
            <button class="close-btn" (click)="closePriorityModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <p>Selecione a nova prioridade para <strong>{{ patientForPriority.fullName }}</strong>:</p>
            
            <div class="priority-options">
              <button 
                class="priority-option urgent" 
                [class.selected]="newPriority === 'urgent'"
                (click)="newPriority = 'urgent'"
              >
                <app-icon name="alert-triangle" [size]="24" />
                <span>Urgente</span>
                <small>Atendimento imediato</small>
              </button>
              <button 
                class="priority-option priority" 
                [class.selected]="newPriority === 'priority'"
                (click)="newPriority = 'priority'"
              >
                <app-icon name="alert-circle" [size]="24" />
                <span>Prioritário</span>
                <small>Atendimento preferencial</small>
              </button>
              <button 
                class="priority-option normal" 
                [class.selected]="newPriority === 'normal'"
                (click)="newPriority = 'normal'"
              >
                <app-icon name="clock" [size]="24" />
                <span>Normal</span>
                <small>Ordem de chegada</small>
              </button>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closePriorityModal()">Cancelar</button>
            <button class="btn-primary" (click)="confirmarPrioridade()">
              Confirmar
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .page-container {
      padding: 24px;
      max-width: 1400px;
      margin: 0 auto;
    }

    .page-header {
      margin-bottom: 24px;
      h1 {
        display: flex;
        align-items: center;
        gap: 12px;
        font-size: 28px;
        font-weight: 700;
        color: #0f172a;
        margin: 16px 0 8px;
      }
      .subtitle { color: #64748b; margin: 0; }
    }

    .back-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      border: none;
      background: #f1f5f9;
      border-radius: 8px;
      color: #64748b;
      font-size: 14px;
      cursor: pointer;
      &:hover { background: #e2e8f0; color: #0d9488; }
    }

    .toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
      flex-wrap: wrap;

      .filters {
        display: flex;
        gap: 12px;
        flex-wrap: wrap;
        flex: 1;
      }

      .search-box {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 14px;
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        min-width: 250px;
        
        app-icon { color: #94a3b8; }
        
        input {
          border: none;
          outline: none;
          font-size: 14px;
          width: 100%;
          &::placeholder { color: #94a3b8; }
        }
      }

      select {
        padding: 10px 14px;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        font-size: 14px;
        background: white;
        cursor: pointer;
        &:focus { outline: none; border-color: #0d9488; }
      }

      .btn-refresh {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 16px;
        border: 1px solid #e2e8f0;
        background: white;
        border-radius: 8px;
        cursor: pointer;
        font-size: 14px;
        color: #64748b;
        &:hover { background: #f1f5f9; color: #0d9488; }
      }
    }

    .queue-summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
      margin-bottom: 24px;

      .summary-card {
        display: flex;
        align-items: center;
        gap: 16px;
        padding: 20px;
        background: white;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.06);

        app-icon { padding: 12px; border-radius: 12px; }

        &.urgent app-icon { background: #fef2f2; color: #dc2626; }
        &.priority app-icon { background: #fefce8; color: #ca8a04; }
        &.normal app-icon { background: #f0fdf4; color: #16a34a; }
        &.total app-icon { background: #eff6ff; color: #2563eb; }

        .info {
          display: flex;
          flex-direction: column;
          .count { font-size: 28px; font-weight: 700; color: #0f172a; }
          .label { font-size: 13px; color: #64748b; }
        }
      }
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 60px;
      .spinner {
        width: 48px;
        height: 48px;
        border: 4px solid #e2e8f0;
        border-top-color: #0d9488;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }
      p { margin-top: 16px; color: #64748b; }
    }

    @keyframes spin { to { transform: rotate(360deg); } }

    .error-message {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 40px;
      background: #fef2f2;
      border-radius: 12px;
      color: #dc2626;
      app-icon { margin-bottom: 12px; }
      button {
        margin-top: 16px;
        padding: 8px 16px;
        background: #dc2626;
        color: white;
        border: none;
        border-radius: 8px;
        cursor: pointer;
      }
    }

    .empty-state {
      text-align: center;
      padding: 60px 24px;
      background: white;
      border-radius: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
      app-icon { color: #22c55e; margin-bottom: 16px; }
      h2 { font-size: 20px; color: #0f172a; margin: 0 0 8px; }
      p { color: #64748b; margin: 0; }
    }

    .queue-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .queue-item {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 16px 20px;
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
      border-left: 4px solid #e2e8f0;
      transition: all 0.2s;

      &:hover {
        box-shadow: 0 4px 16px rgba(0,0,0,0.1);
        transform: translateX(4px);
      }

      &.urgent { border-left-color: #dc2626; }
      &.priority { border-left-color: #ca8a04; }
      &.normal { border-left-color: #22c55e; }

      .position {
        .number {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 36px;
          height: 36px;
          background: #f1f5f9;
          border-radius: 50%;
          font-weight: 700;
          color: #64748b;
          font-size: 14px;
        }
      }

      .patient-info {
        display: flex;
        align-items: center;
        gap: 12px;
        flex: 1;
        min-width: 250px;

        .avatar {
          width: 44px;
          height: 44px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 600;
          font-size: 14px;
          color: white;
        }

        .details {
          h3 { margin: 0; font-size: 15px; color: #0f172a; }
          .meta {
            display: flex;
            gap: 16px;
            margin-top: 4px;
            span {
              display: flex;
              align-items: center;
              gap: 4px;
              font-size: 13px;
              color: #64748b;
            }
          }
        }
      }

      .specialty-info {
        display: flex;
        flex-direction: column;
        min-width: 140px;
        .label { font-size: 11px; color: #94a3b8; text-transform: uppercase; }
        .value { font-size: 14px; color: #0f172a; font-weight: 500; }
      }

      .urgency-badge {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 6px 12px;
        border-radius: 20px;
        font-size: 13px;
        font-weight: 500;
        min-width: 110px;

        &.urgent { background: #fef2f2; color: #dc2626; }
        &.priority { background: #fefce8; color: #ca8a04; }
        &.normal { background: #f0fdf4; color: #16a34a; }
      }

      .item-actions {
        display: flex;
        gap: 8px;
        align-items: center;

        .btn-icon {
          padding: 8px;
          border: none;
          background: #f1f5f9;
          border-radius: 8px;
          cursor: pointer;
          color: #64748b;
          &:hover { background: #e2e8f0; color: #0d9488; }
        }

        .btn-primary {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 16px;
          background: #0d9488;
          border: none;
          border-radius: 8px;
          color: white;
          font-size: 13px;
          font-weight: 500;
          cursor: pointer;
          &:hover { background: #0f766e; }
        }
      }
    }

    /* Modal */
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      padding: 20px;
    }

    .modal-content {
      background: white;
      border-radius: 16px;
      width: 100%;
      max-width: 600px;
      max-height: 90vh;
      overflow-y: auto;

      &.small { max-width: 450px; }
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
      border-bottom: 1px solid #e2e8f0;
      h2 { margin: 0; font-size: 20px; color: #0f172a; }
      .close-btn {
        background: none;
        border: none;
        cursor: pointer;
        color: #64748b;
        &:hover { color: #0f172a; }
      }
    }

    .modal-body {
      padding: 20px;

      .patient-header {
        display: flex;
        align-items: center;
        gap: 16px;
        margin-bottom: 24px;
        padding-bottom: 20px;
        border-bottom: 1px solid #e2e8f0;

        .avatar.large {
          width: 64px;
          height: 64px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 600;
          font-size: 20px;
          color: white;
        }

        h3 { margin: 0 0 8px; font-size: 18px; color: #0f172a; }
      }

      .urgency-badge.inline {
        display: inline-block;
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 12px;
        font-weight: 500;
        &.urgent { background: #fef2f2; color: #dc2626; }
        &.priority { background: #fefce8; color: #ca8a04; }
        &.normal { background: #f0fdf4; color: #16a34a; }
      }

      .detail-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 16px;

        .detail-item {
          label {
            display: block;
            font-size: 12px;
            color: #64748b;
            margin-bottom: 4px;
            text-transform: uppercase;
          }
          span {
            font-size: 14px;
            color: #0f172a;
          }
        }
      }

      .priority-options {
        display: flex;
        flex-direction: column;
        gap: 12px;
        margin-top: 20px;

        .priority-option {
          display: flex;
          align-items: center;
          gap: 16px;
          padding: 16px;
          border: 2px solid #e2e8f0;
          border-radius: 12px;
          background: white;
          cursor: pointer;
          text-align: left;
          transition: all 0.2s;

          &:hover { border-color: #94a3b8; }

          &.selected {
            border-color: #0d9488;
            background: #f0fdfa;
          }

          &.urgent app-icon { color: #dc2626; }
          &.priority app-icon { color: #ca8a04; }
          &.normal app-icon { color: #22c55e; }

          span { font-weight: 600; color: #0f172a; }
          small { color: #64748b; font-size: 12px; margin-left: auto; }
        }
      }
    }

    .modal-footer {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding: 16px 20px;
      border-top: 1px solid #e2e8f0;

      .btn-secondary {
        padding: 10px 20px;
        border: 1px solid #e2e8f0;
        background: white;
        border-radius: 8px;
        cursor: pointer;
        &:hover { background: #f1f5f9; }
      }

      .btn-primary {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 10px 20px;
        background: #0d9488;
        border: none;
        border-radius: 8px;
        color: white;
        cursor: pointer;
        &:hover { background: #0f766e; }
      }
    }

    /* Dark mode */
    :host-context([data-theme="dark"]) {
      .page-header h1 { color: #f1f5f9; }
      .back-btn, .btn-refresh {
        background: #334155;
        color: #94a3b8;
        border-color: #475569;
        &:hover { background: #475569; }
      }
      .toolbar {
        .search-box {
          background: #1e293b;
          border-color: #475569;
          input { background: transparent; color: #f1f5f9; }
        }
        select {
          background: #1e293b;
          border-color: #475569;
          color: #f1f5f9;
        }
      }
      .queue-summary .summary-card {
        background: #1e293b;
        .info .count { color: #f1f5f9; }
      }
      .queue-item {
        background: #1e293b;
        .position .number { background: #334155; color: #94a3b8; }
        .patient-info .details {
          h3 { color: #f1f5f9; }
          .meta span { color: #94a3b8; }
        }
        .specialty-info .value { color: #f1f5f9; }
        .item-actions .btn-icon { background: #334155; color: #94a3b8; }
      }
      .empty-state { background: #1e293b; }
      .empty-state h2 { color: #f1f5f9; }
      .modal-content { background: #1e293b; }
      .modal-header { border-color: #334155; }
      .modal-header h2 { color: #f1f5f9; }
      .modal-body {
        .patient-header { border-color: #334155; }
        .patient-header h3 { color: #f1f5f9; }
        .detail-grid .detail-item span { color: #f1f5f9; }
        .priority-option {
          background: #1e293b;
          border-color: #475569;
          span { color: #f1f5f9; }
          &.selected { background: #134e4a; }
        }
      }
      .modal-footer {
        border-color: #334155;
        .btn-secondary { background: #334155; border-color: #475569; color: #f1f5f9; }
      }
    }

    @media (max-width: 768px) {
      .queue-item {
        flex-wrap: wrap;
        .patient-info { width: 100%; }
        .specialty-info, .urgency-badge { flex: 1; }
        .item-actions { width: 100%; justify-content: flex-end; margin-top: 12px; }
      }
    }
  `]
})
export class RegulatorQueueComponent implements OnInit {
  municipioNome = '';
  queue: QueuePatient[] = [];
  queueFiltered: QueuePatient[] = [];
  specialties: Specialty[] = [];
  
  loading = true;
  error: string | null = null;
  
  searchTerm = '';
  filtroUrgencia = '';
  filtroEspecialidade = '';
  
  selectedPatient: QueuePatient | null = null;
  showPriorityModal = false;
  patientForPriority: QueuePatient | null = null;
  newPriority: 'normal' | 'priority' | 'urgent' = 'normal';

  private searchTimeout: any;

  constructor(
    private authService: AuthService,
    private regulatorService: RegulatorService
  ) {}

  ngOnInit() {
    const user = this.authService.getCurrentUser();
    this.municipioNome = (user as any)?.municipioNome || 'seu município';
    this.loadPatients();
    this.loadSpecialties();
  }

  loadPatients() {
    this.loading = true;
    this.error = null;
    
    // Carregar pacientes do município (simulando fila de espera)
    this.regulatorService.getPatients({ pageSize: 100 }).subscribe({
      next: (response) => {
        // Transformar pacientes em itens de fila com prioridade simulada
        this.queue = response.data.map((patient, index) => ({
          ...patient,
          urgency: this.getRandomUrgency(index),
          requestedSpecialty: this.getRandomSpecialty(),
          waitingSince: this.getRandomDate()
        }));
        this.aplicarFiltros();
        this.loading = false;
      },
      error: (err) => {
        console.error('Erro ao carregar fila:', err);
        this.error = 'Não foi possível carregar a fila. Tente novamente.';
        this.loading = false;
      }
    });
  }

  loadSpecialties() {
    this.regulatorService.getSpecialties().subscribe({
      next: (data) => {
        this.specialties = data;
      },
      error: (err) => {
        console.error('Erro ao carregar especialidades:', err);
      }
    });
  }

  onSearch() {
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      this.aplicarFiltros();
    }, 300);
  }

  aplicarFiltros() {
    let filtered = [...this.queue];
    
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(p => 
        p.fullName.toLowerCase().includes(term) ||
        p.cpf.includes(this.searchTerm) ||
        p.email.toLowerCase().includes(term)
      );
    }
    
    if (this.filtroUrgencia) {
      filtered = filtered.filter(p => p.urgency === this.filtroUrgencia);
    }
    
    if (this.filtroEspecialidade) {
      filtered = filtered.filter(p => 
        p.requestedSpecialty?.toLowerCase().includes(this.filtroEspecialidade.toLowerCase())
      );
    }
    
    // Ordenar por urgência
    filtered.sort((a, b) => {
      const order = { urgent: 0, priority: 1, normal: 2 };
      return order[a.urgency] - order[b.urgency];
    });
    
    this.queueFiltered = filtered;
  }

  get countUrgent(): number {
    return this.queueFiltered.filter(p => p.urgency === 'urgent').length;
  }

  get countPriority(): number {
    return this.queueFiltered.filter(p => p.urgency === 'priority').length;
  }

  get countNormal(): number {
    return this.queueFiltered.filter(p => p.urgency === 'normal').length;
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .filter(n => n.length > 0)
      .slice(0, 2)
      .map(n => n[0].toUpperCase())
      .join('');
  }

  formatCpf(cpf: string): string {
    if (!cpf) return '-';
    return cpf.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('pt-BR');
  }

  formatGender(gender: string | null): string {
    if (!gender) return 'Não informado';
    const map: Record<string, string> = {
      'M': 'Masculino',
      'F': 'Feminino',
      'Male': 'Masculino',
      'Female': 'Feminino'
    };
    return map[gender] || gender;
  }

  getAvatarColor(urgency: string): string {
    const colors: Record<string, string> = {
      urgent: '#dc2626',
      priority: '#ca8a04',
      normal: '#0d9488'
    };
    return colors[urgency] || '#64748b';
  }

  // Helpers para dados simulados (em produção viriam do backend)
  private getRandomUrgency(index: number): 'normal' | 'priority' | 'urgent' {
    if (index % 5 === 0) return 'urgent';
    if (index % 3 === 0) return 'priority';
    return 'normal';
  }

  private getRandomSpecialty(): string {
    const specs = ['Clínica Geral', 'Psiquiatria', 'Cardiologia', 'Dermatologia'];
    return specs[Math.floor(Math.random() * specs.length)];
  }

  private getRandomDate(): string {
    const days = Math.floor(Math.random() * 30);
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date.toISOString();
  }

  verDetalhes(patient: QueuePatient) {
    this.selectedPatient = patient;
  }

  closeModal() {
    this.selectedPatient = null;
  }

  alterarPrioridade(patient: QueuePatient) {
    this.patientForPriority = patient;
    this.newPriority = patient.urgency;
    this.showPriorityModal = true;
  }

  closePriorityModal() {
    this.showPriorityModal = false;
    this.patientForPriority = null;
  }

  confirmarPrioridade() {
    if (this.patientForPriority) {
      this.patientForPriority.urgency = this.newPriority;
      this.aplicarFiltros();
      this.closePriorityModal();
    }
  }

  alocarPaciente(patient: QueuePatient) {
    // TODO: Implementar modal de alocação
    alert(`Funcionalidade de alocação para ${patient.fullName} será implementada em breve.`);
  }
}
