
import { Injectable } from '@angular/core';

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
  PersonalAdmin,
  CrearPersonalAdminRequest,
  CrearPersonalAdminResponse,
  EditarPersonalAdminRequest,
  EditarPersonalAdminResponse,
  BajaPersonalAdminRequest,
  BajaPersonalAdminResponse
} from '../models/admin-personal.model';

@Injectable({
  providedIn: 'root'
})
export class AdminPersonalService {

  private readonly apiUrl =
    `${environment.adminApiUrl}/api/admin/personal`;

  constructor(
    private http: HttpClient
  ) {}

  // CONSULTAR TODOS LOS EMPLEADOS
  // Incluye entrenadores y recepcionistas
  // activos e inactivos

  obtenerPersonal(): Observable<PersonalAdmin[]> {

    return this.http.get<PersonalAdmin[]>(
      this.apiUrl
    );
  }

  // CONSULTAR UN EMPLEADO POR ID PERSONAL

  obtenerPersonalPorId(
    idPersonal: number
  ): Observable<PersonalAdmin> {

    return this.http.get<PersonalAdmin>(
      `${this.apiUrl}/${idPersonal}`
    );
  }

  // REGISTRAR UN NUEVO EMPLEADO
  // Puesto: Entrenador o Recepcionista

  crearPersonal(
    datos: CrearPersonalAdminRequest
  ): Observable<CrearPersonalAdminResponse> {

    return this.http.post<CrearPersonalAdminResponse>(
      this.apiUrl,
      datos
    );
  }

  // EDITAR INFORMACION DEL EMPLEADO
  // No modifica sueldo, puesto ni contrasena

  editarPersonal(
    idPersonal: number,
    datos: EditarPersonalAdminRequest
  ): Observable<EditarPersonalAdminResponse> {

    return this.http.put<EditarPersonalAdminResponse>(
      `${this.apiUrl}/${idPersonal}`,
      datos
    );
  }

  // DAR DE BAJA LOGICA A UN EMPLEADO
  // El backend registra la baja y su motivo

  darDeBajaPersonal(
    idPersonal: number,
    motivo: string
  ): Observable<BajaPersonalAdminResponse> {

    const datos: BajaPersonalAdminRequest = {
      motivo: motivo.trim()
    };

    return this.http.patch<BajaPersonalAdminResponse>(
      `${this.apiUrl}/${idPersonal}/baja`,
      datos
    );
  }
}
