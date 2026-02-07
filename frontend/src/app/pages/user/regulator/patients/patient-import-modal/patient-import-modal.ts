import { Component, EventEmitter, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { RegulatorService, ImportCsvResult } from '@app/core/services/regulator.service';

@Component({
  selector: 'app-patient-import-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  template: `
    <div class="modal-overlay" (click)="onCancel()">
      <div class="modal" (click)="$event.stopPropagation()">
        <div class="modal__header">
          <h2>
            <app-icon name="upload-cloud" [size]="24" />
            Importar Pacientes (CSV)
          </h2>
          <button class="close-btn" (click)="onCancel()">
            <app-icon name="x" [size]="24" />
          </button>
        </div>

        <div class="modal__content">
          @if (step === 'upload') {
            <!-- Step 1: Upload -->
            <div class="upload-section">
              <div class="info-box">
                <app-icon name="info" [size]="20" />
                <div>
                  <strong>Formato esperado:</strong>
                  <p>O arquivo CSV deve conter as colunas: CPF, CNS, NOME, SOBRENOME, DATA_NASCIMENTO, SEXO, NOME_MAE, TELEFONE, etc.</p>
                  <button class="link-btn" (click)="downloadTemplate()">
                    <app-icon name="download" [size]="16" />
                    Baixar modelo de CSV
                  </button>
                </div>
              </div>

              <div 
                class="dropzone"
                [class.active]="isDragging"
                [class.has-file]="selectedFile"
                (dragover)="onDragOver($event)"
                (dragleave)="onDragLeave($event)"
                (drop)="onDrop($event)"
                (click)="fileInput.click()"
              >
                <input 
                  #fileInput
                  type="file" 
                  accept=".csv"
                  (change)="onFileSelected($event)"
                  hidden
                />
                @if (selectedFile) {
                  <app-icon name="file-text" [size]="48" />
                  <p class="file-name">{{ selectedFile.name }}</p>
                  <p class="file-size">{{ formatFileSize(selectedFile.size) }}</p>
                  <button class="remove-btn" (click)="removeFile($event)">
                    <app-icon name="x" [size]="16" /> Remover
                  </button>
                } @else {
                  <app-icon name="upload-cloud" [size]="48" />
                  <p>Arraste o arquivo CSV aqui ou clique para selecionar</p>
                  <span class="hint">Máximo 10MB</span>
                }
              </div>

              @if (fileError) {
                <div class="error-msg">
                  <app-icon name="alert-circle" [size]="16" />
                  {{ fileError }}
                </div>
              }
            </div>
          }

          @if (step === 'processing') {
            <!-- Step 2: Processing -->
            <div class="processing-section">
              <div class="spinner-large"></div>
              <h3>Processando arquivo...</h3>
              <p>Por favor, aguarde enquanto os dados são importados.</p>
            </div>
          }

          @if (step === 'result' && result) {
            <!-- Step 3: Results -->
            <div class="result-section">
              <div class="summary-cards">
                <div class="summary-card success">
                  <app-icon name="check-circle" [size]="32" />
                  <div>
                    <span class="count">{{ result.imported.length }}</span>
                    <span class="label">Importados</span>
                  </div>
                </div>
                <div class="summary-card warning">
                  <app-icon name="alert-triangle" [size]="32" />
                  <div>
                    <span class="count">{{ result.skipped.length }}</span>
                    <span class="label">Ignorados</span>
                  </div>
                </div>
                <div class="summary-card error">
                  <app-icon name="x-circle" [size]="32" />
                  <div>
                    <span class="count">{{ result.errors.length }}</span>
                    <span class="label">Erros</span>
                  </div>
                </div>
              </div>

              <!-- Tabs -->
              <div class="result-tabs">
                <button 
                  class="tab" 
                  [class.active]="activeTab === 'imported'"
                  (click)="activeTab = 'imported'"
                >
                  Importados ({{ result.imported.length }})
                </button>
                <button 
                  class="tab" 
                  [class.active]="activeTab === 'skipped'"
                  (click)="activeTab = 'skipped'"
                >
                  Ignorados ({{ result.skipped.length }})
                </button>
                <button 
                  class="tab" 
                  [class.active]="activeTab === 'errors'"
                  (click)="activeTab = 'errors'"
                >
                  Erros ({{ result.errors.length }})
                </button>
              </div>

              <!-- Tab content -->
              <div class="result-list">
                @if (activeTab === 'imported') {
                  @if (result.imported.length === 0) {
                    <div class="empty-tab">Nenhum paciente importado</div>
                  } @else {
                    @for (item of result.imported; track item.line) {
                      <div class="result-item success">
                        <app-icon name="check" [size]="16" />
                        <span class="line">Linha {{ item.line }}</span>
                        <span class="name">{{ item.name }}</span>
                        @if (item.cpf) {
                          <span class="cpf">CPF: {{ item.cpf }}</span>
                        }
                      </div>
                    }
                  }
                }

                @if (activeTab === 'skipped') {
                  @if (result.skipped.length === 0) {
                    <div class="empty-tab">Nenhum registro ignorado</div>
                  } @else {
                    @for (item of result.skipped; track item.line) {
                      <div class="result-item warning">
                        <app-icon name="x-circle" [size]="16" />
                        <span class="line">Linha {{ item.line }}</span>
                        <span class="reason">{{ item.reason }}</span>
                        @if (item.data) {
                          <span class="data">{{ item.data }}</span>
                        }
                      </div>
                    }
                  }
                }

                @if (activeTab === 'errors') {
                  @if (result.errors.length === 0) {
                    <div class="empty-tab">Nenhum erro encontrado</div>
                  } @else {
                    @for (item of result.errors; track item.line) {
                      <div class="result-item error">
                        <app-icon name="alert-circle" [size]="16" />
                        <span class="line">Linha {{ item.line }}</span>
                        <span class="message">{{ item.message }}</span>
                        @if (item.data) {
                          <span class="data">{{ item.data }}</span>
                        }
                      </div>
                    }
                  }
                }
              </div>
            </div>
          }
        </div>

        <div class="modal__footer">
          @if (step === 'upload') {
            <button class="btn-secondary" (click)="onCancel()">Cancelar</button>
            <button 
              class="btn-primary" 
              [disabled]="!selectedFile || !!fileError"
              (click)="processFile()"
            >
              <app-icon name="upload-cloud" [size]="18" />
              Importar
            </button>
          }

          @if (step === 'result') {
            <button class="btn-secondary" (click)="resetAndUploadNew()">
              <app-icon name="upload-cloud" [size]="18" />
              Importar outro arquivo
            </button>
            <button class="btn-primary" (click)="finishImport()">
              <app-icon name="check" [size]="18" />
              Concluir
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
      z-index: 1000;
      padding: 24px;
    }

    .modal {
      background: white;
      border-radius: 16px;
      width: 100%;
      max-width: 700px;
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
      margin-bottom: 20px;
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
      margin: 0 0 8px;
      font-size: 14px;
    }

    .link-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 0;
      background: none;
      border: none;
      color: #0284c7;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      text-decoration: underline;
    }

    .link-btn:hover {
      color: #0369a1;
    }

    /* Dropzone */
    .dropzone {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 40px 24px;
      border: 2px dashed #cbd5e1;
      border-radius: 12px;
      background: #f8fafc;
      cursor: pointer;
      transition: all 0.2s;
      text-align: center;
    }

    .dropzone:hover,
    .dropzone.active {
      border-color: #0d9488;
      background: #f0fdfa;
    }

    .dropzone.has-file {
      border-style: solid;
      border-color: #0d9488;
      background: #f0fdfa;
    }

    .dropzone app-icon {
      color: #94a3b8;
      margin-bottom: 12px;
    }

    .dropzone.has-file app-icon {
      color: #0d9488;
    }

    .dropzone p {
      color: #64748b;
      margin: 0;
    }

    .dropzone .hint {
      font-size: 13px;
      color: #94a3b8;
      margin-top: 8px;
    }

    .dropzone .file-name {
      font-weight: 600;
      color: #0f172a;
      margin-bottom: 4px;
    }

    .dropzone .file-size {
      font-size: 14px;
      color: #64748b;
    }

    .remove-btn {
      display: flex;
      align-items: center;
      gap: 6px;
      margin-top: 12px;
      padding: 6px 12px;
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 6px;
      color: #dc2626;
      font-size: 13px;
      cursor: pointer;
    }

    .error-msg {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px;
      margin-top: 12px;
      background: #fef2f2;
      border: 1px solid #fecaca;
      border-radius: 8px;
      color: #dc2626;
      font-size: 14px;
    }

    /* Processing */
    .processing-section {
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

    .processing-section h3 {
      font-size: 18px;
      color: #0f172a;
      margin: 0 0 8px;
    }

    .processing-section p {
      color: #64748b;
      margin: 0;
    }

    /* Results */
    .summary-cards {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 16px;
      margin-bottom: 24px;
    }

    .summary-card {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      border-radius: 12px;
      background: #f8fafc;
    }

    .summary-card.success {
      background: #f0fdf4;
    }

    .summary-card.success app-icon {
      color: #22c55e;
    }

    .summary-card.warning {
      background: #fffbeb;
    }

    .summary-card.warning app-icon {
      color: #f59e0b;
    }

    .summary-card.error {
      background: #fef2f2;
    }

    .summary-card.error app-icon {
      color: #ef4444;
    }

    .summary-card .count {
      display: block;
      font-size: 24px;
      font-weight: 700;
      color: #0f172a;
    }

    .summary-card .label {
      font-size: 13px;
      color: #64748b;
    }

    /* Tabs */
    .result-tabs {
      display: flex;
      gap: 4px;
      border-bottom: 1px solid #e2e8f0;
      margin-bottom: 16px;
    }

    .tab {
      padding: 10px 16px;
      background: none;
      border: none;
      font-size: 14px;
      color: #64748b;
      cursor: pointer;
      border-bottom: 2px solid transparent;
      margin-bottom: -1px;
    }

    .tab:hover {
      color: #0d9488;
    }

    .tab.active {
      color: #0d9488;
      border-bottom-color: #0d9488;
      font-weight: 500;
    }

    /* Result list */
    .result-list {
      max-height: 300px;
      overflow-y: auto;
    }

    .empty-tab {
      text-align: center;
      padding: 32px;
      color: #94a3b8;
    }

    .result-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 10px 12px;
      border-radius: 8px;
      margin-bottom: 8px;
      font-size: 14px;
    }

    .result-item.success {
      background: #f0fdf4;
    }

    .result-item.success app-icon {
      color: #22c55e;
    }

    .result-item.warning {
      background: #fffbeb;
    }

    .result-item.warning app-icon {
      color: #f59e0b;
    }

    .result-item.error {
      background: #fef2f2;
    }

    .result-item.error app-icon {
      color: #ef4444;
    }

    .result-item .line {
      font-weight: 500;
      color: #64748b;
      min-width: 70px;
    }

    .result-item .name,
    .result-item .reason,
    .result-item .message {
      flex: 1;
      color: #0f172a;
    }

    .result-item .cpf,
    .result-item .data {
      font-size: 13px;
      color: #64748b;
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

    :host-context([data-theme="dark"]) .modal__header h2 {
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

    :host-context([data-theme="dark"]) .dropzone {
      background: #0f172a;
      border-color: #334155;
    }

    :host-context([data-theme="dark"]) .dropzone:hover {
      background: #134e4a;
      border-color: #0d9488;
    }

    :host-context([data-theme="dark"]) .dropzone p {
      color: #94a3b8;
    }

    :host-context([data-theme="dark"]) .summary-card {
      background: #0f172a;
    }

    :host-context([data-theme="dark"]) .summary-card .count {
      color: #f1f5f9;
    }

    :host-context([data-theme="dark"]) .result-tabs {
      border-color: #334155;
    }

    :host-context([data-theme="dark"]) .result-item {
      background: #0f172a;
    }

    :host-context([data-theme="dark"]) .result-item .name,
    :host-context([data-theme="dark"]) .result-item .reason,
    :host-context([data-theme="dark"]) .result-item .message {
      color: #f1f5f9;
    }

    :host-context([data-theme="dark"]) .btn-secondary {
      background: #334155;
      border-color: #475569;
      color: #f1f5f9;
    }
  `]
})
export class PatientImportModalComponent {
  private regulatorService = inject(RegulatorService);

  @Output() imported = new EventEmitter<number>();
  @Output() cancel = new EventEmitter<void>();

  step: 'upload' | 'processing' | 'result' = 'upload';
  selectedFile: File | null = null;
  fileError: string | null = null;
  isDragging = false;

  result: ImportCsvResult | null = null;
  activeTab: 'imported' | 'skipped' | 'errors' = 'imported';

  downloadTemplate() {
    this.regulatorService.downloadCsvTemplate();
  }

  onDragOver(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;

    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.validateAndSetFile(files[0]);
    }
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.validateAndSetFile(input.files[0]);
    }
  }

  private validateAndSetFile(file: File) {
    this.fileError = null;

    // Validar extensão
    if (!file.name.toLowerCase().endsWith('.csv')) {
      this.fileError = 'Apenas arquivos .csv são aceitos';
      return;
    }

    // Validar tamanho (10MB)
    if (file.size > 10 * 1024 * 1024) {
      this.fileError = 'O arquivo deve ter no máximo 10MB';
      return;
    }

    this.selectedFile = file;
  }

  removeFile(event: Event) {
    event.stopPropagation();
    this.selectedFile = null;
    this.fileError = null;
  }

  formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' bytes';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }

  processFile() {
    if (!this.selectedFile) return;

    this.step = 'processing';

    this.regulatorService.importPatientsFromCsv(this.selectedFile).subscribe({
      next: (result) => {
        this.result = result;
        this.step = 'result';
        // Selecionar tab mais relevante
        if (result.errors.length > 0) {
          this.activeTab = 'errors';
        } else if (result.skipped.length > 0) {
          this.activeTab = 'skipped';
        } else {
          this.activeTab = 'imported';
        }
      },
      error: (err) => {
        this.step = 'upload';
        this.fileError = err.error?.message || 'Erro ao processar arquivo';
      }
    });
  }

  resetAndUploadNew() {
    this.step = 'upload';
    this.selectedFile = null;
    this.fileError = null;
    this.result = null;
    this.activeTab = 'imported';
  }

  finishImport() {
    const importedCount = this.result?.imported.length || 0;
    this.imported.emit(importedCount);
  }

  onCancel() {
    this.cancel.emit();
  }
}
