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
  ActualizarEjercicioRequest,
  CrearEjercicioRequest,
  Ejercicio
} from '../models/ejercicio.model';

@Injectable({
  providedIn: 'root'
})
export class EjercicioService {

  constructor(
    private http: HttpClient
  ) {}


  listarEjercicios():
    Observable<Ejercicio[]> {

    return this.http.get<Ejercicio[]>(
      `${environment.rutinaServiceUrl}/api/ejercicios`
    );
  }


  obtenerEjercicio(
    idEjercicio: number
  ): Observable<Ejercicio> {

    return this.http.get<Ejercicio>(
      `${environment.rutinaServiceUrl}/api/ejercicios/${idEjercicio}`
    );
  }


  crearEjercicio(
    request: CrearEjercicioRequest
  ): Observable<Ejercicio> {

    return this.http.post<Ejercicio>(
      `${environment.rutinaServiceUrl}/api/ejercicios`,
      request
    );
  }


  actualizarEjercicio(
    idEjercicio: number,
    request: ActualizarEjercicioRequest
  ): Observable<Ejercicio> {

    return this.http.put<Ejercicio>(
      `${environment.rutinaServiceUrl}/api/ejercicios/${idEjercicio}`,
      request
    );
  }


  desactivarEjercicio(
    idEjercicio: number
  ): Observable<any> {

    return this.http.delete(
      `${environment.rutinaServiceUrl}/api/ejercicios/${idEjercicio}`
    );
  }


  buscarEjercicios(
    nombre: string
  ): Observable<Ejercicio[]> {

    return this.http.get<Ejercicio[]>(
      `${environment.rutinaServiceUrl}/api/ejercicios/buscar`,
      {
        params: {
          nombre
        }
      }
    );
  }
}