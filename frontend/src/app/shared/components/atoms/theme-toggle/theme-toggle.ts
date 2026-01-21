import { Component, OnInit, OnDestroy, inject, HostListener, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { ThemeService, ThemeType, ThemeInfo, AVAILABLE_THEMES } from '@app/core/services/theme.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-theme-toggle',
  imports: [CommonModule, IconComponent],
  templateUrl: './theme-toggle.html',
  styleUrl: './theme-toggle.scss'
})
export class ThemeToggleComponent implements OnInit, OnDestroy {
  private themeService = inject(ThemeService);
  private elementRef = inject(ElementRef);
  private subscription?: Subscription;
  
  currentTheme: ThemeType = 'light';
  themes: ThemeInfo[] = AVAILABLE_THEMES;
  isOpen = false;
  isDark = false;

  ngOnInit() {
    this.subscription = this.themeService.currentTheme$.subscribe(theme => {
      this.currentTheme = theme;
      this.isDark = this.themeService.isDarkMode();
    });
  }

  ngOnDestroy() {
    this.subscription?.unsubscribe();
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent) {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      this.isOpen = false;
    }
  }

  toggleDropdown() {
    this.isOpen = !this.isOpen;
  }

  selectTheme(theme: ThemeType) {
    this.themeService.setTheme(theme);
    this.isOpen = false;
  }

  getCurrentThemeInfo(): ThemeInfo {
    return this.themes.find(t => t.id === this.currentTheme) || this.themes[0];
  }

  // Mantido para retrocompatibilidade
  toggleTheme() {
    this.themeService.toggleTheme();
  }
}
