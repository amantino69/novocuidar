import { Component, OnInit, OnDestroy, inject, ChangeDetectorRef, PLATFORM_ID, Inject } from '@angular/core';
import { CommonModule, isPlatformBrowser, DatePipe } from '@angular/common';
import { Router, ActivatedRoute, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { BadgeComponent, BadgeVariant } from '@shared/components/atoms/badge/badge';
import { FilterSelectComponent, FilterOption } from '@shared/components/atoms/filter-select/filter-select';
import { PaginationComponent } from '@shared/components/atoms/pagination/pagination';
import { AppointmentsService, Appointment, AppointmentsFilter, AppointmentStatus, AppointmentType } from '@core/services/appointments.service';
import { AppointmentDetailsModalComponent } from '@pages/user/shared/appointments/appointment-details-modal/appointment-details-modal';
import { ModalService } from '@core/services/modal.service';
import { AuthService } from '@core/services/auth.service';
import { RealTimeService, AppointmentStatusUpdate, EntityNotification } from '@core/services/real-time.service';
import { CpfMaskDirective } from '@app/core/directives/cpf-mask.directive';
import { environment } from '@env/environment';
import { filter, take } from 'rxjs/operators';
import { Subscription } from 'rxjs';

// Interface para demandas espontâneas
interface SpontaneousDemand {
  id: string;
  patientName: string;
  professionalName: string;
  specialtyName: string;
  urgencyLevel: 'Red' | 'Orange' | 'Yellow' | 'Green';
  chiefComplaint?: string;
  checkInTime: string;
  status: string;
}

type FilterMode = 'today' | 'all' | 'period' | 'cpf';

@Component({
  selector: 'app-digital-office',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    IconComponent,
    BadgeComponent,
    FilterSelectComponent,
    PaginationComponent,
    AppointmentDetailsModalComponent,
    CpfMaskDirective
  ],
  providers: [DatePipe],
  templateUrl: './digital-office.html',
  styleUrls: ['./digital-office.scss']
})
export class DigitalOfficeComponent implements OnInit, OnDestroy {
  appointments: Appointment[] = [];
  allAppointments: Appointment[] = [];
  loading = false;
  
  // Demandas Espontâneas
  spontaneousDemands: SpontaneousDemand[] = [];
  loadingSpontaneous = false;
  
  // Filtros
  filterMode: FilterMode = 'today';
  searchCpf = '';
  startDate = '';
  endDate = '';
  statusFilter: AppointmentStatus | 'all' = 'all';
  
  // Filtros de texto simples (por parte do nome)
  professionalNameFilter = '';
  patientNameFilter = '';
  
  statusOptions: FilterOption[] = [
    { value: 'all', label: 'Todos os status' },
    { value: 'Scheduled', label: 'Agendada' },
    { value: 'Confirmed', label: 'Confirmada' },
    { value: 'CheckedIn', label: 'Recepcionado' },
    { value: 'AwaitingDoctor', label: 'Aguardando Médico' },
    { value: 'InConsultation', label: 'Em Consulta' },
    { value: 'PendingClosure', label: 'Pendente Fechamento' },
    { value: 'Completed', label: 'Finalizada' },
    { value: 'Cancelled', label: 'Cancelada' },
    { value: 'NoShow', label: 'Não Compareceu' }
  ];

  // Modal
  selectedAppointment: Appointment | null = null;
  isDetailsModalOpen = false;

  // Paginação
  currentPage = 1;
  pageSize = 10;
  totalAppointments = 0;
  totalPages = 0;

  // Real-time subscriptions
  private realTimeSubscriptions: Subscription[] = [];
  private isBrowser: boolean;

  private appointmentsService = inject(AppointmentsService);
  private authService = inject(AuthService);
  private realTimeService = inject(RealTimeService);
  private http = inject(HttpClient);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private modalService = inject(ModalService);
  private cdr = inject(ChangeDetectorRef);
  private datePipe = inject(DatePipe);

  constructor(@Inject(PLATFORM_ID) platformId: Object) {
    this.isBrowser = isPlatformBrowser(platformId);
    
    // Set default dates
    const today = new Date();
    this.startDate = this.formatDate(today);
    this.endDate = this.formatDate(today);
  }

  ngOnInit(): void {
    this.authService.authState$
      .pipe(
        filter(state => state.isAuthenticated && state.user !== null),
        take(1)
      )
      .subscribe(() => {
        setTimeout(() => {
          this.loadAppointments();
          this.loadSpontaneousDemands();
          this.initializeRealTime();
          this.cdr.detectChanges();
        }, 0);
      });
  }
  
  // Debounce timer para filtros de nome
  private filterDebounceTimer: any = null;
  
  // Métodos de filtro por nome (envia para backend)
  onProfessionalFilterChange(): void {
    this.debounceLoadAppointments();
  }

  onPatientFilterChange(): void {
    this.debounceLoadAppointments();
  }
  
  private debounceLoadAppointments(): void {
    if (this.filterDebounceTimer) {
      clearTimeout(this.filterDebounceTimer);
    }
    this.filterDebounceTimer = setTimeout(() => {
      this.currentPage = 1;
      this.loadAppointments();
    }, 400); // 400ms de debounce
  }

  clearProfessionalFilter(): void {
    this.professionalNameFilter = '';
    this.currentPage = 1;
    this.loadAppointments();
  }

  clearPatientFilter(): void {
    this.patientNameFilter = '';
    this.currentPage = 1;
    this.loadAppointments();
  }
  
  // Carrega demandas espontâneas aguardando atendimento
  loadSpontaneousDemands(): void {
    this.loadingSpontaneous = true;
    const today = new Date().toISOString().split('T')[0];
    
    // pendingOnly=true retorna apenas demandas com status Scheduled ou CheckedIn
    this.http.get<{ data: SpontaneousDemand[] }>(`${environment.apiUrl}/receptionist/spontaneous-demands?date=${today}&pendingOnly=true`)
      .subscribe({
        next: (response) => {
          this.spontaneousDemands = response.data || [];
          this.loadingSpontaneous = false;
          this.cdr.detectChanges();
        },
        error: (error) => {
          console.error('Erro ao carregar demandas espontâneas:', error);
          this.spontaneousDemands = [];
          this.loadingSpontaneous = false;
          this.cdr.detectChanges();
        }
      });
  }

  // Retorna a cor baseada na urgência
  getUrgencyColor(level: string): string {
    switch (level) {
      case 'Red': return '#dc3545';
      case 'Orange': return '#fd7e14';
      case 'Yellow': return '#ffc107';
      case 'Green': return '#28a745';
      default: return '#6c757d';
    }
  }

  // Retorna o label da urgência
  getUrgencyLabel(level: string): string {
    switch (level) {
      case 'Red': return 'Crítica';
      case 'Orange': return 'Muito Urgente';
      case 'Yellow': return 'Urgente';
      case 'Green': return 'Pouco Urgente';
      default: return level;
    }
  }

  // Formata o tempo de espera
  getWaitingTime(checkInTime: string): string {
    const checkIn = new Date(checkInTime);
    const now = new Date();
    const diffMs = now.getTime() - checkIn.getTime();
    const diffMinutes = Math.floor(diffMs / 60000);
    
    if (diffMinutes < 60) {
      return `${diffMinutes} min`;
    } else {
      const hours = Math.floor(diffMinutes / 60);
      const mins = diffMinutes % 60;
      return `${hours}h ${mins}min`;
    }
  }

  // Inicia atendimento da demanda espontânea
  startSpontaneousDemand(demand: SpontaneousDemand): void {
    this.http.post(`${environment.apiUrl}/appointments/${demand.id}/start-consultation`, {})
      .subscribe({
        next: () => {
          // Navegar para a teleconsulta
          this.router.navigate(['/teleconsulta', demand.id]);
        },
        error: (error) => {
          console.error('Erro ao iniciar atendimento:', error);
          this.modalService.alert({
            title: 'Erro',
            message: 'Não foi possível iniciar o atendimento. Tente novamente.',
            variant: 'danger'
          });
        }
      });
  }
  
  private initializeRealTime(): void {
    if (!this.isBrowser) return;
    
    this.realTimeService.connect().then(() => {
      const statusSub = this.realTimeService.appointmentStatusChanged$.subscribe(
        (update: AppointmentStatusUpdate) => {
          this.handleAppointmentStatusChange(update);
        }
      );
      this.realTimeSubscriptions.push(statusSub);
      
      const entitySub = this.realTimeService.getEntityEvents$('Appointment').subscribe(
        (notification: EntityNotification) => {
          this.handleAppointmentEntityChange(notification);
        }
      );
      this.realTimeSubscriptions.push(entitySub);
    }).catch(error => {
      console.error('[DigitalOffice] Erro ao conectar SignalR:', error);
    });
  }
  
  private handleAppointmentStatusChange(update: AppointmentStatusUpdate): void {
    const index = this.allAppointments.findIndex(a => a.id === update.appointmentId);
    if (index !== -1) {
      this.allAppointments[index] = {
        ...this.allAppointments[index],
        status: update.newStatus as AppointmentStatus
      };
      this.filterAppointments();
      this.cdr.detectChanges();
    }
  }
  
  private handleAppointmentEntityChange(notification: EntityNotification): void {
    if (notification.action === 'Created' || notification.action === 'Updated') {
      this.loadAppointments();
    } else if (notification.action === 'Deleted') {
      this.allAppointments = this.allAppointments.filter(a => a.id !== notification.entityId);
      this.filterAppointments();
      this.cdr.detectChanges();
    }
  }
  
  ngOnDestroy(): void {
    this.realTimeSubscriptions.forEach(sub => sub.unsubscribe());
  }

  loadAppointments(): void {
    this.loading = true;
    
    const filter: AppointmentsFilter = this.buildFilter();
    
    // Load all appointments (backend should return all for assistants)
    this.appointmentsService.getAppointments(filter, this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        this.allAppointments = response.data;
        this.totalAppointments = response.total;
        this.totalPages = response.totalPages;
        this.filterAppointments();
        setTimeout(() => {
          this.loading = false;
          this.cdr.detectChanges();
        });
      },
      error: (error) => {
        console.error('Erro ao carregar consultas:', error);
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private buildFilter(): AppointmentsFilter {
    const filter: AppointmentsFilter = {};
    
    if (this.statusFilter !== 'all') {
      filter.status = this.statusFilter;
    }
    
    // Filtros por nome (enviados para o backend)
    if (this.professionalNameFilter.trim()) {
      filter.professionalName = this.professionalNameFilter.trim();
    }
    if (this.patientNameFilter.trim()) {
      filter.patientName = this.patientNameFilter.trim();
    }
    
    switch (this.filterMode) {
      case 'today':
        const today = this.formatDate(new Date());
        filter.startDate = today;
        filter.endDate = today;
        break;
      case 'period':
        if (this.startDate) filter.startDate = this.startDate;
        if (this.endDate) filter.endDate = this.endDate;
        break;
      case 'cpf':
        if (this.searchCpf) filter.search = this.searchCpf.replace(/\D/g, '');
        break;
      case 'all':
        // No date filter
        break;
    }
    
    return filter;
  }

  private filterAppointments(): void {
    let filtered = [...this.allAppointments];
    
    // Filtros de nome (professionalName e patientName) são aplicados no backend
    // Aqui só aplicamos filtro de status local se necessário
    if (this.statusFilter !== 'all') {
      filtered = filtered.filter(a => a.status === this.statusFilter);
    }
    
    // Sort by date and time
    filtered.sort((a, b) => {
      const dateA = new Date(`${a.date}T${a.time}`);
      const dateB = new Date(`${b.date}T${b.time}`);
      return dateA.getTime() - dateB.getTime();
    });
    
    this.appointments = filtered;
  }

  setFilterMode(mode: FilterMode): void {
    this.filterMode = mode;
    this.currentPage = 1;
    
    if (mode === 'today') {
      const today = new Date();
      this.startDate = this.formatDate(today);
      this.endDate = this.formatDate(today);
    }
    
    this.loadAppointments();
  }

  onSearchCpf(): void {
    if (this.searchCpf && this.searchCpf.replace(/\D/g, '').length >= 11) {
      this.filterMode = 'cpf';
      this.currentPage = 1;
      this.loadAppointments();
    }
  }

  onDateFilterChange(): void {
    if (this.startDate && this.endDate) {
      this.filterMode = 'period';
      this.currentPage = 1;
      this.loadAppointments();
    }
  }

  onStatusFilterChange(): void {
    this.currentPage = 1;
    this.loadAppointments();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadAppointments();
  }

  openDetails(appointment: Appointment): void {
    this.selectedAppointment = appointment;
    this.isDetailsModalOpen = true;
  }

  closeDetailsModal(): void {
    this.isDetailsModalOpen = false;
    this.selectedAppointment = null;
  }

  enterConsultation(appointment: Appointment): void {
    this.router.navigate(['/teleconsulta', appointment.id]);
  }

  getStatusBadgeVariant(status: AppointmentStatus): BadgeVariant {
    const variantMap: Record<AppointmentStatus, BadgeVariant> = {
      Scheduled: 'info',
      Confirmed: 'primary',
      CheckedIn: 'primary',
      AwaitingDoctor: 'warning',
      InConsultation: 'success',
      PendingClosure: 'warning',
      Completed: 'success',
      Cancelled: 'error',
      NoShow: 'error',
      // Legado
      InProgress: 'warning',
      Abandoned: 'warning'
    };
    return variantMap[status] || 'neutral';
  }

  getStatusLabel(status: AppointmentStatus): string {
    const labels: Record<string, string> = {
      Scheduled: 'Agendada',
      Confirmed: 'Confirmada',
      CheckedIn: 'Recepcionado',
      AwaitingDoctor: 'Aguardando Médico',
      InConsultation: 'Em Consulta',
      PendingClosure: 'Pendente Fechamento',
      Completed: 'Finalizada',
      Cancelled: 'Cancelada',
      NoShow: 'Não Compareceu',
      // Legado
      InProgress: 'Em Andamento',
      Abandoned: 'Pendente Fechamento'
    };
    return labels[status] || status;
  }

  getTypeLabel(type?: AppointmentType): string {
    if (!type) return '-';
    const labels: Record<AppointmentType, string> = {
      FirstVisit: 'Primeira Consulta',
      Return: 'Retorno',
      Routine: 'Rotina',
      Emergency: 'Emergência',
      Common: 'Comum',
      Referral: 'Encaminhamento'
    };
    return labels[type] || type;
  }

  formatTime(time: string): string {
    if (!time) return '';
    // Remove seconds if present
    return time.substring(0, 5);
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  canEnterConsultation(appointment: Appointment): boolean {
    // MODO APRESENTAÇÃO: Permite entrada em qualquer consulta exceto cancelada/noshow
    return appointment.status !== 'Cancelled' && appointment.status !== 'NoShow';
  }
}
