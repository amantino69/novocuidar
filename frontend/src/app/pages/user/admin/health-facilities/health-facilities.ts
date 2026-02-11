import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { environment } from '@env/environment';

interface HealthFacility {
  id: string;
  codigoCNES: string;
  nomeFantasia: string;
  razaoSocial: string | null;
  tipoEstabelecimento: string | null;
  tipoEstabelecimentoDescricao: string | null;
  cnpj: string | null;
  cep: string | null;
  logradouro: string | null;
  numero: string | null;
  complemento: string | null;
  bairro: string | null;
  telefone: string | null;
  email: string | null;
  latitude: number | null;
  longitude: number | null;
  temConsultorioDigital: boolean;
  ativo: boolean;
  ultimaSincronizacaoCNES: string | null;
  municipioId: string;
  municipioNome: string;
  municipioUF: string;
  totalPacientesAdscritos: number;
}

interface Municipality {
  id: string;
  nome: string;
  uf: string;
}

const TIPOS_ESTABELECIMENTO = [
  { codigo: '01', descricao: 'Posto de Saúde' },
  { codigo: '02', descricao: 'Centro de Saúde/Unidade Básica' },
  { codigo: '04', descricao: 'Policlínica' },
  { codigo: '05', descricao: 'Hospital Geral' },
  { codigo: '07', descricao: 'Hospital Especializado' },
  { codigo: '15', descricao: 'Unidade Mista' },
  { codigo: '20', descricao: 'Pronto Socorro Geral' },
  { codigo: '21', descricao: 'Pronto Socorro Especializado' },
  { codigo: '22', descricao: 'Consultório Isolado' },
  { codigo: '32', descricao: 'Unidade Móvel Fluvial' },
  { codigo: '36', descricao: 'Clínica/Centro de Especialidade' },
  { codigo: '39', descricao: 'Unidade de Apoio Diagnose e Terapia (SADT)' },
  { codigo: '40', descricao: 'Unidade Móvel Terrestre' },
  { codigo: '42', descricao: 'Unidade Móvel de Nível Pré-Hospitalar' },
  { codigo: '43', descricao: 'Farmácia' },
  { codigo: '50', descricao: 'Unidade de Vigilância em Saúde' },
  { codigo: '60', descricao: 'Cooperativa' },
  { codigo: '61', descricao: 'Centro de Parto Normal' },
  { codigo: '62', descricao: 'Hospital/Dia - Isolado' },
  { codigo: '64', descricao: 'Central de Regulação de Serviços de Saúde' },
  { codigo: '67', descricao: 'Laboratório Central de Saúde Pública' },
  { codigo: '68', descricao: 'Central de Gestão em Saúde' },
  { codigo: '69', descricao: 'Centro de Atenção Hemoterapia/Hematológica' },
  { codigo: '70', descricao: 'Centro de Atenção Psicossocial' },
  { codigo: '71', descricao: 'Centro de Apoio à Saúde da Família' },
  { codigo: '72', descricao: 'Unidade de Atenção à Saúde Indígena' },
  { codigo: '73', descricao: 'Pronto Atendimento' },
  { codigo: '74', descricao: 'Polo Academia da Saúde' },
  { codigo: '75', descricao: 'Telessaúde' },
  { codigo: '76', descricao: 'Central de Regulação Médica das Urgências' },
  { codigo: '77', descricao: 'Serviço de Atenção Domiciliar Isolado' },
  { codigo: '79', descricao: 'Oficina Ortopédica' },
  { codigo: '80', descricao: 'Laboratório de Saúde Pública' },
  { codigo: '81', descricao: 'Central de Regulação do Acesso' },
  { codigo: '82', descricao: 'Central de Notificação' },
  { codigo: '83', descricao: 'Polo de Prevenção de Doenças e Agravos' }
];

@Component({
  selector: 'app-health-facilities',
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
            <app-icon name="building" [size]="28" />
            Estabelecimentos de Saúde
          </h1>
          <p class="subtitle">Gerencie os estabelecimentos do CNES vinculados ao município</p>
        </div>
        <button class="btn-primary" (click)="openCreateModal()">
          <app-icon name="plus" [size]="18" />
          Novo Estabelecimento
        </button>
      </header>

      <!-- Filtros -->
      <div class="filters-bar">
        <div class="search-box">
          <app-icon name="search" [size]="18" />
          <input 
            type="text" 
            placeholder="Buscar por nome ou CNES..." 
            [(ngModel)]="searchTerm"
            (input)="onSearchChange()"
          >
        </div>
        <select [(ngModel)]="tipoFiltro" (change)="loadFacilities()">
          <option value="">Todos os tipos</option>
          @for (tipo of tiposEstabelecimento; track tipo.codigo) {
            <option [value]="tipo.codigo">{{ tipo.descricao }}</option>
          }
        </select>
        <select [(ngModel)]="ativoFiltro" (change)="loadFacilities()">
          <option value="">Todos os status</option>
          <option value="true">Ativos</option>
          <option value="false">Inativos</option>
        </select>
        <select [(ngModel)]="consultorioFiltro" (change)="loadFacilities()">
          <option value="">Consultório Digital</option>
          <option value="true">Com consultório</option>
          <option value="false">Sem consultório</option>
        </select>
      </div>

      <!-- Stats Cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <app-icon name="building" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ totalFacilities }}</span>
            <span class="stat-label">Total</span>
          </div>
        </div>
        <div class="stat-card success">
          <app-icon name="check-circle" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ facilitiesAtivas }}</span>
            <span class="stat-label">Ativos</span>
          </div>
        </div>
        <div class="stat-card info">
          <app-icon name="monitor" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ facilitiesComConsultorio }}</span>
            <span class="stat-label">Com Consultório Digital</span>
          </div>
        </div>
        <div class="stat-card warning">
          <app-icon name="users" [size]="24" />
          <div class="stat-info">
            <span class="stat-value">{{ totalPacientesAdscritos }}</span>
            <span class="stat-label">Pacientes Adscritos</span>
          </div>
        </div>
      </div>

      <!-- Loading -->
      @if (loading) {
        <div class="loading-container">
          <div class="spinner"></div>
          <p>Carregando estabelecimentos...</p>
        </div>
      }

      <!-- Lista de Estabelecimentos -->
      @if (!loading) {
        <div class="facilities-grid">
          @for (facility of facilities; track facility.id) {
            <div class="facility-card" [class.inactive]="!facility.ativo">
              <div class="facility-header">
                <div class="facility-type-badge" [attr.data-tipo]="facility.tipoEstabelecimento">
                  {{ facility.tipoEstabelecimentoDescricao || 'Não classificado' }}
                </div>
                @if (facility.temConsultorioDigital) {
                  <div class="consultorio-badge">
                    <app-icon name="monitor" [size]="14" />
                    Consultório Digital
                  </div>
                }
              </div>
              
              <h3 class="facility-name">{{ facility.nomeFantasia }}</h3>
              <p class="facility-cnes">CNES: {{ facility.codigoCNES }}</p>
              
              @if (facility.logradouro) {
                <p class="facility-address">
                  <app-icon name="map-pin" [size]="14" />
                  {{ facility.logradouro }}{{ facility.numero ? ', ' + facility.numero : '' }}
                  {{ facility.bairro ? ' - ' + facility.bairro : '' }}
                </p>
              }

              <div class="facility-stats">
                <span class="stat">
                  <app-icon name="users" [size]="14" />
                  {{ facility.totalPacientesAdscritos }} pacientes
                </span>
                @if (facility.telefone) {
                  <span class="stat">
                    <app-icon name="phone" [size]="14" />
                    {{ facility.telefone }}
                  </span>
                }
              </div>

              <div class="facility-actions">
                <button class="btn-icon" title="Editar" (click)="openEditModal(facility)">
                  <app-icon name="edit" [size]="18" />
                </button>
                <button 
                  class="btn-icon" 
                  [title]="facility.temConsultorioDigital ? 'Remover consultório' : 'Ativar consultório'"
                  (click)="toggleConsultorioDigital(facility)"
                >
                  <app-icon [name]="facility.temConsultorioDigital ? 'monitor-off' : 'monitor'" [size]="18" />
                </button>
                <button 
                  class="btn-icon"
                  [class.danger]="facility.ativo"
                  [title]="facility.ativo ? 'Desativar' : 'Ativar'"
                  (click)="toggleAtivo(facility)"
                >
                  <app-icon [name]="facility.ativo ? 'x-circle' : 'check-circle'" [size]="18" />
                </button>
              </div>
            </div>
          }
          
          @if (facilities.length === 0 && !loading) {
            <div class="empty-state">
              <app-icon name="building" [size]="64" />
              <h3>Nenhum estabelecimento encontrado</h3>
              <p>Cadastre o primeiro estabelecimento ou ajuste os filtros</p>
              <button class="btn-primary" (click)="openCreateModal()">
                <app-icon name="plus" [size]="18" />
                Cadastrar Estabelecimento
              </button>
            </div>
          }
        </div>

        <!-- Paginação -->
        @if (totalPages > 1) {
          <div class="pagination">
            <button [disabled]="currentPage === 1" (click)="goToPage(currentPage - 1)">
              <app-icon name="chevron-left" [size]="18" />
            </button>
            <span>Página {{ currentPage }} de {{ totalPages }}</span>
            <button [disabled]="currentPage === totalPages" (click)="goToPage(currentPage + 1)">
              <app-icon name="chevron-right" [size]="18" />
            </button>
          </div>
        }
      }
    </div>

    <!-- Modal Criar/Editar -->
    @if (showModal) {
      <div class="modal-overlay" (click)="closeModal()">
        <div class="modal-content large" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>{{ editingFacility ? 'Editar' : 'Novo' }} Estabelecimento</h2>
            <button class="close-btn" (click)="closeModal()">
              <app-icon name="x" [size]="24" />
            </button>
          </div>
          <div class="modal-body">
            <div class="form-section">
              <h3>Identificação</h3>
              <div class="form-row">
                <div class="form-group">
                  <label>Código CNES *</label>
                  <input type="text" [(ngModel)]="facilityForm.codigoCNES" placeholder="0000000" maxlength="7" [disabled]="!!editingFacility">
                </div>
                <div class="form-group">
                  <label>CNPJ</label>
                  <input type="text" [(ngModel)]="facilityForm.cnpj" placeholder="00.000.000/0000-00">
                </div>
              </div>
              <div class="form-group">
                <label>Nome Fantasia *</label>
                <input type="text" [(ngModel)]="facilityForm.nomeFantasia" placeholder="Nome do estabelecimento">
              </div>
              <div class="form-group">
                <label>Razão Social</label>
                <input type="text" [(ngModel)]="facilityForm.razaoSocial" placeholder="Razão social">
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Tipo de Estabelecimento</label>
                  <select [(ngModel)]="facilityForm.tipoEstabelecimento" (change)="onTipoChange()">
                    <option value="">Selecione</option>
                    @for (tipo of tiposEstabelecimento; track tipo.codigo) {
                      <option [value]="tipo.codigo">{{ tipo.descricao }}</option>
                    }
                  </select>
                </div>
                <div class="form-group">
                  <label>Município *</label>
                  <select [(ngModel)]="facilityForm.municipioId">
                    @for (m of municipalities; track m.id) {
                      <option [value]="m.id">{{ m.nome }} - {{ m.uf }}</option>
                    }
                  </select>
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>Endereço</h3>
              <div class="form-row">
                <div class="form-group small">
                  <label>CEP</label>
                  <input type="text" [(ngModel)]="facilityForm.cep" placeholder="00000-000" maxlength="9">
                </div>
                <div class="form-group">
                  <label>Logradouro</label>
                  <input type="text" [(ngModel)]="facilityForm.logradouro" placeholder="Rua, Avenida...">
                </div>
                <div class="form-group small">
                  <label>Número</label>
                  <input type="text" [(ngModel)]="facilityForm.numero" placeholder="S/N">
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Complemento</label>
                  <input type="text" [(ngModel)]="facilityForm.complemento" placeholder="Sala, Andar...">
                </div>
                <div class="form-group">
                  <label>Bairro</label>
                  <input type="text" [(ngModel)]="facilityForm.bairro" placeholder="Bairro">
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>Contato</h3>
              <div class="form-row">
                <div class="form-group">
                  <label>Telefone</label>
                  <input type="text" [(ngModel)]="facilityForm.telefone" placeholder="(00) 0000-0000">
                </div>
                <div class="form-group">
                  <label>Email</label>
                  <input type="email" [(ngModel)]="facilityForm.email" placeholder="contato@exemplo.com">
                </div>
              </div>
            </div>

            @if (modalError) {
              <div class="form-error">
                <app-icon name="alert-circle" [size]="16" />
                {{ modalError }}
              </div>
            }
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" (click)="closeModal()">Cancelar</button>
            <button class="btn-primary" (click)="saveFacility()" [disabled]="modalLoading">
              @if (modalLoading) {
                <span class="btn-spinner"></span>
              }
              {{ modalLoading ? 'Salvando...' : (editingFacility ? 'Salvar' : 'Cadastrar') }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .page-container {
      padding: 24px;
      max-width: 1600px;
      margin: 0 auto;
    }

    .page-header {
      display: flex;
      align-items: flex-start;
      gap: 24px;
      margin-bottom: 24px;
      flex-wrap: wrap;

      .header-content { flex: 1; }

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

    .filters-bar {
      display: flex;
      gap: 12px;
      margin-bottom: 24px;
      flex-wrap: wrap;

      .search-box {
        flex: 1;
        min-width: 250px;
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 0 12px;
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        
        input {
          flex: 1;
          padding: 10px 0;
          border: none;
          outline: none;
          font-size: 14px;
        }
        
        app-icon { color: #94a3b8; }
      }

      select {
        padding: 10px 14px;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        font-size: 14px;
        background: white;
        min-width: 180px;
        cursor: pointer;
      }
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
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
      &.info app-icon { background: #dbeafe; color: #2563eb; }
      &.warning app-icon { background: #fef3c7; color: #d97706; }

      .stat-info {
        display: flex;
        flex-direction: column;
        .stat-value { font-size: 24px; font-weight: 700; color: #0f172a; }
        .stat-label { font-size: 12px; color: #64748b; }
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

    .facilities-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 20px;
    }

    .facility-card {
      background: white;
      border-radius: 12px;
      padding: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
      transition: transform 0.2s, box-shadow 0.2s;

      &:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 16px rgba(0,0,0,0.1);
      }

      &.inactive {
        opacity: 0.6;
        border: 2px dashed #e2e8f0;
      }

      .facility-header {
        display: flex;
        gap: 8px;
        margin-bottom: 12px;
        flex-wrap: wrap;
      }

      .facility-type-badge {
        display: inline-block;
        padding: 4px 10px;
        background: #f1f5f9;
        color: #475569;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 500;
      }

      .consultorio-badge {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        padding: 4px 10px;
        background: #dcfce7;
        color: #16a34a;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 500;
      }

      .facility-name {
        font-size: 16px;
        font-weight: 600;
        color: #0f172a;
        margin: 0 0 4px;
      }

      .facility-cnes {
        font-size: 13px;
        color: #64748b;
        margin: 0 0 12px;
        font-family: monospace;
      }

      .facility-address {
        display: flex;
        align-items: flex-start;
        gap: 6px;
        font-size: 13px;
        color: #64748b;
        margin: 0 0 12px;
        line-height: 1.4;
        
        app-icon { flex-shrink: 0; margin-top: 2px; }
      }

      .facility-stats {
        display: flex;
        gap: 16px;
        padding: 12px 0;
        border-top: 1px solid #f1f5f9;
        margin-bottom: 12px;

        .stat {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 12px;
          color: #64748b;
        }
      }

      .facility-actions {
        display: flex;
        gap: 8px;
        justify-content: flex-end;
      }

      .btn-icon {
        padding: 8px;
        border: none;
        background: #f1f5f9;
        border-radius: 8px;
        cursor: pointer;
        color: #64748b;
        &:hover { background: #e2e8f0; color: #0d9488; }
        &.danger:hover { color: #dc2626; }
      }
    }

    .empty-state {
      grid-column: 1 / -1;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 60px;
      background: white;
      border-radius: 12px;
      text-align: center;

      app-icon { color: #94a3b8; margin-bottom: 16px; }
      h3 { margin: 0 0 8px; color: #0f172a; }
      p { margin: 0 0 20px; color: #64748b; }
    }

    .pagination {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 16px;
      margin-top: 24px;
      padding: 16px;

      button {
        padding: 8px 12px;
        border: 1px solid #e2e8f0;
        background: white;
        border-radius: 8px;
        cursor: pointer;
        &:disabled { opacity: 0.5; cursor: not-allowed; }
        &:hover:not(:disabled) { background: #f1f5f9; }
      }

      span { font-size: 14px; color: #64748b; }
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
      max-width: 600px;
      max-height: 90vh;
      overflow-y: auto;

      &.large { max-width: 700px; }
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
      border-bottom: 1px solid #e2e8f0;
      position: sticky;
      top: 0;
      background: white;
      z-index: 1;
      
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

      .form-section {
        margin-bottom: 24px;

        h3 {
          font-size: 14px;
          font-weight: 600;
          color: #64748b;
          margin: 0 0 16px;
          padding-bottom: 8px;
          border-bottom: 1px solid #f1f5f9;
        }
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
          &:disabled { background: #f8fafc; }
        }

        &.small { max-width: 150px; }
      }

      .form-row {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
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
      position: sticky;
      bottom: 0;
      background: white;
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
      .filters-bar {
        .search-box { background: #1e293b; border-color: #334155; input { background: transparent; color: #f1f5f9; } }
        select { background: #1e293b; border-color: #334155; color: #f1f5f9; }
      }
      .stat-card { background: #1e293b; .stat-info .stat-value { color: #f1f5f9; } }
      .facility-card {
        background: #1e293b;
        .facility-name { color: #f1f5f9; }
        .btn-icon { background: #334155; color: #94a3b8; }
      }
      .empty-state { background: #1e293b; h3 { color: #f1f5f9; } }
      .modal-content { background: #1e293b; }
      .modal-header { border-color: #334155; h2 { color: #f1f5f9; } }
      .modal-body {
        .form-section h3 { color: #94a3b8; border-color: #334155; }
        .form-group label { color: #94a3b8; }
        input, select { background: #334155; border-color: #475569; color: #f1f5f9; }
      }
      .modal-footer { border-color: #334155; }
      .btn-secondary { background: #334155; border-color: #475569; color: #f1f5f9; }
    }

    @media (max-width: 768px) {
      .page-header { flex-direction: column; }
      .facilities-grid { grid-template-columns: 1fr; }
    }
  `]
})
export class HealthFacilitiesComponent implements OnInit {
  facilities: HealthFacility[] = [];
  municipalities: Municipality[] = [];
  tiposEstabelecimento = TIPOS_ESTABELECIMENTO;

  loading = true;
  searchTerm = '';
  tipoFiltro = '';
  ativoFiltro = '';
  consultorioFiltro = '';

  currentPage = 1;
  pageSize = 12;
  totalPages = 1;
  totalFacilities = 0;

  // Stats
  facilitiesAtivas = 0;
  facilitiesComConsultorio = 0;
  totalPacientesAdscritos = 0;

  // Modal
  showModal = false;
  editingFacility: HealthFacility | null = null;
  modalLoading = false;
  modalError: string | null = null;
  facilityForm = this.getEmptyForm();

  // Cache estático para evitar chamadas repetidas ao navegar entre telas
  private static facilitiesCache: { data: any, timestamp: number, key: string } | null = null;
  private static municipalitiesCache: { data: Municipality[], timestamp: number } | null = null;
  private static CACHE_TTL = 30000; // 30 segundos

  private searchTimeout: any;

  constructor(
    private http: HttpClient,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit() {
    this.loadMunicipalities();
    this.loadFacilities();
  }

  private isCacheValid(cache: { timestamp: number } | null): boolean {
    return cache !== null && (Date.now() - cache.timestamp) < HealthFacilitiesComponent.CACHE_TTL;
  }

  private getCacheKey(): string {
    return `${this.currentPage}-${this.pageSize}-${this.searchTerm}-${this.tipoFiltro}-${this.ativoFiltro}-${this.consultorioFiltro}`;
  }

  private clearCache() {
    HealthFacilitiesComponent.facilitiesCache = null;
  }

  getEmptyForm() {
    return {
      codigoCNES: '',
      nomeFantasia: '',
      razaoSocial: '',
      tipoEstabelecimento: '',
      tipoEstabelecimentoDescricao: '',
      cnpj: '',
      cep: '',
      logradouro: '',
      numero: '',
      complemento: '',
      bairro: '',
      telefone: '',
      email: '',
      municipioId: ''
    };
  }

  loadMunicipalities() {
    // Usar cache se válido
    if (this.isCacheValid(HealthFacilitiesComponent.municipalitiesCache)) {
      this.municipalities = HealthFacilitiesComponent.municipalitiesCache!.data;
      return;
    }

    this.http.get<Municipality[]>(`${environment.apiUrl}/municipalities`)
      .subscribe({
        next: (data) => {
          this.municipalities = data;
          HealthFacilitiesComponent.municipalitiesCache = { data, timestamp: Date.now() };
        },
        error: (err) => console.error('Erro ao carregar municípios:', err)
      });
  }

  loadFacilities() {
    const cacheKey = this.getCacheKey();

    // Usar cache se válido e mesma chave
    if (this.isCacheValid(HealthFacilitiesComponent.facilitiesCache) &&
      HealthFacilitiesComponent.facilitiesCache!.key === cacheKey) {
      const cached = HealthFacilitiesComponent.facilitiesCache!.data;
      this.facilities = cached.data;
      this.totalFacilities = cached.total;
      this.totalPages = cached.totalPages;
      this.facilitiesAtivas = this.facilities.filter((f: any) => f.ativo).length;
      this.facilitiesComConsultorio = this.facilities.filter((f: any) => f.temConsultorioDigital).length;
      this.totalPacientesAdscritos = this.facilities.reduce((sum: number, f: any) => sum + f.totalPacientesAdscritos, 0);
      this.loading = false;
      return;
    }

    this.loading = true;

    let url = `${environment.apiUrl}/healthfacilities?page=${this.currentPage}&pageSize=${this.pageSize}`;

    if (this.searchTerm) url += `&search=${encodeURIComponent(this.searchTerm)}`;
    if (this.tipoFiltro) url += `&tipoEstabelecimento=${this.tipoFiltro}`;
    if (this.ativoFiltro) url += `&ativo=${this.ativoFiltro}`;
    if (this.consultorioFiltro) url += `&temConsultorioDigital=${this.consultorioFiltro}`;

    this.http.get<any>(url).subscribe({
      next: (response) => {
        this.facilities = response.data;
        this.totalFacilities = response.total;
        this.totalPages = response.totalPages;

        // Salvar no cache
        HealthFacilitiesComponent.facilitiesCache = {
          data: response,
          timestamp: Date.now(),
          key: cacheKey
        };

        // Calcular stats
        this.facilitiesAtivas = this.facilities.filter(f => f.ativo).length;
        this.facilitiesComConsultorio = this.facilities.filter(f => f.temConsultorioDigital).length;
        this.totalPacientesAdscritos = this.facilities.reduce((sum, f) => sum + f.totalPacientesAdscritos, 0);

        this.loading = false;
        this.cdr.detectChanges(); // Força atualização da UI
      },
      error: (err) => {
        console.error('Erro ao carregar estabelecimentos:', err);
        this.loading = false;
      }
    });
  }

  onSearchChange() {
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      this.currentPage = 1;
      this.loadFacilities();
    }, 300);
  }

  goToPage(page: number) {
    this.currentPage = page;
    this.loadFacilities();
  }

  openCreateModal() {
    this.editingFacility = null;
    this.facilityForm = this.getEmptyForm();
    if (this.municipalities.length > 0) {
      this.facilityForm.municipioId = this.municipalities[0].id;
    }
    this.modalError = null;
    this.showModal = true;
  }

  openEditModal(facility: HealthFacility) {
    this.editingFacility = facility;
    this.facilityForm = {
      codigoCNES: facility.codigoCNES,
      nomeFantasia: facility.nomeFantasia,
      razaoSocial: facility.razaoSocial || '',
      tipoEstabelecimento: facility.tipoEstabelecimento || '',
      tipoEstabelecimentoDescricao: facility.tipoEstabelecimentoDescricao || '',
      cnpj: facility.cnpj || '',
      cep: facility.cep || '',
      logradouro: facility.logradouro || '',
      numero: facility.numero || '',
      complemento: facility.complemento || '',
      bairro: facility.bairro || '',
      telefone: facility.telefone || '',
      email: facility.email || '',
      municipioId: facility.municipioId
    };
    this.modalError = null;
    this.showModal = true;
  }

  closeModal() {
    this.showModal = false;
    this.editingFacility = null;
    this.modalError = null;
  }

  onTipoChange() {
    const tipo = this.tiposEstabelecimento.find(t => t.codigo === this.facilityForm.tipoEstabelecimento);
    this.facilityForm.tipoEstabelecimentoDescricao = tipo?.descricao || '';
  }

  saveFacility() {
    if (!this.facilityForm.codigoCNES || !this.facilityForm.nomeFantasia || !this.facilityForm.municipioId) {
      this.modalError = 'Preencha os campos obrigatórios: CNES, Nome e Município';
      return;
    }

    this.modalLoading = true;
    this.modalError = null;

    const body = {
      ...this.facilityForm,
      tipoEstabelecimentoDescricao: this.facilityForm.tipoEstabelecimentoDescricao || null
    };

    const request = this.editingFacility
      ? this.http.put(`${environment.apiUrl}/healthfacilities/${this.editingFacility.id}`, body)
      : this.http.post(`${environment.apiUrl}/healthfacilities`, body);

    request.subscribe({
      next: () => {
        this.modalLoading = false;
        this.closeModal();
        this.clearCache(); // Limpar cache após modificação
        this.loadFacilities();
      },
      error: (err) => {
        this.modalLoading = false;
        this.modalError = err.error?.message || 'Erro ao salvar estabelecimento';
      }
    });
  }

  toggleConsultorioDigital(facility: HealthFacility) {
    this.http.put(`${environment.apiUrl}/healthfacilities/${facility.id}`, {
      temConsultorioDigital: !facility.temConsultorioDigital
    }).subscribe({
      next: () => {
        this.clearCache(); // Limpar cache após modificação
        this.loadFacilities();
      },
      error: (err) => console.error('Erro ao atualizar:', err)
    });
  }

  toggleAtivo(facility: HealthFacility) {
    this.http.put(`${environment.apiUrl}/healthfacilities/${facility.id}`, {
      ativo: !facility.ativo
    }).subscribe({
      next: () => {
        this.clearCache(); // Limpar cache após modificação
        this.loadFacilities();
      },
      error: (err) => console.error('Erro ao atualizar:', err)
    });
  }
}
