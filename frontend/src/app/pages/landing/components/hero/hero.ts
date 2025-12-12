import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonComponent } from '@app/shared/components/atoms/button/button';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { BadgeComponent } from '@app/shared/components/atoms/badge/badge';
import { StatCardComponent } from '@app/shared/components/molecules/stat-card/stat-card';

@Component({
  selector: 'app-hero',
  imports: [CommonModule, ButtonComponent, IconComponent, BadgeComponent, StatCardComponent],
  templateUrl: './hero.html',
  styleUrl: './hero.scss'
})
export class HeroComponent {
  stats = [
    { value: '📊', label: 'Dados em Tempo Real', color: 'primary' as const },
    { value: '🤖', label: 'IA Diagnóstica', color: 'blue' as const },
    { value: '💊', label: 'Prescrição Digital', color: 'green' as const },
  ];
}
