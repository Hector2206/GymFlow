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
  RutinaDetalle,
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
}