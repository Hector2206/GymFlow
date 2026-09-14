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
}