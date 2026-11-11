
import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams
} from '@angular/common/http';
import { Observable } from 'rxjs';

import {
  environment
} from '../../environments/environment';

export interface AsistenciaAdmin {
  idAsistencia: number;
  idCliente: number;
  nombreCliente: string;
  fechaHora: string;
  estadoAcceso: string;
  origenRegistro: string;
}

export interface PagoAdmin {
  idPago: number;
  idCliente: number;
  nombreCliente: string;
  monto: number;
  tipoPago: string;
  fechaTransaccion: string;
  concepto: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class AdminDetallesService {

  private readonly apiUrl =
    `${environment.adminApiUrl}/api/admin`;

  constructor(
    private readonly http: HttpClient
  ) {}

  obtenerAsistencias(
    pagina: number,
    limite: number
  ): Observable<AsistenciaAdmin[]> {

    const params = new HttpParams()
      .set('pagina', pagina.toString())
      .set('limite', limite.toString());

    return this.http.get<AsistenciaAdmin[]>(
      `${this.apiUrl}/asistencias`,
      { params }
    );
  }

  obtenerPagos(
    pagina: number,
    limite: number
  ): Observable<PagoAdmin[]> {

    const params = new HttpParams()
      .set('pagina', pagina.toString())
      .set('limite', limite.toString());

    return this.http.get<PagoAdmin[]>(
      `${this.apiUrl}/pagos`,
      { params }
    );
  }
}
