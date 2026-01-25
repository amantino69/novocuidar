import { Component, EventEmitter, Input, Output, OnChanges, SimpleChanges } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { AvatarUploadComponent } from '@app/shared/components/molecules/avatar-upload/avatar-upload';
import { PhoneMaskDirective } from '@app/core/directives/phone-mask.directive';
import { User, CreateUpdatePatientProfile } from '@app/core/services/users.service';

@Component({
  selector: 'app-profile-edit-modal',
  imports: [FormsModule, IconComponent, ButtonComponent, AvatarUploadComponent, PhoneMaskDirective],
  templateUrl: './profile-edit-modal.html',
  styleUrl: './profile-edit-modal.scss'
})
export class ProfileEditModalComponent implements OnChanges {
  @Input() user: User | null = null;
  @Input() isOpen = false;
  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<Partial<User>>();
  @Output() changePassword = new EventEmitter<void>();
  @Output() changeEmail = new EventEmitter<void>();

  editedUser: Partial<User> = {};
  
  // Campos do perfil do paciente
  patientGender: string = '';
  patientBirthDate: string = '';

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['user'] && this.user) {
      this.editedUser = { ...this.user };
      
      // Carrega dados do perfil do paciente
      if (this.user.patientProfile) {
        this.patientGender = this.user.patientProfile.gender || '';
        this.patientBirthDate = this.user.patientProfile.birthDate 
          ? this.user.patientProfile.birthDate.split('T')[0] 
          : '';
      }
    }
  }

  get isPatient(): boolean {
    return this.user?.role === 'PATIENT';
  }

  onBackdropClick(): void {
    this.onCancel();
  }

  onCancel(): void {
    this.close.emit();
  }

  onSave(): void {
    if (this.editedUser && this.isFormValid()) {
      // Inclui dados do perfil do paciente se for paciente
      if (this.isPatient) {
        const patientProfile: CreateUpdatePatientProfile = {
          ...(this.editedUser.patientProfile || {}),
          gender: this.patientGender || undefined,
          birthDate: this.patientBirthDate || undefined
        };
        this.editedUser.patientProfile = patientProfile;
      }
      this.save.emit(this.editedUser);
    }
  }

  onAvatarChange(avatarUrl: string): void {
    this.editedUser.avatar = avatarUrl;
  }

  isFormValid(): boolean {
    return !!(
      this.editedUser.name?.trim() &&
      this.editedUser.phone?.trim()
    );
  }

  onChangePassword(): void {
    this.changePassword.emit();
  }

  onChangeEmail(): void {
    this.changeEmail.emit();
  }
}
