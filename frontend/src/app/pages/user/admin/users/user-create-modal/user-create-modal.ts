import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { CpfMaskDirective } from '@app/core/directives/cpf-mask.directive';
import { PhoneMaskDirective } from '@app/core/directives/phone-mask.directive';
import { EmailValidatorDirective } from '@app/core/directives/email-validator.directive';
import { UserRole } from '@app/core/services/users.service';

export interface CreateUserData {
  name?: string;
  email?: string;
  cpf?: string;
  phone?: string;
  role: UserRole;
}

export type CreateUserAction = 'create' | 'generate-link' | 'send-email';

@Component({
  selector: 'app-user-create-modal',
  imports: [FormsModule, IconComponent, ButtonComponent, CpfMaskDirective, PhoneMaskDirective, EmailValidatorDirective],
  templateUrl: './user-create-modal.html',
  styleUrl: './user-create-modal.scss'
})
export class UserCreateModalComponent {
  @Input() isOpen = false;
  @Output() close = new EventEmitter<void>();
  @Output() create = new EventEmitter<{ data: CreateUserData; action: CreateUserAction }>();

  step: 1 | 2 = 1;
  selectedRole: UserRole | null = null;
  creationMode: 'manual' | 'link' = 'manual';
  linkValidity: number = 7;
  
  userData: CreateUserData = {
    name: '',
    email: '',
    cpf: '',
    phone: '',
    role: 'patient'
  };

  password = '';
  confirmPassword = '';

  onBackdropClick(): void {
    this.onCancel();
  }

  onCancel(): void {
    this.resetModal();
    this.close.emit();
  }

  selectRole(role: UserRole): void {
    this.selectedRole = role;
    this.userData.role = role;
    this.step = 2;
  }

  goBackToRoleSelection(): void {
    this.step = 1;
    this.selectedRole = null;
  }

  toggleCreationMode(): void {
    this.creationMode = this.creationMode === 'manual' ? 'link' : 'manual';
  }

  onCreate(): void {
    if (this.selectedRole) {
      this.create.emit({
        data: { ...this.userData },
        action: 'create'
      });
      this.resetModal();
    }
  }

  onGenerateLink(): void {
    if (this.selectedRole) {
      this.create.emit({
        data: { ...this.userData },
        action: 'generate-link'
      });
      this.resetModal();
    }
  }

  onSendEmail(): void {
    if (this.selectedRole && this.userData.email?.trim()) {
      this.create.emit({
        data: { ...this.userData },
        action: 'send-email'
      });
      this.resetModal();
    }
  }

  canSendEmail(): boolean {
    return !!(this.userData.email?.trim());
  }

  isFormValid(): boolean {
    return !!(
      this.userData.name?.trim() &&
      this.userData.email?.trim() &&
      this.userData.cpf?.trim() &&
      this.userData.phone?.trim() &&
      this.password.trim() &&
      this.confirmPassword.trim() &&
      this.password === this.confirmPassword
    );
  }

  passwordsMatch(): boolean {
    return this.password === this.confirmPassword;
  }

  private resetModal(): void {
    this.step = 1;
    this.selectedRole = null;
    this.creationMode = 'manual';
    this.linkValidity = 7;
    this.userData = {
      name: '',
      email: '',
      cpf: '',
      phone: '',
      role: 'patient'
    };
    this.password = '';
    this.confirmPassword = '';
  }

  getRoleIcon(role: UserRole): 'user' | 'users' | 'shield' {
    const iconMap: Record<UserRole, 'user' | 'users' | 'shield'> = {
      patient: 'user',
      professional: 'users',
      admin: 'shield'
    };
    return iconMap[role];
  }

  getRoleLabel(role: UserRole): string {
    const labels: Record<UserRole, string> = {
      patient: 'Paciente',
      professional: 'Profissional',
      admin: 'Administrador'
    };
    return labels[role];
  }

  getRoleDescription(role: UserRole): string {
    const descriptions: Record<UserRole, string> = {
      patient: 'Usuário que receberá atendimento médico',
      professional: 'Profissional de saúde que realizará atendimentos',
      admin: 'Administrador com acesso total ao sistema'
    };
    return descriptions[role];
  }
}
