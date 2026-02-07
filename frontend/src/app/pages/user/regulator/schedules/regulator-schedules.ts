import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { AuthService } from '@app/core/services/auth.service';
import { RegulatorService, AvailableSchedule, Specialty } from '@app/core/services/regulator.service';

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
    @if (selectedSchedule) {
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

  constructor(
    private authService: AuthService,
    private regulatorService: RegulatorService
  ) {}

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

  verDetalhes(schedule: AvailableSchedule) {
    this.selectedSchedule = schedule;
  }

  alocarPaciente(schedule: AvailableSchedule) {
    // TODO: Implementar modal de alocação de paciente
    alert(`Funcionalidade de alocação para agenda de ${schedule.professional.name} será implementada em breve.`);
  }

  closeModal() {
    this.selectedSchedule = null;
  }
}
