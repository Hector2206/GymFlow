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
  Progreso,
  RegistrarProgresoRequest,
  RegistrarProgresoResponse
} from '../models/progreso.model';

@Injectable({
  providedIn: 'root'
})
export class ProgresoService {

  private readonly apiUrl =
    `${environment.rutinaServiceUrl}/api/progreso`;

  constructor(
    private http: HttpClient
  ) {}


  registrarProgreso(
    request: RegistrarProgresoRequest
  ): Observable<RegistrarProgresoResponse> {

    return this.http.post<RegistrarProgresoResponse>(
      this.apiUrl,
      request
    );
  }


  obtenerMiProgreso():
    Observable<Progreso[]> {

    return this.http.get<Progreso[]>(
      this.apiUrl
    );
  }


  obtenerProgresoPorEjercicio(
    idEjercicio: number
  ): Observable<Progreso[]> {

    return this.http.get<Progreso[]>(
      `${this.apiUrl}/ejercicio/${idEjercicio}`
    );
  }
}