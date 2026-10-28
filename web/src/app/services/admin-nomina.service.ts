
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import {
  environment
} from '../../environments/environment';

import {
  SalarioPersonalAdmin,
  PagoNominaAdmin
} from '../models/admin-nomina.model';

@Injectable({
  providedIn: 'root'
})
export class AdminNominaService {

  private readonly apiUrl =
    `${environment.adminApiUrl}/api/admin/personal`;

  constructor(
    private http: HttpClient
  ) {}

  // CONSULTAR HISTORIAL SALARIAL
  // Incluye salario vigente y anteriores

  obtenerHistorialSalarial(
    idPersonal: number
  ): Observable<SalarioPersonalAdmin[]> {

    return this.http.get<SalarioPersonalAdmin[]>(
      `${this.apiUrl}/${idPersonal}/salarios`
    );
  }

  // CONSULTAR HISTORIAL DE NOMINA
  // Incluye pagos registrados y cancelados

  obtenerHistorialNomina(
    idPersonal: number
  ): Observable<PagoNominaAdmin[]> {

    return this.http.get<PagoNominaAdmin[]>(
      `${this.apiUrl}/${idPersonal}/nomina`
    );
  }
}
