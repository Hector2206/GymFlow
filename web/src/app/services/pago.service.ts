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

export interface RegistrarPagoRequest {
  idCliente: number;
  monto: number;
  tipoPago: string;
}

export interface RegistrarPagoResponse {
  pagoRegistrado: boolean;
  esRenovacion: boolean;
  idCliente: number;
  monto: number;
  tipoPago: string;
  fechaVencimiento: string;
  membresiaActiva: boolean;
  mensaje: string;
}

export interface PagoCliente {
  idPago: number;
  monto: number;
  tipoPago: string;
  fechaTransaccion: string;
}

export interface HistorialPagosResponse {
  idCliente: number;
  pagos: PagoCliente[];
}

export interface MisPagosResponse {
  pagos: PagoCliente[];
}

@Injectable({
  providedIn: 'root'
})
export class PagoService {

  private readonly apiUrl =
    `${environment.clienteAltaUrl}/api/pagos`;

  constructor(
    private http: HttpClient
  ) {}

  registrarPago(
    request: RegistrarPagoRequest
  ): Observable<RegistrarPagoResponse> {

    return this.http.post<RegistrarPagoResponse>(
      this.apiUrl,
      request
    );
  }

  consultarPagosCliente(
    idCliente: number
  ): Observable<HistorialPagosResponse> {

    return this.http.get<HistorialPagosResponse>(
      `${this.apiUrl}/cliente/${idCliente}`
    );
  }

  consultarMisPagos(): Observable<MisPagosResponse> {

    return this.http.get<MisPagosResponse>(
      `${this.apiUrl}/mis-pagos`
    );
  }
}