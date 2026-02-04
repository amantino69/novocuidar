import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subject, interval, takeUntil } from 'rxjs';
import { environment } from '@env/environment';

interface TodayAppointment {
  id: string;
  scheduledDate: string;
  status: string;
  patientName: string;
  professionalName: string;
  specialty: string;
  checkInTime?: string;
}

interface WaitingListItem {
  id: string;
  appointmentId: string;
  patientName: string;
  professionalName: string;
  specialtyName: string;
  position: number;
  priority: number;
  checkInTime: string;
  waitingTime: number;
  status: string;
  isSpontaneousDemand?: boolean;
  urgencyLevel?: string;
  chiefComplaint?: string;
}

interface SpontaneousDemand {
  id: string;
  date: string;
  time: string;
  status: string;
  checkInTime: string;
  patientName: string;
  patientCpf: string;
  professionalName: string;
  specialtyName: string;
  chiefComplaint: string;
  createdAt: string;
}

interface Statistics {
  totalScheduled: number;
  checkedIn: number;
  inConsultation: number;
  completed: number;
  noShows: number;
  averageWaitTime: number;
}

@Component({
  selector: 'app-receptionist-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="receptionist-dashboard">
      <!-- Header -->
      <div class="header">
        <h1>📋 Recepção - Telecuidar</h1>
        <div class="current-time">{{ currentTime | date:'HH:mm:ss' }}</div>
      </div>

      <!-- Botão de Demanda Espontânea -->
      <div class="emergency-button-container">
        <button class="btn-emergency" (click)="openEmergencyModal()" title="Criar consulta de urgência">
          🚨 Demanda Espontânea (Urgência)
        </button>
      </div>

      <!-- Estatísticas -->
      <div class="statistics-grid" *ngIf="statistics">
        <div class="stat-card">
          <div class="stat-icon">📅</div>
          <div class="stat-content">
            <div class="stat-value">{{ statistics.totalScheduled }}</div>
            <div class="stat-label">Agendadas Hoje</div>
          </div>
        </div>
        
        <div class="stat-card checked-in">
          <div class="stat-icon">✅</div>
          <div class="stat-content">
            <div class="stat-value">{{ statistics.checkedIn }}</div>
            <div class="stat-label">Presença Confirmada</div>
          </div>
        </div>
        
        <div class="stat-card in-progress">
          <div class="stat-icon">🏥</div>
          <div class="stat-content">
            <div class="stat-value">{{ statistics.inConsultation }}</div>
            <div class="stat-label">Em Consulta</div>
          </div>
        </div>
        
        <div class="stat-card completed">
          <div class="stat-icon">✔️</div>
          <div class="stat-content">
            <div class="stat-value">{{ statistics.completed }}</div>
            <div class="stat-label">Concluídas</div>
          </div>
        </div>
        
        <div class="stat-card no-show">
          <div class="stat-icon">❌</div>
          <div class="stat-content">
            <div class="stat-value">{{ statistics.noShows }}</div>
            <div class="stat-label">Faltaram</div>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">⏱️</div>
          <div class="stat-content">
            <div class="stat-value">{{ statistics.averageWaitTime }}min</div>
            <div class="stat-label">Tempo Médio</div>
          </div>
        </div>
      </div>

      <!-- Fila de Espera -->
      <div class="waiting-list-section">
        <div class="section-header">
          <h2>🪑 Fila de Espera ({{ waitingList.length }})</h2>
          <button class="btn-refresh" (click)="refreshData()" [disabled]="loading">
            <span [class.spinning]="loading">🔄</span> Atualizar
          </button>
        </div>

        <div class="waiting-list">
          <div *ngIf="waitingList.length === 0" class="empty-state">
            <p>Nenhum paciente na fila de espera</p>
          </div>

          <div *ngFor="let item of waitingList" class="waiting-item" [class.priority]="item.priority">
            <div class="position-badge">{{ item.position }}</div>
            
            <div class="item-content">
              <div class="patient-info">
                <h3>{{ item.patientName }}</h3>
                <p class="doctor-info">Dr(a). {{ item.professionalName }} - {{ item.specialtyName }}</p>
              </div>
              
              <div class="item-details">
                <div class="detail">
                  <span class="label">Chegada:</span>
                  <span class="value">{{ item.checkInTime | date:'HH:mm' }}</span>
                </div>
                <div class="detail">
                  <span class="label">Aguardando:</span>
                  <span class="value" [class.warning]="item.waitingTime > 15">
                    {{ item.waitingTime }} min
                  </span>
                </div>
                <div class="detail">
                  <span class="status-badge" [ngClass]="'status-' + item.status.toLowerCase()">
                    {{ getStatusLabel(item.status) }}
                  </span>
                </div>
                <div *ngIf="item.isSpontaneousDemand" class="spontaneous-badge">
                  🚨 DEMANDA ESPONTÂNEA
                  <span class="urgency-badge" [ngClass]="'urgency-' + item.urgencyLevel?.toLowerCase()">
                    {{ item.urgencyLevel }}
                  </span>
                </div>
                <div *ngIf="item.chiefComplaint" class="chief-complaint">
                  <strong>Queixa:</strong> {{ item.chiefComplaint }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Demandas Espontâneas do Dia -->
      <div class="spontaneous-section" *ngIf="spontaneousDemands.length > 0">
        <h2>🚨 Demandas Espontâneas Criadas Hoje</h2>
        
        <div class="spontaneous-list">
          <div class="spontaneous-item" *ngFor="let demand of spontaneousDemands">
            <div class="item-header">
              <span class="item-time">{{ demand.createdAt | date:'HH:mm' }}</span>
              <span class="status-badge" [ngClass]="'status-' + demand.status.toLowerCase()">
                {{ getStatusLabel(demand.status) }}
              </span>
            </div>
            <div class="item-body">
              <div class="item-row">
                <strong>Paciente:</strong> {{ demand.patientName }}
                <span class="cpf">({{ demand.patientCpf }})</span>
              </div>
              <div class="item-row">
                <strong>Médico:</strong> {{ demand.professionalName }}
              </div>
              <div class="item-row">
                <strong>Especialidade:</strong> {{ demand.specialtyName }}
              </div>
              <div class="item-row" *ngIf="demand.chiefComplaint">
                <strong>Queixa:</strong> {{ demand.chiefComplaint }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Consultas de Hoje -->
      <div class="appointments-section">
        <h2>📅 Consultas de Hoje</h2>
        
        <div *ngIf="todayAppointments.length === 0" class="empty-state">
          <p>Nenhuma consulta agendada para hoje</p>
        </div>

        <div class="appointments-table">
          <table *ngIf="todayAppointments.length > 0">
            <thead>
              <tr>
                <th>Horário</th>
                <th>Paciente</th>
                <th>Profissional</th>
                <th>Especialidade</th>
                <th>Status</th>
                <th>Ações</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let appointment of todayAppointments">
                <td>{{ appointment.scheduledDate | date:'HH:mm' }}</td>
                <td>{{ appointment.patientName }}</td>
                <td>{{ appointment.professionalName }}</td>
                <td>{{ appointment.specialty }}</td>
                <td>
                  <span class="status-badge" [ngClass]="'status-' + appointment.status.toLowerCase()">
                    {{ getStatusLabel(appointment.status) }}
                  </span>
                </td>
                <td>
                  <button 
                    *ngIf="appointment.status === 'Scheduled' || appointment.status === 'Confirmed'"
                    class="btn-check-in"
                    (click)="checkIn(appointment.id)"
                    [disabled]="loading">
                    ✅ Confirmar Presença
                  </button>
                  
                  <button 
                    *ngIf="appointment.status === 'Scheduled' || appointment.status === 'Confirmed'"
                    class="btn-no-show"
                    (click)="markNoShow(appointment.id)"
                    [disabled]="loading">
                    ❌ Faltou
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .receptionist-dashboard {
      padding: 24px;
      max-width: 1400px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
      padding-bottom: 16px;
      border-bottom: 2px solid #e2e8f0;
    }

    .header h1 {
      margin: 0;
      font-size: 32px;
      color: #2d3748;
    }

    .current-time {
      font-size: 24px;
      font-weight: 600;
      color: #667eea;
    }

    .statistics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }

    .stat-card {
      background: white;
      border-radius: 12px;
      padding: 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      transition: transform 0.2s;
    }

    .stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .stat-card.checked-in {
      border-left: 4px solid #48bb78;
    }

    .stat-card.in-progress {
      border-left: 4px solid #4299e1;
    }

    .stat-card.completed {
      border-left: 4px solid #9f7aea;
    }

    .stat-card.no-show {
      border-left: 4px solid #f56565;
    }

    .stat-icon {
      font-size: 36px;
    }

    .emergency-button-container {
      display: flex;
      gap: 12px;
      margin-bottom: 24px;
      justify-content: center;
    }

    .btn-emergency {
      background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
      color: white;
      border: none;
      padding: 14px 28px;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      box-shadow: 0 4px 12px rgba(255, 107, 107, 0.4);
      transition: all 0.3s ease;
      animation: pulse 2s infinite;
    }

    .btn-emergency:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(255, 107, 107, 0.6);
    }

    .btn-emergency:active {
      transform: translateY(0);
    }

    @keyframes pulse {
      0%, 100% {
        box-shadow: 0 4px 12px rgba(255, 107, 107, 0.4);
      }
      50% {
        box-shadow: 0 4px 20px rgba(255, 107, 107, 0.7);
      }
    }

    .stat-content {
      flex: 1;
    }

    .stat-value {
      font-size: 32px;
      font-weight: 700;
      color: #2d3748;
      line-height: 1;
    }

    .stat-label {
      font-size: 14px;
      color: #718096;
      margin-top: 4px;
    }

    .waiting-list-section, .appointments-section {
      background: white;
      border-radius: 12px;
      padding: 24px;
      margin-bottom: 24px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .section-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .section-header h2 {
      margin: 0;
      font-size: 24px;
      color: #2d3748;
    }

    .btn-refresh {
      background: #667eea;
      color: white;
      border: none;
      padding: 10px 20px;
      border-radius: 8px;
      cursor: pointer;
      font-size: 14px;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .btn-refresh:hover:not(:disabled) {
      background: #5568d3;
    }

    .btn-refresh:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .spinning {
      display: inline-block;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .waiting-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .waiting-item {
      background: #f7fafc;
      border: 2px solid #e2e8f0;
      border-radius: 12px;
      padding: 16px;
      display: flex;
      align-items: center;
      gap: 16px;
      transition: all 0.2s;
    }

    .waiting-item:hover {
      border-color: #667eea;
      box-shadow: 0 2px 8px rgba(102, 126, 234, 0.2);
    }

    .waiting-item.priority {
      background: #fff5f5;
      border-color: #fc8181;
    }

    .position-badge {
      background: #667eea;
      color: white;
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      font-weight: 700;
      flex-shrink: 0;
    }

    .priority .position-badge {
      background: #f56565;
    }

    .item-content {
      flex: 1;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .patient-info h3 {
      margin: 0 0 4px;
      font-size: 18px;
      color: #2d3748;
    }

    .doctor-info {
      margin: 0;
      font-size: 14px;
      color: #718096;
    }

    .item-details {
      display: flex;
      gap: 24px;
      align-items: center;
    }

    .detail {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .detail .label {
      font-size: 12px;
      color: #a0aec0;
      text-transform: uppercase;
    }

    .detail .value {
      font-size: 16px;
      font-weight: 600;
      color: #2d3748;
    }

    .detail .value.warning {
      color: #f56565;
    }

    .status-badge {
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status-scheduled, .status-confirmed {
      background: #bee3f8;
      color: #2c5282;
    }

    .status-checkedin {
      background: #c6f6d5;
      color: #22543d;
    }

    .status-inconsultation, .status-inprogress {
      background: #feebc8;
      color: #7c2d12;
    }

    .status-completed {
      background: #e9d8fd;
      color: #44337a;
    }

    .status-noshow, .status-cancelled {
      background: #fed7d7;
      color: #742a2a;
    }

    .status-waiting {
      background: #fefcbf;
      color: #744210;
    }

    .status-called {
      background: #c6f6d5;
      color: #22543d;
    }

    .spontaneous-badge {
      padding: 8px 16px;
      background: #feb2b2;
      border-radius: 8px;
      font-weight: 700;
      color: #742a2a;
      font-size: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .urgency-badge {
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 700;
    }

    .urgency-red {
      background: #fc8181;
      color: #fff;
    }

    .urgency-orange {
      background: #f6ad55;
      color: #fff;
    }

    .urgency-yellow {
      background: #f6e05e;
      color: #744210;
    }

    .urgency-green {
      background: #68d391;
      color: #22543d;
    }

    .chief-complaint {
      padding: 8px;
      background: #edf2f7;
      border-radius: 6px;
      font-size: 13px;
      color: #4a5568;
      margin-top: 8px;
    }

    .spontaneous-section {
      margin-bottom: 32px;
      background: #fff;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }

    .spontaneous-section h2 {
      margin: 0 0 20px;
      font-size: 24px;
      color: #2d3748;
    }

    .spontaneous-list {
      display: grid;
      gap: 16px;
    }

    .spontaneous-item {
      background: #fef5e7;
      border: 2px solid #f6e05e;
      border-radius: 12px;
      padding: 16px;
      transition: all 0.2s;
    }

    .spontaneous-item:hover {
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      transform: translateY(-2px);
    }

    .spontaneous-item .item-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid #f6e05e;
    }

    .spontaneous-item .item-time {
      font-size: 18px;
      font-weight: 700;
      color: #744210;
    }

    .spontaneous-item .item-body {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .spontaneous-item .item-row {
      font-size: 14px;
      color: #2d3748;
    }

    .spontaneous-item .cpf {
      color: #718096;
      font-size: 12px;
      margin-left: 8px;
    }

    .empty-state {
      text-align: center;
      padding: 48px;
      color: #a0aec0;
      font-size: 16px;
    }

    .appointments-section h2 {
      margin: 0 0 20px;
      font-size: 24px;
      color: #2d3748;
    }

    .appointments-table {
      overflow-x: auto;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    thead {
      background: #f7fafc;
    }

    th {
      padding: 12px;
      text-align: left;
      font-size: 14px;
      color: #4a5568;
      font-weight: 600;
      border-bottom: 2px solid #e2e8f0;
    }

    td {
      padding: 16px 12px;
      border-bottom: 1px solid #e2e8f0;
    }

    tbody tr:hover {
      background: #f7fafc;
    }

    .btn-check-in, .btn-no-show {
      padding: 8px 16px;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 500;
      margin-right: 8px;
      transition: all 0.2s;
    }

    .btn-check-in {
      background: #48bb78;
      color: white;
    }

    .btn-check-in:hover:not(:disabled) {
      background: #38a169;
    }

    .btn-no-show {
      background: #f56565;
      color: white;
    }

    .btn-no-show:hover:not(:disabled) {
      background: #e53e3e;
    }

    .btn-check-in:disabled, .btn-no-show:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `]
})
export class ReceptionistDashboardComponent implements OnInit, OnDestroy {
  todayAppointments: TodayAppointment[] = [];
  waitingList: WaitingListItem[] = [];
  spontaneousDemands: SpontaneousDemand[] = [];
  statistics: Statistics | null = null;
  loading = false;
  currentTime = new Date();
  
  private destroy$ = new Subject<void>();
  private readonly apiUrl = `${environment.apiUrl}/receptionist`;

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadData();
    
    // Atualizar dados a cada 30 segundos
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.loadData());

    // Atualizar relógio a cada segundo
    interval(1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.currentTime = new Date());
  }

  openEmergencyModal(): void {
    this.router.navigate(['/recepcao/demanda-espontanea']);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadData(): void {
    this.loadTodayAppointments();
    this.loadWaitingList();
    this.loadStatistics();
    this.loadSpontaneousDemands();
  }

  loadTodayAppointments(): void {
    this.http.get<TodayAppointment[]>(`${this.apiUrl}/today-appointments`)
      .subscribe({
        next: (appointments) => {
          this.todayAppointments = appointments;
        },
        error: (error) => {
          console.error('Erro ao carregar consultas:', error);
        }
      });
  }

  loadWaitingList(): void {
    this.http.get<WaitingListItem[]>(`${this.apiUrl}/waiting-list`)
      .subscribe({
        next: (list) => {
          this.waitingList = list;
        },
        error: (error) => {
          console.error('Erro ao carregar fila:', error);
        }
      });
  }

  loadSpontaneousDemands(): void {
    this.http.get<{ data: SpontaneousDemand[] }>(`${this.apiUrl}/spontaneous-demands`)
      .subscribe({
        next: (response) => {
          this.spontaneousDemands = response.data;
        },
        error: (error) => {
          console.error('Erro ao carregar demandas espontâneas:', error);
        }
      });
  }

  loadStatistics(): void {
    this.http.get<Statistics>(`${this.apiUrl}/statistics`)
      .subscribe({
        next: (stats) => {
          this.statistics = stats;
        },
        error: (error) => {
          console.error('Erro ao carregar estatísticas:', error);
        }
      });
  }

  refreshData(): void {
    this.loading = true;
    this.loadData();
    setTimeout(() => this.loading = false, 1000);
  }

  checkIn(appointmentId: string): void {
    if (!confirm('Confirmar presença do paciente?')) return;

    this.loading = true;
    this.http.post(`${this.apiUrl}/${appointmentId}/check-in`, {})
      .subscribe({
        next: () => {
          alert('✅ Presença confirmada com sucesso!');
          this.loadData();
          this.loading = false;
        },
        error: (error) => {
          console.error('Erro ao confirmar presença:', error);
          alert('Erro ao confirmar presença. Tente novamente.');
          this.loading = false;
        }
      });
  }

  markNoShow(appointmentId: string): void {
    if (!confirm('Confirmar que o paciente faltou?')) return;

    this.loading = true;
    this.http.put(`${this.apiUrl}/${appointmentId}/no-show`, {})
      .subscribe({
        next: () => {
          alert('❌ Paciente marcado como faltante');
          this.loadData();
          this.loading = false;
        },
        error: (error) => {
          console.error('Erro ao marcar falta:', error);
          alert('Erro ao marcar falta. Tente novamente.');
          this.loading = false;
        }
      });
  }

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      'Scheduled': 'Agendada',
      'Confirmed': 'Confirmada',
      'CheckedIn': 'Presente',
      'InProgress': 'Em Consulta',
      'InConsultation': 'Em Consulta',
      'Completed': 'Concluída',
      'Cancelled': 'Cancelada',
      'NoShow': 'Faltou',
      'Waiting': 'Aguardando',
      'Called': 'Chamado'
    };
    return labels[status] || status;
  }
}
