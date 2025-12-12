import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { SpecialtyStatus } from '@app/core/services/specialties.service';

@Component({
  selector: 'app-specialty-create-modal',
  imports: [FormsModule, IconComponent, ButtonComponent],
  templateUrl: './specialty-create-modal.html',
  styleUrl: './specialty-create-modal.scss'
})
export class SpecialtyCreateModalComponent {
  @Input() isOpen = false;
  @Output() close = new EventEmitter<void>();
  @Output() create = new EventEmitter<{ name: string; description: string; status: SpecialtyStatus }>();

  specialtyData = {
    name: '',
    description: '',
    status: 'active' as SpecialtyStatus
  };

  onBackdropClick(): void {
    this.onCancel();
  }

  onCancel(): void {
    this.resetModal();
    this.close.emit();
  }

  onCreate(): void {
    if (this.isFormValid()) {
      this.create.emit({ ...this.specialtyData });
      this.resetModal();
    }
  }

  isFormValid(): boolean {
    return !!(
      this.specialtyData.name?.trim() &&
      this.specialtyData.description?.trim()
    );
  }

  private resetModal(): void {
    this.specialtyData = {
      name: '',
      description: '',
      status: 'active'
    };
  }
}
