import { Component, signal, inject, OnInit, OnDestroy } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ModalComponent } from '@shared/components/atoms/modal/modal';
import { PatientWaitingModalComponent } from '@shared/components/patient-waiting-modal/patient-waiting-modal.component';
import { TitleService } from '@core/services/title.service';
import { SignalRService } from '@core/services/signalr.service';
import { AuthService } from '@core/services/auth.service';
import { Subject, takeUntil } from 'rxjs';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, ModalComponent, PatientWaitingModalComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit, OnDestroy {
  protected readonly title = signal('TeleCuidar');
  private titleService = inject(TitleService);
  private signalRService = inject(SignalRService);
  private authService = inject(AuthService);
  private destroy$ = new Subject<void>();

  ngOnInit(): void {
    // Iniciar conexão SignalR quando usuário estiver autenticado
    this.authService.authState$.pipe(takeUntil(this.destroy$)).subscribe(state => {
      if (state.isAuthenticated && state.accessToken) {
        console.log('🔗 Iniciando conexão SignalR');
        this.signalRService.startConnection(state.accessToken);
      } else {
        console.log('🔌 Parando conexão SignalR');
        this.signalRService.stopConnection();
      }
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.signalRService.stopConnection();
  }
}
