import {
  ChangeDetectorRef,
  Component,
  OnInit
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
  EjercicioService
} from '../services/ejercicio.service';

import {
  Ejercicio
} from '../models/ejercicio.model';

@Component({
  selector: 'app-administrar-ejercicios',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl:
    './administrar-ejercicios.html',
  styleUrl:
    './administrar-ejercicios.css'
})
export class AdministrarEjercicios
implements OnInit {

  ejercicios: Ejercicio[] = [];

  busqueda = '';

  cargando = true;

  desactivandoId:
    number | null = null;

  error = '';

  mensajeExito = '';

  constructor(
    private ejercicioService:
      EjercicioService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {

    const estadoNavegacion =
      history.state as {
        mensaje?: string;
      };

    if (
      estadoNavegacion?.mensaje
    ) {

      this.mensajeExito =
        estadoNavegacion.mensaje;
    }
  }


  ngOnInit(): void {

    this.cargarEjercicios();
  }


  cargarEjercicios(): void {

    this.cargando = true;

    this.error = '';

    this.ejercicioService
      .listarEjercicios()
      .subscribe({

        next: (
          ejercicios: Ejercicio[]
        ) => {

          this.ejercicios =
            ejercicios ?? [];

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar ejercicios:',
            error
          );

          this.cargando = false;

          this.ejercicios = [];

          this.manejarErrorListado(
            error
          );

          this.changeDetector
            .detectChanges();
        }
      });
  }


  buscarEjercicios(): void {

    const termino =
      this.busqueda.trim();

    this.mensajeExito = '';

    if (
      !termino
    ) {

      this.cargarEjercicios();

      return;
    }

    this.cargando = true;

    this.error = '';

    this.ejercicioService
      .buscarEjercicios(
        termino
      )
      .subscribe({

        next: (
          ejercicios: Ejercicio[]
        ) => {

          this.ejercicios =
            ejercicios ?? [];

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al buscar ejercicios:',
            error
          );

          this.cargando = false;

          this.ejercicios = [];

          if (
            error.status === 400
          ) {

            this.error =
              error.error?.mensaje ??
              'La búsqueda no es válida.';

          } else {

            this.manejarErrorListado(
              error
            );
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  limpiarBusqueda(): void {

    this.busqueda = '';

    this.cargarEjercicios();
  }


  nuevoEjercicio(): void {

    this.router.navigate([
      '/entrenador/ejercicios/nuevo'
    ]);
  }


  editarEjercicio(
    ejercicio: Ejercicio
  ): void {

    this.router.navigate([
      '/entrenador/ejercicios/editar',
      ejercicio.idEjercicio
    ]);
  }


  desactivarEjercicio(
    ejercicio: Ejercicio
  ): void {

    if (
      !ejercicio.estado
    ) {

      return;
    }

    const confirmar =
      window.confirm(
        `¿Deseas desactivar el ejercicio "${ejercicio.nombre}"?`
      );

    if (
      !confirmar
    ) {

      return;
    }

    this.mensajeExito = '';

    this.error = '';

    this.desactivandoId =
      ejercicio.idEjercicio;

    this.ejercicioService
      .desactivarEjercicio(
        ejercicio.idEjercicio
      )
      .subscribe({

        next: () => {

          this.desactivandoId =
            null;

          this.mensajeExito =
            `Ejercicio "${ejercicio.nombre}" desactivado correctamente.`;

          this.recargarListadoActual();

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al desactivar ejercicio:',
            error
          );

          this.desactivandoId =
            null;

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para desactivar ejercicios.';

          } else if (
            error.status === 404
          ) {

            this.error =
              error.error?.mensaje ??
              'El ejercicio no existe.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible desactivar el ejercicio.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  recargarListadoActual(): void {

    if (
      this.busqueda.trim()
    ) {

      this.buscarEjercicios();

      return;
    }

    this.cargarEjercicios();
  }


  manejarErrorListado(
    error: any
  ): void {

    if (
      error.status === 401
    ) {

      this.error =
        'Tu sesión no es válida. Inicia sesión nuevamente.';

    } else if (
      error.status === 403
    ) {

      this.error =
        'No tienes permiso para consultar ejercicios.';

    } else if (
      error.status === 0
    ) {

      this.error =
        'No fue posible conectar con el servidor.';

    } else {

      this.error =
        'No fue posible cargar los ejercicios.';
    }
  }


  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}