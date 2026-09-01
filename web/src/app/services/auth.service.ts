import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

import { environment } from '../../environments/environment';
import { LoginResponse } from '../models/login-response.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  constructor(private http: HttpClient) {}

  login(correo: string, password: string): Observable<LoginResponse> {

    return this.http
      .post<LoginResponse>(
        `${environment.authLocalUrl}/api/auth/login`,
        {
          correo,
          password
        }
      )
      .pipe(
        tap((response) => {

          localStorage.setItem(
            'token',
            response.token
          );

          if (response.usuario) {
            localStorage.setItem(
              'usuario',
              JSON.stringify(response.usuario)
            );
          }

        })
      );
  }

  obtenerToken(): string | null {
    return localStorage.getItem('token');
  }

  estaAutenticado(): boolean {
    return !!this.obtenerToken();
  }

  cerrarSesion(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('usuario');
  }
}