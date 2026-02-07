import type { IconName } from '@shared/components/atoms/icon/icon';

export interface TabConfig {
  id: string;
  label: string;
  icon: IconName;
  roles: ('PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' | 'REGULATOR')[];
  /** Se a tab deve aparecer na teleconsulta (modo de atendimento) */
  showInTeleconsultation: boolean;
  /** Se a tab deve aparecer nos detalhes da consulta (modo de visualização) */
  showInDetails: boolean;
  /** Ordem de exibição */
  order: number;
  /** Grupo ao qual a tab pertence (para organização em categorias) */
  group?: 'exame-fisico' | 'documentos' | 'standalone';
}

/**
 * Interface para grupos de tabs (categorias)
 */
export interface TabGroup {
  id: 'exame-fisico' | 'documentos' | 'standalone';
  label: string;
  icon: IconName;
  tabs: TabConfig[];
}

/**
 * Configuração centralizada de todas as tabs disponíveis.
 * 
 * IMPORTANTE - PADRÃO DE CONFIGURAÇÃO:
 * =====================================
 * 
 * 1. ADIÇÃO DE NOVAS TABS:
 *    - Para adicionar uma nova tab, basta adicioná-la a este array TELECONSULTATION_TABS
 *    - Configure `showInTeleconsultation: true` se deve aparecer na videochamada
 *    - Configure `showInDetails: true` se deve aparecer na tela de detalhes
 *    - A tab será automaticamente incluída em ambas as telas conforme configuração
 * 
 * 2. MODO READONLY AUTOMÁTICO:
 *    - Todas as tabs na tela de detalhes (/consultas/:id/detalhes) são AUTOMATICAMENTE
 *      configuradas como somente leitura através da propriedade `isDetailsView`
 *    - NÃO é necessário adicionar readonly manualmente em cada tab
 *    - O componente pai (AppointmentDetailsComponent) gerencia isso globalmente
 * 
 * 3. CNS É A ÚNICA EXCEÇÃO:
 *    - CNS tem `showInDetails: false` porque é específica do atendimento ao vivo
 *    - Todas as outras tabs seguem o padrão: aparecem em ambas as telas
 * 
 * 4. COMO FUNCIONA:
 *    - getTeleconsultationTabs(): retorna tabs para teleconsulta (showInTeleconsultation: true)
 *    - getDetailsTabs(): retorna tabs para detalhes (showInDetails: true)
 *    - Novas tabs são automaticamente incluídas baseado nessas flags
 */
export const TELECONSULTATION_TABS: TabConfig[] = [
  {
    id: 'basic',
    label: 'Informações Básicas',
    icon: 'file',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: false, // Não mostra na teleconsulta, apenas nos detalhes
    showInDetails: true,
    order: 0,
    group: 'standalone'
  },
  {
    id: 'patient-data',
    label: 'Paciente',
    icon: 'user',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: false, // Removido da teleconsulta - info na barra de sinais
    showInDetails: false,
    order: 1,
    group: 'exame-fisico'
  },
  {
    id: 'pre-consultation',
    label: 'Dados da Pré Consulta',
    icon: 'file',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: false, // Temporariamente desativado
    showInDetails: false, // Temporariamente desativado
    order: 2,
    group: 'standalone'
  },
  {
    id: 'anamnesis',
    label: 'Anamnese',
    icon: 'file-text',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 1,
    group: 'exame-fisico'
  },
  {
    id: 'specialty',
    label: 'Específico',
    icon: 'stethoscope',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: false, // DESATIVADO - Removido conforme solicitação
    showInDetails: false,
    order: 3,
    group: 'exame-fisico'
  },
  {
    id: 'medical-devices',
    label: 'Sinais',
    icon: 'activity',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT', 'RECEPTIONIST'],
    showInTeleconsultation: false, // DESATIVADO - Removido da Avaliação Clínica
    showInDetails: false,
    order: 0,
    group: 'standalone'
  },
  {
    id: 'auscultation',
    label: 'Ausculta',
    icon: 'mic',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT', 'RECEPTIONIST'],
    showInTeleconsultation: false, // DESATIVADO - Removido do sistema
    showInDetails: false,
    order: 1,
    group: 'exame-fisico'
  },
  {
    id: 'exam-camera',
    label: 'Câmera de Exame',
    icon: 'video',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT', 'RECEPTIONIST'],
    showInTeleconsultation: false, // DESATIVADO - Focando apenas em ausculta
    showInDetails: false,
    order: 2,
    group: 'exame-fisico'
  },
  {
    id: 'phonocardiogram',
    label: 'Fonocardio',
    icon: 'headphones',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT', 'RECEPTIONIST'],
    showInTeleconsultation: false, // DESATIVADO - Removido da Avaliação Clínica
    showInDetails: false,
    order: 1,
    group: 'standalone'
  },
  {
    id: 'biometrics',
    label: 'Biométricos',
    icon: 'heart',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT', 'RECEPTIONIST'],
    showInTeleconsultation: false, // REMOVIDO conforme solicitação
    showInDetails: false,
    order: 6,
    group: 'standalone'
  },
  {
    id: 'attachments',
    label: 'Anexos',
    icon: 'upload-cloud',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT', 'RECEPTIONIST'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 0,
    group: 'documentos'
  },
  {
    id: 'receita',
    label: 'Receita',
    icon: 'file',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 1,
    group: 'documentos'
  },
  {
    id: 'atestado',
    label: 'Atestado',
    icon: 'file',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 2,
    group: 'documentos'
  },
  {
    id: 'return',
    label: 'Retorno',
    icon: 'calendar',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 3,
    group: 'documentos'
  },
  {
    id: 'referral',
    label: 'Encaminhar',
    icon: 'external-link',
    roles: ['PATIENT', 'PROFESSIONAL', 'ADMIN', 'ASSISTANT'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 4,
    group: 'documentos'
  },
  {
    id: 'ai',
    label: 'IA',
    icon: 'sparkles',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 3,
    group: 'exame-fisico'
  },
  {
    id: 'cns',
    label: 'CADSUS',
    icon: 'user',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: false, // REMOVIDO conforme solicitação
    showInDetails: false,
    order: 91,
    group: 'standalone'
  },
  {
    id: 'patient-history',
    label: 'Histórico',
    icon: 'book',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 2,
    group: 'exame-fisico'
  },
  {
    id: 'conclusion',
    label: 'Finalizar',
    icon: 'check-circle',
    roles: ['PROFESSIONAL', 'ADMIN'],
    showInTeleconsultation: true,
    showInDetails: false,
    order: 99,
    group: 'standalone'
  }
];

/**
 * Retorna as tabs disponíveis para a teleconsulta, filtradas por role
 */
export function getTeleconsultationTabs(role: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' | 'REGULATOR'): TabConfig[] {
  // ASSISTANT agora tem suas próprias permissões definidas no array roles
  return TELECONSULTATION_TABS
    .filter(tab => tab.showInTeleconsultation && tab.roles.includes(role))
    .sort((a, b) => a.order - b.order);
}

/**
 * Retorna os grupos de tabs organizados para a teleconsulta
 */
export function getTeleconsultationTabGroups(role: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT' | 'RECEPTIONIST' | 'REGULATOR'): TabGroup[] {
  const tabs = getTeleconsultationTabs(role);
  
  const groups: TabGroup[] = [
    {
      id: 'exame-fisico',
      label: 'Avaliação Clínica',
      icon: 'stethoscope',
      tabs: tabs.filter(t => t.group === 'exame-fisico').sort((a, b) => a.order - b.order)
    },
    {
      id: 'documentos',
      label: 'Prescrições e Documentos',
      icon: 'file',
      tabs: tabs.filter(t => t.group === 'documentos').sort((a, b) => a.order - b.order)
    },
    {
      id: 'standalone',
      label: 'Ferramentas',
      icon: 'settings',
      tabs: tabs.filter(t => t.group === 'standalone').sort((a, b) => a.order - b.order)
    }
  ];
  
  // Remove grupos vazios e remove 'Avaliação Clínica' para pacientes
  return groups.filter(g => {
    if (g.tabs.length === 0) return false;
    if (role === 'PATIENT' && g.id === 'exame-fisico') return false;
    return true;
  });
}

/**
 * Retorna as tabs disponíveis para a página de detalhes, filtradas por role
 */
export function getDetailsTabs(role: 'PATIENT' | 'PROFESSIONAL' | 'ADMIN' | 'ASSISTANT'): TabConfig[] {
  // ASSISTANT agora tem suas próprias permissões definidas no array roles
  return TELECONSULTATION_TABS
    .filter(tab => tab.showInDetails && tab.roles.includes(role))
    .sort((a, b) => a.order - b.order);
}

/**
 * Retorna todas as tabs disponíveis para a página de detalhes (sem filtro de role)
 */
export function getAllDetailsTabs(): TabConfig[] {
  return TELECONSULTATION_TABS
    .filter(tab => tab.showInDetails)
    .sort((a, b) => a.order - b.order);
}

/**
 * Mapeamento de id da tab para o nome usado na teleconsulta
 */
export const TAB_ID_TO_LEGACY_NAME: Record<string, string> = {
  'medical-devices': 'Sinais Vitais',
  'auscultation': 'Ausculta',
  'exam-camera': 'Câmera de Exame',
  'patient-data': 'Dados do Paciente',
  'pre-consultation': 'Dados da Pré Consulta',
  'anamnesis': 'Anamnese',
  'specialty': 'Campos da Especialidade',
  'biometrics': 'Biométricos',
  'attachments': 'Chat Anexos',
  'receita': 'Receituário',
  'atestado': 'Atestado',
  'ai': 'Análise Diagnóstica',
  'cns': 'Consulta CADSUS',
  'patient-history': 'Histórico Clínico',
  'return': 'Agendar Retorno',
  'referral': 'Encaminhamento',
  'conclusion': 'Finalizar Consulta'
};

/**
 * Mapeamento inverso: nome legacy para id
 */
export const LEGACY_NAME_TO_TAB_ID: Record<string, string> = Object.fromEntries(
  Object.entries(TAB_ID_TO_LEGACY_NAME).map(([id, name]) => [name, id])
);

