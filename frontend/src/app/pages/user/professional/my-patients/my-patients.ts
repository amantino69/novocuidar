import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent, IconName } from '@shared/components/atoms/icon/icon';
import { ButtonComponent } from '@shared/components/atoms/button/button';
import { BadgeComponent, BadgeVariant } from '@shared/components/atoms/badge/badge';
import { AppointmentsService, Appointment } from '@core/services/appointments.service';

// Tabs clínicas para visualização do histórico
import { SoapTabComponent } from '@pages/user/shared/teleconsultation/tabs/soap-tab/soap-tab';
import { BiometricsTabComponent } from '@pages/user/shared/teleconsultation/tabs/biometrics-tab/biometrics-tab';
import { AtestadoTabComponent } from '@pages/user/shared/teleconsultation/tabs/atestado-tab/atestado-tab';
import { ReceitaTabComponent } from '@pages/user/shared/teleconsultation/tabs/receita-tab/receita-tab';
import { ExameTabComponent } from '@pages/user/shared/teleconsultation/tabs/exame-tab/exame-tab';
import { AttachmentsChatTabComponent } from '@pages/user/shared/teleconsultation/tabs/attachments-chat-tab/attachments-chat-tab';
import { AnamnesisTabComponent } from '@pages/user/shared/teleconsultation/tabs/anamnesis-tab/anamnesis-tab';

type SortOrder = 'asc' | 'desc';

interface TabConfig {
  id: string;
  label: string;
  icon: IconName;
}

@Component({
  selector: 'app-my-patients',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    IconComponent,
    ButtonComponent,
    BadgeComponent,
    SoapTabComponent,
    BiometricsTabComponent,
    AtestadoTabComponent,
    ReceitaTabComponent,
    ExameTabComponent,
    AttachmentsChatTabComponent,
    AnamnesisTabComponent
  ],
  templateUrl: './my-patients.html',
  styleUrl: './my-patients.scss'
})
export class MyPatientsComponent {
  private appointmentsService = inject(AppointmentsService);

  // Busca
  searchTerm = signal('');
  isSearching = signal(false);
  searchError = signal<string | null>(null);
  hasSearched = signal(false);

  // Resultados
  appointments = signal<Appointment[]>([]);
  patientName = signal<string | null>(null);
  sortOrder = signal<SortOrder>('desc');

  // Detalhes da consulta
  selectedAppointment = signal<Appointment | null>(null);
  activeTab = signal('soap');

  // Apenas tabs clínicas para visualização de histórico
  tabs: TabConfig[] = [
    { id: 'soap', label: 'SOAP', icon: 'file-text' },
    { id: 'anamnesis', label: 'Anamnese', icon: 'book' },
    { id: 'biometrics', label: 'Biométricos', icon: 'heart' },
    { id: 'receita', label: 'Receitas', icon: 'file' },
    { id: 'atestado', label: 'Atestados', icon: 'file' },
    { id: 'exame', label: 'Exames', icon: 'file-text' },
    { id: 'attachments', label: 'Anexos', icon: 'image' }
  ];

  search(): void {
    const term = this.searchTerm().trim();
    if (!term) {
      this.searchError.set('Digite o CPF ou nome do paciente');
      return;
    }

    this.isSearching.set(true);
    this.searchError.set(null);
    this.appointments.set([]);
    this.patientName.set(null);
    this.hasSearched.set(true);

    this.appointmentsService.searchByPatient(term, this.sortOrder()).subscribe({
      next: (data: Appointment[]) => {
        this.appointments.set(data);
        if (data.length > 0) {
          this.patientName.set(data[0].patientName ?? null);
        }
        this.isSearching.set(false);
      },
      error: () => {
        this.isSearching.set(false);
        this.searchError.set('Erro ao buscar paciente. Tente novamente.');
      }
    });
  }

  toggleSortOrder(): void {
    this.sortOrder.set(this.sortOrder() === 'desc' ? 'asc' : 'desc');
    if (this.appointments().length > 0) {
      this.search();
    }
  }

  openDetails(appointment: Appointment): void {
    this.selectedAppointment.set(appointment);
    this.activeTab.set('soap');
  }

  closeDetails(): void {
    this.selectedAppointment.set(null);
  }

  selectTab(tabId: string): void {
    this.activeTab.set(tabId);
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR');
  }

  formatTime(time: string): string {
    if (!time) return '';
    return time.substring(0, 5);
  }

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      'Scheduled': 'Agendada',
      'Confirmed': 'Confirmada',
      'InProgress': 'Em Andamento',
      'Completed': 'Realizada',
      'Cancelled': 'Cancelada',
      'NoShow': 'Não Compareceu'
    };
    return labels[status] || status;
  }

  getStatusClass(status: string): BadgeVariant {
    const classes: Record<string, BadgeVariant> = {
      'Scheduled': 'warning',
      'Confirmed': 'info',
      'InProgress': 'primary',
      'Completed': 'success',
      'Cancelled': 'error',
      'NoShow': 'neutral'
    };
    return classes[status] || 'neutral';
  }

  getTypeLabel(type: string): string {
    return type === 'FirstConsultation' ? 'Primeira Consulta' : 'Retorno';
  }
}
