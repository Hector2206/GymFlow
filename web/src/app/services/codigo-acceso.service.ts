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

export interface MiCodigoAccesoResponse {
  idCliente: number;
  codigoAcceso: string;
  nombreCompleto: string;
}

@Injectable({
  providedIn: 'root'
})
export class CodigoAccesoService {

  private readonly apiUrl =
    `${environment.clienteAltaUrl}/api/clientes/mi-codigo-acceso`;

  constructor(
    private http: HttpClient
  ) {}

  obtenerMiCodigo(): Observable<MiCodigoAccesoResponse> {

    return this.http.get<MiCodigoAccesoResponse>(
      this.apiUrl
    );
  }
}