import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import {
  UsuarioService
} from '../services/usuario.service';

import {
  AuthService
} from '../services/auth.service';

import {
  Usuario
} from '../models/usuario.model';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home implements OnInit {

  usuario: Usuario | null = null;

  cargando = true;
  error = '';
  mensaje = '';

  constructor(
    private usuarioService: UsuarioService,
    private authService: AuthService,
    private router: Router,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarUsuario();
  }

  cargarUsuario(): void {

    this.cargando = true;
    this.error = '';

    this.usuarioService
      .obtenerUsuarioActual()
      .subscribe({

        next: (usuario) => {

          this.usuario = usuario;

          localStorage.setItem(
            'usuario',
            JSON.stringify(usuario)
          );

          this.cargando = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al obtener usuario:',
            error
          );

          this.cargando = false;

          if (error.status === 401) {

            this.authService
              .cerrarSesion();

            this.router.navigate([
              '/login'
            ]);

            return;
          }

          this.error =
            'No se pudieron cargar los datos del usuario.';

          this.changeDetector
            .detectChanges();
        }
      });
  }

  esRecepcionista(): boolean {

    return this.usuario?.role
      ?.toLowerCase() ===
      'recepcionista';
  }

  esCliente(): boolean {

    return this.usuario?.role
      ?.toLowerCase() ===
      'cliente';
  }

  esAdministrador(): boolean {

    return this.usuario?.role
      ?.toLowerCase() ===
      'administrador';
  }

  esEntrenador(): boolean {

    return this.usuario?.role
      ?.toLowerCase() ===
      'entrenador';
  }

  irPerfil(): void {

    this.router.navigate([
      '/perfil'
    ]);
  }

  irRegistrarCliente(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'No tienes permisos para registrar clientes.';

      this.changeDetector
        .detectChanges();

      return;
    }

    this.router.navigate([
      '/registrar-cliente'
    ]);
  }

  proximamente(
    opcion: string
  ): void {

    this.mensaje =
      `${opcion} estará disponible próximamente.`;

    this.changeDetector
      .detectChanges();

    setTimeout(() => {

      this.mensaje = '';

      this.changeDetector
        .detectChanges();

    }, 3000);
  }

  cerrarSesion(): void {

    this.authService
      .cerrarSesion();

    this.router.navigate([
      '/login'
    ]);
  }
}