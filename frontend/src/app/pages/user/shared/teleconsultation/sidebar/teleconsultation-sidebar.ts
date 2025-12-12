import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconComponent } from '@shared/components/atoms/icon/icon';

@Component({
  selector: 'app-teleconsultation-sidebar',
  standalone: true,
  imports: [CommonModule, IconComponent],
  templateUrl: './teleconsultation-sidebar.html',
  styleUrls: ['./teleconsultation-sidebar.scss']
})
export class TeleconsultationSidebarComponent {
  @Input() isOpen = false;
  @Input() isFullScreen = false;
  @Input() isHeaderVisible = true;
  @Input() tabs: string[] = [];
  @Input() activeTab = '';
  @Input() userRole: 'patient' | 'professional' | 'admin' = 'patient';

  @Output() toggle = new EventEmitter<void>();
  @Output() toggleMode = new EventEmitter<void>();
  @Output() tabChange = new EventEmitter<string>();

  onToggle() {
    this.toggle.emit();
  }

  onToggleMode() {
    this.toggleMode.emit();
  }

  onTabChange(tab: string) {
    this.tabChange.emit(tab);
  }
}
