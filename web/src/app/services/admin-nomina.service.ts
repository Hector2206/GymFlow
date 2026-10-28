
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import {
  environment
} from '../../environments/environment';

import {
  SalarioPersonalAdmin,
  PagoNominaAdmin,
  CambiarSalarioAdminRequest,
  CambiarSalarioAdminResponse,
  RegistrarPagoNominaAdminRequest,
  RegistrarPagoNominaAdminResponse
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

  obtenerHistorialSalarial(
    idPersonal: number
  ): Observable<SalarioPersonalAdmin[]> {

    return this.http.get<SalarioPersonalAdmin[]>(
      `${this.apiUrl}/${idPersonal}/salarios`
    );
  }

  // CONSULTAR PAGOS DE NÓMINA

  obtenerHistorialNomina(
    idPersonal: number
  ): Observable<PagoNominaAdmin[]> {

    return this.http.get<PagoNominaAdmin[]>(
      `${this.apiUrl}/${idPersonal}/nomina`
    );
  }

  // CAMBIAR SUELDO MENSUAL

  cambiarSalario(
    idPersonal: number,
    datos: CambiarSalarioAdminRequest
  ): Observable<CambiarSalarioAdminResponse> {

    return this.http.post<CambiarSalarioAdminResponse>(
      `${this.apiUrl}/${idPersonal}/salarios`,
      datos
    );
  }

  // REGISTRAR PAGO MANUAL DE NÓMINA

  registrarPagoNomina(
    idPersonal: number,
    datos: RegistrarPagoNominaAdminRequest
  ): Observable<RegistrarPagoNominaAdminResponse> {

    return this.http.post<RegistrarPagoNominaAdminResponse>(
      `${this.apiUrl}/${idPersonal}/nomina`,
      datos
    );
  }
}
