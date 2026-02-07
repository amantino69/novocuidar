import { Injectable, NgZone, Inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { BehaviorSubject } from 'rxjs';
import { ModalService } from './modal.service';
import { JitsiService } from './jitsi.service';

@Injectable({
  providedIn: 'root'
})
export class DictationService {
  private recognition: any;
  private isListening = false;
  private activeElement: HTMLInputElement | HTMLTextAreaElement | null = null;
  private lastInterim = '';
  private ignoreResultsUntilIndex = -1; // Ignore results with index <= this value
  private lastResultIndex = -1; // Track the latest result index
  private isBrowser: boolean;
  
  public isDictationActive$ = new BehaviorSubject<boolean>(false);
  public isListening$ = new BehaviorSubject<boolean>(false);
  public isInitializing$ = new BehaviorSubject<boolean>(false); // Estado de inicialização
  public lastTranscript$ = new BehaviorSubject<string>(''); // Para feedback visual

  constructor(
    private zone: NgZone, 
    private modalService: ModalService,
    private jitsiService: JitsiService,
    @Inject(PLATFORM_ID) platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
    
    if (this.isBrowser) {
      this.initRecognition();
    }
  }

  private initRecognition(): void {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    
    if (!SpeechRecognition) {
      console.warn('[Dictation] SpeechRecognition não suportado neste navegador');
      return;
    }

    console.log('[Dictation] Inicializando reconhecimento de voz...');
    this.recognition = new SpeechRecognition();
    this.recognition.continuous = true;
    this.recognition.interimResults = true;
    this.recognition.lang = 'pt-BR';

    this.recognition.onstart = () => {
      console.log('[Dictation] Reconhecimento iniciado');
    };

    this.recognition.onresult = (event: any) => {
      this.zone.run(() => {
        // Track the latest result index (used when focusing a new field)
        this.lastResultIndex = event.results.length - 1;
        this.handleResult(event);
      });
    };

    this.recognition.onerror = (event: any) => {
      console.error('[Dictation] Erro:', event.error);
      this.zone.run(() => {
        // Erros que devem parar o ditado
        if (event.error === 'not-allowed') {
          this.modalService.alert({
            title: 'Microfone Bloqueado',
            message: 'Por favor, permita o acesso ao microfone nas configurações do navegador.',
            variant: 'warning'
          }).subscribe();
          this.stopListening();
        } else if (event.error === 'audio-capture') {
          this.modalService.alert({
            title: 'Microfone Indisponível',
            message: 'Não foi possível acessar o microfone. Verifique se ele está conectado.',
            variant: 'warning'
          }).subscribe();
          this.stopListening();
        }
        // Erros transientes (no-speech, network, aborted) - apenas loga, o onend vai reiniciar
        // Não faz nada aqui para permitir reinício automático
      });
    };

    this.recognition.onend = () => {
      console.log('[Dictation] Reconhecimento terminou, isDictationActive:', this.isDictationActive$.value);
      this.zone.run(() => {
        // Reinicia automaticamente se o modo ditado ainda está ativo
        if (this.isDictationActive$.value) {
          console.log('[Dictation] Reiniciando reconhecimento automaticamente...');
          setTimeout(() => {
            try {
              if (this.isDictationActive$.value) {
                this.recognition.start();
                this.isListening = true;
                this.isListening$.next(true);
              }
            } catch (e) {
              console.error('[Dictation] Erro ao reiniciar:', e);
            }
          }, 100); // Pequeno delay para evitar conflitos
        } else {
          this.isListening = false;
          this.isListening$.next(false);
        }
      });
    };
    
    // Setup global focus listener to track active input
    document.addEventListener('focusin', (e) => {
      const target = e.target as HTMLElement;
      if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement) {
        this.activeElement = target;
        this.lastInterim = '';
        // Ignore all results captured before this field was focused
        this.ignoreResultsUntilIndex = this.lastResultIndex;
        console.log('[Dictation] Campo focado:', target.id || target.name || 'sem id');
      }
    });

    // Setup global blur listener to stop writing when field loses focus
    document.addEventListener('focusout', (e) => {
      const target = e.target as HTMLElement;
      if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement) {
        // Only clear if it's the currently active element
        if (this.activeElement === target) {
          console.log('[Dictation] Campo perdeu foco');
          this.activeElement = null;
          this.lastInterim = '';
        }
      }
    });
    
    console.log('[Dictation] Inicialização completa');
  }

  toggleDictation() {
    // Previne cliques múltiplos durante inicialização
    if (this.isInitializing$.value) {
      console.log('[Dictation] Já está inicializando, ignorando clique');
      return;
    }
    
    if (this.isDictationActive$.value) {
      this.stopDictation();
    } else {
      this.startDictation();
    }
  }

  async startDictation() {
    if (!this.isBrowser) {
      console.warn('[Dictation] Não disponível no servidor');
      return;
    }
    
    if (!this.recognition) {
      this.modalService.alert({
        title: 'Recurso Indisponível',
        message: 'Seu navegador não suporta reconhecimento de voz. Use Chrome, Edge ou Safari.',
        variant: 'warning'
      }).subscribe();
      return;
    }
    
    // Indica que está inicializando (feedback visual imediato)
    this.isInitializing$.next(true);
    console.log('[Dictation] Solicitando acesso ao microfone...');
    
    // Solicita acesso explícito ao microfone primeiro
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      console.log('[Dictation] Microfone liberado com sucesso');
      
      // Lista dispositivos para diagnóstico
      const devices = await navigator.mediaDevices.enumerateDevices();
      const audioInputs = devices.filter(d => d.kind === 'audioinput');
      console.log('[Dictation] Microfones disponíveis:', audioInputs.map(d => d.label || 'Sem nome'));
      
      // Verifica se tem áudio ativo
      const audioTrack = stream.getAudioTracks()[0];
      console.log('[Dictation] Usando microfone:', audioTrack.label);
      
      // Para o stream de teste (o SpeechRecognition vai criar o próprio)
      stream.getTracks().forEach(t => t.stop());
      
    } catch (err) {
      console.error('[Dictation] Erro ao acessar microfone:', err);
      this.isInitializing$.next(false); // Desativa estado de inicialização em caso de erro
      this.modalService.alert({
        title: 'Microfone Inacessível',
        message: 'Não foi possível acessar o microfone. Verifique as permissões do navegador.',
        variant: 'warning'
      }).subscribe();
      return;
    }
    
    console.log('[Dictation] Ativando modo ditado...');
    this.isDictationActive$.next(true);
    this.isInitializing$.next(false); // Desativa estado de inicialização após sucesso
    
    // Muta o microfone do Jitsi para o paciente não ouvir o médico ditando
    this.jitsiService.setLocalAudioMuted(true);
    
    this.startListening();
  }

  stopDictation() {
    this.isDictationActive$.next(false);
    this.isInitializing$.next(false); // Garante que inicialização está desativada
    this.stopListening();
    this.activeElement = null;
    this.lastInterim = '';
    
    // Desmuta o microfone do Jitsi quando parar de ditar
    this.jitsiService.setLocalAudioMuted(false);
  }

  private startListening() {
    if (!this.isListening && this.recognition) {
      try {
        this.recognition.start();
        this.isListening = true;
        this.isListening$.next(true);
      } catch (e) {
        console.error('Error starting speech recognition', e);
      }
    }
  }

  private stopListening() {
    if (this.isListening && this.recognition) {
      this.isListening = false;
      this.isListening$.next(false);
      this.recognition.stop();
    }
  }

  private handleResult(event: any) {
    if (!this.activeElement) {
      console.log('[Dictation] Nenhum campo com foco - texto ignorado');
      return;
    }

    let newFinals = '';
    let newInterim = '';

    // Only process results with index > ignoreResultsUntilIndex
    const startIndex = Math.max(event.resultIndex, this.ignoreResultsUntilIndex + 1);
    
    for (let i = startIndex; i < event.results.length; ++i) {
      const transcript = event.results[i][0].transcript;
      if (event.results[i].isFinal) {
        if (newFinals && !newFinals.endsWith(' ') && !transcript.startsWith(' ')) {
          newFinals += ' ';
        }
        newFinals += transcript;
      } else {
        newInterim += transcript;
      }
    }

    // PRIMEIRO: Verifica comandos de edição (apagar, etc)
    if (newFinals) {
      const editResult = this.processEditCommands(newFinals);
      if (editResult.commandExecuted) {
        // Comando de edição foi executado, não adiciona texto
        this.lastInterim = '';
        this.lastTranscript$.next(editResult.commandName || '');
        return;
      }
      // Se não foi comando, aplica pontuação normal
      newFinals = this.applyPunctuation(newFinals);
    }

    // Log para diagnóstico
    if (newFinals || newInterim) {
      console.log('[Dictation] Texto capturado - Final:', newFinals, '| Interim:', newInterim);
      this.lastTranscript$.next(newFinals || newInterim);
    }

    let currentValue = this.activeElement.value;
    
    // 1. Remove previous interim text if it exists at the end
    if (this.lastInterim && currentValue.endsWith(this.lastInterim)) {
      currentValue = currentValue.slice(0, -this.lastInterim.length);
    }
    
    // 2. Prepare text to add (Finals + Interim)
    let trackedInterim = '';
    
    // Add finals
    if (newFinals) {
       const prefix = (currentValue && !currentValue.endsWith(' ')) ? ' ' : '';
       currentValue += prefix + newFinals;
    }
    
    // Add interim
    if (newInterim) {
       const prefix = (currentValue && !currentValue.endsWith(' ')) ? ' ' : '';
       trackedInterim = prefix + newInterim;
       currentValue += trackedInterim;
    }
    
    this.activeElement.value = currentValue;
    this.lastInterim = trackedInterim;
    
    // Dispatch input event to trigger Angular/Reactive Forms updates
    this.activeElement.dispatchEvent(new Event('input', { bubbles: true }));
    this.activeElement.dispatchEvent(new Event('change', { bubbles: true }));
    
    // Auto-scroll para o final do texto (resolve problema de texto oculto)
    this.scrollToEnd(this.activeElement);
  }

  /**
   * Rola o campo de texto para mostrar o final do conteúdo
   */
  private scrollToEnd(element: HTMLInputElement | HTMLTextAreaElement): void {
    // Move o cursor para o final
    element.selectionStart = element.value.length;
    element.selectionEnd = element.value.length;
    
    // Para textareas, rola verticalmente até o final
    if (element instanceof HTMLTextAreaElement) {
      element.scrollTop = element.scrollHeight;
    }
    
    // Força scroll horizontal para o final se necessário
    element.scrollLeft = element.scrollWidth;
  }

  /**
   * Processa comandos de edição por voz (apagar, desfazer, etc)
   * 
   * Comandos suportados:
   * - "apagar" ou "apaga" → apaga a última palavra
   * - "apagar palavra" → apaga a última palavra
   * - "apagar tudo" ou "limpar tudo" ou "limpar" → limpa o campo inteiro
   * - "apagar frase" ou "apaga frase" → apaga até o último ponto/início
   * - "apagar linha" ou "apaga linha" → apaga a última linha
   * - "desfazer" → desfaz última ação (Ctrl+Z)
   * 
   * @returns { commandExecuted: boolean, commandName?: string }
   */
  private processEditCommands(text: string): { commandExecuted: boolean; commandName?: string } {
    if (!this.activeElement) {
      return { commandExecuted: false };
    }

    // Normaliza: minúsculas, remove espaços extras, remove pontuação final
    const normalizedText = text.toLowerCase().trim()
      .replace(/[.,!?;:]+$/, '')  // Remove pontuação final
      .replace(/\s+/g, ' ');       // Normaliza espaços múltiplos
    
    let currentValue = this.activeElement.value;
    let commandName = '';

    // Log para diagnóstico
    console.log('[Dictation] Verificando comando:', `"${normalizedText}"`);

    // APAGAR TUDO / LIMPAR TUDO / LIMPAR
    // Variações: "apagar tudo", "apaga tudo", "limpar tudo", "limpa tudo", "limpar", "limpa"
    if (/^(apagar?|apaga|limpar?|limpa)\s*(tudo)?$/i.test(normalizedText) && 
        (normalizedText.includes('tudo') || /^(limpar?|limpa)$/i.test(normalizedText))) {
      console.log('[Dictation] ✅ Comando: APAGAR TUDO');
      this.activeElement.value = '';
      commandName = '🗑️ Tudo apagado';
    }
    // APAGAR FRASE (até o último ponto ou início)
    // Variações: "apagar frase", "apaga frase", "apaga a frase", "apagar a frase"
    else if (/^(apagar?|apaga)\s*(a\s+)?frase$/i.test(normalizedText)) {
      console.log('[Dictation] ✅ Comando: APAGAR FRASE');
      // Encontra o último ponto final, interrogação ou exclamação
      const lastSentenceEnd = Math.max(
        currentValue.lastIndexOf('. '),
        currentValue.lastIndexOf('? '),
        currentValue.lastIndexOf('! '),
        currentValue.lastIndexOf('.\n'),
        currentValue.lastIndexOf('?\n'),
        currentValue.lastIndexOf('!\n')
      );
      
      if (lastSentenceEnd > 0) {
        // Mantém até o ponto (inclusive)
        this.activeElement.value = currentValue.substring(0, lastSentenceEnd + 2).trimEnd() + ' ';
      } else {
        // Não encontrou ponto, apaga tudo
        this.activeElement.value = '';
      }
      commandName = '🗑️ Frase apagada';
    }
    // APAGAR LINHA (até a última quebra de linha ou início)
    // Variações: "apagar linha", "apaga linha", "apaga a linha", "apagar a linha"
    else if (/^(apagar?|apaga)\s*(a\s+)?linha$/i.test(normalizedText)) {
      console.log('[Dictation] ✅ Comando: APAGAR LINHA');
      const lastNewline = currentValue.lastIndexOf('\n');
      
      if (lastNewline > 0) {
        this.activeElement.value = currentValue.substring(0, lastNewline + 1);
      } else {
        this.activeElement.value = '';
      }
      commandName = '🗑️ Linha apagada';
    }
    // APAGAR / APAGA (última palavra)
    // Variações: "apagar", "apaga", "apagar palavra", "apaga palavra", "apaga a palavra", "a pagar" (erro comum)
    else if (/^(apagar?|apaga|a\s*pagar?)\s*(a\s+)?(palavra)?$/i.test(normalizedText)) {
      console.log('[Dictation] ✅ Comando: APAGAR PALAVRA');
      // Remove espaços finais e encontra a última palavra
      currentValue = currentValue.trimEnd();
      const lastSpaceIndex = currentValue.lastIndexOf(' ');
      
      if (lastSpaceIndex > 0) {
        this.activeElement.value = currentValue.substring(0, lastSpaceIndex + 1);
      } else if (currentValue.length > 0) {
        // Só tinha uma palavra
        this.activeElement.value = '';
      }
      commandName = '🗑️ Palavra apagada';
    }
    // DESFAZER
    // Variações: "desfazer", "desfaz", "voltar", "volta", "ctrl z"
    else if (/^(desfazer?|desfaz|voltar?|volta|ctrl\s*z)$/i.test(normalizedText)) {
      console.log('[Dictation] ✅ Comando: DESFAZER');
      document.execCommand('undo');
      commandName = '↩️ Desfeito';
    }
    // Não é um comando de edição
    else {
      console.log('[Dictation] ❌ Não é comando, será tratado como texto');
      return { commandExecuted: false };
    }

    // Dispara eventos para atualizar o Angular
    this.activeElement.dispatchEvent(new Event('input', { bubbles: true }));
    this.activeElement.dispatchEvent(new Event('change', { bubbles: true }));
    this.scrollToEnd(this.activeElement);

    return { commandExecuted: true, commandName };
  }

  /**
   * Aplica pontuação automática ao texto transcrito.
   * Converte comandos de voz em sinais de pontuação.
   * 
   * COMANDOS DE PONTUAÇÃO:
   * - "ponto" ou "ponto final" → "."
   * - "vírgula" → ","
   * - "dois pontos" → ":"
   * - "ponto e vírgula" → ";"
   * - "interrogação" ou "ponto de interrogação" → "?"
   * - "exclamação" ou "ponto de exclamação" → "!"
   * - "abre parênteses" ou "abre parêntese" → "("
   * - "fecha parênteses" ou "fecha parêntese" → ")"
   * - "travessão" ou "traço" → "—"
   * - "nova linha" ou "próxima linha" ou "enter" → "\n"
   * - "novo parágrafo" ou "parágrafo" → "\n\n"
   * - "abre aspas" → """
   * - "fecha aspas" → """
   * 
   * COMANDOS DE EDIÇÃO (processados em processEditCommands):
   * - "apagar" ou "apaga" → apaga última palavra
   * - "apagar tudo" ou "limpar" → limpa o campo
   * - "apagar frase" → apaga até o último ponto
   * - "apagar linha" → apaga até a última quebra de linha
   * - "desfazer" → Ctrl+Z
   */
  private applyPunctuation(text: string): string {
    if (!text) return text;

    // Mapeamento de comandos de voz para pontuação
    const punctuationMap: { pattern: RegExp; replacement: string }[] = [
      // Pontos finais (verificar primeiro os compostos)
      { pattern: /\s*ponto\s+final\s*/gi, replacement: '. ' },
      { pattern: /\s*ponto\s+de\s+interrogação\s*/gi, replacement: '? ' },
      { pattern: /\s*ponto\s+de\s+exclamação\s*/gi, replacement: '! ' },
      { pattern: /\s*ponto\s+e\s+vírgula\s*/gi, replacement: '; ' },
      { pattern: /\s*ponto\s*/gi, replacement: '. ' },
      
      // Vírgula
      { pattern: /\s*vírgula\s*/gi, replacement: ', ' },
      
      // Dois pontos
      { pattern: /\s*dois\s+pontos\s*/gi, replacement: ': ' },
      
      // Interrogação e exclamação
      { pattern: /\s*interrogação\s*/gi, replacement: '? ' },
      { pattern: /\s*exclamação\s*/gi, replacement: '! ' },
      
      // Parênteses
      { pattern: /\s*abre\s+parêntese[s]?\s*/gi, replacement: ' (' },
      { pattern: /\s*fecha\s+parêntese[s]?\s*/gi, replacement: ') ' },
      
      // Travessão
      { pattern: /\s*travessão\s*/gi, replacement: ' — ' },
      { pattern: /\s*traço\s*/gi, replacement: ' — ' },
      
      // Quebras de linha
      { pattern: /\s*(nova\s+linha|próxima\s+linha|enter)\s*/gi, replacement: '\n' },
      { pattern: /\s*(novo\s+parágrafo|parágrafo)\s*/gi, replacement: '\n\n' },
      
      // Aspas
      { pattern: /\s*abre\s+aspas\s*/gi, replacement: ' "' },
      { pattern: /\s*fecha\s+aspas\s*/gi, replacement: '" ' },
    ];

    let result = text;
    
    for (const { pattern, replacement } of punctuationMap) {
      result = result.replace(pattern, replacement);
    }

    // Capitaliza após pontuação final (. ? !)
    result = result.replace(/([.?!])\s+([a-záéíóúâêîôûãõç])/gi, (match, punct, letter) => {
      return punct + ' ' + letter.toUpperCase();
    });

    // Capitaliza início de parágrafo
    result = result.replace(/(\n\n?)([a-záéíóúâêîôûãõç])/gi, (match, newline, letter) => {
      return newline + letter.toUpperCase();
    });

    // Remove espaços múltiplos
    result = result.replace(/  +/g, ' ');

    return result;
  }
}
