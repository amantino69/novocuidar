import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subject, debounceTime, takeUntil } from 'rxjs';
import { environment } from '@env/environment';

interface Patient {
  id: string;
  name: string;
  email: string;
  cpf?: string;
  birthDate?: string;
  age?: number;
  phone?: string;
}

interface Specialty {
  id: string;
  name: string;
}

interface Professional {
  id: string;
  name: string;
  isOnline: boolean;
}

@Component({
  selector: 'app-spontaneous-demand',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  template: `
    <div class="spontaneous-demand-container">
      <div class="modal-overlay" *ngIf="true">
        <div class="modal-content">
          <div class="modal-header">
            <h2>🚨 Demanda Espontânea (Atendimento Urgente)</h2>
            <button class="close-btn" (click)="cancel()">✕</button>
          </div>

          <!-- STEP 1: Buscar Paciente -->
          <div class="step" [hidden]="currentStep !== 1">
            <h3>Passo 1: Buscar Paciente</h3>
            <div class="form-group">
              <label>Buscar por Nome, CPF ou Email:</label>
              <input
                type="text"
                placeholder="Ex: Maria Silva, 123.456.789-00 ou maria@email.com..."
                [(ngModel)]="searchQuery"
                (ngModelChange)="onSearchChange()"
                class="search-input"
                [class.has-results]="searchResults.length > 0"
              />
              <small class="search-hint">Mínimo 2 caracteres</small>
            </div>

            <div class="patients-list" *ngIf="searchResults.length > 0">
              <div class="patients-header">Pacientes encontrados ({{ searchResults.length }})</div>
              <div
                class="patient-item"
                *ngFor="let patient of searchResults"
                (click)="selectPatient(patient)"
                [class.selected]="selectedPatient?.id === patient.id"
              >
                <div class="patient-main">
                  <div class="patient-name">{{ patient.name }}</div>
                  <div class="patient-details">
                    <span class="badge email">{{ patient.email }}</span>
                    <span *ngIf="patient.cpf" class="badge cpf">{{ patient.cpf }}</span>
                    <span *ngIf="patient.age" class="badge age">{{ patient.age }} anos</span>
                  </div>
                </div>
                <div class="patient-select-icon" *ngIf="selectedPatient?.id === patient.id">
                  ✓
                </div>
              </div>
            </div>

            <div class="no-results" *ngIf="searchQuery && searchQuery.length >= 2 && searchResults.length === 0">
              <p>❌ Nenhum paciente encontrado com esses critérios</p>
              <small>Tente refinar a busca por nome ou CPF</small>
            </div>

            <div class="search-empty" *ngIf="!searchQuery">
              <p>🔍 Digite no campo acima para buscar pacientes</p>
            </div>

            <div class="selected-patient-block" *ngIf="selectedPatient">
              <div class="success-badge">✓ PACIENTE SELECIONADO</div>
              <div class="patient-summary">
                <div><strong>Nome:</strong> {{ selectedPatient.name }}</div>
                <div><strong>Email:</strong> {{ selectedPatient.email }}</div>
                <div *ngIf="selectedPatient.cpf"><strong>CPF:</strong> {{ selectedPatient.cpf }}</div>
                <div *ngIf="selectedPatient.age"><strong>Idade:</strong> {{ selectedPatient.age }} anos</div>
              </div>
            </div>

            <button
              class="btn-next"
              (click)="nextStep()"
              [disabled]="!selectedPatient"
            >
              Próximo →
            </button>
          </div>

          <!-- STEP 2: Selecionar Especialidade -->
          <div class="step" [hidden]="currentStep !== 2">
            <h3>Passo 2: Selecionar Especialidade</h3>
            <div class="specialties-grid">
              <div
                class="specialty-card"
                *ngFor="let specialty of specialties"
                (click)="selectSpecialty(specialty)"
                [class.selected]="selectedSpecialty?.id === specialty.id"
              >
                <div class="specialty-name">{{ specialty.name }}</div>
              </div>
            </div>

            <div class="navigation">
              <button class="btn-back" (click)="previousStep()">← Voltar</button>
              <button
                class="btn-next"
                (click)="nextStep()"
                [disabled]="!selectedSpecialty"
              >
                Próximo →
              </button>
            </div>
          </div>

          <!-- STEP 3: Classificar Urgência -->
          <div class="step" [hidden]="currentStep !== 3">
            <h3>Passo 3: Classificar Urgência</h3>
            <div class="urgency-options">
              <div
                class="urgency-card red"
                (click)="selectUrgency('Red')"
                [class.selected]="selectedUrgency === 'Red'"
              >
                <div class="urgency-badge">🔴</div>
                <div class="urgency-title">CRÍTICA</div>
                <div class="urgency-time">Atendimento imediato</div>
              </div>

              <div
                class="urgency-card orange"
                (click)="selectUrgency('Orange')"
                [class.selected]="selectedUrgency === 'Orange'"
              >
                <div class="urgency-badge">🟠</div>
                <div class="urgency-title">MUITO URGENTE</div>
                <div class="urgency-time">até 30 minutos</div>
              </div>

              <div
                class="urgency-card yellow"
                (click)="selectUrgency('Yellow')"
                [class.selected]="selectedUrgency === 'Yellow'"
              >
                <div class="urgency-badge">🟡</div>
                <div class="urgency-title">URGENTE</div>
                <div class="urgency-time">até 1 hora</div>
              </div>

              <div
                class="urgency-card green"
                (click)="selectUrgency('Green')"
                [class.selected]="selectedUrgency === 'Green'"
              >
                <div class="urgency-badge">🟢</div>
                <div class="urgency-title">POUCO URGENTE</div>
                <div class="urgency-time">até 2 horas</div>
              </div>
            </div>

            <div class="form-group">
              <label>Queixa Principal (Opcional):</label>
              <textarea
                [(ngModel)]="chiefComplaint"
                placeholder="Ex: Dor torácica intensa há 30 minutos..."
                rows="3"
              ></textarea>
            </div>

            <div class="navigation">
              <button class="btn-back" (click)="previousStep()">← Voltar</button>
              <button
                class="btn-next"
                (click)="nextStep()"
                [disabled]="!selectedUrgency"
              >
                Próximo →
              </button>
            </div>
          </div>

          <!-- STEP 4: Selecionar Médico -->
          <div class="step" [hidden]="currentStep !== 4">
            <h3>Passo 4: Atribuir Médico</h3>
            <div class="form-group">
              <label>
                <input type="checkbox" [(ngModel)]="autoAssign" />
                Atribuição Automática
              </label>
            </div>

            <div class="professionals-list" *ngIf="!autoAssign">
              <div
                class="professional-card"
                *ngFor="let professional of professionals"
                (click)="selectProfessional(professional)"
                [class.selected]="selectedProfessional?.id === professional.id"
              >
                <div class="professional-name">{{ professional.name }}</div>
                <div class="professional-status" [class.online]="professional.isOnline">
                  {{ professional.isOnline ? '🟢 Online' : '⚪ Offline' }}
                </div>
              </div>
            </div>

            <div class="selected-professional" *ngIf="selectedProfessional">
              <p><strong>✓ Médico Selecionado:</strong> {{ selectedProfessional.name }}</p>
            </div>

            <div class="navigation">
              <button class="btn-back" (click)="previousStep()">← Voltar</button>
              <button
                class="btn-submit"
                (click)="submit()"
                [disabled]="!autoAssign && !selectedProfessional"
              >
                ✓ Registrar Demanda
              </button>
            </div>
          </div>

          <!-- Loading -->
          <div class="loading" *ngIf="isLoading">
            <div class="spinner"></div>
            <p>Processando...</p>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .spontaneous-demand-container {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 2000;
    }

    .modal-overlay {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.7);
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .modal-content {
      background: white;
      border-radius: 12px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      max-width: 700px;
      width: 90%;
      max-height: 90vh;
      overflow-y: auto;
      position: relative;
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 24px;
      border-bottom: 2px solid #f0f0f0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border-radius: 12px 12px 0 0;
    }

    .modal-header h2 {
      margin: 0;
      font-size: 20px;
    }

    .close-btn {
      background: transparent;
      border: none;
      color: white;
      font-size: 28px;
      cursor: pointer;
      padding: 0;
      width: 40px;
      height: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      transition: background 0.3s;
    }

    .close-btn:hover {
      background: rgba(255, 255, 255, 0.2);
    }

    .step {
      padding: 32px;
      animation: fadeIn 0.3s ease-in;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    .step h3 {
      margin: 0 0 24px 0;
      font-size: 18px;
      color: #333;
      border-left: 4px solid #667eea;
      padding-left: 12px;
    }

    .form-group {
      margin-bottom: 20px;
    }

    .form-group label {
      display: block;
      margin-bottom: 8px;
      font-weight: 600;
      color: #555;
      font-size: 14px;
    }

    .search-input {
      width: 100%;
      padding: 12px;
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      font-size: 14px;
      font-family: inherit;
      transition: border-color 0.3s;
    }

    .search-input:focus {
      outline: none;
      border-color: #667eea;
    }

    .search-input.has-results {
      border-bottom-left-radius: 0;
      border-bottom-right-radius: 0;
      border-bottom-color: #667eea;
    }

    .search-hint {
      display: block;
      margin-top: 4px;
      font-size: 12px;
      color: #999;
    }

    textarea {
      width: 100%;
      padding: 12px;
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      font-size: 14px;
      font-family: inherit;
      transition: border-color 0.3s;
      resize: vertical;
    }

    textarea:focus {
      outline: none;
      border-color: #667eea;
    }

    .patients-list {
      margin-top: -2px;
      max-height: 400px;
      overflow-y: auto;
      border: 2px solid #e0e0e0;
      border-top-width: 0;
      border-radius: 0 0 8px 8px;
      background: white;
      z-index: 10;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .patients-header {
      padding: 12px 16px;
      background: #f5f7ff;
      border-bottom: 1px solid #e0e0e0;
      font-size: 13px;
      font-weight: 600;
      color: #667eea;
      position: sticky;
      top: 0;
    }

    .patient-item {
      padding: 14px 16px;
      border-bottom: 1px solid #f0f0f0;
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .patient-item:hover {
      background: #f9f9f9;
      padding-left: 20px;
    }

    .patient-item.selected {
      background: #e8f0ff;
      border-left: 4px solid #667eea;
      padding-left: 12px;
    }

    .patient-main {
      flex: 1;
    }

    .patient-name {
      font-weight: 600;
      color: #333;
      margin-bottom: 6px;
    }

    .patient-details {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 500;
      white-space: nowrap;
    }

    .badge.email {
      background: #e3f2fd;
      color: #1976d2;
    }

    .badge.cpf {
      background: #f3e5f5;
      color: #7b1fa2;
    }

    .badge.age {
      background: #e8f5e9;
      color: #388e3c;
    }

    .patient-select-icon {
      width: 28px;
      height: 28px;
      background: #667eea;
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      font-size: 16px;
    }

    .no-results {
      text-align: center;
      padding: 32px 24px;
      color: #999;
      background: #fafafa;
      border-radius: 8px;
      margin-top: 16px;
    }

    .no-results p {
      margin: 0 0 8px 0;
      font-size: 15px;
    }

    .no-results small {
      display: block;
      font-size: 12px;
      color: #bbb;
    }

    .search-empty {
      text-align: center;
      padding: 32px 24px;
      color: #aaa;
      background: #f9f9f9;
      border-radius: 8px;
      margin-top: 16px;
    }

    .search-empty p {
      margin: 0;
      font-size: 15px;
    }

    .selected-patient-block {
      background: #e8f5e9;
      border-left: 4px solid #4caf50;
      padding: 16px;
      border-radius: 4px;
      margin: 20px 0;
    }

    .success-badge {
      display: inline-block;
      background: #4caf50;
      color: white;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 12px;
    }

    .patient-summary {
      font-size: 14px;
      color: #2e7d32;
    }

    .patient-summary div {
      margin: 6px 0;
    }

    .patient-summary strong {
      color: #1b5e20;
      margin-right: 8px;
    }

    .specialties-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      gap: 12px;
      margin-bottom: 20px;
    }

    .specialty-card {
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      padding: 16px;
      cursor: pointer;
      text-align: center;
      transition: all 0.3s;
    }

    .specialty-card:hover {
      border-color: #667eea;
      background: #f5f7ff;
    }

    .specialty-card.selected {
      border-color: #667eea;
      background: #667eea;
      color: white;
    }

    .specialty-name {
      font-weight: 600;
      font-size: 14px;
    }

    .urgency-options {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
      gap: 12px;
      margin-bottom: 20px;
    }

    .urgency-card {
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      padding: 16px;
      cursor: pointer;
      text-align: center;
      transition: all 0.3s;
    }

    .urgency-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .urgency-card.red { border-color: #dc3545; }
    .urgency-card.red.selected { background: #dc3545; color: white; }

    .urgency-card.orange { border-color: #fd7e14; }
    .urgency-card.orange.selected { background: #fd7e14; color: white; }

    .urgency-card.yellow { border-color: #ffc107; }
    .urgency-card.yellow.selected { background: #ffc107; color: #333; }

    .urgency-card.green { border-color: #28a745; }
    .urgency-card.green.selected { background: #28a745; color: white; }

    .urgency-badge {
      font-size: 32px;
      margin-bottom: 8px;
    }

    .urgency-title {
      font-weight: 600;
      font-size: 14px;
      margin-bottom: 4px;
    }

    .urgency-time {
      font-size: 12px;
      opacity: 0.7;
    }

    .professionals-list {
      display: grid;
      gap: 12px;
      margin-bottom: 20px;
      max-height: 300px;
      overflow-y: auto;
    }

    .professional-card {
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      padding: 16px;
      cursor: pointer;
      transition: all 0.3s;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .professional-card:hover {
      border-color: #667eea;
      background: #f5f7ff;
    }

    .professional-card.selected {
      border-color: #667eea;
      background: #667eea;
      color: white;
    }

    .professional-name {
      font-weight: 600;
    }

    .professional-status {
      font-size: 12px;
      opacity: 0.7;
    }

    .professional-status.online {
      color: #4caf50;
      opacity: 1;
    }

    .navigation {
      display: flex;
      gap: 12px;
      justify-content: space-between;
      margin-top: 24px;
    }

    .btn-back,
    .btn-next,
    .btn-submit {
      padding: 12px 24px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
    }

    .btn-back {
      background: #f0f0f0;
      color: #333;
      flex: 1;
    }

    .btn-back:hover {
      background: #e0e0e0;
    }

    .btn-next,
    .btn-submit {
      background: #667eea;
      color: white;
      flex: 1;
    }

    .btn-next:hover:not(:disabled),
    .btn-submit:hover:not(:disabled) {
      background: #5568d3;
    }

    .btn-next:disabled,
    .btn-submit:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px 20px;
    }

    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #e0e0e0;
      border-top-color: #667eea;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-bottom: 16px;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  `]
})
export class SpontaneousDemandComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private readonly apiUrl = environment.apiUrl;

  currentStep = 1;
  searchQuery = '';
  searchResults: Patient[] = [];
  selectedPatient: Patient | null = null;
  specialties: Specialty[] = [];
  selectedSpecialty: Specialty | null = null;
  selectedUrgency: string | null = null;
  chiefComplaint = '';
  professionals: Professional[] = [];
  selectedProfessional: Professional | null = null;
  autoAssign = true;
  isLoading = false;

  private searchSubject = new Subject<string>();

  constructor(private http: HttpClient, private router: Router) {}

  ngOnInit(): void {
    this.loadSpecialties();
    this.setupSearch();
  }

  private setupSearch(): void {
    this.searchSubject
      .pipe(
        debounceTime(300),
        takeUntil(this.destroy$)
      )
      .subscribe(query => {
        if (query.length > 2) {
          this.searchPatients(query);
        } else {
          this.searchResults = [];
        }
      });
  }

  onSearchChange(): void {
    this.searchSubject.next(this.searchQuery);
  }

  private searchPatients(query: string): void {
    const url = `${this.apiUrl}/receptionist/patients/search?query=${encodeURIComponent(query)}`;
    this.http.get<any>(url)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          // Backend já retorna ordenado, mas garantir ordenação alfabética
          this.searchResults = (response.data || []).sort((a: Patient, b: Patient) => 
            a.name.localeCompare(b.name, 'pt-BR')
          );
        },
        error: (error: any) => {
          console.error('Erro ao buscar pacientes:', error);
          this.searchResults = [];
        }
      });
  }

  private loadSpecialties(): void {
    const url = `${this.apiUrl}/receptionist/specialties`;
    this.http.get<any>(url)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          this.specialties = response.data || [];
        },
        error: (error: any) => {
          console.error('Erro ao carregar especialidades:', error);
        }
      });
  }

  selectPatient(patient: Patient): void {
    this.selectedPatient = patient;
  }

  selectSpecialty(specialty: Specialty): void {
    this.selectedSpecialty = specialty;
    this.professionals = [];
    this.selectedProfessional = null;
    this.loadProfessionals(specialty.id);
  }

  private loadProfessionals(specialtyId: string): void {
    const url = `${this.apiUrl}/receptionist/professionals/by-specialty/${specialtyId}`;
    this.http.get<any>(url)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          this.professionals = response.data || [];
        },
        error: (error: any) => {
          console.error('Erro ao carregar médicos:', error);
        }
      });
  }

  selectUrgency(level: string): void {
    this.selectedUrgency = level;
  }

  selectProfessional(professional: Professional): void {
    this.selectedProfessional = professional;
  }

  calculateAge(birthDate: string): number {
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();

    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }

    return age;
  }

  nextStep(): void {
    if (this.currentStep < 4) {
      this.currentStep++;
    }
  }

  previousStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  async submit(): Promise<void> {
    if (!this.selectedPatient || !this.selectedSpecialty || !this.selectedUrgency) {
      console.error('Preencha todos os campos obrigatórios');
      alert('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    this.isLoading = true;

    const payload = {
      patientId: this.selectedPatient.id,
      specialtyId: this.selectedSpecialty.id,
      professionalId: this.selectedProfessional?.id || null,
      urgencyLevel: this.selectedUrgency,
      chiefComplaint: this.chiefComplaint
    };

    console.log('🚀 Enviando demanda espontânea:', payload);

    const url = `${this.apiUrl}/receptionist/spontaneous-demand`;
    this.http.post<any>(url, payload)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          this.isLoading = false;
          console.log('✅ Demanda registrada com sucesso:', response);
          alert(`Demanda registrada com sucesso! ID: ${response.appointmentId}`);
          this.close();
        },
        error: (error: any) => {
          this.isLoading = false;
          const errorMsg = error?.error?.message || error?.message || JSON.stringify(error);
          console.error('❌ Erro ao registrar demanda:', errorMsg);
          alert(`Erro ao registrar demanda: ${errorMsg}`);
        }
      });
  }

  cancel(): void {
    this.close();
  }

  private close(): void {
    this.router.navigate(['/recepcao']);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
