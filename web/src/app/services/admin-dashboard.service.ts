
import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams
} from '@angular/common/http';

import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

import {
  TotalClientesResponse,
  MembresiasActivasResponse,
  AsistenciasDiaResponse,
  PagosRegistradosResponse,
  IngresosPeriodoResponse
} from '../models/admin-dashboard.model';

@Injectable({
  providedIn: 'root'
})
export class AdminDashboardService {

  private readonly apiUrl =
    `${environment.adminApiUrl}/api/admin/dashboard`;

  constructor(
    private http: HttpClient
  ) {}

  // Total de clientes registrados
  obtenerTotalClientes():
    Observable<TotalClientesResponse> {

    return this.http.get<TotalClientesResponse>(
      `${this.apiUrl}/total-clientes`
    );
  }

  // Membresias activas
  obtenerMembresiasActivas():
    Observable<MembresiasActivasResponse> {

    return this.http.get<MembresiasActivasResponse>(
      `${this.apiUrl}/membresias-activas`
    );
  }

  // Asistencias registradas hoy
  obtenerAsistenciasDia():
    Observable<AsistenciasDiaResponse> {

    return this.http.get<AsistenciasDiaResponse>(
      `${this.apiUrl}/asistencias-dia`
    );
  }

  // Pagos registrados de clientes
  obtenerPagosRegistrados():
    Observable<PagosRegistradosResponse> {

    return this.http.get<PagosRegistradosResponse>(
      `${this.apiUrl}/pagos-registrados`
    );
  }

  // Ingresos brutos por periodo
  obtenerIngresosPeriodo(
    desde: string,
    hasta: string
  ): Observable<IngresosPeriodoResponse> {

    const params = new HttpParams()
      .set('desde', desde)
      .set('hasta', hasta);

    return this.http.get<IngresosPeriodoResponse>(
      `${this.apiUrl}/ingresos-periodo`,
      { params }
    );
  }
}
