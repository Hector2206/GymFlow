
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
  RegistrarPagoNominaAdminResponse,
  CancelarPagoNominaAdminRequest,
  CancelarPagoNominaAdminResponse
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

  // HISTORIAL SALARIAL

  obtenerHistorialSalarial(
    idPersonal: number
  ): Observable<SalarioPersonalAdmin[]> {

    return this.http.get<SalarioPersonalAdmin[]>(
      `${this.apiUrl}/${idPersonal}/salarios`
    );
  }

  // HISTORIAL DE PAGOS

  obtenerHistorialNomina(
    idPersonal: number
  ): Observable<PagoNominaAdmin[]> {

    return this.http.get<PagoNominaAdmin[]>(
      `${this.apiUrl}/${idPersonal}/nomina`
    );
  }

  // CAMBIAR SUELDO

  cambiarSalario(
    idPersonal: number,
    datos: CambiarSalarioAdminRequest
  ): Observable<CambiarSalarioAdminResponse> {

    return this.http.post<CambiarSalarioAdminResponse>(
      `${this.apiUrl}/${idPersonal}/salarios`,
      datos
    );
  }

  // REGISTRAR PAGO

  registrarPagoNomina(
    idPersonal: number,
    datos: RegistrarPagoNominaAdminRequest
  ): Observable<RegistrarPagoNominaAdminResponse> {

    return this.http.post<RegistrarPagoNominaAdminResponse>(
      `${this.apiUrl}/${idPersonal}/nomina`,
      datos
    );
  }

  // CANCELAR PAGO (BAJA LÓGICA DEL REGISTRO)

  cancelarPagoNomina(
    idPersonal: number,
    idPago: number,
    datos: CancelarPagoNominaAdminRequest
  ): Observable<CancelarPagoNominaAdminResponse> {

    return this.http.patch<CancelarPagoNominaAdminResponse>(
      `${this.apiUrl}/${idPersonal}/nomina/${idPago}/cancelacion`,
      datos
    );
  }
}
