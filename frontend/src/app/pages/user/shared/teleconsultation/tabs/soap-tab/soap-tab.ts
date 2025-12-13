import { Component, Input, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { ButtonComponent } from '@shared/components/atoms/button/button';

@Component({
  selector: 'app-soap-tab',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, ButtonComponent],
  templateUrl: './soap-tab.html',
  styleUrls: ['./soap-tab.scss']
})
export class SoapTabComponent implements OnInit {
  @Input() appointmentId: string | null = null;
  @Input() userRole: 'patient' | 'professional' | 'admin' = 'patient';

  soapForm: FormGroup;
  isSaving = false;
  lastSaved: Date | null = null;

  constructor(private fb: FormBuilder) {
    this.soapForm = this.fb.group({
      subjective: [''],
      objective: [''],
      assessment: [''],
      plan: ['']
    });
  }

  ngOnInit() {
    // Here we would load existing SOAP data if available
  }

  saveSoap() {
    this.isSaving = true;
    // Simulate API call
    setTimeout(() => {
      this.isSaving = false;
      this.lastSaved = new Date();
      this.soapForm.markAsPristine();
    }, 1000);
  }
}
