import {
  Injectable
} from '@angular/core';

import {
  HttpClient
} from '@angular/common/http';

import {
  Observable
} from 'rxjs';

import {
  environment
} from '../../environments/environment';

export interface RegistrarAsistenciaRequest {
  codigoAcceso: string;
}

export interface RegistrarAsistenciaResponse {
  accesoAprobado?: boolean;
  idCliente?: number;
  nombreCompleto?: string;
  codigoAcceso?: string;
  idMembresia?: number;
  nombrePlan?: string;
  fechaVencimiento?: string;
  fechaHoraAsistencia?: string;
  motivo?: string;
  mensaje?: string;
}

export interface AsistenciaCliente {
  idAsistencia: number;
  fechaHora: string;
  estadoAcceso: string;
  origenRegistro: string;
}

export interface HistorialAsistenciasResponse {
  idCliente: number;
  asistencias: AsistenciaCliente[];
}

export interface MisAsistenciasResponse {
  asistencias: AsistenciaCliente[];
}

@Injectable({
  providedIn: 'root'
})
export class AsistenciaService {

  private readonly apiUrl =
    `${environment.clienteAltaUrl}/api/asistencias`;

  constructor(
    private http: HttpClient
  ) {}

  registrarPorCodigo(
    codigoAcceso: string
  ): Observable<RegistrarAsistenciaResponse> {

    const body: RegistrarAsistenciaRequest = {
      codigoAcceso
    };

    return this.http.post<RegistrarAsistenciaResponse>(
      `${this.apiUrl}/codigo`,
      body
    );
  }

  consultarPorCliente(
    idCliente: number
  ): Observable<HistorialAsistenciasResponse> {

    return this.http.get<HistorialAsistenciasResponse>(
      `${this.apiUrl}/cliente/${idCliente}`
    );
  }

  consultarMisAsistencias(): Observable<MisAsistenciasResponse> {

    return this.http.get<MisAsistenciasResponse>(
      `${this.apiUrl}/mis-asistencias`
    );
  }
}