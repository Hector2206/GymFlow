import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface CambiarMembresiaResponse {
  mensaje: string;
  idCliente: number;
  idMembresiaAnterior: number;
  idMembresiaNueva: number;
}

@Injectable({ providedIn: 'root' })
export class CambioMembresiaService {
  private readonly apiUrl = `${environment.clienteAltaUrl}/api/clientes`;

  constructor(private readonly http: HttpClient) {}

  cambiar(
    idCliente: number,
    idMembresia: number
  ): Observable<CambiarMembresiaResponse> {
    return this.http.put<CambiarMembresiaResponse>(
      `${this.apiUrl}/${idCliente}/membresia`,
      { idMembresia }
    );
  }
}

