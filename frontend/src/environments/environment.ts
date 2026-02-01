// ========================================
// Este arquivo é gerado automaticamente pelo script generate-env.js
// NÃO EDITE MANUALMENTE - Edite o arquivo .env na raiz do projeto
// ========================================

// Determina dinamicamente a URL da API baseado no host atual
const getApiUrl = () => {
  if (typeof window !== 'undefined') {
    const host = window.location.hostname;
    // Se acessando via IP ou não-localhost, usar o mesmo host para API
    if (host !== 'localhost' && host !== '127.0.0.1') {
      return `http://${host}:5239/api`;
    }
  }
  return 'http://localhost:5239/api';
};

// Determina dinamicamente o domínio do Jitsi Self-Hosted
const getJitsiDomain = () => {
  if (typeof window !== 'undefined') {
    const host = window.location.hostname;
    // Sempre usar Jitsi de produção (VPS)
    // O meet.telecuidar.com.br funciona tanto em dev quanto prod
    return 'meet.telecuidar.com.br';
  }
  return 'meet.telecuidar.com.br';
};

export const environment = {
  production: false,
  apiUrl: getApiUrl(),
  
  // Configurações do Jitsi Meet Self-Hosted
  jitsi: {
    domain: getJitsiDomain(),
    enabled: true,
    requiresAuth: true,
    appId: 'telecuidar'
  }
};
