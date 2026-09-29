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
}