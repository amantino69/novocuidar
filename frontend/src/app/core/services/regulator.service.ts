import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';

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

  /**
   * Obtém estatísticas do município para o dashboard
   */
  getStats(): Observable<MunicipalStats> {
    return this.http.get<MunicipalStats>(`${this.apiUrl}/stats`);
  }

  /**
   * Lista pacientes do município com paginação e filtros
   */
  getPatients(params?: {
    search?: string;
    page?: number;
    pageSize?: number;
  }): Observable<PaginatedResponse<RegulatorPatient>> {
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
   * Lista agendas disponíveis
   */
  getAvailableSchedules(): Observable<AvailableSchedule[]> {
    return this.http.get<AvailableSchedule[]>(`${this.apiUrl}/available-schedules`);
  }

  /**
   * Lista especialidades disponíveis
   */
  getSpecialties(): Observable<Specialty[]> {
    return this.http.get<Specialty[]>(`${this.apiUrl}/specialties`);
  }
}
