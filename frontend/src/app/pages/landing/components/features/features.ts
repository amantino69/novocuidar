import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FeatureCardComponent } from '@app/shared/components/molecules/feature-card/feature-card';
import { IconName } from '@app/shared/components/atoms/icon/icon';

interface Feature {
  icon: IconName;
  title: string;
  description: string;
  color: 'primary' | 'red' | 'green' | 'blue';
}

@Component({
  selector: 'app-features',
  imports: [CommonModule, FeatureCardComponent],
  templateUrl: './features.html',
  styleUrl: './features.scss'
})
export class FeaturesComponent {
  patientFeatures: Feature[] = [
    {
      icon: 'stethoscope',
      title: 'Telemedicina Híbrida',
      description: 'Consultas especializadas com suporte de IA, dispositivos IoT e profissionais qualificados.',
      color: 'blue'
    },
    {
      icon: 'heart',
      title: 'Inteligência Artificial',
      description: 'Análise de dados em tempo real, detecção de padrões e sugestões de diagnóstico diferencial.',
      color: 'primary'
    },
    {
      icon: 'file',
      title: 'App Pessoal de Saúde',
      description: 'Histórico médico completo, agendamentos e acompanhamento na palma da sua mão.',
      color: 'green'
    }
  ];

  professionalFeatures: Feature[] = [
    {
      icon: 'shield',
      title: 'Segurança Total',
      description: 'Conformidade com LGPD, criptografia de ponta e assinatura digital certificada.',
      color: 'red'
    },
    {
      icon: 'clock',
      title: 'Sem Filas',
      description: 'Agendamento inteligente que reduz drasticamente o tempo de espera para consultas.',
      color: 'blue'
    },
    {
      icon: 'users',
      title: 'Acesso Universal',
      description: 'Atendimento especializado para áreas remotas, quebrando barreiras geográficas.',
      color: 'green'
    }
  ];

  advancedFeatures: Feature[] = [];
}
