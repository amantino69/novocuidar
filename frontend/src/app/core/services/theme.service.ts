import { Injectable, Renderer2, RendererFactory2, Inject, PLATFORM_ID, OnDestroy } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { BehaviorSubject } from 'rxjs';
import { IconName } from '@app/shared/components/atoms/icon/icon';

export type ThemeType = 'light' | 'dark' | 'ocean' | 'aurora';

export interface ThemeInfo {
  id: ThemeType;
  name: string;
  description: string;
  icon: IconName;
  preview: {
    primary: string;
    secondary: string;
    accent: string;
  };
}

export const AVAILABLE_THEMES: ThemeInfo[] = [
  {
    id: 'light',
    name: 'Claro',
    description: 'Tema clássico claro',
    icon: 'sun',
    preview: { primary: '#ffffff', secondary: '#f8fafc', accent: '#3b82f6' }
  },
  {
    id: 'dark',
    name: 'Escuro',
    description: 'Tema escuro elegante',
    icon: 'moon',
    preview: { primary: '#0f172a', secondary: '#1e293b', accent: '#60a5fa' }
  },
  {
    id: 'ocean',
    name: 'Oceano',
    description: 'Azul profundo para saúde',
    icon: 'droplet',
    preview: { primary: '#0c1929', secondary: '#132f4c', accent: '#5090d3' }
  },
  {
    id: 'aurora',
    name: 'Aurora',
    description: 'Moderno com gradientes suaves',
    icon: 'sparkles',
    preview: { primary: '#fafbff', secondary: '#f0f4ff', accent: '#6366f1' }
  }
];

@Injectable({
  providedIn: 'root',
})
export class ThemeService implements OnDestroy {
  private renderer: Renderer2;
  private readonly THEME_KEY = 'telecuidar-theme';
  private mediaQueryListener: (() => void) | null = null;
  
  // Observable para mudanças de tema
  private currentThemeSubject = new BehaviorSubject<ThemeType>('light');
  public currentTheme$ = this.currentThemeSubject.asObservable();
  
  // Mantido para retrocompatibilidade
  private isDarkThemeSubject = new BehaviorSubject<boolean>(false);
  public isDarkTheme$ = this.isDarkThemeSubject.asObservable();

  constructor(
    rendererFactory: RendererFactory2,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    this.renderer = rendererFactory.createRenderer(null, null);
    this.initTheme();
    this.listenToSystemThemeChanges();
  }

  ngOnDestroy(): void {
    if (this.mediaQueryListener) {
      this.mediaQueryListener();
    }
  }

  private initTheme(): void {
    if (isPlatformBrowser(this.platformId)) {
      const savedTheme = localStorage.getItem(this.THEME_KEY) as ThemeType | null;
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      const theme = savedTheme || (prefersDark ? 'dark' : 'light');
      this.applyTheme(theme);
    }
  }

  private listenToSystemThemeChanges(): void {
    if (isPlatformBrowser(this.platformId)) {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      
      const handler = (e: MediaQueryListEvent) => {
        const savedTheme = localStorage.getItem(this.THEME_KEY);
        if (!savedTheme) {
          const theme = e.matches ? 'dark' : 'light';
          this.applyTheme(theme);
        }
      };

      mediaQuery.addEventListener('change', handler);
      this.mediaQueryListener = () => mediaQuery.removeEventListener('change', handler);
    }
  }

  private applyTheme(theme: ThemeType): void {
    if (isPlatformBrowser(this.platformId)) {
      // Remove todos os temas existentes
      this.renderer.removeAttribute(document.documentElement, 'data-theme');
      
      // Aplica o novo tema
      if (theme !== 'light') {
        this.renderer.setAttribute(document.documentElement, 'data-theme', theme);
      }
      
      this.currentThemeSubject.next(theme);
      this.isDarkThemeSubject.next(theme === 'dark' || theme === 'ocean');
    }
  }

  setTheme(theme: ThemeType): void {
    if (isPlatformBrowser(this.platformId)) {
      this.applyTheme(theme);
      localStorage.setItem(this.THEME_KEY, theme);
    }
  }

  toggleTheme(): void {
    const themes: ThemeType[] = ['light', 'dark', 'ocean', 'aurora'];
    const currentIndex = themes.indexOf(this.getCurrentTheme());
    const nextIndex = (currentIndex + 1) % themes.length;
    this.setTheme(themes[nextIndex]);
  }

  getCurrentTheme(): ThemeType {
    return this.currentThemeSubject.getValue();
  }

  isDarkMode(): boolean {
    const theme = this.getCurrentTheme();
    return theme === 'dark' || theme === 'ocean';
  }

  getAvailableThemes(): ThemeInfo[] {
    return AVAILABLE_THEMES;
  }

  getThemeInfo(themeId: ThemeType): ThemeInfo | undefined {
    return AVAILABLE_THEMES.find(t => t.id === themeId);
  }

  useSystemTheme(): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.removeItem(this.THEME_KEY);
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      this.applyTheme(prefersDark ? 'dark' : 'light');
    }
  }

  isUsingManualPreference(): boolean {
    if (isPlatformBrowser(this.platformId)) {
      return localStorage.getItem(this.THEME_KEY) !== null;
    }
    return false;
  }
}
