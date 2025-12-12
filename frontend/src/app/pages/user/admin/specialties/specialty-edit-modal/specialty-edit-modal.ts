import { Component, EventEmitter, Input, Output, OnChanges, SimpleChanges } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { Specialty, SpecialtyStatus } from '@app/core/services/specialties.service';

@Component({
  selector: 'app-specialty-edit-modal',
  imports: [FormsModule, IconComponent, ButtonComponent],
  templateUrl: './specialty-edit-modal.html',
  styleUrl: './specialty-edit-modal.scss'
})
export class SpecialtyEditModalComponent implements OnChanges {
  @Input() isOpen = false;
  @Input() specialty: Specialty | null = null;
  @Output() close = new EventEmitter<void>();
  @Output() update = new EventEmitter<Partial<Specialty>>();

  specialtyData = {
    name: '',
    description: '',
    status: 'active' as SpecialtyStatus
  };

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['specialty'] && this.specialty) {
      this.specialtyData = {
        name: this.specialty.name,
        description: this.specialty.description,
        status: this.specialty.status
      };
    }
  }

  onBackdropClick(): void {
    this.onCancel();
  }

  onCancel(): void {
    this.close.emit();
  }

  onUpdate(): void {
    if (this.isFormValid()) {
      this.update.emit({ ...this.specialtyData });
    }
  }

  isFormValid(): boolean {
    return !!(
      this.specialtyData.name?.trim() &&
      this.specialtyData.description?.trim()
    );
  }
}
