import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconComponent, IconName } from '@app/shared/components/atoms/icon/icon';

@Component({
  selector: 'app-feature-card',
  imports: [CommonModule, IconComponent],
  templateUrl: './feature-card.html',
  styleUrl: './feature-card.scss'
})
export class FeatureCardComponent {
  @Input() icon!: IconName;
  @Input() title!: string;
  @Input() description!: string;
  @Input() color: 'primary' | 'red' | 'green' | 'blue' = 'primary';
}
