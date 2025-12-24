import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { ButtonComponent } from '@shared/components/atoms/button/button';
import { BadgeComponent } from '@shared/components/atoms/badge/badge';
import { AppointmentsService, Appointment, AppointmentType } from '@core/services/appointments.service';
import { AuthService } from '@core/services/auth.service';
import { BiometricsTabComponent } from '@pages/user/shared/teleconsultation/tabs/biometrics-tab/biometrics-tab';
import { AttachmentsChatTabComponent } from '@pages/user/shared/teleconsultation/tabs/attachments-chat-tab/attachments-chat-tab';
import { SoapTabComponent } from '@pages/user/shared/teleconsultation/tabs/soap-tab/soap-tab';
import { ConclusionTabComponent } from '@pages/user/shared/teleconsultation/tabs/conclusion-tab/conclusion-tab';
import { PatientDataTabComponent } from '@pages/user/shared/teleconsultation/tabs/patient-data-tab/patient-data-tab';
import { PreConsultationDataTabComponent } from '@pages/user/shared/teleconsultation/tabs/pre-consultation-data-tab/pre-consultation-data-tab';
import { AnamnesisTabComponent } from '@pages/user/shared/teleconsultation/tabs/anamnesis-tab/anamnesis-tab';
import { SpecialtyFieldsTabComponent } from '@pages/user/shared/teleconsultation/tabs/specialty-fields-tab/specialty-fields-tab';
import { IotTabComponent } from '@pages/user/shared/teleconsultation/tabs/iot-tab/iot-tab';
import { AITabComponent } from '@pages/user/shared/teleconsultation/tabs/ai-tab/ai-tab';
import { ReceitaTabComponent } from '@pages/user/shared/teleconsultation/tabs/receita-tab/receita-tab';
import { ReferralTabComponent } from '@pages/user/shared/teleconsultation/tabs/referral-tab/referral-tab';
import { ReturnTabComponent } from '@pages/user/shared/teleconsultation/tabs/return-tab/return-tab';
import { getAllDetailsTabs, TabConfig } from '@pages/user/shared/teleconsultation/tabs/tab-config';

@Component({
  selector: 'app-appointment-details',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    IconComponent,
    ButtonComponent,
    BadgeComponent,
    BiometricsTabComponent,
    AttachmentsChatTabComponent,
    SoapTabComponent,
    ConclusionTabComponent,
    PatientDataTabComponent,
    PreConsultationDataTabComponent,
    AnamnesisTabComponent,
    SpecialtyFieldsTabComponent,
    IotTabComponent,
    AITabComponent,
    ReceitaTabComponent,
    ReferralTabComponent,
    ReturnTabComponent
  ],
  templateUrl: './appointment-details.html',
  styleUrls: ['./appointment-details.scss']
})
export class AppointmentDetailsComponent implements OnInit {
  appointment: Appointment | null = null;
  appointmentId: string | null = null;
  loading = false;
  userrole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' = 'PATIENT';
  
  // Tabs - usando configuração centralizada
  activeTab = 'basic';
  availableTabs: TabConfig[] = getAllDetailsTabs();

  private appointmentsService = inject(AppointmentsService);
  private authService = inject(AuthService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  ngOnInit(): void {
    this.determineuserrole();
    this.appointmentId = this.route.snapshot.paramMap.get('id');
    
    // Aguardar autenticação antes de carregar
    this.authService.authState$.subscribe((state) => {
      if (state.isAuthenticated && this.appointmentId && !this.appointment) {
        this.loadAppointment(this.appointmentId);
      }
    });
  }

  determineuserrole() {
    const currentUser = this.authService.currentUser();
    if (currentUser) {
      this.userrole = currentUser.role;
    } else {
      // Fallback based on URL
      const url = this.router.url;
      if (url.includes('/patient')) {
        this.userrole = 'PATIENT';
      } else if (url.includes('/professional')) {
        this.userrole = 'PROFESSIONAL';
      } else {
        this.userrole = 'ADMIN';
      }
    }
  }

  loadAppointment(id: string) {
    this.loading = true;
    this.appointmentsService.getAppointmentById(id).subscribe({
      next: (appointment) => {
        this.appointment = appointment;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('Erro ao carregar consulta:', error);
        // Se for erro 401, o interceptor já redireciona automaticamente
        if (error.status === 401) {
          return;
        }
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  get visibleTabs(): TabConfig[] {
    // Retornar todas as tabs disponíveis para a página de detalhes
    return this.availableTabs;
  }

  changeTab(tabId: string) {
    this.activeTab = tabId;
  }

  goBack() {
    this.router.navigate(['/consultas']);
  }

  getStatusBadgeVariant(status: string): 'success' | 'warning' | 'error' | 'info' | 'neutral' | 'primary' {
    switch (status) {
      case 'Confirmed':
        return 'success';
      case 'Scheduled':
        return 'info';
      case 'Completed':
        return 'success';
      case 'Cancelled':
        return 'error';
      default:
        return 'neutral';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'Scheduled':
        return 'Agendada';
      case 'Confirmed':
        return 'Confirmada';
      case 'Completed':
        return 'Realizada';
      case 'Cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  onFinish(observations: string) {
    console.log('Consulta finalizada com observações:', observations);
    // Aqui você implementaria a lógica para finalizar a consulta
  }

  getAppointmentTypeLabel(appointment: Appointment): string {
    if (!appointment.type) return 'Consulta';
    
    const labels: Record<AppointmentType, string> = {
      'FirstVisit': 'Primeira Consulta',
      'Return': 'Retorno',
      'Routine': 'Rotina',
      'Emergency': 'Emergencial',
      'Common': 'Comum',
      'Referral': 'Encaminhamento'
    };
    return labels[appointment.type] || 'Consulta';
  }
}
