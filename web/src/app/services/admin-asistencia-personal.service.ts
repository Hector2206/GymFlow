
import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams
} from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

import {
  AsistenciaPersonal,
  RegistrarEntradaPersonalRequest,
  RegistrarEntradaPersonalResponse,
  RegistrarSalidaPersonalResponse,
  FiltrosAsistenciaPersonal
} from '../models/asistencia-personal.model';

@Injectable({
  providedIn: 'root'
})
export class AdminAsistenciaPersonalService {
  private readonly apiUrl =
    `${environment.adminApiUrl}/api/admin/personal/asistencias`;

  constructor(private http: HttpClient) {}

  obtenerHistorial(
    filtros: FiltrosAsistenciaPersonal = {}
  ): Observable<AsistenciaPersonal[]> {
    let params = new HttpParams();

    if (filtros.idPersonal !== undefined) {
      params = params.set(
        'idPersonal',
        String(filtros.idPersonal)
      );
    }

    if (filtros.fechaInicio) {
      params = params.set(
        'fechaInicio',
        filtros.fechaInicio
      );
    }

    if (filtros.fechaFin) {
      params = params.set(
        'fechaFin',
        filtros.fechaFin
      );
    }

    return this.http.get<AsistenciaPersonal[]>(
      this.apiUrl,
      { params }
    );
  }

  registrarEntrada(
    request: RegistrarEntradaPersonalRequest
  ): Observable<RegistrarEntradaPersonalResponse> {
    return this.http.post<RegistrarEntradaPersonalResponse>(
      this.apiUrl,
      request
    );
  }

  registrarSalida(
    idAsistencia: number,
    horaSalida: string
  ): Observable<RegistrarSalidaPersonalResponse> {
    return this.http.patch<RegistrarSalidaPersonalResponse>(
      `${this.apiUrl}/${idAsistencia}/salida`,
      { horaSalida }
    );
  }
}
