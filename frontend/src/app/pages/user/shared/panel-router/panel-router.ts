import { Component, OnInit, inject, computed, effect } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '@app/core/services/auth.service';

// Import all panel components
import { AdminPanelComponent } from '@pages/user/admin/admin-panel/admin-panel';
import { PatientPanelComponent } from '@pages/user/patient/patient-panel/patient-panel';
import { ProfessionalPanelComponent } from '@pages/user/professional/professional-panel/professional-panel';
import { AssistantPanelComponent } from '@pages/user/assistant/assistant-panel/assistant-panel';
import { RegulatorPanelComponent } from '@pages/user/regulator/regulator-panel/regulator-panel';

@Component({
  selector: 'app-panel-router',
  standalone: true,
  imports: [
    AdminPanelComponent,
    PatientPanelComponent,
    ProfessionalPanelComponent,
    AssistantPanelComponent,
    RegulatorPanelComponent
  ],
  template: `
    @switch (userRole()) {
      @case ('ADMIN') {
        <app-admin-panel />
      }
      @case ('PATIENT') {
        <app-patient-panel />
      }
      @case ('PROFESSIONAL') {
        <app-professional-panel />
      }
      @case ('ASSISTANT') {
        <app-assistant-panel />
      }
      @case ('REGULATOR') {
        <app-regulator-panel />
      }
      @default {
        <div class="loading">Carregando...</div>
      }
    }
  `,
  styles: [`
    :host {
      display: block;
      width: 100%;
      height: 100vh;
    }
    .loading {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      font-size: 1.5rem;
      color: #64748b;
    }
  `]
})
export class PanelRouterComponent implements OnInit {
  private authService = inject(AuthService);
  private router = inject(Router);
  
  // Signal computed que reage a mudanças no currentUser
  userRole = computed(() => {
    const user = this.authService.getCurrentUser();
    return user?.role || '';
  });

  constructor() {
    // Effect que monitora mudanças no userRole
    effect(() => {
      const role = this.userRole();
      if (!role) {
        this.router.navigate(['/entrar']);
        return;
      }

      // Recepcionista usa o dashboard dedicado
      if (role === 'RECEPTIONIST') {
        this.router.navigate(['/recepcao']);
      }
    });
  }

  ngOnInit(): void {
    // O userRole já está sendo monitorado pelo computed signal
    // Se houver usuário, ele será renderizado automaticamente
    // Se não houver, o effect acima vai redirecionar
  }
}
