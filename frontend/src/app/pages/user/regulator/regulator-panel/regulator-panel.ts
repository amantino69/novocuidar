import { Component, OnInit, OnDestroy, PLATFORM_ID, Inject } from '@angular/core';
import { CommonModule, DatePipe, isPlatformBrowser } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { IconComponent, IconName } from '@app/shared/components/atoms/icon/icon';
import { AvatarComponent } from '@app/shared/components/atoms/avatar/avatar';
import { LogoComponent } from '@app/shared/components/atoms/logo/logo';
import { ThemeToggleComponent } from '@app/shared/components/atoms/theme-toggle/theme-toggle';
import { AuthService } from '@app/core/services/auth.service';
import { RegulatorService, MunicipalStats } from '@app/core/services/regulator.service';
import { User as AuthUser } from '@app/core/models/auth.model';

interface PanelButton {
  id: string;
  title: string;
  description: string;
  icon: IconName;
  route: string;
  color: 'green' | 'blue' | 'red' | 'purple' | 'orange' | 'teal';
  stats?: string | number;
  isLogout?: boolean;
}

@Component({
  selector: 'app-regulator-panel',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    IconComponent,
    AvatarComponent,
    LogoComponent,
    ThemeToggleComponent
  ],
  providers: [DatePipe],
  templateUrl: './regulator-panel.html',
  styleUrls: ['./regulator-panel.scss']
})
export class RegulatorPanelComponent implements OnInit, OnDestroy {
  user: AuthUser | null = null;
  stats: MunicipalStats | null = null;
  currentTime: string = '';
  currentDate: string = '';
  private timeInterval: any;

  // Informações do município
  municipioNome: string = '';
  municipioUF: string = '';

  panelButtons: PanelButton[] = [
    {
      id: 'pacientes',
      title: 'Pacientes',
      description: 'Cidadãos do município',
      icon: 'users',
      route: '/regulacao/pacientes',
      color: 'blue'
    },
    {
      id: 'agendas',
      title: 'Agendas',
      description: 'Agendas disponíveis para alocação',
      icon: 'calendar',
      route: '/regulacao/agendas',
      color: 'green'
    },
    {
      id: 'fila',
      title: 'Fila de Espera',
      description: 'Pacientes aguardando alocação',
      icon: 'clock',
      route: '/regulacao/fila',
      color: 'orange'
    },
    {
      id: 'notificacoes',
      title: 'Notificações',
      description: 'Central de notificações',
      icon: 'bell',
      route: '/notificacoes',
      color: 'teal'
    },
    {
      id: 'perfil',
      title: 'Perfil',
      description: 'Configurações da conta',
      icon: 'user',
      route: '/perfil',
      color: 'purple'
    }
  ];

  constructor(
    private authService: AuthService,
    private regulatorService: RegulatorService,
    private router: Router,
    private datePipe: DatePipe,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}

  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();
    
    // Extrair info do município do usuário
    if (this.user) {
      this.municipioNome = (this.user as any).municipioNome || 'Município não definido';
    }

    if (isPlatformBrowser(this.platformId)) {
      this.updateTime();
      this.timeInterval = setInterval(() => this.updateTime(), 1000);
    }

    // TODO: Carregar estatísticas do município via API
    this.loadMunicipalStats();
  }

  ngOnDestroy(): void {
    if (this.timeInterval) {
      clearInterval(this.timeInterval);
    }
  }

  private updateTime(): void {
    const now = new Date();
    this.currentTime = this.datePipe.transform(now, 'HH:mm') || '';
    this.currentDate = this.datePipe.transform(now, 'EEEE, d \'de\' MMMM', 'pt-BR') || '';
  }

  private loadMunicipalStats(): void {
    this.regulatorService.getStats().subscribe({
      next: (stats) => {
        this.stats = stats;
        if (stats.municipio) {
          this.municipioNome = stats.municipio.nome;
          this.municipioUF = stats.municipio.uf;
        }
      },
      error: (err) => {
        console.error('Erro ao carregar estatísticas:', err);
        // Fallback para dados vazios
        this.stats = {
          totalPacientes: 0,
          consultasHoje: 0,
          consultasPendentes: 0,
          agendasDisponiveis: 0,
          municipio: null
        };
      }
    });
  }

  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  navigateTo(route: string): void {
    this.router.navigate([route]);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/']);
  }
}
