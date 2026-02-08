import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { map, tap, shareReplay } from 'rxjs/operators';
import { environment } from '@env/environment';

// Cache com expiração para evitar chamadas repetidas
interface CacheEntry<T> {
  data: T;
  timestamp: number;
}

const CACHE_TTL = 30000; // 30 segundos

export interface MunicipalStats {
  totalPacientes: number;
  consultasHoje: number;
  consultasPendentes: number;
  agendasDisponiveis: number;
  municipio: {
    id: string;
    nome: string;
    uf: string;
    codigoIbge: string;
  } | null;
}

export interface RegulatorPatient {
  id: string;
  name: string;
  lastName: string;
  fullName: string;
  email: string;
  cpf: string;
  phone: string | null;
  avatar: string | null;
  status: string;
  cns: string | null;
  birthDate: string | null;
  gender: string | null;
  city: string | null;
  state: string | null;
  createdAt: string;
}

export interface PatientDetails {
  patient: {
    id: string;
    name: string;
    lastName: string;
    email: string;
    cpf: string;
    phone: string | null;
    avatar: string | null;
    status: string;
    profile: {
      cns: string | null;
      socialName: string | null;
      birthDate: string | null;
      gender: string | null;
      motherName: string | null;
      nacionalidade: string | null;
      racaCor: string | null;
      zipCode: string | null;
      logradouro: string | null;
      numero: string | null;
      complemento: string | null;
      bairro: string | null;
      city: string | null;
      state: string | null;
    };
    createdAt: string;
  };
  recentAppointments: {
    id: string;
    date: string;
    time: string;
    status: string;
    professionalName: string;
    specialtyName: string;
  }[];
}

export interface RegulatorAppointment {
  id: string;
  date: string;
  time: string;
  status: string;
  patient: {
    id: string;
    name: string;
    cpf: string;
  };
  professional: {
    id: string;
    name: string;
  };
  specialty: {
    id: string;
    name: string;
  };
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

export interface AvailableSchedule {
  id: string;
  validityStartDate: string;
  validityEndDate: string | null;
  isActive: boolean;
  professional: {
    id: string;
    name: string;
    specialty: string;
    specialtyId?: string;
  };
}

export interface ScheduleSlot {
  date: string;
  time: string;
  dayOfWeek: string;
  dayOfWeekPt: string;
}

export interface ScheduleSlotsResponse {
  schedule: {
    id: string;
    professional: {
      id: string;
      name: string;
      specialty: string;
      specialtyId: string;
    };
    slotDuration: number;
  };
  slots: ScheduleSlot[];
  totalSlots: number;
}

export interface AllocatePatientData {
  patientId: string;
  scheduleId: string;
  date: string;
  time: string;
  observation?: string;
}

export interface AllocatePatientResponse {
  message: string;
  appointment: {
    id: string;
    date: string;
    time: string;
    patient: {
      id: string;
      name: string;
    };
    professional: {
      id: string;
      name: string;
    };
    specialty: string;
  };
}

export interface Specialty {
  id: string;
  name: string;
  description: string;
}

@Injectable({
  providedIn: 'root'
})
export class RegulatorService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/regulator`;

  // Cache para evitar chamadas repetidas ao navegar entre telas
  private statsCache: CacheEntry<MunicipalStats> | null = null;
  private patientsCache = new Map<string, CacheEntry<PaginatedResponse<RegulatorPatient>>>();
  private schedulesCache: CacheEntry<AvailableSchedule[]> | null = null;
  private specialtiesCache: CacheEntry<Specialty[]> | null = null;

  private isCacheValid<T>(cache: CacheEntry<T> | null | undefined): cache is CacheEntry<T> {
    return cache !== null && cache !== undefined && (Date.now() - cache.timestamp) < CACHE_TTL;
  }

  /**
   * Limpa todo o cache (usar após criar/editar dados)
   */
  clearCache() {
    this.statsCache = null;
    this.patientsCache.clear();
    this.schedulesCache = null;
    this.specialtiesCache = null;
  }

  /**
   * Obtém estatísticas do município para o dashboard - COM CACHE
   */
  getStats(): Observable<MunicipalStats> {
    if (this.isCacheValid(this.statsCache)) {
      return of(this.statsCache.data);
    }
    return this.http.get<MunicipalStats>(`${this.apiUrl}/stats`).pipe(
      tap(data => this.statsCache = { data, timestamp: Date.now() })
    );
  }

  /**
   * Lista pacientes do município com paginação e filtros - COM CACHE
   */
  getPatients(params?: {
    search?: string;
    page?: number;
    pageSize?: number;
  }): Observable<PaginatedResponse<RegulatorPatient>> {
    // Criar chave de cache baseada nos parâmetros
    const cacheKey = JSON.stringify(params || {});
    const cached = this.patientsCache.get(cacheKey);
    
    if (this.isCacheValid(cached)) {
      return of(cached.data);
    }

    let httpParams = new HttpParams();
    
    if (params?.search) {
      httpParams = httpParams.set('search', params.search);
    }
    if (params?.page) {
      httpParams = httpParams.set('page', params.page.toString());
    }
    if (params?.pageSize) {
      httpParams = httpParams.set('pageSize', params.pageSize.toString());
    }

    return this.http.get<PaginatedResponse<RegulatorPatient>>(
      `${this.apiUrl}/patients`,
      { params: httpParams }
    ).pipe(
      tap(data => this.patientsCache.set(cacheKey, { data, timestamp: Date.now() }))
    );
  }

  /**
   * Obtém detalhes de um paciente específico
   */
  getPatientDetails(patientId: string): Observable<PatientDetails> {
    return this.http.get<PatientDetails>(`${this.apiUrl}/patients/${patientId}`);
  }

  /**
   * Lista consultas do município com filtros
   */
  getAppointments(params?: {
    startDate?: string;
    endDate?: string;
    status?: string;
    page?: number;
    pageSize?: number;
  }): Observable<PaginatedResponse<RegulatorAppointment>> {
    let httpParams = new HttpParams();
    
    if (params?.startDate) {
      httpParams = httpParams.set('startDate', params.startDate);
    }
    if (params?.endDate) {
      httpParams = httpParams.set('endDate', params.endDate);
    }
    if (params?.status) {
      httpParams = httpParams.set('status', params.status);
    }
    if (params?.page) {
      httpParams = httpParams.set('page', params.page.toString());
    }
    if (params?.pageSize) {
      httpParams = httpParams.set('pageSize', params.pageSize.toString());
    }

    return this.http.get<PaginatedResponse<RegulatorAppointment>>(
      `${this.apiUrl}/appointments`,
      { params: httpParams }
    );
  }

  /**
   * Lista agendas disponíveis - COM CACHE
   */
  getAvailableSchedules(): Observable<AvailableSchedule[]> {
    if (this.isCacheValid(this.schedulesCache)) {
      return of(this.schedulesCache.data);
    }
    return this.http.get<AvailableSchedule[]>(`${this.apiUrl}/available-schedules`).pipe(
      tap(data => this.schedulesCache = { data, timestamp: Date.now() })
    );
  }

  /**
   * Busca slots disponíveis de uma agenda específica
   */
  getScheduleSlots(scheduleId: string, startDate?: string, endDate?: string): Observable<ScheduleSlotsResponse> {
    let httpParams = new HttpParams();
    if (startDate) {
      httpParams = httpParams.set('startDate', startDate);
    }
    if (endDate) {
      httpParams = httpParams.set('endDate', endDate);
    }
    return this.http.get<ScheduleSlotsResponse>(`${this.apiUrl}/available-schedules/${scheduleId}/slots`, { params: httpParams });
  }

  /**
   * Aloca um paciente em um horário disponível - LIMPA CACHE após sucesso
   */
  allocatePatient(data: AllocatePatientData): Observable<AllocatePatientResponse> {
    return this.http.post<AllocatePatientResponse>(`${this.apiUrl}/appointments/allocate`, data).pipe(
      tap(() => this.clearCache())
    );
  }

  /**
   * Busca pacientes do município para alocação (pelo nome ou CPF)
   */
  searchPatientsForAllocation(query: string): Observable<RegulatorPatient[]> {
    const params = new HttpParams().set('search', query).set('pageSize', '20');
    return this.http.get<{ data: RegulatorPatient[], totalCount: number }>(`${this.apiUrl}/patients`, { params })
      .pipe(map(response => response.data));
  }

  /**
   * Lista especialidades disponíveis - COM CACHE
   */
  getSpecialties(): Observable<Specialty[]> {
    if (this.isCacheValid(this.specialtiesCache)) {
      return of(this.specialtiesCache.data);
    }
    return this.http.get<Specialty[]>(`${this.apiUrl}/specialties`).pipe(
      tap(data => this.specialtiesCache = { data, timestamp: Date.now() })
    );
  }

  /**
   * Importa pacientes a partir de arquivo CSV
   */
  importPatientsFromCsv(file: File): Observable<ImportCsvResult> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<ImportCsvResult>(`${this.apiUrl}/patients/import-csv`, formData);
  }

  /**
   * Baixa o modelo CSV para importação
   */
  downloadCsvTemplate(): void {
    window.open(`${this.apiUrl}/patients/csv-template`, '_blank');
  }

  /**
   * Cria um novo paciente - LIMPA CACHE após sucesso
   */
  createPatient(data: CreatePatientData): Observable<{ id: string; fullName: string; cpf: string; cns: string }> {
    return this.http.post<{ id: string; fullName: string; cpf: string; cns: string }>(`${this.apiUrl}/patients`, data).pipe(
      tap(() => this.clearCache())
    );
  }

  /**
   * Atualiza um paciente existente - LIMPA CACHE após sucesso
   */
  updatePatient(patientId: string, data: Partial<CreatePatientData>): Observable<{ message: string }> {
    return this.http.put<{ message: string }>(`${this.apiUrl}/patients/${patientId}`, data).pipe(
      tap(() => this.clearCache())
    );
  }

  /**
   * Lista unidades de saúde do município
   */
  getHealthFacilities(): Observable<HealthFacility[]> {
    return this.http.get<HealthFacility[]>(`${this.apiUrl}/health-facilities`);
  }

  /**
   * Busca cidadão no CADSUS por CPF ou CNS
   */
  searchCadsus(params: { cpf?: string; cns?: string }): Observable<CadsusResult> {
    let httpParams = new HttpParams();
    if (params.cpf) {
      httpParams = httpParams.set('cpf', params.cpf);
    }
    if (params.cns) {
      httpParams = httpParams.set('cns', params.cns);
    }
    return this.http.get<CadsusResult>(`${this.apiUrl}/cadsus/search`, { params: httpParams });
  }
}

// === Interface para resultado CADSUS ===
export interface CadsusResult {
  found: boolean;
  source: 'CADSUS' | 'LOCAL';
  message?: string;
  
  // Dados do cidadão
  cpf?: string;
  cns?: string;
  nome?: string;
  nomeSocial?: string;
  sobrenome?: string;
  dataNascimento?: string;
  sexo?: string;
  nomeMae?: string;
  nomePai?: string;
  nacionalidade?: string;
  racaCor?: string;
  telefone?: string;
  email?: string;
  
  // Endereço
  cep?: string;
  logradouro?: string;
  numero?: string;
  complemento?: string;
  bairro?: string;
  municipio?: string;
  uf?: string;
  
  // Se já está cadastrado localmente
  alreadyRegistered: boolean;
  localPatientId?: string;
}

// === Interfaces para importação e CRUD ===
export interface ImportCsvResult {
  imported: ImportSuccess[];
  skipped: ImportSkipped[];
  errors: ImportError[];
  totalProcessed: number;
}

export interface ImportSuccess {
  line: number;
  name: string;
  cpf?: string;
  cns?: string;
}

export interface ImportSkipped {
  line: number;
  reason: string;
  data?: string;
}

export interface ImportError {
  line: number;
  message: string;
  data?: string;
}

export interface CreatePatientData {
  name: string;
  lastName: string;
  cpf: string;
  email?: string;
  phone?: string;
  cns?: string;
  socialName?: string;
  gender?: string;
  birthDate?: Date;
  motherName?: string;
  fatherName?: string;
  nationality?: string;
  racaCor?: string;
  zipCode?: string;
  logradouro?: string;
  numero?: string;
  complemento?: string;
  bairro?: string;
  city?: string;
  state?: string;
  unidadeAdscritaId?: string;
  responsavelNome?: string;
  responsavelCpf?: string;
  responsavelTelefone?: string;
  responsavelEmail?: string;
  responsavelGrauParentesco?: string;
}

export interface HealthFacility {
  id: string;
  codigoCnes: string;
  nome: string;
  tipo: string;
}
