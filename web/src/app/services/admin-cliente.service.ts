
import { Injectable } from '@angular/core';

import {
  HttpClient,
  HttpParams
} from '@angular/common/http';

import { Observable } from 'rxjs';

import {
  environment
} from '../../environments/environment';

import {
  ClienteAdmin,
  BuscarClientesAdminFiltros
} from '../models/admin-cliente.model';

@Injectable({
  providedIn: 'root'
})
export class AdminClienteService {

  private readonly apiUrl =
    `${environment.adminApiUrl}/api/admin/clientes`;

  constructor(
    private http: HttpClient
  ) {}

  // Consultar clientes con filtros opcionales
  buscarClientes(
    filtros: BuscarClientesAdminFiltros = {}
  ): Observable<ClienteAdmin[]> {

    let params = new HttpParams();

    // Buscar por nombre
    const nombre = filtros.nombre?.trim();

    if (nombre) {
      params = params.set('nombre', nombre);
    }

    // Buscar por correo
    const correo = filtros.correo?.trim();

    if (correo) {
      params = params.set('correo', correo);
    }

    // Filtrar por estatus de la cuenta
    if (filtros.estatus) {
      params = params.set(
        'estatus',
        filtros.estatus
      );
    }

    // Filtrar por vigencia de membresia
    if (filtros.vigencia) {
      params = params.set(
        'vigencia',
        filtros.vigencia
      );
    }

    // Filtrar por ID de membresia
    if (filtros.idMembresia !== undefined) {
      params = params.set(
        'idMembresia',
        filtros.idMembresia.toString()
      );
    }

    return this.http.get<ClienteAdmin[]>(
      this.apiUrl,
      { params }
    );
  }

  // Consultar todos los clientes sin filtros
  obtenerTodos(): Observable<ClienteAdmin[]> {

    return this.buscarClientes();
  }
}
