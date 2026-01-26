import { Injectable, OnDestroy, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, interval, Subscription } from 'rxjs';
import { tap } from 'rxjs/operators';
import { isPlatformBrowser } from '@angular/common';
import { environment } from '@env/environment';

export interface BiometricsData {
  heartRate?: number; // bpm
  bloodPressureSystolic?: number; // mmHg
  bloodPressureDiastolic?: number; // mmHg
  oxygenSaturation?: number; // %
  temperature?: number; // Celsius
  respiratoryRate?: number; // rpm
  weight?: number; // kg
  height?: number; // cm
  glucose?: number; // mg/dL
  lastUpdated?: string; // ISO date
}

@Injectable({
  providedIn: 'root'
})
export class BiometricsService implements OnDestroy {
  private biometricsSubjects: Map<string, BehaviorSubject<BiometricsData | null>> = new Map();
  private pollingSubscriptions: Map<string, Subscription> = new Map();
  private lastKnownTimestamp: Map<string, string> = new Map();
  private localCache: Map<string, BiometricsData> = new Map(); // Cache local persistente
  
  private readonly POLLING_INTERVAL = 2000; // 2 seconds
  private readonly CACHE_KEY_PREFIX = 'biometrics_cache_';

  constructor(
    private http: HttpClient,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    // Restaurar cache do sessionStorage ao inicializar
    this.restoreCacheFromStorage();
  }

  ngOnDestroy() {
    // Clean up all polling subscriptions
    this.pollingSubscriptions.forEach(sub => sub.unsubscribe());
    this.pollingSubscriptions.clear();
  }

  /**
   * Restaura cache do sessionStorage (sobrevive a mudanças de aba)
   */
  private restoreCacheFromStorage(): void {
    if (!isPlatformBrowser(this.platformId)) return;
    
    try {
      // Buscar todas as chaves de cache de biometrics
      for (let i = 0; i < sessionStorage.length; i++) {
        const key = sessionStorage.key(i);
        if (key?.startsWith(this.CACHE_KEY_PREFIX)) {
          const appointmentId = key.replace(this.CACHE_KEY_PREFIX, '');
          const cached = sessionStorage.getItem(key);
          if (cached) {
            const data = JSON.parse(cached) as BiometricsData;
            this.localCache.set(appointmentId, data);
            // Também popula o BehaviorSubject imediatamente
            this.getSubject(appointmentId).next(data);
          }
        }
      }
    } catch (e) {
      console.warn('Error restoring biometrics cache:', e);
    }
  }

  /**
   * Salva dados no cache local e sessionStorage
   */
  private saveToCache(appointmentId: string, data: BiometricsData): void {
    this.localCache.set(appointmentId, data);
    
    if (isPlatformBrowser(this.platformId)) {
      try {
        sessionStorage.setItem(
          this.CACHE_KEY_PREFIX + appointmentId,
          JSON.stringify(data)
        );
      } catch (e) {
        console.warn('Error saving biometrics to cache:', e);
      }
    }
  }

  /**
   * Obtém dados do cache local
   */
  getCachedBiometrics(appointmentId: string): BiometricsData | null {
    return this.localCache.get(appointmentId) || null;
  }

  /**
   * Atualiza o cache com dados recebidos via SignalR (tempo real)
   * Usado para persistir dados entre mudanças de aba
   */
  updateCache(appointmentId: string, data: BiometricsData): void {
    this.saveToCache(appointmentId, data);
    this.getSubject(appointmentId).next(data);
    this.lastKnownTimestamp.set(appointmentId, data.lastUpdated || '');
  }

  private getSubject(appointmentId: string): BehaviorSubject<BiometricsData | null> {
    if (!this.biometricsSubjects.has(appointmentId)) {
      // Inicializar com dados do cache, se existirem
      const cached = this.localCache.get(appointmentId) || null;
      this.biometricsSubjects.set(appointmentId, new BehaviorSubject<BiometricsData | null>(cached));
    }
    return this.biometricsSubjects.get(appointmentId)!;
  }

  /**
   * Obtém observable para dados biométricos de uma consulta
   * Retorna dados cacheados imediatamente e inicia polling para atualizações
   */
  getBiometrics(appointmentId: string): Observable<BiometricsData | null> {
    const subject = this.getSubject(appointmentId);
    
    // Se não tem dados no subject, tenta buscar do cache
    if (!subject.value) {
      const cached = this.localCache.get(appointmentId);
      if (cached) {
        subject.next(cached);
      }
    }
    
    // Fetch da API em background (não bloqueia a UI)
    this.fetchBiometrics(appointmentId);
    
    // Start polling if not already
    this.startPolling(appointmentId);
    
    return this.getSubject(appointmentId).asObservable();
  }

  /**
   * Salva dados biométricos (usado pelo paciente)
   */
  saveBiometrics(appointmentId: string, data: BiometricsData): void {
    const url = `${environment.apiUrl}/appointments/${appointmentId}/biometrics`;
    
    // Salvar no cache local imediatamente (otimistic update)
    const dataWithTimestamp = { ...data, lastUpdated: new Date().toISOString() };
    this.saveToCache(appointmentId, dataWithTimestamp);
    this.getSubject(appointmentId).next(dataWithTimestamp);
    
    this.http.put<{ message: string; data: BiometricsData }>(url, data).subscribe({
      next: (response) => {
        // Update com dados do servidor
        this.getSubject(appointmentId).next(response.data);
        this.saveToCache(appointmentId, response.data);
        this.lastKnownTimestamp.set(appointmentId, response.data.lastUpdated || '');
      },
      error: (err) => {
        console.error('Error saving biometrics:', err);
      }
    });
  }

  /**
   * Busca dados biométricos do servidor
   */
  private fetchBiometrics(appointmentId: string): void {
    const url = `${environment.apiUrl}/appointments/${appointmentId}/biometrics`;
    
    this.http.get<BiometricsData>(url).subscribe({
      next: (data) => {
        const currentData = this.getSubject(appointmentId).value;
        const currentTimestamp = currentData?.lastUpdated || '';
        const newTimestamp = data?.lastUpdated || '';
        
        // Only update if data changed
        if (newTimestamp !== currentTimestamp) {
          this.getSubject(appointmentId).next(data);
          this.saveToCache(appointmentId, data); // Salvar no cache
          this.lastKnownTimestamp.set(appointmentId, newTimestamp);
        }
      },
      error: (err) => {
        if (err.status !== 404) {
          console.error('Error fetching biometrics:', err);
        }
      }
    });
  }

  /**
   * Inicia polling para atualizações em tempo real
   */
  startPolling(appointmentId: string): void {
    if (!isPlatformBrowser(this.platformId)) return;
    if (this.pollingSubscriptions.has(appointmentId)) return;

    const subscription = interval(this.POLLING_INTERVAL).subscribe(() => {
      this.fetchBiometrics(appointmentId);
    });
    
    this.pollingSubscriptions.set(appointmentId, subscription);
  }

  /**
   * Para o polling de uma consulta
   */
  stopPolling(appointmentId: string): void {
    const subscription = this.pollingSubscriptions.get(appointmentId);
    if (subscription) {
      subscription.unsubscribe();
      this.pollingSubscriptions.delete(appointmentId);
    }
  }

  /**
   * Força uma atualização imediata dos dados do servidor
   * Retorna um Observable que completa após receber os dados
   */
  forceRefresh(appointmentId: string): Observable<BiometricsData | null> {
    const url = `${environment.apiUrl}/appointments/${appointmentId}/biometrics`;
    
    return this.http.get<BiometricsData>(url).pipe(
      tap(data => {
        if (data) {
          this.saveToCache(appointmentId, data);
          this.getSubject(appointmentId).next(data);
          this.lastKnownTimestamp.set(appointmentId, data.lastUpdated || '');
        }
      })
    );
  }
}
