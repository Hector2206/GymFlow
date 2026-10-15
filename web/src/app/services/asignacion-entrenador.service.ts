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
  EntrenadorResumen,
  AsignarEntrenadorRequest,
  AsignarEntrenadorResponse,
  QuitarEntrenadorResponse
} from '../models/asignacion-entrenador.model';


@Injectable({
  providedIn: 'root'
})
export class AsignacionEntrenadorService {

  private readonly apiUrl =
    environment.clienteAltaUrl;

  constructor(
    private http: HttpClient
  ) {}


  obtenerEntrenadores():
    Observable<EntrenadorResumen[]> {

    return this.http.get<
      EntrenadorResumen[]
    >(
      `${this.apiUrl}/api/entrenadores`
    );
  }


  asignarEntrenador(
    idCliente: number,
    idEntrenador: number
  ): Observable<AsignarEntrenadorResponse> {

    const request:
      AsignarEntrenadorRequest = {
        idEntrenador
      };

    return this.http.put<
      AsignarEntrenadorResponse
    >(
      `${this.apiUrl}/api/clientes/${idCliente}/entrenador`,
      request
    );
  }


  quitarEntrenador(
    idCliente: number
  ): Observable<QuitarEntrenadorResponse> {

    return this.http.delete<
      QuitarEntrenadorResponse
    >(
      `${this.apiUrl}/api/clientes/${idCliente}/entrenador`
    );
  }
}