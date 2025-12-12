import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { Schedule, DayOfWeek } from '@app/core/services/schedules.service';

@Component({
  selector: 'app-schedule-view-modal',
  standalone: true,
  imports: [CommonModule, DatePipe],
  templateUrl: './schedule-view-modal.html',
  styleUrl: './schedule-view-modal.scss'
})
export class ScheduleViewModalComponent {
  @Input() isOpen = false;
  @Input() schedule: Schedule | null = null;
  @Output() close = new EventEmitter<void>();

  dayLabels: Record<DayOfWeek, string> = {
    'segunda': 'Segunda-feira',
    'terca': 'Terça-feira',
    'quarta': 'Quarta-feira',
    'quinta': 'Quinta-feira',
    'sexta': 'Sexta-feira',
    'sabado': 'Sábado',
    'domingo': 'Domingo'
  };

  onClose(): void {
    this.close.emit();
  }

  getDayLabel(day: DayOfWeek): string {
    return this.dayLabels[day];
  }
}
