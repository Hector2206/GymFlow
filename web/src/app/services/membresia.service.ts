
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

export interface MembresiaActiva {
  idMembresia: number;
  nombrePlan: string;
  costoMensual: number;
  costoAnualidad: number;
  descripcion: string;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class MembresiaService {
  private readonly url =
    `${environment.adminApiUrl}/api/membresias/activas`;

  constructor(private http: HttpClient) {}

  obtenerActivas(): Observable<MembresiaActiva[]> {
    return this.http.get<MembresiaActiva[]>(this.url);
  }
}
