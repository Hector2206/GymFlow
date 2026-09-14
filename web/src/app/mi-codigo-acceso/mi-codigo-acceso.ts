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
  CodigoAccesoService,
  MiCodigoAccesoResponse
} from '../services/codigo-acceso.service';

@Component({
  selector: 'app-mi-codigo-acceso',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './mi-codigo-acceso.html',
  styleUrl: './mi-codigo-acceso.css'
})
export class MiCodigoAcceso implements OnInit {

  datos:
    MiCodigoAccesoResponse | null = null;

  cargando = true;

  error = '';

  constructor(
    private router: Router,
    private codigoAccesoService: CodigoAccesoService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {

    this.cargarCodigo();
  }

  cargarCodigo(): void {

    this.cargando = true;
    this.error = '';

    this.codigoAccesoService
      .obtenerMiCodigo()
      .subscribe({

        next: (respuesta) => {

          this.datos =
            respuesta;

          this.cargando = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al obtener código de acceso:',
            error
          );

          this.cargando = false;

          if (
            error.status === 404
          ) {

            this.error =
              'No se encontró un código de acceso para tu cuenta.';

          } else if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar este código.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar tu código de acceso.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}