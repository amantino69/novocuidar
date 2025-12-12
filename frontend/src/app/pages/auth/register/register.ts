import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '@app/core/services/auth.service';
import { CustomValidators } from '@app/core/validators/custom-validators';
import { AUTH_CONSTANTS } from '@app/core/constants/auth.constants';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { LogoComponent } from '@app/shared/components/atoms/logo/logo';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { InputPasswordComponent } from '@app/shared/components/atoms/input-password/input-password';
import { CheckboxComponent } from '@app/shared/components/atoms/checkbox/checkbox';
import { CpfMaskDirective } from '@app/core/directives/cpf-mask.directive';
import { PhoneMaskDirective } from '@app/core/directives/phone-mask.directive';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    ButtonComponent,
    LogoComponent,
    IconComponent,
    InputPasswordComponent,
    CheckboxComponent,
    CpfMaskDirective,
    PhoneMaskDirective
  ],
  templateUrl: './register.html',
  styleUrl: './register.scss'
})
export class RegisterComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);

  registerForm: FormGroup;
  isLoading = false;
  errorMessage = '';
  successMessage = '';

  constructor() {
    this.registerForm = this.fb.group({
      name: [
        '',
        [
          Validators.required,
          Validators.pattern(AUTH_CONSTANTS.VALIDATION_PATTERNS.NAME),
          Validators.minLength(AUTH_CONSTANTS.FIELD_LENGTHS.NAME.min),
          Validators.maxLength(AUTH_CONSTANTS.FIELD_LENGTHS.NAME.max)
        ]
      ],
      lastName: [
        '',
        [
          Validators.required,
          Validators.pattern(AUTH_CONSTANTS.VALIDATION_PATTERNS.NAME),
          Validators.minLength(AUTH_CONSTANTS.FIELD_LENGTHS.NAME.min),
          Validators.maxLength(AUTH_CONSTANTS.FIELD_LENGTHS.NAME.max)
        ]
      ],
      email: [
        '',
        [
          Validators.required,
          Validators.email,
          Validators.pattern(AUTH_CONSTANTS.VALIDATION_PATTERNS.EMAIL)
        ]
      ],
      cpf: ['', [Validators.required, CustomValidators.cpf()]],
      phone: ['', [Validators.required, CustomValidators.phone()]],
      password: [
        '',
        [
          Validators.required,
          Validators.minLength(AUTH_CONSTANTS.FIELD_LENGTHS.PASSWORD.min),
          CustomValidators.strongPassword()
        ]
      ],
      confirmPassword: ['', [Validators.required]],
      acceptTerms: [false, [Validators.requiredTrue]]
    }, {
      validators: CustomValidators.passwordMatch('password', 'confirmPassword')
    });
  }

  onSubmit(): void {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';

    const formValue = this.registerForm.value;
    const registerData = {
      name: formValue.name,
      lastName: formValue.lastName,
      email: formValue.email,
      cpf: formValue.cpf.replace(/\D/g, ''), // Remove mask
      phone: formValue.phone.replace(/\D/g, ''), // Remove mask
      password: formValue.password,
      confirmPassword: formValue.confirmPassword,
      acceptTerms: formValue.acceptTerms
    };

    this.authService.register(registerData).subscribe({
      next: (response) => {
        this.isLoading = false;
        this.successMessage = 'Cadastro realizado com sucesso! Verifique seu e-mail para confirmar sua conta.';
        
        // Redirect to login after 3 seconds
        setTimeout(() => {
          this.router.navigate(['/auth/login']);
        }, 3000);
      },
      error: (error) => {
        this.isLoading = false;
        this.errorMessage = error.error?.message || 'Erro ao realizar cadastro. Tente novamente.';
      }
    });
  }

  registerWithGoogle(): void {
    this.isLoading = true;
    this.errorMessage = '';

    // TODO: Implement Google OAuth when backend is ready
    this.authService.loginWithGoogle();
    this.isLoading = false;
    this.errorMessage = 'Login com Google ainda não está disponível.';
  }

  getErrorMessage(fieldName: string): string {
    const control = this.registerForm.get(fieldName);
    
    if (!control || !control.errors || !control.touched) {
      return '';
    }

    if (control.errors['required']) {
      return AUTH_CONSTANTS.VALIDATION_MESSAGES.REQUIRED;
    }

    if (fieldName === 'email') {
      if (control.errors['email'] || control.errors['pattern']) {
        return AUTH_CONSTANTS.VALIDATION_MESSAGES.EMAIL;
      }
    }

    if (fieldName === 'name' || fieldName === 'lastName') {
      if (control.errors['pattern']) {
        return AUTH_CONSTANTS.VALIDATION_MESSAGES.NAME;
      }
      if (control.errors['minlength']) {
        return AUTH_CONSTANTS.VALIDATION_MESSAGES.NAME_MIN_LENGTH;
      }
    }

    if (fieldName === 'cpf' && control.errors['invalidCpf']) {
      return AUTH_CONSTANTS.VALIDATION_MESSAGES.CPF;
    }

    if (fieldName === 'phone' && control.errors['invalidPhone']) {
      return AUTH_CONSTANTS.VALIDATION_MESSAGES.PHONE;
    }

    if (fieldName === 'password') {
      if (control.errors['minlength']) {
        return AUTH_CONSTANTS.VALIDATION_MESSAGES.PASSWORD_MIN_LENGTH;
      }
      if (control.errors['weakPassword']) {
        return AUTH_CONSTANTS.VALIDATION_MESSAGES.PASSWORD_WEAK;
      }
    }

    if (fieldName === 'confirmPassword' && this.registerForm.errors?.['passwordMismatch']) {
      return AUTH_CONSTANTS.VALIDATION_MESSAGES.PASSWORD_MATCH;
    }

    if (fieldName === 'acceptTerms' && control.errors['required']) {
      return 'Você deve aceitar os termos de uso';
    }

    return '';
  }

  goToHome(): void {
    this.router.navigate(['/']);
  }
}
