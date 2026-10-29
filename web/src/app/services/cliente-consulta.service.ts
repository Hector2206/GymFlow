
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

// ==========================================
// MODELO DE CLIENTE PARA RECEPCIÓN
// ==========================================

export interface ClienteResumen {
  idCliente: number;
  nombreCompleto: string;

  // Entrenador asignado
  idEntrenador?: number | null;
  nombreEntrenador?: string | null;

  // Membresía actual del cliente
  idMembresia?: number | null;
  nombrePlan?: string | null;
}

// ==========================================
// SERVICIO DE CONSULTA DE CLIENTES
// ==========================================

@Injectable({
  providedIn: 'root'
})
export class ClienteConsultaService {

  private readonly apiUrl =
    `${environment.clienteAltaUrl}/api/clientes`;

  constructor(
    private readonly http: HttpClient
  ) {}

  obtenerClientes(): Observable<ClienteResumen[]> {
    return this.http.get<ClienteResumen[]>(
      this.apiUrl
    );
  }
}
