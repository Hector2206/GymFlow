
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

import {
  MiMembresiaResponse
} from '../models/mi-membresia.model';

@Injectable({
  providedIn: 'root'
})
export class MiMembresiaService {
  private readonly url =
    `${environment.clienteAltaUrl}/api/clientes/mi-membresia`;

  constructor(private http: HttpClient) {}

  obtenerMiMembresia(): Observable<MiMembresiaResponse> {
    return this.http.get<MiMembresiaResponse>(this.url);
  }
}
