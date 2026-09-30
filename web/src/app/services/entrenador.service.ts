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

import {
  ClientesEntrenadorResponse
} from '../models/cliente-asignado.model';

@Injectable({
  providedIn: 'root'
})
export class EntrenadorService {

  constructor(
    private http: HttpClient
  ) {}

  obtenerMisClientes():
    Observable<ClientesEntrenadorResponse> {

    return this.http.get<ClientesEntrenadorResponse>(
      `${environment.rutinaServiceUrl}/api/entrenador/mis-clientes`
    );
  }
}