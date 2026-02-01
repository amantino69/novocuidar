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
    const labels: Record<string, string> = {
      'Scheduled': 'Agendada',
      'Confirmed': 'Confirmada',
      'InProgress': 'Em Andamento',
      'Completed': 'Realizada',
      'Cancelled': 'Cancelada',
      'NoShow': 'Não Compareceu'
    };
    return labels[status || ''] || status || '--';
  }
}
