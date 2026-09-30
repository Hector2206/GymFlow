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
  CrearRutinaRequest,
  RutinaDetalle,
  RutinaGuardadaResponse,
  RutinaResumen
} from '../models/rutina.model';

@Injectable({
  providedIn: 'root'
})
export class RutinaService {

  constructor(
    private http: HttpClient
  ) {}


  listarRutinas():
    Observable<RutinaResumen[]> {

    return this.http.get<RutinaResumen[]>(
      `${environment.rutinaServiceUrl}/api/rutinas`
    );
  }


  obtenerRutinaPorId(
    idRutina: number
  ): Observable<RutinaDetalle> {

    return this.http.get<RutinaDetalle>(
      `${environment.rutinaServiceUrl}/api/rutinas/${idRutina}`
    );
  }


  obtenerMiRutina():
    Observable<RutinaDetalle> {

    return this.http.get<RutinaDetalle>(
      `${environment.rutinaServiceUrl}/api/rutinas/mi-rutina`
    );
  }


  crearRutina(
    request: CrearRutinaRequest
  ): Observable<RutinaGuardadaResponse> {

    return this.http.post<RutinaGuardadaResponse>(
      `${environment.rutinaServiceUrl}/api/rutinas`,
      request
    );
  }


  actualizarRutina(
    idRutina: number,
    request: CrearRutinaRequest
  ): Observable<RutinaGuardadaResponse> {

    return this.http.put<RutinaGuardadaResponse>(
      `${environment.rutinaServiceUrl}/api/rutinas/${idRutina}`,
      request
    );
  }


  eliminarRutina(
    idRutina: number
  ): Observable<{
    idRutina: number;
    mensaje: string;
  }> {

    return this.http.delete<{
      idRutina: number;
      mensaje: string;
    }>(
      `${environment.rutinaServiceUrl}/api/rutinas/${idRutina}`
    );
  }
}