import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { AvatarComponent } from '@app/shared/components/atoms/avatar/avatar';
import { AuthService } from '@app/core/services/auth.service';
import { RegulatorService, RegulatorPatient } from '@app/core/services/regulator.service';

@Component({
  selector: 'app-regulator-patients',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, IconComponent, AvatarComponent],
  template: `
    <div class="page-container">
      <header class="page-header">
        <button class="back-btn" routerLink="/painel">
          <app-icon name="arrow-left" [size]="20" />
          Voltar
        </button>
        <h1>
          <app-icon name="users" [size]="28" />
          Pacientes do Município
        </h1>
        <p class="subtitle">{{ municipioNome }} • {{ totalPatients }} paciente(s)</p>
      </header>

      <!-- Search -->
      <div class="filters">
        <div class="search-box">
          <app-icon name="search" [size]="20" />
          <input 
            type="text" 
            placeholder="Buscar por nome, CPF ou CNS..."
            [(ngModel)]="searchTerm"
            (ngModelChange)="onSearchChange($event)"
          />
        </div>
      </div>

      <!-- Loading -->
      @if (loading) {
        <div class="loading-state">
          <div class="spinner"></div>
          <p>Carregando pacientes...</p>
        </div>
      }

      <!-- Error -->
      @if (error) {
        <div class="error-state">
          <app-icon name="alert-circle" [size]="48" />
          <p>{{ error }}</p>
          <button class="retry-btn" (click)="loadPatients()">Tentar novamente</button>
        </div>
      }

      <!-- List -->
      @if (!loading && !error) {
        @if (patients.length === 0) {
          <div class="empty-state">
            <app-icon name="users" [size]="64" />
            <h2>Nenhum paciente encontrado</h2>
            <p>
              @if (searchTerm) {
                Nenhum paciente corresponde à busca "{{ searchTerm }}"
              } @else {
                Não há pacientes cadastrados neste município
              }
            </p>
          </div>
        } @else {
          <div class="patients-grid">
            @for (patient of patients; track patient.id) {
              <div class="patient-card" (click)="viewPatient(patient)">
                <div class="patient-card__header">
                  <app-avatar [name]="patient.fullName" [imageUrl]="patient.avatar ?? undefined" size="lg" />
                  <div class="patient-info">
                    <h3>{{ patient.fullName }}</h3>
                    <span class="cpf">CPF: {{ formatCpf(patient.cpf) }}</span>
                    @if (patient.cns) {
                      <span class="cns">CNS: {{ patient.cns }}</span>
                    }
                  </div>
                </div>
                <div class="patient-card__details">
                  @if (patient.birthDate) {
                    <div class="detail">
                      <app-icon name="calendar" [size]="16" />
                      <span>{{ calculateAge(patient.birthDate) }} anos</span>
                    </div>
                  }
                  @if (patient.gender) {
                    <div class="detail">
                      <app-icon name="user" [size]="16" />
                      <span>{{ patient.gender === 'M' ? 'Masculino' : patient.gender === 'F' ? 'Feminino' : patient.gender }}</span>
                    </div>
                  }
                </div>
                <div class="patient-card__footer">
                  <span class="status" [class.active]="patient.status === 'Active'">
                    {{ patient.status === 'Active' ? 'Ativo' : patient.status }}
                  </span>
                  <button class="view-btn">
                    Ver detalhes <app-icon name="arrow-right" [size]="16" />
                  </button>
                </div>
              </div>
            }
          </div>

          <!-- Pagination -->
          @if (totalPages > 1) {
            <div class="pagination">
              <button class="page-btn" [disabled]="currentPage === 1" (click)="goToPage(currentPage - 1)">
                <app-icon name="arrow-left" [size]="18" /> Anterior
              </button>
              <span class="page-info">Página {{ currentPage }} de {{ totalPages }}</span>
              <button class="page-btn" [disabled]="currentPage === totalPages" (click)="goToPage(currentPage + 1)">
                Próxima <app-icon name="arrow-right" [size]="18" />
              </button>
            </div>
          }
        }
      }

      <!-- Modal -->
      @if (selectedPatient && patientDetails) {
        <div class="modal-overlay" (click)="closeModal()">
          <div class="modal" (click)="$event.stopPropagation()">
            <div class="modal__header">
              <h2>Detalhes do Paciente</h2>
              <button class="close-btn" (click)="closeModal()"><app-icon name="x" [size]="24" /></button>
            </div>
            <div class="modal__content">
              <div class="details-header">
                <app-avatar [name]="patientDetails.patient.name + ' ' + patientDetails.patient.lastName" size="xl" />
                <div>
                  <h3>{{ patientDetails.patient.name }} {{ patientDetails.patient.lastName }}</h3>
                  <p>{{ patientDetails.patient.email }}</p>
                </div>
              </div>
              <div class="details-grid">
                <div class="detail-item"><label>CPF</label><span>{{ formatCpf(patientDetails.patient.cpf) }}</span></div>
                @if (patientDetails.patient.profile.cns) {
                  <div class="detail-item"><label>CNS</label><span>{{ patientDetails.patient.profile.cns }}</span></div>
                }
                @if (patientDetails.patient.phone) {
                  <div class="detail-item"><label>Telefone</label><span>{{ patientDetails.patient.phone }}</span></div>
                }
                @if (patientDetails.patient.profile.birthDate) {
                  <div class="detail-item"><label>Nascimento</label><span>{{ formatDate(patientDetails.patient.profile.birthDate) }}</span></div>
                }
              </div>
              @if (patientDetails.recentAppointments.length > 0) {
                <div class="appointments-section">
                  <h4>Últimas Consultas</h4>
                  @for (appt of patientDetails.recentAppointments; track appt.id) {
                    <div class="appointment-item">
                      <span>{{ formatDate(appt.date) }} - {{ appt.specialtyName }}</span>
                      <span class="appt-status" [attr.data-status]="appt.status">{{ translateStatus(appt.status) }}</span>
                    </div>
                  }
                </div>
              }
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .page-container { padding: 24px; max-width: 1400px; margin: 0 auto; }
    .page-header { margin-bottom: 24px; }
    .page-header h1 { display: flex; align-items: center; gap: 12px; font-size: 28px; font-weight: 700; color: #0f172a; margin: 16px 0 8px; }
    .page-header .subtitle { color: #64748b; margin: 0; }
    .back-btn { display: inline-flex; align-items: center; gap: 8px; padding: 8px 16px; border: none; background: #f1f5f9; border-radius: 8px; color: #64748b; font-size: 14px; cursor: pointer; transition: all 0.2s; }
    .back-btn:hover { background: #e2e8f0; color: #0d9488; }
    .filters { margin-bottom: 24px; }
    .search-box { display: flex; align-items: center; gap: 12px; padding: 12px 16px; background: white; border: 1px solid #e2e8f0; border-radius: 12px; max-width: 400px; }
    .search-box input { flex: 1; border: none; outline: none; font-size: 15px; color: #0f172a; }
    .search-box input::placeholder { color: #94a3b8; }
    .search-box app-icon { color: #94a3b8; }
    .loading-state, .error-state, .empty-state { text-align: center; padding: 60px 24px; background: white; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
    .loading-state app-icon, .empty-state app-icon { color: #0d9488; opacity: 0.5; margin-bottom: 16px; }
    .error-state app-icon { color: #ef4444; margin-bottom: 16px; }
    .loading-state h2, .error-state h2, .empty-state h2 { font-size: 20px; color: #0f172a; margin: 0 0 8px; }
    .loading-state p, .error-state p, .empty-state p { color: #64748b; margin: 0; }
    .retry-btn { margin-top: 16px; padding: 10px 20px; background: #0d9488; color: white; border: none; border-radius: 8px; cursor: pointer; }
    .spinner { width: 40px; height: 40px; border: 3px solid #e2e8f0; border-top-color: #0d9488; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .patients-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 20px; }
    .patient-card { background: white; border-radius: 16px; padding: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); cursor: pointer; transition: all 0.2s; }
    .patient-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
    .patient-card__header { display: flex; gap: 16px; margin-bottom: 16px; }
    .patient-card__header .patient-info { flex: 1; min-width: 0; }
    .patient-card__header .patient-info h3 { font-size: 16px; font-weight: 600; color: #0f172a; margin: 0 0 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .patient-card__header .patient-info .cpf, .patient-card__header .patient-info .cns { display: block; font-size: 13px; color: #64748b; }
    .patient-card__details { display: flex; flex-wrap: wrap; gap: 12px; padding: 12px 0; border-top: 1px solid #f1f5f9; border-bottom: 1px solid #f1f5f9; }
    .patient-card__details .detail { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #64748b; }
    .patient-card__details .detail app-icon { color: #0d9488; }
    .patient-card__footer { display: flex; justify-content: space-between; align-items: center; margin-top: 12px; }
    .patient-card__footer .status { font-size: 12px; padding: 4px 10px; border-radius: 20px; background: #f1f5f9; color: #64748b; }
    .patient-card__footer .status.active { background: #d1fae5; color: #059669; }
    .patient-card__footer .view-btn { display: flex; align-items: center; gap: 6px; padding: 6px 12px; border: none; background: transparent; color: #0d9488; font-size: 13px; font-weight: 500; cursor: pointer; }
    .pagination { display: flex; justify-content: center; align-items: center; gap: 16px; margin-top: 32px; }
    .pagination .page-btn { display: flex; align-items: center; gap: 8px; padding: 10px 16px; border: 1px solid #e2e8f0; background: white; border-radius: 8px; color: #0f172a; font-size: 14px; cursor: pointer; }
    .pagination .page-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .pagination .page-info { color: #64748b; font-size: 14px; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; padding: 24px; }
    .modal { background: white; border-radius: 16px; width: 100%; max-width: 640px; max-height: 90vh; overflow: hidden; }
    .modal__header { display: flex; justify-content: space-between; align-items: center; padding: 20px 24px; border-bottom: 1px solid #e2e8f0; }
    .modal__header h2 { font-size: 18px; font-weight: 600; color: #0f172a; margin: 0; }
    .modal__header .close-btn { display: flex; align-items: center; justify-content: center; width: 36px; height: 36px; border: none; background: #f1f5f9; border-radius: 8px; color: #64748b; cursor: pointer; }
    .modal__content { padding: 24px; overflow-y: auto; }
    .details-header { display: flex; gap: 16px; margin-bottom: 24px; }
    .details-header h3 { font-size: 20px; font-weight: 600; color: #0f172a; margin: 0 0 4px; }
    .details-header p { color: #64748b; margin: 0; }
    .details-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; margin-bottom: 24px; }
    .details-grid .detail-item label { display: block; font-size: 12px; color: #64748b; margin-bottom: 4px; text-transform: uppercase; }
    .details-grid .detail-item span { font-size: 15px; color: #0f172a; }
    .appointments-section { padding-top: 20px; border-top: 1px solid #e2e8f0; }
    .appointments-section h4 { font-size: 14px; font-weight: 600; color: #0f172a; margin: 0 0 12px; }
    .appointment-item { display: flex; justify-content: space-between; align-items: center; padding: 12px; background: #f8fafc; border-radius: 8px; margin-bottom: 8px; }
    .appointment-item span:first-child { font-size: 14px; color: #0f172a; }
    .appointment-item .appt-status { font-size: 12px; padding: 4px 10px; border-radius: 20px; background: #f1f5f9; color: #64748b; }
    .appointment-item .appt-status[data-status="Completed"] { background: #d1fae5; color: #059669; }
    .appointment-item .appt-status[data-status="Cancelled"] { background: #fee2e2; color: #dc2626; }
    :host-context([data-theme="dark"]) .page-header h1 { color: #f1f5f9; }
    :host-context([data-theme="dark"]) .back-btn { background: #334155; color: #94a3b8; }
    :host-context([data-theme="dark"]) .search-box { background: #1e293b; border-color: #334155; }
    :host-context([data-theme="dark"]) .search-box input { color: #f1f5f9; background: transparent; }
    :host-context([data-theme="dark"]) .loading-state, :host-context([data-theme="dark"]) .error-state, :host-context([data-theme="dark"]) .empty-state, :host-context([data-theme="dark"]) .patient-card, :host-context([data-theme="dark"]) .modal { background: #1e293b; }
    :host-context([data-theme="dark"]) .patient-card__header .patient-info h3 { color: #f1f5f9; }
  `]
})
export class RegulatorPatientsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();

  municipioNome = '';
  patients: RegulatorPatient[] = [];
  totalPatients = 0;
  currentPage = 1;
  totalPages = 1;
  pageSize = 12;
  searchTerm = '';
  loading = false;
  error: string | null = null;

  selectedPatient: RegulatorPatient | null = null;
  patientDetails: any = null;

  constructor(
    private authService: AuthService,
    private regulatorService: RegulatorService
  ) {}

  ngOnInit() {
    const user = this.authService.getCurrentUser();
    this.municipioNome = (user as any)?.municipioNome || 'Não definido';

    this.searchSubject.pipe(
      debounceTime(400),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(term => {
      this.searchTerm = term;
      this.currentPage = 1;
      this.loadPatients();
    });

    this.loadPatients();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadPatients() {
    this.loading = true;
    this.error = null;

    this.regulatorService.getPatients({
      search: this.searchTerm || undefined,
      page: this.currentPage,
      pageSize: this.pageSize
    }).subscribe({
      next: (response) => {
        this.patients = response.data;
        this.totalPatients = response.pagination.total;
        this.totalPages = response.pagination.totalPages;
        this.loading = false;
      },
      error: (err) => {
        this.error = err.error?.message || 'Erro ao carregar pacientes';
        this.loading = false;
      }
    });
  }

  onSearchChange(term: string) {
    this.searchSubject.next(term);
  }

  goToPage(page: number) {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
      this.loadPatients();
    }
  }

  viewPatient(patient: RegulatorPatient) {
    this.selectedPatient = patient;
    this.regulatorService.getPatientDetails(patient.id).subscribe({
      next: (details) => { this.patientDetails = details; },
      error: (err) => { console.error('Erro ao carregar detalhes:', err); }
    });
  }

  closeModal() {
    this.selectedPatient = null;
    this.patientDetails = null;
  }

  formatCpf(cpf: string): string {
    if (!cpf || cpf.length !== 11) return cpf;
    return `${cpf.slice(0, 3)}.${cpf.slice(3, 6)}.${cpf.slice(6, 9)}-${cpf.slice(9)}`;
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('pt-BR');
  }

  calculateAge(birthDate: string): number {
    if (!birthDate) return 0;
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) age--;
    return age;
  }

  translateStatus(status: string): string {
    const map: Record<string, string> = {
      'Scheduled': 'Agendada', 'Confirmed': 'Confirmada', 'CheckedIn': 'Check-in',
      'InProgress': 'Em Andamento', 'Completed': 'Realizada', 'Cancelled': 'Cancelada', 'NoShow': 'Não compareceu'
    };
    return map[status] || status;
  }
}
