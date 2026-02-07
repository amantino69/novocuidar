import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { environment } from '@env/environment';
import { CadsusSearchModalComponent } from '../cadsus-search-modal/cadsus-search-modal';
import { CadsusResult } from '@app/core/services/regulator.service';

interface HealthFacility {
  id: string;
  codigoCnes: string;
  nome: string;
  tipo: string;
}

interface PatientFormData {
  // Dados básicos
  name: string;
  lastName: string;
  cpf: string;
  email: string;
  phone: string;
  
  // Perfil
  cns: string;
  socialName: string;
  gender: string;
  birthDate: string;
  motherName: string;
  fatherName: string;
  nationality: string;
  racaCor: string;
  
  // Endereço
  zipCode: string;
  logradouro: string;
  numero: string;
  complemento: string;
  bairro: string;
  city: string;
  state: string;
  
  // Unidade de saúde
  unidadeAdscritaId: string;
  
  // Responsável legal
  responsavelNome: string;
  responsavelCpf: string;
  responsavelTelefone: string;
  responsavelEmail: string;
  responsavelGrauParentesco: string;
}

const ESTADOS_BR = [
  { uf: 'AC', nome: 'Acre' },
  { uf: 'AL', nome: 'Alagoas' },
  { uf: 'AP', nome: 'Amapá' },
  { uf: 'AM', nome: 'Amazonas' },
  { uf: 'BA', nome: 'Bahia' },
  { uf: 'CE', nome: 'Ceará' },
  { uf: 'DF', nome: 'Distrito Federal' },
  { uf: 'ES', nome: 'Espírito Santo' },
  { uf: 'GO', nome: 'Goiás' },
  { uf: 'MA', nome: 'Maranhão' },
  { uf: 'MT', nome: 'Mato Grosso' },
  { uf: 'MS', nome: 'Mato Grosso do Sul' },
  { uf: 'MG', nome: 'Minas Gerais' },
  { uf: 'PA', nome: 'Pará' },
  { uf: 'PB', nome: 'Paraíba' },
  { uf: 'PR', nome: 'Paraná' },
  { uf: 'PE', nome: 'Pernambuco' },
  { uf: 'PI', nome: 'Piauí' },
  { uf: 'RJ', nome: 'Rio de Janeiro' },
  { uf: 'RN', nome: 'Rio Grande do Norte' },
  { uf: 'RS', nome: 'Rio Grande do Sul' },
  { uf: 'RO', nome: 'Rondônia' },
  { uf: 'RR', nome: 'Roraima' },
  { uf: 'SC', nome: 'Santa Catarina' },
  { uf: 'SP', nome: 'São Paulo' },
  { uf: 'SE', nome: 'Sergipe' },
  { uf: 'TO', nome: 'Tocantins' }
];

const RACAS_CORES = [
  { codigo: '01', nome: 'Branca' },
  { codigo: '02', nome: 'Preta' },
  { codigo: '03', nome: 'Parda' },
  { codigo: '04', nome: 'Amarela' },
  { codigo: '05', nome: 'Indígena' }
];

const GRAUS_PARENTESCO = [
  'Mãe',
  'Pai',
  'Avó',
  'Avô',
  'Tio(a)',
  'Irmão(ã)',
  'Cônjuge',
  'Tutor Legal',
  'Curador',
  'Outro'
];

@Component({
  selector: 'app-patient-form-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent, CadsusSearchModalComponent],
  template: `
    <div class="modal-overlay" (click)="onCancel()">
      <div class="modal-content" (click)="$event.stopPropagation()">
        <div class="modal-header">
          <h2>{{ isEditing ? 'Editar' : 'Cadastrar' }} Paciente</h2>
          <div class="header-actions">
            @if (!isEditing) {
              <button class="cadsus-btn" (click)="showCadsusSearch = true">
                <app-icon name="search" [size]="16" />
                Buscar no CADSUS
              </button>
            }
            <button class="close-btn" (click)="onCancel()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
        </div>

        <div class="modal-body">
          <!-- Abas -->
          <div class="tabs">
            <button 
              [class.active]="activeTab === 'basico'" 
              (click)="activeTab = 'basico'"
            >
              <app-icon name="user" [size]="16" />
              Dados Básicos
            </button>
            <button 
              [class.active]="activeTab === 'endereco'" 
              (click)="activeTab = 'endereco'"
            >
              <app-icon name="map-pin" [size]="16" />
              Endereço
            </button>
            <button 
              [class.active]="activeTab === 'responsavel'" 
              (click)="activeTab = 'responsavel'"
            >
              <app-icon name="users" [size]="16" />
              Responsável
            </button>
          </div>

          <!-- Tab: Dados Básicos -->
          @if (activeTab === 'basico') {
            <div class="tab-content">
              <div class="section-title">Identificação</div>
              
              <div class="form-row three-cols">
                <div class="form-group">
                  <label>Nome *</label>
                  <input type="text" [(ngModel)]="form.name" placeholder="Primeiro nome" required>
                </div>
                <div class="form-group">
                  <label>Sobrenome *</label>
                  <input type="text" [(ngModel)]="form.lastName" placeholder="Sobrenome" required>
                </div>
                <div class="form-group">
                  <label>Nome Social</label>
                  <input type="text" [(ngModel)]="form.socialName" placeholder="Se diferente do nome civil">
                </div>
              </div>

              <div class="form-row three-cols">
                <div class="form-group">
                  <label>CPF *</label>
                  <input 
                    type="text" 
                    [(ngModel)]="form.cpf" 
                    placeholder="000.000.000-00"
                    maxlength="14"
                    [disabled]="isEditing"
                    (input)="formatCpf()"
                    required
                  >
                </div>
                <div class="form-group">
                  <label>CNS (Cartão SUS)</label>
                  <input 
                    type="text" 
                    [(ngModel)]="form.cns" 
                    placeholder="000 0000 0000 0000"
                    maxlength="18"
                    (input)="formatCns()"
                  >
                </div>
                <div class="form-group">
                  <label>Data de Nascimento</label>
                  <input type="date" [(ngModel)]="form.birthDate">
                </div>
              </div>

              <div class="form-row three-cols">
                <div class="form-group">
                  <label>Sexo</label>
                  <select [(ngModel)]="form.gender">
                    <option value="">Selecione</option>
                    <option value="M">Masculino</option>
                    <option value="F">Feminino</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Raça/Cor</label>
                  <select [(ngModel)]="form.racaCor">
                    <option value="">Selecione</option>
                    @for (raca of racasCores; track raca.codigo) {
                      <option [value]="raca.nome">{{ raca.nome }}</option>
                    }
                  </select>
                </div>
                <div class="form-group">
                  <label>Nacionalidade</label>
                  <input type="text" [(ngModel)]="form.nationality" placeholder="Brasileira">
                </div>
              </div>

              <div class="section-title">Filiação</div>
              
              <div class="form-row two-cols">
                <div class="form-group">
                  <label>Nome da Mãe</label>
                  <input type="text" [(ngModel)]="form.motherName" placeholder="Nome completo da mãe">
                </div>
                <div class="form-group">
                  <label>Nome do Pai</label>
                  <input type="text" [(ngModel)]="form.fatherName" placeholder="Nome completo do pai">
                </div>
              </div>

              <div class="section-title">Contato</div>
              
              <div class="form-row two-cols">
                <div class="form-group">
                  <label>Telefone</label>
                  <input 
                    type="text" 
                    [(ngModel)]="form.phone" 
                    placeholder="(00) 00000-0000"
                    maxlength="15"
                    (input)="formatPhone()"
                  >
                </div>
                <div class="form-group">
                  <label>Email</label>
                  <input type="email" [(ngModel)]="form.email" placeholder="email@exemplo.com">
                </div>
              </div>

              <div class="section-title">Unidade de Saúde</div>
              
              <div class="form-group">
                <label>Unidade de Saúde (UBS/ESF)</label>
                <select [(ngModel)]="form.unidadeAdscritaId">
                  <option value="">Selecione a unidade</option>
                  @for (facility of healthFacilities; track facility.id) {
                    <option [value]="facility.id">{{ facility.nome }} ({{ facility.codigoCnes }})</option>
                  }
                </select>
              </div>
            </div>
          }

          <!-- Tab: Endereço -->
          @if (activeTab === 'endereco') {
            <div class="tab-content">
              <div class="section-title">Endereço Residencial</div>
              
              <div class="form-row">
                <div class="form-group small">
                  <label>CEP</label>
                  <input 
                    type="text" 
                    [(ngModel)]="form.zipCode" 
                    placeholder="00000-000"
                    maxlength="9"
                    (input)="formatCep()"
                    (blur)="buscarCep()"
                  >
                </div>
                <div class="form-group flex-2">
                  <label>Logradouro</label>
                  <input type="text" [(ngModel)]="form.logradouro" placeholder="Rua, Avenida, Travessa...">
                </div>
                <div class="form-group small">
                  <label>Número</label>
                  <input type="text" [(ngModel)]="form.numero" placeholder="S/N">
                </div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label>Complemento</label>
                  <input type="text" [(ngModel)]="form.complemento" placeholder="Apto, Bloco, Casa...">
                </div>
                <div class="form-group">
                  <label>Bairro</label>
                  <input type="text" [(ngModel)]="form.bairro" placeholder="Bairro">
                </div>
              </div>

              <div class="form-row two-cols">
                <div class="form-group">
                  <label>Cidade</label>
                  <input type="text" [(ngModel)]="form.city" placeholder="Cidade">
                </div>
                <div class="form-group">
                  <label>Estado</label>
                  <select [(ngModel)]="form.state">
                    <option value="">Selecione</option>
                    @for (estado of estados; track estado.uf) {
                      <option [value]="estado.uf">{{ estado.nome }}</option>
                    }
                  </select>
                </div>
              </div>
            </div>
          }

          <!-- Tab: Responsável -->
          @if (activeTab === 'responsavel') {
            <div class="tab-content">
              <div class="info-box">
                <app-icon name="info" [size]="18" />
                <span>Preencha os dados do responsável legal para pacientes menores de idade ou incapazes.</span>
              </div>

              <div class="section-title">Dados do Responsável Legal</div>
              
              <div class="form-row two-cols">
                <div class="form-group">
                  <label>Nome Completo</label>
                  <input type="text" [(ngModel)]="form.responsavelNome" placeholder="Nome do responsável">
                </div>
                <div class="form-group">
                  <label>Grau de Parentesco</label>
                  <select [(ngModel)]="form.responsavelGrauParentesco">
                    <option value="">Selecione</option>
                    @for (grau of grausParentesco; track grau) {
                      <option [value]="grau">{{ grau }}</option>
                    }
                  </select>
                </div>
              </div>

              <div class="form-row two-cols">
                <div class="form-group">
                  <label>CPF do Responsável</label>
                  <input 
                    type="text" 
                    [(ngModel)]="form.responsavelCpf" 
                    placeholder="000.000.000-00"
                    maxlength="14"
                    (input)="formatResponsavelCpf()"
                  >
                </div>
                <div class="form-group">
                  <label>Telefone</label>
                  <input 
                    type="text" 
                    [(ngModel)]="form.responsavelTelefone" 
                    placeholder="(00) 00000-0000"
                    maxlength="15"
                    (input)="formatResponsavelPhone()"
                  >
                </div>
              </div>

              <div class="form-group">
                <label>Email do Responsável</label>
                <input type="email" [(ngModel)]="form.responsavelEmail" placeholder="email@exemplo.com">
              </div>
            </div>
          }

          @if (error) {
            <div class="error-message">
              <app-icon name="alert-circle" [size]="16" />
              {{ error }}
            </div>
          }
        </div>

        <div class="modal-footer">
          <button class="btn-secondary" (click)="onCancel()">Cancelar</button>
          <button class="btn-primary" (click)="onSave()" [disabled]="saving">
            @if (saving) {
              <span class="spinner"></span>
            }
            {{ saving ? 'Salvando...' : (isEditing ? 'Salvar Alterações' : 'Cadastrar Paciente') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal de busca CADSUS -->
    @if (showCadsusSearch) {
      <app-cadsus-search-modal
        (selected)="applyCadsusData($event)"
        (cancel)="showCadsusSearch = false"
      />
    }
  `,
  styles: [`
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: flex-start;
      justify-content: center;
      z-index: 1000;
      padding: 100px 20px 20px 20px;
      overflow-y: auto;
    }

    .modal-content {
      background: white;
      border-radius: 16px;
      width: 100%;
      max-width: 800px;
      max-height: calc(100vh - 120px);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      margin-top: 0;
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 24px;
      border-bottom: 1px solid #e2e8f0;
      flex-shrink: 0;
      background: white;
      z-index: 10;

      h2 {
        margin: 0;
        font-size: 20px;
        font-weight: 600;
        color: #0f172a;
      }

      .header-actions {
        display: flex;
        align-items: center;
        gap: 12px;
      }

      .cadsus-btn {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 8px 14px;
        background: #f0f9ff;
        border: 1px solid #bae6fd;
        border-radius: 8px;
        color: #0284c7;
        font-size: 13px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
        &:hover {
          background: #e0f2fe;
          border-color: #7dd3fc;
        }
      }

      .close-btn {
        background: none;
        border: none;
        cursor: pointer;
        color: #64748b;
        padding: 4px;
        border-radius: 8px;
        &:hover { background: #f1f5f9; color: #0f172a; }
      }
    }

    .modal-body {
      flex: 1;
      overflow-y: auto;
      padding: 0;
      min-height: 0;
    }

    .tabs {
      display: flex;
      gap: 4px;
      padding: 16px 24px;
      border-bottom: 1px solid #e2e8f0;
      background: #f8fafc;
      position: sticky;
      top: 0;
      z-index: 5;

      button {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 16px;
        border: none;
        background: transparent;
        border-radius: 8px;
        font-size: 14px;
        color: #64748b;
        cursor: pointer;
        transition: all 0.2s;

        &:hover { background: #e2e8f0; }
        &.active {
          background: #0d9488;
          color: white;
        }
      }
    }

    .tab-content {
      padding: 24px;
    }

    .section-title {
      font-size: 13px;
      font-weight: 600;
      color: #64748b;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin: 20px 0 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid #f1f5f9;

      &:first-child { margin-top: 0; }
    }

    .form-row {
      display: grid;
      gap: 16px;
      margin-bottom: 16px;

      &.two-cols { grid-template-columns: 1fr 1fr; }
      &.three-cols { grid-template-columns: 1fr 1fr 1fr; }
    }

    .form-group {
      &.small { max-width: 140px; }
      &.flex-2 { flex: 2; }

      label {
        display: block;
        font-size: 13px;
        font-weight: 500;
        color: #374151;
        margin-bottom: 6px;
      }

      input, select {
        width: 100%;
        padding: 10px 12px;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        font-size: 14px;
        transition: border-color 0.2s;

        &:focus {
          outline: none;
          border-color: #0d9488;
        }

        &:disabled {
          background: #f8fafc;
          cursor: not-allowed;
        }
      }

      select { cursor: pointer; }
    }

    .info-box {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 16px;
      background: #f0fdfa;
      border-radius: 8px;
      margin-bottom: 20px;

      app-icon { color: #0d9488; flex-shrink: 0; margin-top: 2px; }
      span { font-size: 14px; color: #0f766e; line-height: 1.5; }
    }

    .error-message {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 24px;
      background: #fef2f2;
      color: #dc2626;
      font-size: 14px;
    }

    .modal-footer {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding: 16px 24px;
      border-top: 1px solid #e2e8f0;
      background: #f8fafc;
      flex-shrink: 0;
    }

    .btn-primary {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 20px;
      background: #0d9488;
      border: none;
      border-radius: 8px;
      color: white;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;

      &:hover { background: #0f766e; }
      &:disabled { opacity: 0.6; cursor: not-allowed; }
    }

    .btn-secondary {
      padding: 10px 20px;
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      font-size: 14px;
      cursor: pointer;

      &:hover { background: #f1f5f9; }
    }

    .spinner {
      width: 16px;
      height: 16px;
      border: 2px solid rgba(255,255,255,0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin { to { transform: rotate(360deg); } }

    /* Dark mode */
    :host-context([data-theme="dark"]) {
      .modal-content { background: #1e293b; }
      .modal-header { 
        border-color: #334155; 
        h2 { color: #f1f5f9; }
        .cadsus-btn {
          background: #0c4a6e;
          border-color: #0369a1;
          color: #7dd3fc;
          &:hover { background: #075985; }
        }
      }
      .tabs { 
        background: #0f172a; 
        border-color: #334155;
        button { color: #94a3b8; &:hover { background: #334155; } }
      }
      .section-title { color: #94a3b8; border-color: #334155; }
      .form-group {
        label { color: #94a3b8; }
        input, select { 
          background: #334155; 
          border-color: #475569; 
          color: #f1f5f9;
        }
      }
      .info-box { background: #134e4a; span { color: #5eead4; } }
      .modal-footer { background: #0f172a; border-color: #334155; }
      .btn-secondary { background: #334155; border-color: #475569; color: #f1f5f9; }
    }

    @media (max-width: 768px) {
      .form-row.two-cols, .form-row.three-cols { grid-template-columns: 1fr; }
      .tabs { flex-wrap: wrap; }
    }
  `]
})
export class PatientFormModalComponent implements OnInit {
  @Input() patientId: string | null = null;
  @Output() saved = new EventEmitter<void>();
  @Output() cancel = new EventEmitter<void>();

  isEditing = false;
  saving = false;
  error: string | null = null;
  activeTab: 'basico' | 'endereco' | 'responsavel' = 'basico';

  healthFacilities: HealthFacility[] = [];
  estados = ESTADOS_BR;
  racasCores = RACAS_CORES;
  grausParentesco = GRAUS_PARENTESCO;

  form: PatientFormData = this.getEmptyForm();

  // CADSUS search
  showCadsusSearch = false;

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.isEditing = !!this.patientId;
    this.loadHealthFacilities();
    
    if (this.isEditing && this.patientId) {
      this.loadPatientData();
    }
  }

  getEmptyForm(): PatientFormData {
    return {
      name: '',
      lastName: '',
      cpf: '',
      email: '',
      phone: '',
      cns: '',
      socialName: '',
      gender: '',
      birthDate: '',
      motherName: '',
      fatherName: '',
      nationality: 'Brasileira',
      racaCor: '',
      zipCode: '',
      logradouro: '',
      numero: '',
      complemento: '',
      bairro: '',
      city: '',
      state: '',
      unidadeAdscritaId: '',
      responsavelNome: '',
      responsavelCpf: '',
      responsavelTelefone: '',
      responsavelEmail: '',
      responsavelGrauParentesco: ''
    };
  }

  loadHealthFacilities() {
    this.http.get<HealthFacility[]>(`${environment.apiUrl}/regulator/health-facilities`)
      .subscribe({
        next: (data) => this.healthFacilities = data,
        error: (err) => console.error('Erro ao carregar unidades:', err)
      });
  }

  loadPatientData() {
    this.http.get<any>(`${environment.apiUrl}/regulator/patients/${this.patientId}`)
      .subscribe({
        next: (response) => {
          const p = response.patient;
          const profile = p.profile;
          
          this.form = {
            name: p.name || '',
            lastName: p.lastName || '',
            cpf: p.cpf || '',
            email: p.email || '',
            phone: p.phone || '',
            cns: profile?.cns || '',
            socialName: profile?.socialName || '',
            gender: profile?.gender || '',
            birthDate: profile?.birthDate ? profile.birthDate.substring(0, 10) : '',
            motherName: profile?.motherName || '',
            fatherName: profile?.fatherName || '',
            nationality: profile?.nationality || 'Brasileira',
            racaCor: profile?.racaCor || '',
            zipCode: profile?.zipCode || '',
            logradouro: profile?.logradouro || '',
            numero: profile?.numero || '',
            complemento: profile?.complemento || '',
            bairro: profile?.bairro || '',
            city: profile?.city || '',
            state: profile?.state || '',
            unidadeAdscritaId: profile?.unidadeAdscritaId || '',
            responsavelNome: profile?.responsavelNome || '',
            responsavelCpf: profile?.responsavelCpf || '',
            responsavelTelefone: profile?.responsavelTelefone || '',
            responsavelEmail: profile?.responsavelEmail || '',
            responsavelGrauParentesco: profile?.responsavelGrauParentesco || ''
          };
        },
        error: (err) => {
          this.error = 'Erro ao carregar dados do paciente';
          console.error(err);
        }
      });
  }

  onSave() {
    if (!this.form.name || !this.form.lastName || !this.form.cpf) {
      this.error = 'Preencha os campos obrigatórios: Nome, Sobrenome e CPF';
      return;
    }

    this.saving = true;
    this.error = null;

    const body = {
      ...this.form,
      birthDate: this.form.birthDate || null,
      unidadeAdscritaId: this.form.unidadeAdscritaId || null
    };

    const request = this.isEditing
      ? this.http.put(`${environment.apiUrl}/regulator/patients/${this.patientId}`, body)
      : this.http.post(`${environment.apiUrl}/regulator/patients`, body);

    request.subscribe({
      next: () => {
        this.saving = false;
        this.saved.emit();
      },
      error: (err) => {
        this.saving = false;
        this.error = err.error?.message || 'Erro ao salvar paciente';
      }
    });
  }

  onCancel() {
    this.cancel.emit();
  }

  // Formatação de campos
  formatCpf() {
    let value = this.form.cpf.replace(/\D/g, '');
    if (value.length > 11) value = value.slice(0, 11);
    if (value.length > 9) {
      value = value.replace(/(\d{3})(\d{3})(\d{3})(\d{1,2})/, '$1.$2.$3-$4');
    } else if (value.length > 6) {
      value = value.replace(/(\d{3})(\d{3})(\d{1,3})/, '$1.$2.$3');
    } else if (value.length > 3) {
      value = value.replace(/(\d{3})(\d{1,3})/, '$1.$2');
    }
    this.form.cpf = value;
  }

  formatCns() {
    let value = this.form.cns.replace(/\D/g, '');
    if (value.length > 15) value = value.slice(0, 15);
    if (value.length > 11) {
      value = value.replace(/(\d{3})(\d{4})(\d{4})(\d{1,4})/, '$1 $2 $3 $4');
    } else if (value.length > 7) {
      value = value.replace(/(\d{3})(\d{4})(\d{1,4})/, '$1 $2 $3');
    } else if (value.length > 3) {
      value = value.replace(/(\d{3})(\d{1,4})/, '$1 $2');
    }
    this.form.cns = value;
  }

  formatPhone() {
    let value = this.form.phone.replace(/\D/g, '');
    if (value.length > 11) value = value.slice(0, 11);
    if (value.length > 10) {
      value = value.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
    } else if (value.length > 6) {
      value = value.replace(/(\d{2})(\d{4,5})(\d{0,4})/, '($1) $2-$3');
    } else if (value.length > 2) {
      value = value.replace(/(\d{2})(\d{0,5})/, '($1) $2');
    }
    this.form.phone = value;
  }

  formatCep() {
    let value = this.form.zipCode.replace(/\D/g, '');
    if (value.length > 8) value = value.slice(0, 8);
    if (value.length > 5) {
      value = value.replace(/(\d{5})(\d{1,3})/, '$1-$2');
    }
    this.form.zipCode = value;
  }

  formatResponsavelCpf() {
    let value = this.form.responsavelCpf.replace(/\D/g, '');
    if (value.length > 11) value = value.slice(0, 11);
    if (value.length > 9) {
      value = value.replace(/(\d{3})(\d{3})(\d{3})(\d{1,2})/, '$1.$2.$3-$4');
    } else if (value.length > 6) {
      value = value.replace(/(\d{3})(\d{3})(\d{1,3})/, '$1.$2.$3');
    } else if (value.length > 3) {
      value = value.replace(/(\d{3})(\d{1,3})/, '$1.$2');
    }
    this.form.responsavelCpf = value;
  }

  formatResponsavelPhone() {
    let value = this.form.responsavelTelefone.replace(/\D/g, '');
    if (value.length > 11) value = value.slice(0, 11);
    if (value.length > 10) {
      value = value.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
    } else if (value.length > 6) {
      value = value.replace(/(\d{2})(\d{4,5})(\d{0,4})/, '($1) $2-$3');
    } else if (value.length > 2) {
      value = value.replace(/(\d{2})(\d{0,5})/, '($1) $2');
    }
    this.form.responsavelTelefone = value;
  }

  buscarCep() {
    const cep = this.form.zipCode.replace(/\D/g, '');
    if (cep.length !== 8) return;

    // Usar API ViaCEP para buscar endereço
    this.http.get<any>(`https://viacep.com.br/ws/${cep}/json/`)
      .subscribe({
        next: (data) => {
          if (!data.erro) {
            this.form.logradouro = data.logradouro || '';
            this.form.bairro = data.bairro || '';
            this.form.city = data.localidade || '';
            this.form.state = data.uf || '';
          }
        },
        error: () => {} // Silenciar erros
      });
  }

  // === CADSUS Integration ===
  applyCadsusData(data: CadsusResult) {
    this.showCadsusSearch = false;

    // Preencher formulário com dados do CADSUS
    if (data.nome) this.form.name = data.nome;
    if (data.sobrenome) this.form.lastName = data.sobrenome;
    if (data.cpf) {
      this.form.cpf = data.cpf;
      this.formatCpf();
    }
    if (data.cns) {
      this.form.cns = data.cns;
      this.formatCns();
    }
    if (data.nomeSocial) this.form.socialName = data.nomeSocial;
    if (data.sexo) this.form.gender = data.sexo;
    if (data.dataNascimento) {
      const date = new Date(data.dataNascimento);
      this.form.birthDate = date.toISOString().substring(0, 10);
    }
    if (data.nomeMae) this.form.motherName = data.nomeMae;
    if (data.nomePai) this.form.fatherName = data.nomePai;
    if (data.nacionalidade) this.form.nationality = data.nacionalidade;
    if (data.racaCor) this.form.racaCor = data.racaCor;
    if (data.telefone) {
      this.form.phone = data.telefone;
      this.formatPhone();
    }
    if (data.email) this.form.email = data.email;
    if (data.cep) {
      this.form.zipCode = data.cep;
      this.formatCep();
    }
    if (data.logradouro) this.form.logradouro = data.logradouro;
    if (data.numero) this.form.numero = data.numero;
    if (data.complemento) this.form.complemento = data.complemento;
    if (data.bairro) this.form.bairro = data.bairro;
    if (data.municipio) this.form.city = data.municipio;
    if (data.uf) this.form.state = data.uf;

    // Mudar para aba básica para mostrar os dados preenchidos
    this.activeTab = 'basico';
  }
}
