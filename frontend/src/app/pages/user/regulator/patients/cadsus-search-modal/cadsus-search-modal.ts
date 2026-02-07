import { Component, EventEmitter, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { RegulatorService, CadsusResult } from '@app/core/services/regulator.service';

type SearchType = 'cpf' | 'cns';

@Component({
  selector: 'app-cadsus-search-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  template: `
    <div class="modal-overlay" (click)="onCancel()">
      <div class="modal" (click)="$event.stopPropagation()">
        <div class="modal__header">
          <h2>
            <app-icon name="search" [size]="24" />
            Buscar no CADSUS
          </h2>
          <button class="close-btn" (click)="onCancel()">
            <app-icon name="x" [size]="24" />
          </button>
        </div>

        <div class="modal__content">
          @if (step === 'search') {
            <!-- Step 1: Search -->
            <div class="search-section">
              <div class="info-box">
                <app-icon name="info" [size]="20" />
                <div>
                  <strong>CADSUS - Cadastro Nacional de Usuários do SUS</strong>
                  <p>Busque o cidadão pelo CPF ou pelo número do Cartão Nacional de Saúde (CNS) para importar os dados cadastrais automaticamente.</p>
                </div>
              </div>

              <div class="search-type-toggle">
                <button 
                  [class.active]="searchType === 'cpf'"
                  (click)="searchType = 'cpf'; clearSearch()"
                >
                  <app-icon name="user" [size]="16" />
                  Buscar por CPF
                </button>
                <button 
                  [class.active]="searchType === 'cns'"
                  (click)="searchType = 'cns'; clearSearch()"
                >
                  <app-icon name="heart" [size]="16" />
                  Buscar por CNS
                </button>
              </div>

              <div class="search-input-group">
                @if (searchType === 'cpf') {
                  <label>CPF do Cidadão</label>
                  <input 
                    type="text" 
                    [(ngModel)]="cpfInput"
                    placeholder="000.000.000-00"
                    maxlength="14"
                    (input)="formatCpfInput()"
                    (keydown.enter)="search()"
                    autofocus
                  />
                  <span class="hint">Digite os 11 dígitos do CPF</span>
                } @else {
                  <label>Cartão Nacional de Saúde (CNS)</label>
                  <input 
                    type="text" 
                    [(ngModel)]="cnsInput"
                    placeholder="000 0000 0000 0000"
                    maxlength="18"
                    (input)="formatCnsInput()"
                    (keydown.enter)="search()"
                    autofocus
                  />
                  <span class="hint">Digite os 15 dígitos do CNS</span>
                }
              </div>

              @if (searchError) {
                <div class="error-box">
                  <app-icon name="alert-circle" [size]="16" />
                  {{ searchError }}
                </div>
              }

              <!-- CPFs de teste para demonstração -->
              <div class="test-data-hint">
                <app-icon name="info" [size]="14" />
                <span>
                  <strong>POC:</strong> CPFs de teste disponíveis: 111.222.333-44, 222.333.444-55, 333.444.555-66
                </span>
              </div>
            </div>
          }

          @if (step === 'loading') {
            <!-- Step 2: Loading -->
            <div class="loading-section">
              <div class="spinner-large"></div>
              <h3>Consultando CADSUS...</h3>
              <p>Aguarde enquanto buscamos os dados do cidadão.</p>
            </div>
          }

          @if (step === 'result' && result) {
            <!-- Step 3: Result -->
            <div class="result-section">
              @if (!result.found) {
                <!-- Not found -->
                <div class="not-found-box">
                  <app-icon name="alert-circle" [size]="48" />
                  <h3>Cidadão não encontrado</h3>
                  <p>{{ result.message || 'Não foram encontrados registros no CADSUS para os dados informados.' }}</p>
                  <button class="btn-secondary" (click)="step = 'search'">
                    <app-icon name="search" [size]="16" />
                    Nova busca
                  </button>
                </div>
              } @else if (result.alreadyRegistered) {
                <!-- Already registered locally -->
                <div class="already-registered-box">
                  <app-icon name="check-circle" [size]="48" />
                  <h3>Paciente já cadastrado</h3>
                  <p>Este cidadão já está cadastrado no sistema.</p>
                  <div class="patient-preview">
                    <div class="preview-row">
                      <span class="label">Nome:</span>
                      <span class="value">{{ result.nome }} {{ result.sobrenome }}</span>
                    </div>
                    <div class="preview-row">
                      <span class="label">CPF:</span>
                      <span class="value">{{ formatCpf(result.cpf) }}</span>
                    </div>
                    @if (result.cns) {
                      <div class="preview-row">
                        <span class="label">CNS:</span>
                        <span class="value">{{ result.cns }}</span>
                      </div>
                    }
                  </div>
                  <div class="actions-row">
                    <button class="btn-secondary" (click)="step = 'search'">
                      <app-icon name="search" [size]="16" />
                      Nova busca
                    </button>
                  </div>
                </div>
              } @else {
                <!-- Found - show preview -->
                <div class="found-box">
                  <div class="source-badge" [class.local]="result.source === 'LOCAL'">
                    <app-icon name="check-circle" [size]="16" />
                    {{ result.source === 'LOCAL' ? 'Encontrado no sistema local' : 'Encontrado no CADSUS' }}
                  </div>

                  <h3>{{ result.nome }} {{ result.sobrenome }}</h3>

                  <div class="data-preview">
                    <div class="preview-section">
                      <h4>Identificação</h4>
                      <div class="preview-grid">
                        <div class="preview-item">
                          <span class="label">CPF</span>
                          <span class="value">{{ formatCpf(result.cpf) }}</span>
                        </div>
                        @if (result.cns) {
                          <div class="preview-item">
                            <span class="label">CNS</span>
                            <span class="value">{{ result.cns }}</span>
                          </div>
                        }
                        @if (result.dataNascimento) {
                          <div class="preview-item">
                            <span class="label">Data de Nascimento</span>
                            <span class="value">{{ formatDate(result.dataNascimento) }}</span>
                          </div>
                        }
                        @if (result.sexo) {
                          <div class="preview-item">
                            <span class="label">Sexo</span>
                            <span class="value">{{ result.sexo === 'M' ? 'Masculino' : 'Feminino' }}</span>
                          </div>
                        }
                      </div>
                    </div>

                    @if (result.nomeMae || result.nomePai) {
                      <div class="preview-section">
                        <h4>Filiação</h4>
                        <div class="preview-grid">
                          @if (result.nomeMae) {
                            <div class="preview-item full">
                              <span class="label">Nome da Mãe</span>
                              <span class="value">{{ result.nomeMae }}</span>
                            </div>
                          }
                          @if (result.nomePai) {
                            <div class="preview-item full">
                              <span class="label">Nome do Pai</span>
                              <span class="value">{{ result.nomePai }}</span>
                            </div>
                          }
                        </div>
                      </div>
                    }

                    @if (result.logradouro || result.municipio) {
                      <div class="preview-section">
                        <h4>Endereço</h4>
                        <div class="preview-grid">
                          @if (result.logradouro) {
                            <div class="preview-item full">
                              <span class="label">Logradouro</span>
                              <span class="value">
                                {{ result.logradouro }}@if (result.numero) {, {{ result.numero }}}
                                @if (result.complemento) { - {{ result.complemento }}}
                              </span>
                            </div>
                          }
                          @if (result.bairro) {
                            <div class="preview-item">
                              <span class="label">Bairro</span>
                              <span class="value">{{ result.bairro }}</span>
                            </div>
                          }
                          @if (result.municipio) {
                            <div class="preview-item">
                              <span class="label">Município/UF</span>
                              <span class="value">{{ result.municipio }}@if (result.uf) {/{{ result.uf }}}</span>
                            </div>
                          }
                          @if (result.cep) {
                            <div class="preview-item">
                              <span class="label">CEP</span>
                              <span class="value">{{ formatCep(result.cep) }}</span>
                            </div>
                          }
                        </div>
                      </div>
                    }
                  </div>
                </div>
              }
            </div>
          }
        </div>

        <div class="modal__footer">
          @if (step === 'search') {
            <button class="btn-secondary" (click)="onCancel()">Cancelar</button>
            <button 
              class="btn-primary" 
              [disabled]="!canSearch()"
              (click)="search()"
            >
              <app-icon name="search" [size]="18" />
              Buscar
            </button>
          }

          @if (step === 'result' && result && result.found && !result.alreadyRegistered) {
            <button class="btn-secondary" (click)="step = 'search'">
              <app-icon name="arrow-left" [size]="16" />
              Nova busca
            </button>
            <button class="btn-primary" (click)="useData()">
              <app-icon name="check" [size]="18" />
              Usar estes dados
            </button>
          }
        </div>
      </div>
    </div>
  `,
  styles: [`
    .modal-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1001;
      padding: 24px;
    }

    .modal {
      background: white;
      border-radius: 16px;
      width: 100%;
      max-width: 600px;
      max-height: 90vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .modal__header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 24px;
      border-bottom: 1px solid #e2e8f0;
    }

    .modal__header h2 {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 18px;
      font-weight: 600;
      color: #0f172a;
      margin: 0;
    }

    .close-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      border: none;
      background: #f1f5f9;
      border-radius: 8px;
      color: #64748b;
      cursor: pointer;
      transition: all 0.2s;
    }

    .close-btn:hover {
      background: #e2e8f0;
      color: #0f172a;
    }

    .modal__content {
      flex: 1;
      padding: 24px;
      overflow-y: auto;
    }

    .modal__footer {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding: 16px 24px;
      border-top: 1px solid #e2e8f0;
    }

    /* Info box */
    .info-box {
      display: flex;
      gap: 12px;
      padding: 16px;
      background: #f0f9ff;
      border: 1px solid #bae6fd;
      border-radius: 12px;
      margin-bottom: 24px;
    }

    .info-box app-icon {
      color: #0284c7;
      flex-shrink: 0;
      margin-top: 2px;
    }

    .info-box strong {
      display: block;
      color: #0c4a6e;
      margin-bottom: 4px;
    }

    .info-box p {
      color: #0369a1;
      margin: 0;
      font-size: 14px;
    }

    /* Search type toggle */
    .search-type-toggle {
      display: flex;
      gap: 8px;
      margin-bottom: 20px;
    }

    .search-type-toggle button {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 12px 16px;
      background: #f8fafc;
      border: 2px solid #e2e8f0;
      border-radius: 10px;
      font-size: 14px;
      font-weight: 500;
      color: #64748b;
      cursor: pointer;
      transition: all 0.2s;
    }

    .search-type-toggle button:hover {
      background: #f1f5f9;
      border-color: #cbd5e1;
    }

    .search-type-toggle button.active {
      background: #f0fdfa;
      border-color: #0d9488;
      color: #0d9488;
    }

    /* Search input */
    .search-input-group {
      margin-bottom: 16px;
    }

    .search-input-group label {
      display: block;
      font-size: 14px;
      font-weight: 500;
      color: #374151;
      margin-bottom: 8px;
    }

    .search-input-group input {
      width: 100%;
      padding: 14px 16px;
      font-size: 18px;
      font-family: 'Monaco', 'Menlo', monospace;
      letter-spacing: 1px;
      border: 2px solid #e2e8f0;
      border-radius: 10px;
      outline: none;
      transition: all 0.2s;
    }

    .search-input-group input:focus {
      border-color: #0d9488;
      box-shadow: 0 0 0 3px rgba(13, 148, 136, 0.1);
    }

    .search-input-group .hint {
      display: block;
      font-size: 12px;
      color: #94a3b8;
      margin-top: 6px;
    }

    /* Error box */
    .error-box {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      background: #fef2f2;
      border: 1px solid #fecaca;
      border-radius: 8px;
      color: #dc2626;
      font-size: 14px;
      margin-bottom: 16px;
    }

    /* Test data hint */
    .test-data-hint {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      background: #fffbeb;
      border: 1px solid #fde68a;
      border-radius: 8px;
      font-size: 13px;
      color: #92400e;
    }

    /* Loading */
    .loading-section {
      text-align: center;
      padding: 40px 24px;
    }

    .spinner-large {
      width: 56px;
      height: 56px;
      border: 4px solid #e2e8f0;
      border-top-color: #0d9488;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 24px;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .loading-section h3 {
      font-size: 18px;
      color: #0f172a;
      margin: 0 0 8px;
    }

    .loading-section p {
      color: #64748b;
      margin: 0;
    }

    /* Not found */
    .not-found-box {
      text-align: center;
      padding: 32px;
    }

    .not-found-box app-icon {
      color: #f59e0b;
      margin-bottom: 16px;
    }

    .not-found-box h3 {
      font-size: 18px;
      color: #0f172a;
      margin: 0 0 8px;
    }

    .not-found-box p {
      color: #64748b;
      margin: 0 0 20px;
    }

    /* Already registered */
    .already-registered-box {
      text-align: center;
      padding: 24px;
    }

    .already-registered-box app-icon {
      color: #22c55e;
      margin-bottom: 16px;
    }

    .already-registered-box h3 {
      font-size: 18px;
      color: #0f172a;
      margin: 0 0 8px;
    }

    .already-registered-box p {
      color: #64748b;
      margin: 0 0 20px;
    }

    .patient-preview {
      background: #f8fafc;
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 20px;
      text-align: left;
    }

    .preview-row {
      display: flex;
      gap: 8px;
      padding: 6px 0;
    }

    .preview-row .label {
      font-weight: 500;
      color: #64748b;
      min-width: 60px;
    }

    .preview-row .value {
      color: #0f172a;
    }

    .actions-row {
      display: flex;
      justify-content: center;
      gap: 12px;
    }

    /* Found box */
    .found-box {
      padding: 0;
    }

    .source-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      background: #f0fdf4;
      border: 1px solid #bbf7d0;
      border-radius: 20px;
      font-size: 13px;
      color: #15803d;
      margin-bottom: 16px;
    }

    .source-badge.local {
      background: #f0f9ff;
      border-color: #bae6fd;
      color: #0369a1;
    }

    .found-box h3 {
      font-size: 22px;
      font-weight: 600;
      color: #0f172a;
      margin: 0 0 20px;
    }

    .data-preview {
      background: #f8fafc;
      border-radius: 12px;
      overflow: hidden;
    }

    .preview-section {
      padding: 16px;
      border-bottom: 1px solid #e2e8f0;
    }

    .preview-section:last-child {
      border-bottom: none;
    }

    .preview-section h4 {
      font-size: 12px;
      font-weight: 600;
      color: #64748b;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin: 0 0 12px;
    }

    .preview-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
    }

    .preview-item {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .preview-item.full {
      grid-column: 1 / -1;
    }

    .preview-item .label {
      font-size: 12px;
      color: #94a3b8;
    }

    .preview-item .value {
      font-size: 14px;
      color: #0f172a;
    }

    /* Buttons */
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
      transition: all 0.2s;
    }

    .btn-primary:hover:not(:disabled) {
      background: #0f766e;
    }

    .btn-primary:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .btn-secondary {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 20px;
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      color: #0f172a;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-secondary:hover {
      background: #f8fafc;
      border-color: #cbd5e1;
    }

    /* Dark mode */
    :host-context([data-theme="dark"]) .modal {
      background: #1e293b;
    }

    :host-context([data-theme="dark"]) .modal__header,
    :host-context([data-theme="dark"]) .modal__footer {
      border-color: #334155;
    }

    :host-context([data-theme="dark"]) .modal__header h2,
    :host-context([data-theme="dark"]) .found-box h3 {
      color: #f1f5f9;
    }

    :host-context([data-theme="dark"]) .close-btn {
      background: #334155;
      color: #94a3b8;
    }

    :host-context([data-theme="dark"]) .info-box {
      background: #0c4a6e;
      border-color: #0369a1;
    }

    :host-context([data-theme="dark"]) .info-box strong {
      color: #e0f2fe;
    }

    :host-context([data-theme="dark"]) .info-box p {
      color: #7dd3fc;
    }

    :host-context([data-theme="dark"]) .search-type-toggle button {
      background: #0f172a;
      border-color: #334155;
      color: #94a3b8;
    }

    :host-context([data-theme="dark"]) .search-type-toggle button.active {
      background: #134e4a;
      border-color: #0d9488;
      color: #5eead4;
    }

    :host-context([data-theme="dark"]) .search-input-group label {
      color: #e2e8f0;
    }

    :host-context([data-theme="dark"]) .search-input-group input {
      background: #0f172a;
      border-color: #334155;
      color: #f1f5f9;
    }

    :host-context([data-theme="dark"]) .data-preview,
    :host-context([data-theme="dark"]) .patient-preview {
      background: #0f172a;
    }

    :host-context([data-theme="dark"]) .preview-section {
      border-color: #334155;
    }

    :host-context([data-theme="dark"]) .preview-item .value,
    :host-context([data-theme="dark"]) .preview-row .value {
      color: #f1f5f9;
    }

    :host-context([data-theme="dark"]) .btn-secondary {
      background: #334155;
      border-color: #475569;
      color: #f1f5f9;
    }
  `]
})
export class CadsusSearchModalComponent {
  private regulatorService = inject(RegulatorService);

  @Output() selected = new EventEmitter<CadsusResult>();
  @Output() cancel = new EventEmitter<void>();

  step: 'search' | 'loading' | 'result' = 'search';
  searchType: SearchType = 'cpf';
  cpfInput = '';
  cnsInput = '';
  searchError: string | null = null;
  result: CadsusResult | null = null;

  clearSearch() {
    this.cpfInput = '';
    this.cnsInput = '';
    this.searchError = null;
  }

  formatCpfInput() {
    let value = this.cpfInput.replace(/\D/g, '');
    if (value.length > 11) value = value.slice(0, 11);
    
    if (value.length > 9) {
      this.cpfInput = `${value.slice(0, 3)}.${value.slice(3, 6)}.${value.slice(6, 9)}-${value.slice(9)}`;
    } else if (value.length > 6) {
      this.cpfInput = `${value.slice(0, 3)}.${value.slice(3, 6)}.${value.slice(6)}`;
    } else if (value.length > 3) {
      this.cpfInput = `${value.slice(0, 3)}.${value.slice(3)}`;
    } else {
      this.cpfInput = value;
    }
  }

  formatCnsInput() {
    let value = this.cnsInput.replace(/\D/g, '');
    if (value.length > 15) value = value.slice(0, 15);
    
    if (value.length > 11) {
      this.cnsInput = `${value.slice(0, 3)} ${value.slice(3, 7)} ${value.slice(7, 11)} ${value.slice(11)}`;
    } else if (value.length > 7) {
      this.cnsInput = `${value.slice(0, 3)} ${value.slice(3, 7)} ${value.slice(7)}`;
    } else if (value.length > 3) {
      this.cnsInput = `${value.slice(0, 3)} ${value.slice(3)}`;
    } else {
      this.cnsInput = value;
    }
  }

  canSearch(): boolean {
    if (this.searchType === 'cpf') {
      const cpfDigits = this.cpfInput.replace(/\D/g, '');
      return cpfDigits.length === 11;
    } else {
      const cnsDigits = this.cnsInput.replace(/\D/g, '');
      return cnsDigits.length === 15;
    }
  }

  search() {
    if (!this.canSearch()) return;

    this.searchError = null;
    this.step = 'loading';

    const params = this.searchType === 'cpf' 
      ? { cpf: this.cpfInput.replace(/\D/g, '') }
      : { cns: this.cnsInput.replace(/\D/g, '') };

    this.regulatorService.searchCadsus(params).subscribe({
      next: (result) => {
        this.result = result;
        this.step = 'result';
      },
      error: (err) => {
        this.searchError = err.error?.message || 'Erro ao consultar o CADSUS';
        this.step = 'search';
      }
    });
  }

  useData() {
    if (this.result) {
      this.selected.emit(this.result);
    }
  }

  formatCpf(cpf?: string): string {
    if (!cpf) return '';
    const digits = cpf.replace(/\D/g, '');
    if (digits.length !== 11) return cpf;
    return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6, 9)}-${digits.slice(9)}`;
  }

  formatCep(cep?: string): string {
    if (!cep) return '';
    const digits = cep.replace(/\D/g, '');
    if (digits.length !== 8) return cep;
    return `${digits.slice(0, 5)}-${digits.slice(5)}`;
  }

  formatDate(dateStr?: string): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR');
  }

  onCancel() {
    this.cancel.emit();
  }
}
