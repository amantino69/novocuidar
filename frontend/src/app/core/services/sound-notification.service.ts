import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

/**
 * Serviço para gerenciar notificações sonoras no TeleCuidar
 */
@Injectable({
  providedIn: 'root'
})
export class SoundNotificationService {
  private audioCache: Map<string, HTMLAudioElement> = new Map();
  private isMuted: boolean = false;
  private platformId = inject(PLATFORM_ID);
  private isBrowser: boolean;

  constructor() {
    this.isBrowser = isPlatformBrowser(this.platformId);
    
    // Só executar no navegador
    if (!this.isBrowser) {
      return;
    }
    
    // Carregar preferência de som do localStorage
    const mutedPreference = localStorage.getItem('telecuidar_sound_muted');
    this.isMuted = mutedPreference === 'true';
    
    // Pré-carregar sons mais usados
    this.preloadSound('urgent', '/assets/sounds/urgent-alert.mp3');
    this.preloadSound('notification', '/assets/sounds/notification.mp3');
    this.preloadSound('success', '/assets/sounds/success.mp3');
    this.preloadSound('warning', '/assets/sounds/warning.mp3');
  }

  /**
   * Pré-carrega um arquivo de áudio na memória
   */
  private preloadSound(key: string, path: string): void {
    if (!this.isBrowser) return;
    
    try {
      const audio = new Audio(path);
      audio.preload = 'auto';
      // Não chamar load() que causa erro se arquivo não existir
      // audio.load();
      this.audioCache.set(key, audio);
    } catch (error) {
      console.warn(`Erro ao pré-carregar som ${key}:`, error);
      // Continuar sem som em caso de erro - não quebra a aplicação
    }
  }

  /**
   * Toca um som de notificação
   * @param soundType Tipo de som: 'urgent', 'notification', 'success', 'warning'
   * @param volume Volume de 0 a 1 (padrão: 0.7)
   */
  async playSound(soundType: 'urgent' | 'notification' | 'success' | 'warning', volume: number = 0.7): Promise<void> {
    if (!this.isBrowser) return;
    
    if (this.isMuted) {
      console.log(`Som ${soundType} silenciado por preferência do usuário`);
      return;
    }

    try {
      let audio = this.audioCache.get(soundType);
      
      if (!audio) {
        console.warn(`Som ${soundType} não encontrado no cache - usando Web Audio API como fallback`);
        // Criar um som de fallback usando Web Audio API
        this.playFallbackSound(volume);
        return;
      }

      // Clonar o áudio para permitir múltiplas reproduções simultâneas
      audio = audio.cloneNode(true) as HTMLAudioElement;
      audio.volume = Math.max(0, Math.min(1, volume));
      
      try {
        await audio.play().catch(err => {
          console.warn(`Erro ao reproduzir som ${soundType}:`, err);
          // Fallback se play() falhar
          this.playFallbackSound(volume);
        });
      } catch (error) {
        console.warn(`Erro durante play():`, error);
        this.playFallbackSound(volume);
      }
      
    } catch (error) {
      console.warn(`Erro ao reproduzir som ${soundType}:`, error);
      this.playFallbackSound(volume);
    }
  }

  /**
   * Fallback: toca som usando Web Audio API se arquivo não existir
   */
  private playFallbackSound(volume: number = 0.7): void {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      oscillator.frequency.value = 800; // Frequência em Hz
      oscillator.type = 'sine';
      
      gainNode.gain.setValueAtTime(volume, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.3);
    } catch (error) {
      console.warn('Erro ao tocar som de fallback:', error);
      // Sem som - aplicação continua funcionando
    }
  }

  /**
   * Toca som de demanda espontânea urgente (Red/Orange)
   */
  async playUrgentAlert(): Promise<void> {
    await this.playSound('urgent', 0.8);
  }

  /**
   * Toca som de notificação normal (Yellow/Green)
   */
  async playNotification(): Promise<void> {
    await this.playSound('notification', 0.6);
  }

  /**
   * Toca som de sucesso
   */
  async playSuccess(): Promise<void> {
    await this.playSound('success', 0.5);
  }

  /**
   * Toca som de aviso
   */
  async playWarning(): Promise<void> {
    await this.playSound('warning', 0.6);
  }

  /**
   * Toca som baseado no nível de urgência
   */
  async playByUrgency(urgencyLevel: 'Red' | 'Orange' | 'Yellow' | 'Green'): Promise<void> {
    switch (urgencyLevel) {
      case 'Red':
      case 'Orange':
        await this.playUrgentAlert();
        // Para urgências críticas, tocar 2 vezes com intervalo
        if (urgencyLevel === 'Red') {
          setTimeout(() => this.playUrgentAlert(), 800);
        }
        break;
      case 'Yellow':
      case 'Green':
        await this.playNotification();
        break;
    }
  }

  /**
   * Ativa ou desativa o som
   */
  toggleMute(): boolean {
    if (!this.isBrowser) return this.isMuted;
    
    this.isMuted = !this.isMuted;
    localStorage.setItem('telecuidar_sound_muted', this.isMuted.toString());
    return this.isMuted;
  }

  /**
   * Verifica se o som está silenciado
   */
  isSoundMuted(): boolean {
    return this.isMuted;
  }

  /**
   * Define se o som está silenciado
   */
  setMuted(muted: boolean): void {
    if (!this.isBrowser) return;
    
    this.isMuted = muted;
    localStorage.setItem('telecuidar_sound_muted', muted.toString());
  }

  /**
   * Testa o sistema de som
   */
  async testSound(): Promise<void> {
    console.log('Testando sistema de som...');
    await this.playNotification();
  }
}
