import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { AuthService } from '@app/core/services/auth.service';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { LogoComponent } from '@app/shared/components/atoms/logo/logo';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';

@Component({
  selector: 'app-verify-email',
  standalone: true,
  imports: [
    CommonModule,
    ButtonComponent,
    LogoComponent,
    IconComponent
  ],
  templateUrl: './verify-email.html',
  styleUrl: './verify-email.scss'
})
export class VerifyEmailComponent implements OnInit {
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  isLoading = true;
  errorMessage = '';
  successMessage = '';
  verificationToken = '';
  emailVerified = false;
  verificationFailed = false;

  ngOnInit(): void {
    // Get verification token from URL query params
    this.route.queryParams.subscribe(params => {
      this.verificationToken = params['token'] || '';
      
      if (!this.verificationToken) {
        this.isLoading = false;
        this.verificationFailed = true;
        this.errorMessage = 'Token de verificação inválido.';
        return;
      }

      this.verifyEmail();
    });
  }

  verifyEmail(): void {
    this.isLoading = true;
    this.errorMessage = '';

    this.authService.verifyEmail({ token: this.verificationToken }).subscribe({
      next: () => {
        this.isLoading = false;
        this.emailVerified = true;
        this.successMessage = 'E-mail verificado com sucesso!';
        
        // Redirect to login after 3 seconds
        setTimeout(() => {
          this.router.navigate(['/auth/login']);
        }, 3000);
      },
      error: (error) => {
        this.isLoading = false;
        this.verificationFailed = true;
        this.errorMessage = error.error?.message || 'Erro ao verificar e-mail. O token pode estar expirado.';
      }
    });
  }

  resendVerificationEmail(): void {
    // This would need user email - could be stored in localStorage or ask user to input
    this.errorMessage = 'Para reenviar o e-mail de verificação, faça login novamente.';
  }

  goToLogin(): void {
    this.router.navigate(['/auth/login']);
  }

  goToHome(): void {
    this.router.navigate(['/']);
  }
}
