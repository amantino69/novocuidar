import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { AuthService } from '@app/core/services/auth.service';
import { RegulatorService, AvailableSchedule, Specialty, ScheduleSlot, ScheduleSlotsResponse, RegulatorPatient } from '@app/core/services/regulator.service';

@Component({
  selector: 'app-regulator-schedules',
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
          <app-icon name="calendar" [size]="28" />
          Agendas Disponíveis
        </h1>
        <p class="subtitle">Agendas liberadas para {{ municipioNome }}</p>
      </header>

      <!-- Filtros -->
      <div class="filters-bar">
        <div class="filter-group">
          <label>Especialidade</label>
          <select [(ngModel)]="filtroEspecialidade" (change)="aplicarFiltros()">
            <option value="">Todas</option>
            @for (esp of specialties; track esp.id) {
              <option [value]="esp.name">{{ esp.name }}</option>
            }
          </select>
        </div>
        <div class="filter-group">
          <label>Status</label>
          <select [(ngModel)]="filtroStatus" (change)="aplicarFiltros()">
            <option value="">Todos</option>
            <option value="active">Ativas</option>
            <option value="inactive">Inativas</option>
          </select>
        </div>
        <button class="btn-refresh" (click)="loadSchedules()">
          <app-icon name="refresh-cw" [size]="18" />
          Atualizar
        </button>
      </div>

      <!-- Loading -->
      @if (loading) {
        <div class="loading-container">
          <div class="spinner"></div>
          <p>Carregando agendas...</p>
        </div>
      }

      <!-- Erro -->
      @if (error && !loading) {
        <div class="error-message">
          <app-icon name="alert-circle" [size]="24" />
          <p>{{ error }}</p>
          <button (click)="loadSchedules()">Tentar novamente</button>
        </div>
      }

      <!-- Lista de Agendas -->
      @if (!loading && !error) {
        @if (schedulesFiltered.length === 0) {
          <div class="empty-state">
            <app-icon name="calendar" [size]="64" />
            <h2>Nenhuma agenda encontrada</h2>
            <p>Não há agendas disponíveis com os filtros selecionados.</p>
          </div>
        } @else {
          <div class="schedules-summary">
            <span class="badge active">{{ countAtivas }} ativas</span>
            <span class="badge inactive">{{ countInativas }} inativas</span>
            <span class="badge total">{{ schedulesFiltered.length }} total</span>
          </div>

          <div class="schedules-grid">
            @for (schedule of schedulesFiltered; track schedule.id) {
              <div class="schedule-card" [class.inactive]="!schedule.isActive">
                <div class="card-header">
                  <div class="professional-info">
                    <div class="avatar">
                      {{ getInitials(schedule.professional.name) }}
                    </div>
                    <div class="details">
                      <h3>{{ schedule.professional.name }}</h3>
                      <span class="specialty">{{ schedule.professional.specialty }}</span>
                    </div>
                  </div>
                  <span class="status-badge" [class.active]="schedule.isActive">
                    {{ schedule.isActive ? 'Ativa' : 'Inativa' }}
                  </span>
                </div>

                <div class="card-body">
                  <div class="info-row">
                    <app-icon name="calendar" [size]="16" />
                    <span>Início: {{ formatDate(schedule.validityStartDate) }}</span>
                  </div>
                  @if (schedule.validityEndDate) {
                    <div class="info-row">
                      <app-icon name="calendar" [size]="16" />
                      <span>Término: {{ formatDate(schedule.validityEndDate) }}</span>
                    </div>
                  } @else {
                    <div class="info-row">
                      <app-icon name="clock" [size]="16" />
                      <span>Sem data de término</span>
                    </div>
                  }
                </div>

                <div class="card-actions">
                  <button class="btn-secondary" (click)="verDetalhes(schedule)">
                    <app-icon name="eye" [size]="16" />
                    Ver Detalhes
                  </button>
                  @if (schedule.isActive) {
                    <button class="btn-primary" (click)="alocarPaciente(schedule)">
                      <app-icon name="plus-circle" [size]="16" />
                      Alocar Paciente
                    </button>
                  }
                </div>
              </div>
            }
          </div>
        }
      }
    </div>

    <!-- Modal Ver Detalhes (simplificado) -->
    @if (selectedSchedule && !showAllocationModal) {
      <div class="modal-overlay" (click)="closeModal()">
        <div class="modal-content" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>Detalhes da Agenda</h2>
            <button class="close-btn" (click)="closeModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <div class="detail-section">
              <h4>Profissional</h4>
              <p><strong>{{ selectedSchedule.professional.name }}</strong></p>
              <p>{{ selectedSchedule.professional.specialty }}</p>
            </div>
            <div class="detail-section">
              <h4>Período de Vigência</h4>
              <p>Início: {{ formatDate(selectedSchedule.validityStartDate) }}</p>
              <p>Término: {{ selectedSchedule.validityEndDate ? formatDate(selectedSchedule.validityEndDate) : 'Indeterminado' }}</p>
            </div>
            <div class="detail-section">
              <h4>Status</h4>
              <span class="status-badge large" [class.active]="selectedSchedule.isActive">
                {{ selectedSchedule.isActive ? 'Agenda Ativa' : 'Agenda Inativa' }}
              </span>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closeModal()">Fechar</button>
          </div>
        </div>
      </div>
    }

    <!-- Modal Alocar Paciente -->
    @if (showAllocationModal && allocationSchedule) {
      <div class="modal-overlay" (click)="closeAllocationModal()">
        <div class="modal-content allocation-modal" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>
              <app-icon name="plus-circle" [size]="24" />
              Alocar Paciente
            </h2>
            <button class="close-btn" (click)="closeAllocationModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          
          <div class="modal-body allocation-body">
            <!-- Info do Profissional -->
            <div class="allocation-info">
              <div class="professional-badge">
                <div class="avatar">{{ getInitials(allocationSchedule.professional.name) }}</div>
                <div>
                  <strong>{{ allocationSchedule.professional.name }}</strong>
                  <span>{{ allocationSchedule.professional.specialty }}</span>
                </div>
              </div>
            </div>

            <!-- Passo 1: Selecionar Paciente -->
            <div class="allocation-step" [class.completed]="selectedPatient">
              <div class="step-header">
                <span class="step-number">1</span>
                <h4>Selecionar Paciente</h4>
              </div>
              
              <div class="patient-search">
                <div class="search-input">
                  <app-icon name="search" [size]="18" />
                  <input 
                    type="text" 
                    placeholder="Buscar paciente por nome ou CPF..."
                    [(ngModel)]="patientSearchTerm"
                    (input)="searchPatients()"
                  />
                </div>
                
                @if (loadingPatients) {
                  <div class="loading-small">
                    <div class="spinner-small"></div>
                    <span>Buscando...</span>
                  </div>
                }
                
                @if (patients.length > 0 && !selectedPatient) {
                  <div class="patients-list">
                    @for (patient of patients; track patient.id) {
                      <div class="patient-item" (click)="selectPatient(patient)">
                        <div class="patient-avatar">{{ getInitials(patient.fullName) }}</div>
                        <div class="patient-info">
                          <strong>{{ patient.fullName }}</strong>
                          <span>{{ formatCpf(patient.cpf) }}</span>
                        </div>
                      </div>
                    }
                  </div>
                }
                
                @if (selectedPatient) {
                  <div class="selected-patient">
                    <div class="patient-avatar selected">{{ getInitials(selectedPatient.fullName) }}</div>
                    <div class="patient-info">
                      <strong>{{ selectedPatient.fullName }}</strong>
                      <span>{{ formatCpf(selectedPatient.cpf) }}</span>
                    </div>
                    <button class="btn-change" (click)="clearSelectedPatient()">
                      <app-icon name="x" [size]="16" />
                    </button>
                  </div>
                }
              </div>
            </div>

            <!-- Passo 2: Selecionar Horário -->
            <div class="allocation-step" [class.disabled]="!selectedPatient" [class.completed]="selectedSlot">
              <div class="step-header">
                <span class="step-number">2</span>
                <h4>Selecionar Horário</h4>
              </div>
              
              @if (selectedPatient) {
                @if (loadingSlots) {
                  <div class="loading-small">
                    <div class="spinner-small"></div>
                    <span>Carregando horários disponíveis...</span>
                  </div>
                } @else if (availableSlots.length === 0) {
                  <div class="no-slots">
                    <app-icon name="alert-circle" [size]="32" />
                    <p>Nenhum horário disponível nos próximos 30 dias.</p>
                  </div>
                } @else {
                  <div class="slots-grid">
                    @for (slot of displayedSlots; track slot.date + slot.time) {
                      <div 
                        class="slot-item" 
                        [class.selected]="isSlotSelected(slot)"
                        (click)="selectSlot(slot)"
                      >
                        <div class="slot-date">
                          <strong>{{ formatDateShort(slot.date) }}</strong>
                          <span>{{ slot.dayOfWeekPt }}</span>
                        </div>
                        <div class="slot-time">{{ slot.time }}</div>
                      </div>
                    }
                  </div>
                  @if (availableSlots.length > 12) {
                    <button class="btn-load-more" (click)="loadMoreSlots()">
                      Mostrar mais horários ({{ availableSlots.length - displayedSlots.length }} restantes)
                    </button>
                  }
                }
              }
            </div>

            <!-- Passo 3: Observação (opcional) -->
            <div class="allocation-step" [class.disabled]="!selectedSlot">
              <div class="step-header">
                <span class="step-number">3</span>
                <h4>Observação (opcional)</h4>
              </div>
              
              @if (selectedSlot) {
                <textarea 
                  class="observation-input"
                  placeholder="Digite uma observação sobre esta alocação..."
                  [(ngModel)]="allocationObservation"
                  rows="3"
                ></textarea>
              }
            </div>
          </div>
          
          <div class="modal-footer allocation-footer">
            <button class="btn-secondary" (click)="closeAllocationModal()">Cancelar</button>
            <button 
              class="btn-primary" 
              [disabled]="!canAllocate() || allocating"
              (click)="confirmAllocation()"
            >
              @if (allocating) {
                <div class="spinner-small white"></div>
                Alocando...
              } @else {
                <app-icon name="check" [size]="18" />
                Confirmar Alocação
              }
            </button>
          </div>
        </div>
      </div>
    }

    <!-- Toast de Sucesso -->
    @if (showSuccessToast) {
      <div class="toast success">
        <app-icon name="check-circle" [size]="24" />
        <span>{{ successMessage }}</span>
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
      .subtitle {
        color: #64748b;
        margin: 0;
      }
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
      transition: all 0.2s;
      &:hover {
        background: #e2e8f0;
        color: #0d9488;
      }
    }

    .filters-bar {
      display: flex;
      gap: 16px;
      align-items: flex-end;
      margin-bottom: 24px;
      padding: 16px;
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
      flex-wrap: wrap;

      .filter-group {
        display: flex;
        flex-direction: column;
        gap: 6px;

        label {
          font-size: 12px;
          font-weight: 600;
          color: #64748b;
          text-transform: uppercase;
        }

        select {
          padding: 10px 14px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          font-size: 14px;
          min-width: 180px;
          background: white;
          cursor: pointer;
          &:focus {
            outline: none;
            border-color: #0d9488;
          }
        }
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
        margin-left: auto;
        &:hover {
          background: #f1f5f9;
          color: #0d9488;
        }
      }
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px;
      .spinner {
        width: 48px;
        height: 48px;
        border: 4px solid #e2e8f0;
        border-top-color: #0d9488;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }
      p {
        margin-top: 16px;
        color: #64748b;
      }
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .error-message {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 40px;
      background: #fef2f2;
      border-radius: 12px;
      color: #dc2626;
      app-icon { margin-bottom: 12px; }
      p { margin: 0 0 16px; }
      button {
        padding: 8px 16px;
        background: #dc2626;
        color: white;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        &:hover { background: #b91c1c; }
      }
    }

    .empty-state {
      text-align: center;
      padding: 60px 24px;
      background: white;
      border-radius: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
      app-icon { color: #94a3b8; margin-bottom: 16px; }
      h2 { font-size: 20px; color: #0f172a; margin: 0 0 8px; }
      p { color: #64748b; margin: 0; }
    }

    .schedules-summary {
      display: flex;
      gap: 12px;
      margin-bottom: 20px;
      .badge {
        padding: 6px 12px;
        border-radius: 20px;
        font-size: 13px;
        font-weight: 500;
        &.active { background: #dcfce7; color: #16a34a; }
        &.inactive { background: #fee2e2; color: #dc2626; }
        &.total { background: #e0f2fe; color: #0284c7; }
      }
    }

    .schedules-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
      gap: 20px;
    }

    .schedule-card {
      background: white;
      border-radius: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
      overflow: hidden;
      transition: transform 0.2s, box-shadow 0.2s;
      &:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 24px rgba(0,0,0,0.12);
      }
      &.inactive {
        opacity: 0.7;
        .card-header { background: #f1f5f9; }
      }
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
      color: white;

      .professional-info {
        display: flex;
        align-items: center;
        gap: 12px;

        .avatar {
          width: 48px;
          height: 48px;
          border-radius: 50%;
          background: rgba(255,255,255,0.2);
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 700;
          font-size: 16px;
        }

        .details {
          h3 {
            margin: 0;
            font-size: 16px;
            font-weight: 600;
          }
          .specialty {
            font-size: 13px;
            opacity: 0.9;
          }
        }
      }

      .status-badge {
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 12px;
        font-weight: 600;
        background: rgba(255,255,255,0.2);
        &.active {
          background: #22c55e;
        }
      }
    }

    .card-body {
      padding: 16px;
      .info-row {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 8px 0;
        color: #64748b;
        font-size: 14px;
        border-bottom: 1px solid #f1f5f9;
        &:last-child { border-bottom: none; }
        app-icon { color: #94a3b8; }
      }
    }

    .card-actions {
      display: flex;
      gap: 8px;
      padding: 16px;
      border-top: 1px solid #f1f5f9;

      button {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        padding: 10px;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
      }

      .btn-secondary {
        background: #f1f5f9;
        border: none;
        color: #64748b;
        &:hover { background: #e2e8f0; }
      }

      .btn-primary {
        background: #0d9488;
        border: none;
        color: white;
        &:hover { background: #0f766e; }
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
      max-width: 500px;
      max-height: 90vh;
      overflow-y: auto;
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
      .detail-section {
        margin-bottom: 20px;
        h4 {
          margin: 0 0 8px;
          font-size: 12px;
          text-transform: uppercase;
          color: #64748b;
        }
        p { margin: 4px 0; color: #0f172a; }
      }
      .status-badge.large {
        display: inline-block;
        padding: 8px 16px;
        border-radius: 8px;
        font-size: 14px;
        font-weight: 600;
        background: #fee2e2;
        color: #dc2626;
        &.active {
          background: #dcfce7;
          color: #16a34a;
        }
      }
    }

    .modal-footer {
      display: flex;
      justify-content: flex-end;
      padding: 16px 20px;
      border-top: 1px solid #e2e8f0;
    }

    /* Modal Alocação */
    .allocation-modal {
      max-width: 600px;
      width: 95%;
    }

    .allocation-body {
      max-height: 60vh;
      overflow-y: auto;
    }

    .allocation-info {
      margin-bottom: 20px;
      .professional-badge {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 12px 16px;
        background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
        border-radius: 12px;
        color: white;
        .avatar {
          width: 48px;
          height: 48px;
          border-radius: 50%;
          background: rgba(255,255,255,0.2);
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 700;
          font-size: 16px;
        }
        strong { display: block; font-size: 16px; }
        span { opacity: 0.9; font-size: 14px; }
      }
    }

    .allocation-step {
      margin-bottom: 20px;
      padding: 16px;
      background: #f8fafc;
      border-radius: 12px;
      border: 2px solid transparent;
      transition: all 0.2s;
      &.completed { border-color: #10b981; background: #f0fdf4; }
      &.disabled { opacity: 0.5; pointer-events: none; }
      .step-header {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 12px;
        .step-number {
          width: 28px;
          height: 28px;
          border-radius: 50%;
          background: #0d9488;
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 700;
          font-size: 14px;
        }
        h4 { margin: 0; font-size: 15px; color: #0f172a; }
      }
    }

    .patient-search {
      .search-input {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 10px 14px;
        background: white;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        transition: border-color 0.2s;
        &:focus-within { border-color: #0d9488; }
        input {
          flex: 1;
          border: none;
          outline: none;
          font-size: 14px;
          &::placeholder { color: #94a3b8; }
        }
      }
    }

    .loading-small {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px;
      color: #64748b;
      .spinner-small {
        width: 20px;
        height: 20px;
        border: 2px solid #e2e8f0;
        border-top-color: #0d9488;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
        &.white { border-color: rgba(255,255,255,0.3); border-top-color: white; }
      }
    }

    .patients-list {
      margin-top: 12px;
      max-height: 200px;
      overflow-y: auto;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      background: white;
    }

    .patient-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px;
      cursor: pointer;
      transition: background 0.2s;
      border-bottom: 1px solid #f1f5f9;
      &:last-child { border-bottom: none; }
      &:hover { background: #f0fdf4; }
      .patient-avatar {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: #e0f2fe;
        color: #0284c7;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 600;
        font-size: 14px;
      }
      .patient-info {
        strong { display: block; font-size: 14px; color: #0f172a; }
        span { font-size: 12px; color: #64748b; }
      }
    }

    .selected-patient {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-top: 12px;
      padding: 12px 16px;
      background: #dcfce7;
      border: 2px solid #10b981;
      border-radius: 10px;
      .patient-avatar.selected {
        background: #10b981;
        color: white;
      }
      .btn-change {
        margin-left: auto;
        width: 28px;
        height: 28px;
        border-radius: 50%;
        border: none;
        background: #fee2e2;
        color: #dc2626;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        &:hover { background: #fecaca; }
      }
    }

    .no-slots {
      text-align: center;
      padding: 24px;
      color: #64748b;
      p { margin: 8px 0 0; }
    }

    .slots-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
      max-height: 240px;
      overflow-y: auto;
    }

    .slot-item {
      padding: 12px;
      background: white;
      border: 2px solid #e2e8f0;
      border-radius: 10px;
      cursor: pointer;
      text-align: center;
      transition: all 0.2s;
      &:hover { border-color: #0d9488; background: #f0fdfa; }
      &.selected {
        border-color: #10b981;
        background: #dcfce7;
      }
      .slot-date {
        margin-bottom: 4px;
        strong { display: block; font-size: 14px; color: #0f172a; }
        span { font-size: 11px; color: #64748b; }
      }
      .slot-time {
        font-size: 16px;
        font-weight: 700;
        color: #0d9488;
      }
    }

    .btn-load-more {
      display: block;
      width: 100%;
      margin-top: 12px;
      padding: 10px;
      background: #f1f5f9;
      border: 1px dashed #94a3b8;
      border-radius: 8px;
      color: #64748b;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
      &:hover { background: #e2e8f0; color: #475569; }
    }

    .observation-input {
      width: 100%;
      padding: 12px;
      border: 2px solid #e2e8f0;
      border-radius: 10px;
      font-size: 14px;
      resize: vertical;
      font-family: inherit;
      &:focus { outline: none; border-color: #0d9488; }
    }

    .allocation-footer {
      gap: 12px;
      .btn-primary {
        display: flex;
        align-items: center;
        gap: 8px;
        &:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
      }
    }

    .toast {
      position: fixed;
      bottom: 24px;
      right: 24px;
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px 24px;
      border-radius: 12px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.15);
      animation: slideIn 0.3s ease-out;
      z-index: 10000;
      &.success { background: #10b981; color: white; }
      &.error { background: #dc2626; color: white; }
    }

    @keyframes slideIn {
      from { transform: translateX(100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
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
      .filters-bar {
        background: #1e293b;
        select {
          background: #334155;
          border-color: #475569;
          color: #f1f5f9;
        }
      }
      .schedule-card {
        background: #1e293b;
        &.inactive .card-header { background: #334155; }
      }
      .card-body .info-row { color: #94a3b8; border-color: #334155; }
      .card-actions { border-color: #334155; }
      .card-actions .btn-secondary { background: #334155; color: #94a3b8; }
      .empty-state { background: #1e293b; }
      .empty-state h2 { color: #f1f5f9; }
      .modal-content { background: #1e293b; }
      .modal-header { border-color: #334155; }
      .modal-header h2 { color: #f1f5f9; }
      .modal-body p { color: #f1f5f9; }
      .modal-footer { border-color: #334155; }
    }
  `]
})
export class RegulatorSchedulesComponent implements OnInit {
  municipioNome = '';
  schedules: AvailableSchedule[] = [];
  schedulesFiltered: AvailableSchedule[] = [];
  specialties: Specialty[] = [];

  loading = true;
  error: string | null = null;

  filtroEspecialidade = '';
  filtroStatus = '';

  selectedSchedule: AvailableSchedule | null = null;

  // Allocation Modal
  showAllocationModal = false;
  allocationSchedule: AvailableSchedule | null = null;

  // Patient selection
  patientSearchTerm = '';
  patients: RegulatorPatient[] = [];
  selectedPatient: RegulatorPatient | null = null;
  loadingPatients = false;
  private searchTimeout: any;

  // Slot selection
  availableSlots: ScheduleSlot[] = [];
  displayedSlots: ScheduleSlot[] = [];
  selectedSlot: ScheduleSlot | null = null;
  loadingSlots = false;

  // Allocation
  allocationObservation = '';
  allocating = false;

  // Toast
  showSuccessToast = false;
  successMessage = '';

  constructor(
    private authService: AuthService,
    private regulatorService: RegulatorService,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit() {
    const user = this.authService.getCurrentUser();
    this.municipioNome = (user as any)?.municipioNome || 'seu município';
    this.loadSchedules();
    this.loadSpecialties();
  }

  loadSchedules() {
    this.loading = true;
    this.error = null;

    this.regulatorService.getAvailableSchedules().subscribe({
      next: (data) => {
        this.schedules = data;
        this.aplicarFiltros();
        this.loading = false;
        this.cdr.detectChanges(); // Força atualização da UI
      },
      error: (err) => {
        console.error('Erro ao carregar agendas:', err);
        this.error = 'Não foi possível carregar as agendas. Tente novamente.';
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

  aplicarFiltros() {
    let filtered = [...this.schedules];

    if (this.filtroEspecialidade) {
      filtered = filtered.filter(s =>
        s.professional.specialty.toLowerCase().includes(this.filtroEspecialidade.toLowerCase())
      );
    }

    if (this.filtroStatus === 'active') {
      filtered = filtered.filter(s => s.isActive);
    } else if (this.filtroStatus === 'inactive') {
      filtered = filtered.filter(s => !s.isActive);
    }

    this.schedulesFiltered = filtered;
  }

  get countAtivas(): number {
    return this.schedulesFiltered.filter(s => s.isActive).length;
  }

  get countInativas(): number {
    return this.schedulesFiltered.filter(s => !s.isActive).length;
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .filter(n => n.length > 0)
      .slice(0, 2)
      .map(n => n[0].toUpperCase())
      .join('');
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR');
  }

  formatDateShort(dateStr: string): string {
    if (!dateStr) return '-';
    const date = new Date(dateStr + 'T00:00:00');
    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
  }

  formatCpf(cpf: string): string {
    if (!cpf) return '-';
    const cleaned = cpf.replace(/\D/g, '');
    if (cleaned.length !== 11) return cpf;
    return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
  }

  verDetalhes(schedule: AvailableSchedule) {
    this.selectedSchedule = schedule;
  }

  alocarPaciente(schedule: AvailableSchedule) {
    this.allocationSchedule = schedule;
    this.showAllocationModal = true;
    this.resetAllocationState();
  }

  closeModal() {
    this.selectedSchedule = null;
  }

  closeAllocationModal() {
    this.showAllocationModal = false;
    this.allocationSchedule = null;
    this.resetAllocationState();
  }

  private resetAllocationState() {
    this.patientSearchTerm = '';
    this.patients = [];
    this.selectedPatient = null;
    this.availableSlots = [];
    this.displayedSlots = [];
    this.selectedSlot = null;
    this.allocationObservation = '';
    this.allocating = false;
  }

  // Patient Search
  searchPatients() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    if (this.patientSearchTerm.length < 2) {
      this.patients = [];
      return;
    }

    this.searchTimeout = setTimeout(() => {
      this.loadingPatients = true;
      this.regulatorService.searchPatientsForAllocation(this.patientSearchTerm).subscribe({
        next: (data) => {
          this.patients = data;
          this.loadingPatients = false;
        },
        error: (err) => {
          console.error('Erro ao buscar pacientes:', err);
          this.patients = [];
          this.loadingPatients = false;
        }
      });
    }, 300);
  }

  selectPatient(patient: RegulatorPatient) {
    this.selectedPatient = patient;
    this.patients = [];
    this.patientSearchTerm = '';
    this.loadSlots();
  }

  clearSelectedPatient() {
    this.selectedPatient = null;
    this.availableSlots = [];
    this.displayedSlots = [];
    this.selectedSlot = null;
  }

  // Slots
  loadSlots() {
    if (!this.allocationSchedule) return;

    this.loadingSlots = true;
    this.regulatorService.getScheduleSlots(this.allocationSchedule.id).subscribe({
      next: (response: ScheduleSlotsResponse) => {
        this.availableSlots = response.slots;
        this.displayedSlots = this.availableSlots.slice(0, 12);
        this.loadingSlots = false;
      },
      error: (err) => {
        console.error('Erro ao carregar horários:', err);
        this.availableSlots = [];
        this.displayedSlots = [];
        this.loadingSlots = false;
      }
    });
  }

  loadMoreSlots() {
    const currentCount = this.displayedSlots.length;
    this.displayedSlots = this.availableSlots.slice(0, currentCount + 12);
  }

  selectSlot(slot: ScheduleSlot) {
    this.selectedSlot = slot;
  }

  isSlotSelected(slot: ScheduleSlot): boolean {
    return this.selectedSlot?.date === slot.date && this.selectedSlot?.time === slot.time;
  }

  canAllocate(): boolean {
    return !!this.selectedPatient && !!this.selectedSlot;
  }

  confirmAllocation() {
    if (!this.canAllocate() || !this.allocationSchedule || !this.selectedPatient || !this.selectedSlot) return;

    this.allocating = true;

    this.regulatorService.allocatePatient({
      patientId: this.selectedPatient.id,
      scheduleId: this.allocationSchedule.id,
      date: this.selectedSlot.date,
      time: this.selectedSlot.time,
      observation: this.allocationObservation || undefined
    }).subscribe({
      next: (response) => {
        this.allocating = false;
        this.closeAllocationModal();
        this.showSuccess(`Paciente ${this.selectedPatient?.fullName} alocado com sucesso!`);
        this.loadSchedules(); // Refresh list
      },
      error: (err) => {
        console.error('Erro ao alocar paciente:', err);
        this.allocating = false;
        alert(err.error?.message || 'Erro ao alocar paciente. Tente novamente.');
      }
    });
  }

  private showSuccess(message: string) {
    this.successMessage = message;
    this.showSuccessToast = true;
    setTimeout(() => {
      this.showSuccessToast = false;
    }, 4000);
  }
}
