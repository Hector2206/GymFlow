import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { Usuario } from '../models/usuario.model';

@Injectable({
  providedIn: 'root'
})
export class UsuarioService {

  constructor(private http: HttpClient) {}

  obtenerUsuarioActual(): Observable<Usuario> {
    return this.http.get<Usuario>(
      `${environment.usuarioConsultaUrl}/api/usuarios/me`
    );
  }
}