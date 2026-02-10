import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Appointment } from '@core/services/appointments.service';
import { ButtonComponent } from '@shared/components/atoms/button/button';

@Component({
  selector: 'app-conclusion-tab',
  standalone: true,
  imports: [CommonModule, FormsModule, ButtonComponent],
  templateUrl: './conclusion-tab.html',
  styleUrls: ['./conclusion-tab.scss']
})
export class ConclusionTabComponent {
  @Input() appointment: Appointment | null = null;
  @Input() readonly = false;
  @Output() finish = new EventEmitter<string>();

  observations = '';

  onFinish() {
    this.finish.emit(this.observations);
  }

  /** Traduz o tipo de consulta para português */
  getTypeLabel(type: string | undefined): string {
    const labels: Record<string, string> = {
      'FirstVisit': 'Primeira Consulta',
      'FollowUp': 'Retorno',
      'Referral': 'Encaminhamento',
      'Urgent': 'Urgência',
      'Routine': 'Rotina'
    };
    return labels[type || ''] || type || '--';
  }

  /** Traduz o status da consulta para português */
  getStatusLabel(status: string | undefined): string {
    if (!status) return '--';
    // Normaliza UPPERCASE para PascalCase
    const normalizedStatus = this.normalizeStatus(status);
    const labels: Record<string, string> = {
      'Scheduled': 'Agendada',
      'Confirmed': 'Confirmada',
      'CheckedIn': 'Recepcionado',
      'AwaitingDoctor': 'Aguardando Médico',
      'InConsultation': 'Em Consulta',
      'PendingClosure': 'Pendente Fechamento',
      'Completed': 'Realizada',
      'Cancelled': 'Cancelada',
      'NoShow': 'Não Compareceu',
      'InProgress': 'Em Andamento'
    };
    return labels[normalizedStatus] || status;
  }

  private normalizeStatus(status: string): string {
    const statusMap: Record<string, string> = {
      'SCHEDULED': 'Scheduled', 'CONFIRMED': 'Confirmed', 'CHECKEDIN': 'CheckedIn',
      'AWAITINGDOCTOR': 'AwaitingDoctor', 'INCONSULTATION': 'InConsultation',
      'PENDINGCLOSURE': 'PendingClosure', 'COMPLETED': 'Completed',
      'CANCELLED': 'Cancelled', 'NOSHOW': 'NoShow', 'INPROGRESS': 'InProgress'
    };
    return statusMap[status.toUpperCase()] || status;
  }
}
