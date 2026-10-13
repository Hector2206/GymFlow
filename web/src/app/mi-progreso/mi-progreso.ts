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
  ProgresoService
} from '../services/progreso.service';

import {
  Progreso
} from '../models/progreso.model';

@Component({
  selector: 'app-mi-progreso',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './mi-progreso.html',
  styleUrl: './mi-progreso.css'
})
export class MiProgreso
implements OnInit {

  progresos: Progreso[] = [];

  cargando = true;

  error = '';

  constructor(
    private progresoService:
      ProgresoService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {

    this.cargarProgreso();
  }


  cargarProgreso(): void {

    this.cargando = true;

    this.error = '';

    this.progresos = [];

    this.progresoService
      .obtenerMiProgreso()
      .subscribe({

        next: (
          progresos: Progreso[]
        ) => {

          this.progresos =
            progresos;

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (
          error
        ) => {

          console.error(
            'Error al consultar mi progreso:',
            error
          );

          this.cargando =
            false;

          if (
            error.status === 401
          ) {

            this.router.navigate(
              [
                '/login'
              ],
              {
                queryParams: {
                  returnUrl:
                    '/mi-progreso'
                }
              }
            );

            return;
          }

          if (
            error.status === 403
          ) {

            this.error =
              'Esta sección está disponible únicamente para clientes.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar tu progreso en este momento.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  formatearFecha(
    fecha: string
  ): string {

    if (
      !fecha
    ) {

      return '-';
    }

    const fechaRegistro =
      new Date(fecha);

    if (
      Number.isNaN(
        fechaRegistro.getTime()
      )
    ) {

      return fecha;
    }

    return fechaRegistro
      .toLocaleString(
        'es-MX',
        {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        }
      );
  }


  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}