import {
  ChangeDetectorRef,
  Component
} from '@angular/core';

import {
  CommonModule
} from '@angular/common';

import {
  FormsModule
} from '@angular/forms';

import {
  Router
} from '@angular/router';

import {
  AsistenciaCliente,
  AsistenciaService,
  HistorialAsistenciasResponse
} from '../services/asistencia.service';

@Component({
  selector: 'app-historial-asistencias',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './historial-asistencias.html',
  styleUrl: './historial-asistencias.css'
})
export class HistorialAsistencias {

  idCliente: number | null = null;

  asistencias: AsistenciaCliente[] = [];

  cargando = false;

  error = '';

  constructor(
    private router: Router,
    private asistenciaService: AsistenciaService,
    private changeDetector: ChangeDetectorRef
  ) {}

  consultarAsistencias(): void {

    this.error = '';
    this.asistencias = [];

    if (
      this.idCliente === null ||
      this.idCliente <= 0
    ) {

      this.error =
        'Ingresa un ID de cliente válido.';

      this.changeDetector
        .detectChanges();

      return;
    }

    this.cargando = true;

    this.changeDetector
      .detectChanges();

    this.asistenciaService
      .consultarPorCliente(
        this.idCliente
      )
      .subscribe({

        next: (
          respuesta: HistorialAsistenciasResponse
        ) => {

          this.asistencias =
            respuesta.asistencias ?? [];

          this.cargando = false;

          if (
            this.asistencias.length === 0
          ) {

            this.error =
              'Este cliente no tiene asistencias registradas.';
          }

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar asistencias:',
            error
          );

          this.cargando = false;

          if (
            error.status === 404
          ) {

            this.error =
              'No se encontraron asistencias para este cliente.';

          } else if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar asistencias.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible consultar las asistencias.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  formatearFecha(
    fechaHora: string
  ): string {

    if (!fechaHora) {
      return 'Sin fecha';
    }

    const fecha =
      new Date(fechaHora);

    return fecha.toLocaleDateString(
      'es-MX',
      {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }
    );
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}