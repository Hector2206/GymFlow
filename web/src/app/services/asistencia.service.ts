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
}