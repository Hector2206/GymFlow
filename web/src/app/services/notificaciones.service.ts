
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';

import { environment } from '../../environments/environment';

import {
  NotificacionGymFlow,
  ContadorNotificaciones,
  LecturaNotificacionResponse
} from '../models/notificacion.model';

@Injectable({
  providedIn: 'root'
})
export class NotificacionesService {
  private readonly apiUrl =
    `${environment.adminApiUrl}/api/notificaciones`;

  constructor(private http: HttpClient) {}

  obtenerNotificaciones(): Observable<NotificacionGymFlow[]> {
    return this.http.get<NotificacionGymFlow[]>(
      this.apiUrl
    );
  }

  obtenerNoLeidas(): Observable<number> {
    return this.http.get<ContadorNotificaciones>(
      `${this.apiUrl}/no-leidas`
    ).pipe(
      map(respuesta => {
        if (
          !Number.isInteger(respuesta?.noLeidas) ||
          respuesta.noLeidas < 0
        ) {
          throw new Error(
            'El contador recibido no es válido.'
          );
        }

        return respuesta.noLeidas;
      })
    );
  }

  marcarComoLeida(
    idNotificacion: number
  ): Observable<LecturaNotificacionResponse> {
    if (
      !Number.isSafeInteger(idNotificacion) ||
      idNotificacion <= 0
    ) {
      throw new Error('ID de notificación inválido.');
    }

    return this.http.patch<LecturaNotificacionResponse>(
      `${this.apiUrl}/${idNotificacion}/lectura`,
      null
    );
  }
}
