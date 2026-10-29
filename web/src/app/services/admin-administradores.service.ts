import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  Administrador,
  CrearAdministradorRequest,
  EditarAdministradorRequest,
  BajaAdministradorRequest,
  OperacionAdministradorResponse
} from '../models/admin-administrador.model';

@Injectable({ providedIn: 'root' })
export class AdminAdministradoresService {
  private readonly apiUrl = `${environment.adminApiUrl}/api/admin/administradores`;

  constructor(private readonly http: HttpClient) {}

  listar(): Observable<Administrador[]> {
    return this.http.get<Administrador[]>(this.apiUrl);
  }

  obtenerPorId(idUsuario: number): Observable<Administrador> {
    return this.http.get<Administrador>(`${this.apiUrl}/${idUsuario}`);
  }

  crear(datos: CrearAdministradorRequest): Observable<OperacionAdministradorResponse> {
    return this.http.post<OperacionAdministradorResponse>(this.apiUrl, datos);
  }

  editar(
    idUsuario: number,
    datos: EditarAdministradorRequest
  ): Observable<OperacionAdministradorResponse> {
    return this.http.put<OperacionAdministradorResponse>(
      `${this.apiUrl}/${idUsuario}`,
      datos
    );
  }

  darDeBaja(
    idUsuario: number,
    datos: BajaAdministradorRequest
  ): Observable<OperacionAdministradorResponse> {
    return this.http.patch<OperacionAdministradorResponse>(
      `${this.apiUrl}/${idUsuario}/baja`,
      datos
    );
  }
}
