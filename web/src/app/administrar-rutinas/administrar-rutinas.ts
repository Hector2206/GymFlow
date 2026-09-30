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
  RutinaService
} from '../services/rutina.service';

import {
  RutinaResumen
} from '../models/rutina.model';

@Component({
  selector: 'app-administrar-rutinas',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl:
    './administrar-rutinas.html',
  styleUrl:
    './administrar-rutinas.css'
})
export class AdministrarRutinas
implements OnInit {

  rutinas:
    RutinaResumen[] = [];

  cargando = true;

  error = '';

  mensajeExito = '';

  mensajeErrorAccion = '';

  eliminandoIdRutina:
    number | null = null;

  constructor(
    private rutinaService:
      RutinaService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {

    const estado =
      history.state as {
        mensaje?: string;
      };

    if (
      estado?.mensaje
    ) {

      this.mensajeExito =
        estado.mensaje;
    }
  }


  ngOnInit(): void {

    this.cargarRutinas();
  }


  cargarRutinas(): void {

    this.cargando = true;

    this.error = '';

    this.mensajeErrorAccion = '';

    this.rutinaService
      .listarRutinas()
      .subscribe({

        next: (
          rutinas:
            RutinaResumen[]
        ) => {

          this.rutinas =
            rutinas ?? [];

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar rutinas:',
            error
          );

          this.cargando =
            false;

          this.rutinas = [];

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar las rutinas.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar las rutinas.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  nuevaRutina(): void {

    this.router.navigate([
      '/entrenador/rutinas/nueva'
    ]);
  }


  editarRutina(
    rutina:
      RutinaResumen
  ): void {

    this.router.navigate([
      '/entrenador/rutinas/editar',
      rutina.idRutina
    ]);
  }


  eliminarRutina(
    rutina:
      RutinaResumen
  ): void {

    if (
      this.eliminandoIdRutina !==
      null
    ) {

      return;
    }

    const confirmar =
      window.confirm(
        `¿Eliminar la rutina "${rutina.nombre}"?\n\n` +
        `Esta acción eliminará también sus días y ejercicios asignados.\n\n` +
        `Esta acción no se puede deshacer.`
      );

    if (
      !confirmar
    ) {

      return;
    }

    this.mensajeExito = '';

    this.mensajeErrorAccion = '';

    this.eliminandoIdRutina =
      rutina.idRutina;

    this.rutinaService
      .eliminarRutina(
        rutina.idRutina
      )
      .subscribe({

        next: (
          respuesta
        ) => {

          this.rutinas =
            this.rutinas.filter(
              item =>
                item.idRutina !==
                rutina.idRutina
            );

          this.mensajeExito =
            respuesta.mensaje ??
            `Rutina "${rutina.nombre}" eliminada correctamente.`;

          this.eliminandoIdRutina =
            null;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al eliminar rutina:',
            error
          );

          this.eliminandoIdRutina =
            null;

          if (
            error.status === 401
          ) {

            this.mensajeErrorAccion =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.mensajeErrorAccion =
              error.error?.mensaje ??
              'No tienes permiso para eliminar esta rutina.';

          } else if (
            error.status === 404
          ) {

            this.mensajeErrorAccion =
              error.error?.mensaje ??
              'La rutina ya no existe.';

          } else if (
            error.status === 0
          ) {

            this.mensajeErrorAccion =
              'No fue posible conectar con el servidor.';

          } else {

            this.mensajeErrorAccion =
              error.error?.mensaje ??
              'No fue posible eliminar la rutina.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  estaEliminando(
    rutina:
      RutinaResumen
  ): boolean {

    return (
      this.eliminandoIdRutina ===
      rutina.idRutina
    );
  }


  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}