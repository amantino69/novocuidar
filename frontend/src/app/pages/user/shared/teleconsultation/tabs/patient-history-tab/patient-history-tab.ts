import { Component, Input, OnInit, OnDestroy, inject, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, takeUntil } from 'rxjs';
import {
  ClinicalTimelineService,
  ClinicalTimeline,
  TimelineEntry,
  TimelineBiometrics,
} from '../../../../../../core/services/clinical-timeline.service';
import { Appointment } from '../../../../../../core/services/appointments.service';
import { IconComponent, IconName } from '../../../../../../shared/components/atoms/icon/icon';

interface VitalTrend {
  label: string;
  value: string;
  unit: string;
  trend: 'up' | 'down' | 'stable' | null;
  status: 'normal' | 'warning' | 'critical';
  icon: IconName;
}

@Component({
  selector: 'app-patient-history-tab',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  templateUrl: './patient-history-tab.html',
  styleUrl: './patient-history-tab.scss',
})
export class PatientHistoryTabComponent implements OnInit, OnDestroy, OnChanges {
  @Input() appointmentId: string | null | undefined;
  @Input() appointment: Appointment | null | undefined;
  @Input() isDetailsView = false;

  private readonly timelineService = inject(ClinicalTimelineService);
  private readonly destroy$ = new Subject<void>();

  loading = true;
  error: string | null = null;
  timeline: ClinicalTimeline | null = null;
  filteredEntries: TimelineEntry[] = [];
  selectedEntry: TimelineEntry | null = null;
  loadingDetails = false;
  activeFilter: 'all' | 'consultations' | 'prescriptions' | 'exams' = 'all';
  dateFilter: 'all' | '30d' | '90d' | '1y' = 'all';
  vitalTrends: VitalTrend[] = [];

  ngOnInit() {
    this.loadTimeline();
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['appointment'] && !changes['appointment'].firstChange) {
      this.loadTimeline();
    }
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private get patientId(): string | null {
    return this.appointment?.patientId || null;
  }

  loadTimeline() {
    if (!this.patientId) {
      this.loading = false;
      this.error = 'Paciente não identificado';
      return;
    }

    this.loading = true;
    this.error = null;

    this.timelineService
      .getTimelineByPatientId(this.patientId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data: ClinicalTimeline) => {
          this.timeline = data;
          this.applyFilter();
          this.buildVitalTrends();
          this.loading = false;
        },
        error: () => {
          this.error = 'Erro ao carregar prontuário';
          this.loading = false;
        },
      });
  }

  private buildVitalTrends() {
    if (!this.timeline?.entries?.length) {
      this.vitalTrends = [];
      return;
    }

    const bio = this.findLastBiometric(this.timeline.entries);
    if (!bio.current) {
      this.vitalTrends = [];
      return;
    }

    const trends: VitalTrend[] = [];
    const c = bio.current;
    const p = bio.previous;

    if (c.bloodPressureSystolic && c.bloodPressureDiastolic) {
      trends.push({
        label: 'Pressão Arterial',
        value: `${c.bloodPressureSystolic}/${c.bloodPressureDiastolic}`,
        unit: 'mmHg',
        trend: this.calcTrend(c.bloodPressureSystolic, p?.bloodPressureSystolic),
        status: this.getBPStatus(c.bloodPressureSystolic, c.bloodPressureDiastolic),
        icon: 'heart-pulse',
      });
    }

    if (c.heartRate) {
      trends.push({
        label: 'Frequência Cardíaca',
        value: c.heartRate.toString(),
        unit: 'bpm',
        trend: this.calcTrend(c.heartRate, p?.heartRate),
        status: this.getHRStatus(c.heartRate),
        icon: 'heart',
      });
    }

    if (c.oxygenSaturation) {
      trends.push({
        label: 'Saturação O₂',
        value: c.oxygenSaturation.toString(),
        unit: '%',
        trend: this.calcTrend(c.oxygenSaturation, p?.oxygenSaturation),
        status: this.getSpO2Status(c.oxygenSaturation),
        icon: 'activity',
      });
    }

    if (c.temperature) {
      trends.push({
        label: 'Temperatura',
        value: c.temperature.toFixed(1),
        unit: '°C',
        trend: this.calcTrend(c.temperature, p?.temperature),
        status: this.getTempStatus(c.temperature),
        icon: 'thermometer',
      });
    }

    if (c.weight) {
      trends.push({
        label: 'Peso',
        value: c.weight.toFixed(1),
        unit: 'kg',
        trend: this.calcTrend(c.weight, p?.weight),
        status: 'normal',
        icon: 'scale',
      });
    }

    this.vitalTrends = trends;
  }

  private findLastBiometric(entries: TimelineEntry[]): { current: TimelineBiometrics | null; previous: TimelineBiometrics | null } {
    let current: TimelineBiometrics | null = null;
    let previous: TimelineBiometrics | null = null;

    for (const entry of entries) {
      if (entry.biometrics) {
        if (!current) {
          current = entry.biometrics;
        } else if (!previous) {
          previous = entry.biometrics;
          break;
        }
      }
    }
    return { current, previous };
  }

  private calcTrend(curr: number | null | undefined, prev: number | null | undefined): 'up' | 'down' | 'stable' | null {
    if (!curr || !prev) return null;
    const diff = curr - prev;
    const threshold = prev * 0.05;
    if (Math.abs(diff) < threshold) return 'stable';
    return diff > 0 ? 'up' : 'down';
  }

  getBPStatus(sys: number, dia: number): 'normal' | 'warning' | 'critical' {
    if (sys >= 180 || dia >= 120) return 'critical';
    if (sys >= 140 || dia >= 90) return 'warning';
    if (sys < 90 || dia < 60) return 'warning';
    return 'normal';
  }

  getHRStatus(hr: number): 'normal' | 'warning' | 'critical' {
    if (hr < 40 || hr > 150) return 'critical';
    if (hr < 60 || hr > 100) return 'warning';
    return 'normal';
  }

  getSpO2Status(spo2: number): 'normal' | 'warning' | 'critical' {
    if (spo2 < 90) return 'critical';
    if (spo2 < 95) return 'warning';
    return 'normal';
  }

  getTempStatus(temp: number): 'normal' | 'warning' | 'critical' {
    if (temp >= 39.5 || temp <= 35) return 'critical';
    if (temp >= 37.5 || temp < 36) return 'warning';
    return 'normal';
  }

  applyFilter() {
    if (!this.timeline?.entries) {
      this.filteredEntries = [];
      return;
    }

    let entries = [...this.timeline.entries];

    if (this.dateFilter !== 'all') {
      const now = new Date();
      let cutoff: Date;
      switch (this.dateFilter) {
        case '30d': cutoff = new Date(now.setDate(now.getDate() - 30)); break;
        case '90d': cutoff = new Date(now.setDate(now.getDate() - 90)); break;
        case '1y': cutoff = new Date(now.setFullYear(now.getFullYear() - 1)); break;
        default: cutoff = new Date(0);
      }
      entries = entries.filter((e) => new Date(e.date) >= cutoff);
    }

    if (this.activeFilter !== 'all') {
      entries = entries.filter((e) => {
        switch (this.activeFilter) {
          case 'consultations': return e.soap || e.aiSummary;
          case 'prescriptions': return e.prescriptionsCount > 0;
          case 'exams': return e.examRequestsCount > 0;
          default: return true;
        }
      });
    }

    this.filteredEntries = entries;
  }

  setFilter(filter: 'all' | 'consultations' | 'prescriptions' | 'exams') {
    this.activeFilter = filter;
    this.applyFilter();
  }

  setDateFilter(filter: 'all' | '30d' | '90d' | '1y') {
    this.dateFilter = filter;
    this.applyFilter();
  }

  loadEntryDetails(entry: TimelineEntry) {
    if (this.selectedEntry?.appointmentId === entry.appointmentId) {
      this.selectedEntry = null;
      return;
    }

    this.loadingDetails = true;
    this.selectedEntry = entry;

    if (!entry.soap && !entry.prescriptions && !entry.aiSummary) {
      this.timelineService
        .getAppointmentDetails(entry.appointmentId)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (details: TimelineEntry) => {
            Object.assign(entry, details);
            this.loadingDetails = false;
          },
          error: () => {
            this.loadingDetails = false;
          },
        });
    } else {
      this.loadingDetails = false;
    }
  }

  formatDate(date: string): string {
    return new Date(date).toLocaleDateString('pt-BR');
  }

  getStatusText(status: string): string {
    const map: Record<string, string> = {
      Completed: 'Realizada',
      InProgress: 'Em andamento',
      Scheduled: 'Agendada',
      Cancelled: 'Cancelada',
      NoShow: 'Não compareceu',
    };
    return map[status] || status;
  }

  getStatusClass(status: string): string {
    const map: Record<string, string> = {
      Completed: 'status-completed',
      InProgress: 'status-progress',
      Scheduled: 'status-scheduled',
      Cancelled: 'status-cancelled',
      NoShow: 'status-noshow',
    };
    return map[status] || '';
  }

  getTrendIcon(trend: 'up' | 'down' | 'stable' | null): IconName {
    switch (trend) {
      case 'up': return 'chevron-up';
      case 'down': return 'chevron-down';
      default: return 'minus';
    }
  }

  getVitalStatusClass(status: 'normal' | 'warning' | 'critical'): string {
    switch (status) {
      case 'critical': return 'vital-critical';
      case 'warning': return 'vital-warning';
      default: return 'vital-normal';
    }
  }

  isCurrentAppointment(entry: TimelineEntry): boolean {
    return entry.appointmentId === this.appointmentId;
  }

  hasAIInsights(): boolean {
    return !!this.timeline?.entries?.some((e) => e.aiSummary);
  }

  getAIInsights(): string[] {
    if (!this.timeline?.entries) return [];
    return this.timeline.entries.filter((e) => e.aiSummary).map((e) => e.aiSummary!).slice(0, 3);
  }

  refresh() {
    this.loadTimeline();
  }
}
