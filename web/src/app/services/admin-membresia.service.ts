
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

export interface AdminMembresia {
  idMembresia: number;
  nombrePlan: string;
  descripcion: string;
  costoMensual: number;
  costoAnualidad: number;
  activo: boolean;
}

export interface GuardarMembresiaRequest {
  nombrePlan: string;
  descripcion: string;
  costoMensual: number;
  costoAnualidad: number;
}

export interface HistorialPrecio {
  idHistorial: number;
  idMembresia: number;
  costoMensual: number;
  costoAnualidad: number;
  registradoEn: string;
  idUsuarioApp: number | null;
  origen: string;
}

@Injectable({
  providedIn: 'root'
})
export class AdminMembresiaService {
  private readonly url =
    `${environment.adminApiUrl}/api/admin/membresias`;

  constructor(private http: HttpClient) {}

  obtenerCatalogo(): Observable<AdminMembresia[]> {
    return this.http.get<AdminMembresia[]>(this.url);
  }

  crear(
    datos: GuardarMembresiaRequest
  ): Observable<unknown> {
    return this.http.post(this.url, datos);
  }

  editar(
    id: number,
    datos: GuardarMembresiaRequest
  ): Observable<unknown> {
    return this.http.put(`${this.url}/${id}`, datos);
  }

  cambiarEstado(
    id: number,
    activo: boolean
  ): Observable<unknown> {
    return this.http.patch(
      `${this.url}/${id}/estado`,
      { activo }
    );
  }

  obtenerHistorial(
    id: number
  ): Observable<HistorialPrecio[]> {
    return this.http.get<HistorialPrecio[]>(
      `${this.url}/${id}/historial-precios`
    );
  }
}
