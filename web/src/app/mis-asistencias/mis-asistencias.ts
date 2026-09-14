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
  AsistenciaCliente,
  AsistenciaService,
  MisAsistenciasResponse
} from '../services/asistencia.service';

@Component({
  selector: 'app-mis-asistencias',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './mis-asistencias.html',
  styleUrl: './mis-asistencias.css'
})
export class MisAsistencias implements OnInit {

  asistencias: AsistenciaCliente[] = [];

  cargando = true;

  error = '';

  constructor(
    private router: Router,
    private asistenciaService: AsistenciaService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {

    this.cargarAsistencias();
  }

  cargarAsistencias(): void {

    this.cargando = true;
    this.error = '';

    this.asistenciaService
      .consultarMisAsistencias()
      .subscribe({

        next: (
          respuesta: MisAsistenciasResponse
        ) => {

          this.asistencias =
            respuesta.asistencias ?? [];

          this.cargando = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar mis asistencias:',
            error
          );

          this.cargando = false;

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar tus asistencias.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar tus asistencias.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  formatearFecha(
    fechaHora: string
  ): string {

    return new Date(
      fechaHora
    ).toLocaleDateString(
      'es-MX',
      {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }
    );
  }

  formatearHora(
    fechaHora: string
  ): string {

    return new Date(
      fechaHora
    ).toLocaleTimeString(
      'es-MX',
      {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }
    );
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}