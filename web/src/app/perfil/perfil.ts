import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import {
  CommonModule
} from '@angular/common';

import {
  Router
} from '@angular/router';

import {
  UsuarioService
} from '../services/usuario.service';

import {
  AuthService
} from '../services/auth.service';

import {
  SistemaService
} from '../services/sistema.service';

import {
  Usuario
} from '../models/usuario.model';

@Component({
  selector: 'app-perfil',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './perfil.html',
  styleUrl: './perfil.css'
})
export class Perfil implements OnInit {

  usuario:
    Usuario | null = null;

  versionSistema = '';

  cargando = true;

  cargandoVersion = true;

  error = '';

  constructor(
    private usuarioService:
      UsuarioService,
    private authService:
      AuthService,
    private sistemaService:
      SistemaService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {

    this.cargarUsuario();

    this.cargarVersionSistema();
  }


  cargarUsuario(): void {

    this.usuarioService
      .obtenerUsuarioActual()
      .subscribe({

        next: (
          usuario
        ) => {

          this.usuario =
            usuario;

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (
          error
        ) => {

          console.error(
            'Error al cargar perfil:',
            error
          );

          this.cargando =
            false;

          if (
            error.status === 401
          ) {

            this.authService
              .cerrarSesion();

            this.router.navigate([
              '/login'
            ]);

            return;
          }

          this.error =
            'No se pudo cargar la información del perfil.';

          this.changeDetector
            .detectChanges();
        }
      });
  }


  cargarVersionSistema(): void {

    this.cargandoVersion =
      true;

    this.sistemaService
      .obtenerVersionSistema()
      .subscribe({

        next: (
          respuesta
        ) => {

          this.versionSistema =
            respuesta.version ?? '';

          this.cargandoVersion =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (
          error
        ) => {

          console.error(
            'Error al consultar versión del sistema:',
            error
          );

          this.versionSistema = '';

          this.cargandoVersion =
            false;

          this.changeDetector
            .detectChanges();
        }
      });
  }


  volver(): void {

    this.router.navigate([
      '/home'
    ]);
  }


  cerrarSesion(): void {

    this.authService
      .cerrarSesion();

    this.router.navigate([
      '/login'
    ]);
  }
}