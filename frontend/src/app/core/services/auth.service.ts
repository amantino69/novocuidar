import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, tap, catchError, of } from 'rxjs';
import {
  User,
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  ForgotPasswordRequest,
  ForgotPasswordResponse,
  ResetPasswordRequest,
  ResetPasswordResponse,
  VerifyEmailRequest,
  VerifyEmailResponse,
  AuthState
} from '@app/core/models/auth.model';
import { AUTH_ENDPOINTS, STORAGE_KEYS } from '@app/core/constants/auth.constants';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private authState = new BehaviorSubject<AuthState>({
    user: null,
    accessToken: null,
    refreshToken: null,
    isAuthenticated: false,
    isLoading: false,
    error: null
  });

  public authState$ = this.authState.asObservable();
  public currentUser = signal<User | null>(null);
  public isAuthenticated = signal<boolean>(false);

  constructor(private http: HttpClient) {
    this.loadUserFromStorage();
  }

  // Login
  login(request: LoginRequest): Observable<LoginResponse> {
    this.setLoading(true);
    
    return this.http.post<LoginResponse>(AUTH_ENDPOINTS.LOGIN, request).pipe(
      tap(response => {
        this.handleAuthSuccess(response, request.rememberMe);
        this.setLoading(false);
      }),
      catchError(error => {
        this.setError(error.error?.message || 'Erro ao fazer login');
        this.setLoading(false);
        throw error;
      })
    );
  }

  // Register
  register(request: RegisterRequest): Observable<RegisterResponse> {
    this.setLoading(true);
    
    return this.http.post<RegisterResponse>(AUTH_ENDPOINTS.REGISTER, request).pipe(
      tap(response => {
        this.setLoading(false);
      }),
      catchError(error => {
        this.setError(error.error?.message || 'Erro ao criar conta');
        this.setLoading(false);
        throw error;
      })
    );
  }

  // Logout
  logout(): void {
    this.http.post(AUTH_ENDPOINTS.LOGOUT, {}).subscribe();
    
    this.clearStorage();
    this.authState.next({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      isLoading: false,
      error: null
    });
    this.currentUser.set(null);
    this.isAuthenticated.set(false);
  }

  // Forgot Password
  forgotPassword(request: ForgotPasswordRequest): Observable<ForgotPasswordResponse> {
    this.setLoading(true);
    
    return this.http.post<ForgotPasswordResponse>(AUTH_ENDPOINTS.FORGOT_PASSWORD, request).pipe(
      tap(() => this.setLoading(false)),
      catchError(error => {
        this.setError(error.error?.message || 'Erro ao enviar email');
        this.setLoading(false);
        throw error;
      })
    );
  }

  // Reset Password
  resetPassword(request: ResetPasswordRequest): Observable<ResetPasswordResponse> {
    this.setLoading(true);
    
    return this.http.post<ResetPasswordResponse>(AUTH_ENDPOINTS.RESET_PASSWORD, request).pipe(
      tap(() => this.setLoading(false)),
      catchError(error => {
        this.setError(error.error?.message || 'Erro ao redefinir senha');
        this.setLoading(false);
        throw error;
      })
    );
  }

  // Verify Email
  verifyEmail(request: VerifyEmailRequest): Observable<VerifyEmailResponse> {
    this.setLoading(true);
    
    return this.http.post<VerifyEmailResponse>(AUTH_ENDPOINTS.VERIFY_EMAIL, request).pipe(
      tap(response => {
        if (response.user) {
          this.currentUser.set(response.user);
        }
        this.setLoading(false);
      }),
      catchError(error => {
        this.setError(error.error?.message || 'Erro ao verificar email');
        this.setLoading(false);
        throw error;
      })
    );
  }

  // Resend Verification Email
  resendVerificationEmail(email: string): Observable<any> {
    return this.http.post(AUTH_ENDPOINTS.RESEND_VERIFICATION, { email });
  }

  // Google Login (placeholder)
  loginWithGoogle(): void {
    // Implementar OAuth2 com Google
    window.location.href = AUTH_ENDPOINTS.GOOGLE_LOGIN;
  }

  // Refresh Token
  refreshToken(): Observable<LoginResponse> {
    const refreshToken = localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
    
    return this.http.post<LoginResponse>(AUTH_ENDPOINTS.REFRESH_TOKEN, { refreshToken }).pipe(
      tap(response => {
        this.handleAuthSuccess(response, true);
      })
    );
  }

  // Get Access Token
  getAccessToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
  }

  // Private helper methods
  private handleAuthSuccess(response: LoginResponse, rememberMe?: boolean): void {
    this.authState.next({
      user: response.user,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      isAuthenticated: true,
      isLoading: false,
      error: null
    });
    
    this.currentUser.set(response.user);
    this.isAuthenticated.set(true);
    
    if (rememberMe) {
      localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, response.accessToken);
      localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, response.refreshToken);
      localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(response.user));
      localStorage.setItem(STORAGE_KEYS.REMEMBER_ME, 'true');
    } else {
      sessionStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, response.accessToken);
      sessionStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, response.refreshToken);
      sessionStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(response.user));
    }
  }

  private loadUserFromStorage(): void {
    const rememberMe = localStorage.getItem(STORAGE_KEYS.REMEMBER_ME) === 'true';
    const storage = rememberMe ? localStorage : sessionStorage;
    
    const accessToken = storage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
    const refreshToken = storage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
    const userStr = storage.getItem(STORAGE_KEYS.USER);
    
    if (accessToken && refreshToken && userStr) {
      const user = JSON.parse(userStr);
      this.authState.next({
        user,
        accessToken,
        refreshToken,
        isAuthenticated: true,
        isLoading: false,
        error: null
      });
      this.currentUser.set(user);
      this.isAuthenticated.set(true);
    }
  }

  private clearStorage(): void {
    localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.USER);
    localStorage.removeItem(STORAGE_KEYS.REMEMBER_ME);
    
    sessionStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN);
    sessionStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
    sessionStorage.removeItem(STORAGE_KEYS.USER);
  }

  private setLoading(isLoading: boolean): void {
    const current = this.authState.value;
    this.authState.next({ ...current, isLoading });
  }

  private setError(error: string): void {
    const current = this.authState.value;
    this.authState.next({ ...current, error });
  }
}
