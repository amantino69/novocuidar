import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { AuthService } from '@app/core/services/auth.service';
import { RegulatorService, WaitingQueuePatient, Specialty, AvailableSchedule, ScheduleSlot, AllocatePatientData } from '@app/core/services/regulator.service';

interface QueuePatient extends WaitingQueuePatient {
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

                @if (patient.hasAllocation) {
                  <div class="allocation-badge allocated">
                    <app-icon name="check-circle" [size]="16" />
                    Já Alocado
                    @if (patient.nextAppointmentDate) {
                      <span class="date-info">{{ patient.nextAppointmentDate }}</span>
                    }
                  </div>
                }

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

    <!-- Modal de Alocação -->
    @if (showAllocationModal && patientForAllocation) {
      <div class="modal-overlay" (click)="closeAllocationModal()">
        <div class="modal-content allocation-modal" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>
              <app-icon name="calendar" [size]="24" />
              Alocar Paciente
            </h2>
            <button class="close-btn" (click)="closeAllocationModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <!-- Info do Paciente -->
            <div class="allocation-patient-info">
              <div class="avatar" [style.background]="getAvatarColor(patientForAllocation.urgency)">
                {{ getInitials(patientForAllocation.fullName) }}
              </div>
              <div class="info">
                <h3>{{ patientForAllocation.fullName }}</h3>
                <span class="urgency-tag" [class]="patientForAllocation.urgency">
                  @switch (patientForAllocation.urgency) {
                    @case ('urgent') { Urgente }
                    @case ('priority') { Prioritário }
                    @default { Normal }
                  }
                </span>
              </div>
            </div>

            <!-- Mensagens de erro/sucesso -->
            @if (allocationError) {
              <div class="allocation-message error">
                <app-icon name="alert-circle" [size]="18" />
                {{ allocationError }}
              </div>
            }
            @if (allocationSuccess) {
              <div class="allocation-message success">
                <app-icon name="check-circle" [size]="18" />
                {{ allocationSuccess }}
              </div>
            }

            <!-- Step 1: Selecionar Profissional/Agenda -->
            <div class="allocation-step">
              <label>
                <app-icon name="user-check" [size]="16" />
                Selecione o Profissional
              </label>
              @if (loadingSchedules) {
                <div class="loading-inline">
                  <div class="spinner-small"></div>
                  Carregando agendas...
                </div>
              } @else if (availableSchedules.length === 0) {
                <div class="no-schedules">
                  <app-icon name="calendar" [size]="24" />
                  <p>Nenhuma agenda disponível no momento.</p>
                </div>
              } @else {
                <div class="schedules-list">
                  @for (schedule of availableSchedules; track schedule.id) {
                    <button 
                      class="schedule-option"
                      [class.selected]="selectedSchedule?.id === schedule.id"
                      (click)="selectSchedule(schedule)"
                    >
                      <div class="schedule-info">
                        <strong>{{ schedule.professional.name }}</strong>
                        <span class="specialty">{{ schedule.professional.specialty }}</span>
                      </div>
                      <app-icon name="chevron-right" [size]="18" />
                    </button>
                  }
                </div>
              }
            </div>

            <!-- Step 2: Selecionar Horário -->
            @if (selectedSchedule) {
              <div class="allocation-step">
                <label>
                  <app-icon name="clock" [size]="16" />
                  Selecione o Horário
                </label>
                @if (loadingSlots) {
                  <div class="loading-inline">
                    <div class="spinner-small"></div>
                    Carregando horários...
                  </div>
                } @else if (availableSlots.length === 0) {
                  <div class="no-schedules">
                    <app-icon name="calendar" [size]="24" />
                    <p>Nenhum horário disponível para esta agenda.</p>
                  </div>
                } @else {
                  <div class="slots-grid">
                    @for (slot of availableSlots; track slot.date + slot.time) {
                      <button 
                        class="slot-option"
                        [class.selected]="selectedSlot === slot"
                        (click)="selectedSlot = slot"
                      >
                        <span class="slot-date">{{ formatSlotDate(slot.date) }}</span>
                        <span class="slot-day">{{ slot.dayOfWeekPt }}</span>
                        <span class="slot-time">{{ slot.time }}</span>
                      </button>
                    }
                  </div>
                }
              </div>
            }

            <!-- Step 3: Observação (opcional) -->
            @if (selectedSlot) {
              <div class="allocation-step">
                <label>
                  <app-icon name="file-text" [size]="16" />
                  Observação (opcional)
                </label>
                <textarea 
                  [(ngModel)]="allocationObservation"
                  placeholder="Adicione uma observação para a consulta..."
                  rows="3"
                ></textarea>
              </div>
            }
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closeAllocationModal()" [disabled]="allocating">
              Cancelar
            </button>
            <button 
              class="btn-primary" 
              (click)="confirmarAlocacao()"
              [disabled]="!selectedSlot || allocating"
            >
              @if (allocating) {
                <div class="spinner-small white"></div>
                Alocando...
              } @else {
                <app-icon name="check" [size]="16" />
                Confirmar Alocação
              }
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

      .allocation-badge {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 6px 12px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 500;
        
        &.allocated { 
          background: #dbeafe; 
          color: #2563eb;
          
          .date-info {
            font-size: 10px;
            opacity: 0.8;
            margin-left: 4px;
          }
        }
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
        &:disabled { opacity: 0.6; cursor: not-allowed; }
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
        &:disabled { opacity: 0.6; cursor: not-allowed; }
      }
    }

    /* Modal de Alocação */
    .allocation-modal {
      max-width: 600px;
      max-height: 85vh;
      overflow-y: auto;
    }

    .allocation-patient-info {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 16px;
      background: #f8fafc;
      border-radius: 12px;
      margin-bottom: 20px;

      .avatar {
        width: 56px;
        height: 56px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
        font-weight: 700;
        color: white;
      }

      .info {
        h3 { margin: 0 0 6px; font-size: 18px; color: #0f172a; }
        .urgency-tag {
          display: inline-block;
          padding: 4px 10px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 600;
          &.urgent { background: #fef2f2; color: #dc2626; }
          &.priority { background: #fefce8; color: #ca8a04; }
          &.normal { background: #f0fdf4; color: #16a34a; }
        }
      }
    }

    .allocation-message {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 16px;
      border-radius: 8px;
      margin-bottom: 16px;
      font-size: 14px;

      &.error {
        background: #fef2f2;
        color: #dc2626;
        border: 1px solid #fecaca;
      }

      &.success {
        background: #f0fdf4;
        color: #16a34a;
        border: 1px solid #bbf7d0;
      }
    }

    .allocation-step {
      margin-bottom: 20px;

      > label {
        display: flex;
        align-items: center;
        gap: 8px;
        font-weight: 600;
        color: #475569;
        margin-bottom: 12px;
        font-size: 14px;
      }

      textarea {
        width: 100%;
        padding: 12px;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        font-size: 14px;
        resize: vertical;
        &:focus { outline: none; border-color: #0d9488; }
      }
    }

    .loading-inline {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 16px;
      color: #64748b;
      font-size: 14px;
    }

    .spinner-small {
      width: 18px;
      height: 18px;
      border: 2px solid #e2e8f0;
      border-top-color: #0d9488;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      &.white { border-color: rgba(255,255,255,0.3); border-top-color: white; }
    }

    .no-schedules {
      text-align: center;
      padding: 24px;
      color: #64748b;
      app-icon { margin-bottom: 8px; }
      p { margin: 0; }
    }

    .schedules-list {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .schedule-option {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 14px 16px;
      border: 2px solid #e2e8f0;
      border-radius: 10px;
      background: white;
      cursor: pointer;
      transition: all 0.2s;
      text-align: left;

      &:hover { border-color: #94a3b8; background: #f8fafc; }

      &.selected {
        border-color: #0d9488;
        background: #f0fdfa;
        app-icon { color: #0d9488; }
      }

      .schedule-info {
        display: flex;
        flex-direction: column;
        gap: 2px;
        strong { color: #0f172a; font-size: 15px; }
        .specialty { color: #64748b; font-size: 13px; }
      }

      app-icon { color: #94a3b8; }
    }

    .slots-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
      gap: 10px;
      max-height: 280px;
      overflow-y: auto;
      padding: 4px;
    }

    .slot-option {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      padding: 12px;
      border: 2px solid #e2e8f0;
      border-radius: 10px;
      background: white;
      cursor: pointer;
      transition: all 0.2s;

      &:hover { border-color: #94a3b8; background: #f8fafc; }

      &.selected {
        border-color: #0d9488;
        background: #f0fdfa;
      }

      .slot-date { font-weight: 600; color: #0f172a; font-size: 14px; }
      .slot-day { color: #64748b; font-size: 12px; }
      .slot-time { 
        font-weight: 700; 
        color: #0d9488; 
        font-size: 16px; 
        margin-top: 4px;
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

  // Propriedades do modal de alocação
  showAllocationModal = false;
  patientForAllocation: QueuePatient | null = null;
  availableSchedules: AvailableSchedule[] = [];
  selectedSchedule: AvailableSchedule | null = null;
  availableSlots: ScheduleSlot[] = [];
  selectedSlot: ScheduleSlot | null = null;
  allocationObservation = '';
  loadingSchedules = false;
  loadingSlots = false;
  allocating = false;
  allocationError: string | null = null;
  allocationSuccess: string | null = null;

  private searchTimeout: any;

  constructor(
    private authService: AuthService,
    private regulatorService: RegulatorService,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit() {
    const user = this.authService.getCurrentUser();
    this.municipioNome = (user as any)?.municipioNome || 'seu município';
    this.loadPatients();
    this.loadSpecialties();
  }

  loadPatients() {
    this.loading = true;
    this.error = null;

    // Carregar fila de espera com urgência real e status de alocação
    this.regulatorService.getWaitingQueue(100).subscribe({
      next: (response) => {
        // Usar dados reais do backend (urgência e alocação já calculados)
        this.queue = response.data.map(patient => ({
          ...patient,
          requestedSpecialty: this.getRandomSpecialty(), // TODO: adicionar no backend
          waitingSince: this.getRandomDate() // TODO: adicionar no backend
        }));
        this.aplicarFiltros();
        this.loading = false;
        this.cdr.detectChanges(); // Força atualização da UI
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

  // === MODAL DE ALOCAÇÃO ===

  alocarPaciente(patient: QueuePatient) {
    this.patientForAllocation = patient;
    this.showAllocationModal = true;
    this.allocationError = null;
    this.allocationSuccess = null;
    this.selectedSchedule = null;
    this.selectedSlot = null;
    this.availableSlots = [];
    this.allocationObservation = '';
    this.loadAvailableSchedules();
  }

  closeAllocationModal() {
    this.showAllocationModal = false;
    this.patientForAllocation = null;
    this.selectedSchedule = null;
    this.selectedSlot = null;
    this.availableSlots = [];
    this.allocationObservation = '';
    this.allocationError = null;
    this.allocationSuccess = null;
  }

  loadAvailableSchedules() {
    this.loadingSchedules = true;
    this.regulatorService.getAvailableSchedules().subscribe({
      next: (schedules) => {
        this.availableSchedules = schedules;
        this.loadingSchedules = false;
      },
      error: (err) => {
        console.error('Erro ao carregar agendas:', err);
        this.allocationError = 'Erro ao carregar agendas disponíveis.';
        this.loadingSchedules = false;
      }
    });
  }

  selectSchedule(schedule: AvailableSchedule) {
    this.selectedSchedule = schedule;
    this.selectedSlot = null;
    this.availableSlots = [];
    this.loadScheduleSlots(schedule.id);
  }

  loadScheduleSlots(scheduleId: string) {
    this.loadingSlots = true;

    // Buscar slots para os próximos 14 dias
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 14);

    const startStr = startDate.toISOString().split('T')[0];
    const endStr = endDate.toISOString().split('T')[0];

    this.regulatorService.getScheduleSlots(scheduleId, startStr, endStr).subscribe({
      next: (response) => {
        this.availableSlots = response.slots;
        this.loadingSlots = false;
      },
      error: (err) => {
        console.error('Erro ao carregar horários:', err);
        this.allocationError = 'Erro ao carregar horários disponíveis.';
        this.loadingSlots = false;
      }
    });
  }

  formatSlotDate(dateStr: string): string {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
  }

  confirmarAlocacao() {
    if (!this.patientForAllocation || !this.selectedSchedule || !this.selectedSlot) {
      return;
    }

    this.allocating = true;
    this.allocationError = null;
    this.allocationSuccess = null;

    const data: AllocatePatientData = {
      patientId: this.patientForAllocation.id,
      scheduleId: this.selectedSchedule.id,
      date: this.selectedSlot.date,
      time: this.selectedSlot.time,
      observation: this.allocationObservation || undefined
    };

    this.regulatorService.allocatePatient(data).subscribe({
      next: (response) => {
        this.allocating = false;
        this.allocationSuccess = `Paciente alocado com sucesso para ${this.formatSlotDate(this.selectedSlot!.date)} às ${this.selectedSlot!.time} com Dr(a). ${response.appointment.professional.name}`;

        // Atualizar status do paciente na lista
        if (this.patientForAllocation) {
          this.patientForAllocation.hasAllocation = true;
          this.patientForAllocation.nextAppointmentDate = this.selectedSlot!.date;
        }

        // Fechar modal após 2 segundos
        setTimeout(() => {
          this.closeAllocationModal();
          this.loadPatients(); // Recarregar lista
        }, 2000);
      },
      error: (err) => {
        this.allocating = false;
        this.allocationError = err.error?.message || 'Erro ao alocar paciente. Tente novamente.';
      }
    });
  }
}
