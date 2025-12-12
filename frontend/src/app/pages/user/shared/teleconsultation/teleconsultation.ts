import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { IconComponent } from '@shared/components/atoms/icon/icon';
import { ButtonComponent } from '@shared/components/atoms/button/button';
import { ThemeToggleComponent } from '@shared/components/atoms/theme-toggle/theme-toggle';
import { AppointmentsService, Appointment } from '@core/services/appointments.service';
import { TeleconsultationSidebarComponent } from './sidebar/teleconsultation-sidebar';

@Component({
  selector: 'app-teleconsultation',
  standalone: true,
  imports: [CommonModule, IconComponent, ButtonComponent, ThemeToggleComponent, RouterModule, TeleconsultationSidebarComponent],
  templateUrl: './teleconsultation.html',
  styleUrls: ['./teleconsultation.scss']
})
export class TeleconsultationComponent implements OnInit {
  appointmentId: string | null = null;
  appointment: Appointment | null = null;
  userRole: 'patient' | 'professional' | 'admin' = 'patient';
  
  // UI States
  isHeaderVisible = true;
  isSidebarOpen = false;
  isSidebarFull = false;
  activeTab: string = '';

  // Tabs configuration
  professionalTabs = ['A', 'B', 'C'];
  patientTabs = ['D', 'E', 'F'];
  currentTabs: string[] = [];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private appointmentsService: AppointmentsService
  ) {}

  ngOnInit(): void {
    this.appointmentId = this.route.snapshot.paramMap.get('id');
    this.determineUserRole();
    this.setupTabs();
    
    if (this.appointmentId) {
      this.loadAppointment(this.appointmentId);
    }
  }

  determineUserRole() {
    const url = this.router.url;
    if (url.includes('/patient')) {
      this.userRole = 'patient';
    } else if (url.includes('/professional')) {
      this.userRole = 'professional';
    } else {
      this.userRole = 'admin';
    }
  }

  setupTabs() {
    this.currentTabs = this.userRole === 'professional' ? this.professionalTabs : this.patientTabs;
    if (this.currentTabs.length > 0) {
      this.activeTab = this.currentTabs[0];
    }
  }

  loadAppointment(id: string) {
    this.appointmentsService.getAppointmentById(id).subscribe(appt => {
      if (appt) {
        this.appointment = appt;
      }
    });
  }

  toggleHeader() {
    this.isHeaderVisible = !this.isHeaderVisible;
  }

  toggleSidebar() {
    this.isSidebarOpen = !this.isSidebarOpen;
    if (!this.isSidebarOpen) {
        this.isSidebarFull = false; // Reset full mode when closing
    }
  }

  toggleSidebarMode() {
    this.isSidebarFull = !this.isSidebarFull;
  }

  setActiveTab(tab: string) {
    this.activeTab = tab;
  }

  exitCall() {
    // Navigate back to appointments
    const basePath = this.userRole === 'patient' ? 'patient' : 'professional';
    this.router.navigate([`/${basePath}/appointments`]);
  }
}
