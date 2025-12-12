import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LogoComponent } from '@app/shared/components/atoms/logo/logo';

@Component({
  selector: 'app-footer',
  imports: [CommonModule, LogoComponent],
  templateUrl: './footer.html',
  styleUrl: './footer.scss'
})
export class FooterComponent {
  currentYear = new Date().getFullYear();

  links = {
    platform: [
      { label: 'Nossa Missão', href: '#mission' },
      { label: 'Tecnologia', href: '#technology' },
      { label: 'Nossa Solução', href: '#solution' },
      { label: 'Impacto Social', href: '#impact' }
    ],
    legal: [
      { label: 'Política de Privacidade', href: '/privacidade' },
      { label: 'Termos de Uso', href: '/termos' },
      { label: 'Conformidade LGPD', href: '#lgpd' },
      { label: 'Certificações', href: 'https://docs.microsoft.com/pt-br/azure/compliance/' }
    ]
  };
}
