import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { ButtonComponent } from '@shared/components/atoms/button/button';
import { AppointmentsService, Appointment } from '@core/services/appointments.service';
import { Subject, takeUntil, debounceTime } from 'rxjs';

@Component({
  selector: 'app-soap-tab',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, ButtonComponent],
  templateUrl: './soap-tab.html',
  styleUrls: ['./soap-tab.scss']
})
export class SoapTabComponent implements OnInit, OnDestroy {
  @Input() appointmentId: string | null = null;
  @Input() appointment: Appointment | null = null;
  @Input() userrole: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' = 'PATIENT';
  @Input() readonly = false;

  soapForm: FormGroup;
  isSaving = false;
  lastSaved: Date | null = null;
  private destroy$ = new Subject<void>();

  constructor(
    private fb: FormBuilder,
    private appointmentsService: AppointmentsService
  ) {
    this.soapForm = this.fb.group({
      subjective: [''],
      objective: [''],
      assessment: [''],
      plan: ['']
    });
  }

  ngOnInit() {
    // Carregar dados existentes do SOAP
    this.loadSoapData();
    
    if (this.readonly) {
      this.soapForm.disable();
      return;
    }
    
    // Auto-save on value changes (debounced) - apenas para profissionais
    if (this.userrole === 'PROFESSIONAL') {
      this.soapForm.valueChanges
        .pipe(
          takeUntil(this.destroy$),
          debounceTime(2000)
        )
        .subscribe(() => {
          if (this.soapForm.dirty) {
            this.saveSoap();
          }
        });
    }
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadSoapData() {
    if (this.appointment?.soapJson) {
      try {
        const soapData = JSON.parse(this.appointment.soapJson);
        this.soapForm.patchValue(soapData);
        this.soapForm.markAsPristine();
      } catch (error) {
        console.error('Erro ao carregar dados do SOAP:', error);
      }
    }
  }

  saveSoap() {
    if (!this.appointmentId) return;
    
    this.isSaving = true;
    
    const soapJson = JSON.stringify(this.soapForm.value);
    
    this.appointmentsService.updateAppointment(this.appointmentId, { soapJson })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.isSaving = false;
          this.lastSaved = new Date();
          this.soapForm.markAsPristine();
        },
        error: (error) => {
          console.error('Erro ao salvar SOAP:', error);
          this.isSaving = false;
        }
      });
  }
}
