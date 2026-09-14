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

export interface ClienteResumen {
  idCliente: number;
  nombreCompleto: string;
}

@Injectable({
  providedIn: 'root'
})
export class ClienteConsultaService {

  private readonly apiUrl =
    `${environment.clienteAltaUrl}/api/clientes`;

  constructor(
    private http: HttpClient
  ) {}

  obtenerClientes(): Observable<ClienteResumen[]> {

    return this.http.get<ClienteResumen[]>(
      this.apiUrl
    );
  }
}