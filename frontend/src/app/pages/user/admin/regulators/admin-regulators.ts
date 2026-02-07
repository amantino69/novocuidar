import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { environment } from '@env/environment';

interface Regulator {
  id: string;
  name: string;
  lastName: string;
  fullName: string;
  email: string;
  cpf: string;
  phone: string | null;
  status: string;
  municipioId: string | null;
  municipio: {
    id: string;
    nome: string;
    uf: string;
    codigoIbge: string;
  } | null;
  createdAt: string;
}

interface Municipality {
  id: string;
  nome: string;
  uf: string;
  codigoIbge: string;
  temRegulador: boolean;
}

@Component({
  selector: 'app-admin-regulators',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, IconComponent],
  template: `
    <div class="page-container">
      <header class="page-header">
        <button class="back-btn" routerLink="/painel">
          <app-icon name="arrow-left" [size]="20" />
          Voltar
        </button>
        <div class="header-content">
          <h1>
            <app-icon name="users" [size]="28" />
            Gestão de Reguladores
          </h1>
          <p class="subtitle">Gerencie reguladores municipais e suas vinculações</p>
        </div>
        <button class="btn-primary" (click)="openCreateModal()">
          <app-icon name="plus" [size]="18" />
          Novo Regulador
        </button>
      </header>

      <!-- Stats Cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <app-icon name="users" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ regulators.length }}</span>
            <span class="stat-label">Total Reguladores</span>
          </div>
        </div>
        <div class="stat-card success">
          <app-icon name="check-circle" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ regulatorsVinculados }}</span>
            <span class="stat-label">Vinculados</span>
          </div>
        </div>
        <div class="stat-card warning">
          <app-icon name="alert-circle" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ regulatorsSemVinculo }}</span>
            <span class="stat-label">Sem Vínculo</span>
          </div>
        </div>
        <div class="stat-card info">
          <app-icon name="globe" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ municipalities.length }}</span>
            <span class="stat-label">Municípios</span>
          </div>
        </div>
      </div>

      <!-- Loading -->
      @if (loading) {
        <div class="loading-container">
          <div class="spinner"></div>
          <p>Carregando reguladores...</p>
        </div>
      }

      <!-- Error -->
      @if (error && !loading) {
        <div class="error-message">
          <app-icon name="alert-circle" [size]="24" />
          <p>{{ error }}</p>
          <button (click)="loadData()">Tentar novamente</button>
        </div>
      }

      <!-- Lista de Reguladores -->
      @if (!loading && !error) {
        <div class="regulators-table">
          <table>
            <thead>
              <tr>
                <th>Regulador</th>
                <th>Email</th>
                <th>CPF</th>
                <th>Município Vinculado</th>
                <th>Status</th>
                <th>Ações</th>
              </tr>
            </thead>
            <tbody>
              @for (regulator of regulators; track regulator.id) {
                <tr>
                  <td class="name-cell">
                    <div class="avatar">{{ getInitials(regulator.fullName) }}</div>
                    <div class="name-info">
                      <span class="name">{{ regulator.fullName }}</span>
                      <span class="phone">{{ regulator.phone || 'Sem telefone' }}</span>
                    </div>
                  </td>
                  <td>{{ regulator.email }}</td>
                  <td>{{ formatCpf(regulator.cpf) }}</td>
                  <td>
                    @if (regulator.municipio) {
                      <span class="municipio-badge">
                        <app-icon name="check-circle" [size]="14" />
                        {{ regulator.municipio.nome }} - {{ regulator.municipio.uf }}
                      </span>
                    } @else {
                      <span class="no-municipio">
                        <app-icon name="alert-circle" [size]="14" />
                        Não vinculado
                      </span>
                    }
                  </td>
                  <td>
                    <span class="status-badge" [class]="regulator.status.toLowerCase()">
                      {{ regulator.status === 'Active' ? 'Ativo' : 'Inativo' }}
                    </span>
                  </td>
                  <td class="actions-cell">
                    <button class="btn-icon" title="Vincular Município" (click)="openVinculateModal(regulator)">
                      <app-icon name="globe" [size]="18" />
                    </button>
                    <button class="btn-icon" title="Editar" (click)="editRegulator(regulator)">
                      <app-icon name="edit" [size]="18" />
                    </button>
                  </td>
                </tr>
              }
              @if (regulators.length === 0) {
                <tr>
                  <td colspan="6" class="empty-row">
                    <app-icon name="users" [size]="48" />
                    <p>Nenhum regulador cadastrado</p>
                    <button class="btn-primary small" (click)="openCreateModal()">
                      Cadastrar primeiro regulador
                    </button>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }
    </div>

    <!-- Modal de Vinculação -->
    @if (showVinculateModal && selectedRegulator) {
      <div class="modal-overlay" (click)="closeVinculateModal()">
        <div class="modal-content" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>Vincular Município</h2>
            <button class="close-btn" (click)="closeVinculateModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <p class="modal-description">
              Vincular <strong>{{ selectedRegulator.fullName }}</strong> a um município:
            </p>
            
            <div class="form-group">
              <label>Município</label>
              <select [(ngModel)]="selectedMunicipioId">
                <option [value]="null">-- Remover vínculo --</option>
                @for (mun of municipalities; track mun.id) {
                  <option 
                    [value]="mun.id" 
                    [disabled]="mun.temRegulador && mun.id !== selectedRegulator.municipioId"
                  >
                    {{ mun.nome }} - {{ mun.uf }}
                    @if (mun.temRegulador && mun.id !== selectedRegulator.municipioId) {
                      (já possui regulador)
                    }
                  </option>
                }
              </select>
            </div>

            @if (vinculateError) {
              <div class="form-error">
                <app-icon name="alert-circle" [size]="16" />
                {{ vinculateError }}
              </div>
            }
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closeVinculateModal()">Cancelar</button>
            <button class="btn-primary" (click)="vinculate()" [disabled]="vinculateLoading">
              @if (vinculateLoading) {
                <span class="btn-spinner"></span>
              }
              {{ vinculateLoading ? 'Salvando...' : 'Salvar Vínculo' }}
            </button>
          </div>
        </div>
      </div>
    }

    <!-- Modal de Criação -->
    @if (showCreateModal) {
      <div class="modal-overlay" (click)="closeCreateModal()">
        <div class="modal-content large" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>Novo Regulador</h2>
            <button class="close-btn" (click)="closeCreateModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <div class="form-row">
              <div class="form-group">
                <label>Nome *</label>
                <input type="text" [(ngModel)]="newRegulator.name" placeholder="Nome">
              </div>
              <div class="form-group">
                <label>Sobrenome *</label>
                <input type="text" [(ngModel)]="newRegulator.lastName" placeholder="Sobrenome">
              </div>
            </div>
            
            <div class="form-row">
              <div class="form-group">
                <label>Email *</label>
                <input type="email" [(ngModel)]="newRegulator.email" placeholder="email@exemplo.com">
              </div>
              <div class="form-group">
                <label>CPF *</label>
                <input type="text" [(ngModel)]="newRegulator.cpf" placeholder="000.000.000-00" maxlength="14">
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>Telefone</label>
                <input type="text" [(ngModel)]="newRegulator.phone" placeholder="(00) 00000-0000">
              </div>
              <div class="form-group">
                <label>Senha *</label>
                <input type="password" [(ngModel)]="newRegulator.password" placeholder="Senha inicial">
              </div>
            </div>

            <div class="form-group">
              <label>Município (opcional)</label>
              <select [(ngModel)]="newRegulator.municipioId">
                <option [value]="null">-- Vincular depois --</option>
                @for (mun of municipalities; track mun.id) {
                  <option [value]="mun.id" [disabled]="mun.temRegulador">
                    {{ mun.nome }} - {{ mun.uf }}
                    @if (mun.temRegulador) { (já possui regulador) }
                  </option>
                }
              </select>
            </div>

            @if (createError) {
              <div class="form-error">
                <app-icon name="alert-circle" [size]="16" />
                {{ createError }}
              </div>
            }
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closeCreateModal()">Cancelar</button>
            <button class="btn-primary" (click)="createRegulator()" [disabled]="createLoading">
              @if (createLoading) {
                <span class="btn-spinner"></span>
              }
              {{ createLoading ? 'Criando...' : 'Criar Regulador' }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .page-container {
      padding: 24px;
      max-width: 1400px;
      margin: 0 auto;
    }

    .page-header {
      display: flex;
      align-items: flex-start;
      gap: 24px;
      margin-bottom: 24px;
      flex-wrap: wrap;

      .header-content {
        flex: 1;
      }

      h1 {
        display: flex;
        align-items: center;
        gap: 12px;
        font-size: 28px;
        font-weight: 700;
        color: #0f172a;
        margin: 16px 0 8px;
      }

      .subtitle { color: #64748b; margin: 0; }
    }

    .back-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      border: none;
      background: #f1f5f9;
      border-radius: 8px;
      color: #64748b;
      font-size: 14px;
      cursor: pointer;
      &:hover { background: #e2e8f0; color: #0d9488; }
    }

    .btn-primary {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 20px;
      background: #0d9488;
      border: none;
      border-radius: 8px;
      color: white;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      &:hover { background: #0f766e; }
      &:disabled { opacity: 0.6; cursor: not-allowed; }
      &.small { padding: 8px 16px; font-size: 13px; }
    }

    .btn-secondary {
      padding: 10px 20px;
      border: 1px solid #e2e8f0;
      background: white;
      border-radius: 8px;
      cursor: pointer;
      font-size: 14px;
      &:hover { background: #f1f5f9; }
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 20px;
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);

      app-icon {
        padding: 12px;
        border-radius: 12px;
        background: #f1f5f9;
        color: #64748b;
      }

      &.success app-icon { background: #dcfce7; color: #16a34a; }
      &.warning app-icon { background: #fef3c7; color: #d97706; }
      &.info app-icon { background: #dbeafe; color: #2563eb; }

      .stat-info {
        display: flex;
        flex-direction: column;
        .stat-value { font-size: 28px; font-weight: 700; color: #0f172a; }
        .stat-label { font-size: 13px; color: #64748b; }
      }
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 60px;
      
      .spinner {
        width: 48px;
        height: 48px;
        border: 4px solid #e2e8f0;
        border-top-color: #0d9488;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }
      p { margin-top: 16px; color: #64748b; }
    }

    @keyframes spin { to { transform: rotate(360deg); } }

    .error-message {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 40px;
      background: #fef2f2;
      border-radius: 12px;
      color: #dc2626;
      
      button {
        margin-top: 16px;
        padding: 8px 16px;
        background: #dc2626;
        color: white;
        border: none;
        border-radius: 8px;
        cursor: pointer;
      }
    }

    .regulators-table {
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
      overflow: hidden;

      table {
        width: 100%;
        border-collapse: collapse;
      }

      th {
        text-align: left;
        padding: 16px;
        background: #f8fafc;
        font-size: 12px;
        font-weight: 600;
        color: #64748b;
        text-transform: uppercase;
        border-bottom: 1px solid #e2e8f0;
      }

      td {
        padding: 16px;
        border-bottom: 1px solid #f1f5f9;
        font-size: 14px;
        color: #0f172a;
      }

      tr:last-child td { border-bottom: none; }
      tr:hover { background: #f8fafc; }

      .name-cell {
        display: flex;
        align-items: center;
        gap: 12px;

        .avatar {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: linear-gradient(135deg, #0d9488, #0f766e);
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 600;
          font-size: 14px;
        }

        .name-info {
          display: flex;
          flex-direction: column;
          .name { font-weight: 500; }
          .phone { font-size: 12px; color: #64748b; }
        }
      }

      .municipio-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 4px 10px;
        background: #dcfce7;
        color: #16a34a;
        border-radius: 12px;
        font-size: 13px;
      }

      .no-municipio {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 4px 10px;
        background: #fef3c7;
        color: #d97706;
        border-radius: 12px;
        font-size: 13px;
      }

      .status-badge {
        display: inline-block;
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 12px;
        font-weight: 500;
        &.active { background: #dcfce7; color: #16a34a; }
        &.inactive { background: #fee2e2; color: #dc2626; }
      }

      .actions-cell {
        display: flex;
        gap: 8px;
      }

      .btn-icon {
        padding: 8px;
        border: none;
        background: #f1f5f9;
        border-radius: 8px;
        cursor: pointer;
        color: #64748b;
        &:hover { background: #e2e8f0; color: #0d9488; }
      }

      .empty-row {
        text-align: center;
        padding: 60px !important;
        app-icon { color: #94a3b8; margin-bottom: 16px; }
        p { color: #64748b; margin: 0 0 16px; }
      }
    }

    /* Modal */
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      padding: 20px;
    }

    .modal-content {
      background: white;
      border-radius: 16px;
      width: 100%;
      max-width: 450px;
      max-height: 90vh;
      overflow-y: auto;

      &.large { max-width: 600px; }
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
      border-bottom: 1px solid #e2e8f0;
      
      h2 { margin: 0; font-size: 20px; color: #0f172a; }
      
      .close-btn {
        background: none;
        border: none;
        cursor: pointer;
        color: #64748b;
        &:hover { color: #0f172a; }
      }
    }

    .modal-body {
      padding: 20px;

      .modal-description {
        margin: 0 0 20px;
        color: #64748b;
      }

      .form-group {
        margin-bottom: 16px;

        label {
          display: block;
          margin-bottom: 6px;
          font-size: 14px;
          font-weight: 500;
          color: #374151;
        }

        input, select {
          width: 100%;
          padding: 10px 14px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          font-size: 14px;
          &:focus { outline: none; border-color: #0d9488; }
        }
      }

      .form-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 16px;
      }

      .form-error {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 12px;
        background: #fef2f2;
        border-radius: 8px;
        color: #dc2626;
        font-size: 14px;
        margin-top: 16px;
      }
    }

    .modal-footer {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding: 16px 20px;
      border-top: 1px solid #e2e8f0;
    }

    .btn-spinner {
      width: 16px;
      height: 16px;
      border: 2px solid rgba(255,255,255,0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    /* Dark mode */
    :host-context([data-theme="dark"]) {
      .page-header h1 { color: #f1f5f9; }
      .back-btn { background: #334155; color: #94a3b8; }
      .stat-card { background: #1e293b; }
      .stat-card .stat-info .stat-value { color: #f1f5f9; }
      .regulators-table {
        background: #1e293b;
        th { background: #334155; color: #94a3b8; border-color: #475569; }
        td { border-color: #334155; color: #f1f5f9; }
        tr:hover { background: #334155; }
        .name-cell .name-info .phone { color: #94a3b8; }
        .btn-icon { background: #334155; color: #94a3b8; }
      }
      .modal-content { background: #1e293b; }
      .modal-header { border-color: #334155; }
      .modal-header h2 { color: #f1f5f9; }
      .modal-body {
        .form-group label { color: #94a3b8; }
        input, select { background: #334155; border-color: #475569; color: #f1f5f9; }
      }
      .modal-footer { border-color: #334155; }
      .btn-secondary { background: #334155; border-color: #475569; color: #f1f5f9; }
    }

    @media (max-width: 768px) {
      .page-header { flex-direction: column; }
      .stats-grid { grid-template-columns: 1fr 1fr; }
      .regulators-table { overflow-x: auto; }
      .modal-body .form-row { grid-template-columns: 1fr; }
    }
  `]
})
export class AdminRegulatorsComponent implements OnInit {
  regulators: Regulator[] = [];
  municipalities: Municipality[] = [];
  
  loading = true;
  error: string | null = null;
  
  // Modal de vinculação
  showVinculateModal = false;
  selectedRegulator: Regulator | null = null;
  selectedMunicipioId: string | null = null;
  vinculateLoading = false;
  vinculateError: string | null = null;
  
  // Modal de criação
  showCreateModal = false;
  createLoading = false;
  createError: string | null = null;
  newRegulator = {
    name: '',
    lastName: '',
    email: '',
    cpf: '',
    phone: '',
    password: '',
    municipioId: null as string | null
  };

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.loading = true;
    this.error = null;

    // Carregar reguladores e municípios em paralelo
    Promise.all([
      this.http.get<Regulator[]>(`${environment.apiUrl}/admin/regulators`).toPromise(),
      this.http.get<Municipality[]>(`${environment.apiUrl}/admin/municipalities/available`).toPromise()
    ]).then(([regulators, municipalities]) => {
      this.regulators = regulators || [];
      this.municipalities = municipalities || [];
      this.loading = false;
    }).catch(err => {
      console.error('Erro ao carregar dados:', err);
      this.error = 'Não foi possível carregar os dados. Tente novamente.';
      this.loading = false;
    });
  }

  get regulatorsVinculados(): number {
    return this.regulators.filter(r => r.municipio !== null).length;
  }

  get regulatorsSemVinculo(): number {
    return this.regulators.filter(r => r.municipio === null).length;
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .filter(n => n.length > 0)
      .slice(0, 2)
      .map(n => n[0].toUpperCase())
      .join('');
  }

  formatCpf(cpf: string): string {
    if (!cpf) return '-';
    return cpf.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
  }

  // Modal de Vinculação
  openVinculateModal(regulator: Regulator) {
    this.selectedRegulator = regulator;
    this.selectedMunicipioId = regulator.municipioId;
    this.vinculateError = null;
    this.showVinculateModal = true;
  }

  closeVinculateModal() {
    this.showVinculateModal = false;
    this.selectedRegulator = null;
    this.selectedMunicipioId = null;
    this.vinculateError = null;
  }

  vinculate() {
    if (!this.selectedRegulator) return;

    this.vinculateLoading = true;
    this.vinculateError = null;

    const body = { 
      municipioId: this.selectedMunicipioId === 'null' ? null : this.selectedMunicipioId 
    };

    this.http.post<any>(
      `${environment.apiUrl}/admin/regulators/${this.selectedRegulator.id}/vinculate`,
      body
    ).subscribe({
      next: () => {
        this.vinculateLoading = false;
        this.closeVinculateModal();
        this.loadData(); // Recarregar dados
      },
      error: (err) => {
        this.vinculateLoading = false;
        this.vinculateError = err.error?.message || 'Erro ao vincular regulador';
      }
    });
  }

  // Modal de Criação
  openCreateModal() {
    this.newRegulator = {
      name: '',
      lastName: '',
      email: '',
      cpf: '',
      phone: '',
      password: '',
      municipioId: null
    };
    this.createError = null;
    this.showCreateModal = true;
  }

  closeCreateModal() {
    this.showCreateModal = false;
    this.createError = null;
  }

  createRegulator() {
    // Validação básica
    if (!this.newRegulator.name || !this.newRegulator.lastName || 
        !this.newRegulator.email || !this.newRegulator.cpf || !this.newRegulator.password) {
      this.createError = 'Preencha todos os campos obrigatórios';
      return;
    }

    this.createLoading = true;
    this.createError = null;

    const body = {
      ...this.newRegulator,
      municipioId: this.newRegulator.municipioId === 'null' ? null : this.newRegulator.municipioId
    };

    this.http.post<any>(`${environment.apiUrl}/admin/regulators`, body).subscribe({
      next: () => {
        this.createLoading = false;
        this.closeCreateModal();
        this.loadData();
      },
      error: (err) => {
        this.createLoading = false;
        this.createError = err.error?.message || 'Erro ao criar regulador';
      }
    });
  }

  editRegulator(regulator: Regulator) {
    // TODO: Implementar edição completa
    alert(`Edição do regulador ${regulator.fullName} em desenvolvimento`);
  }
}
