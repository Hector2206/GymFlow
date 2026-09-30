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
  CrearEjercicioRequest,
  Ejercicio
} from '../models/ejercicio.model';


type ModoFormulario =
  'crear' |
  'editar';


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

  modoFormulario:
    ModoFormulario = 'crear';

  idEjercicioEditando:
    number | null = null;

  nombre = '';

  descripcion = '';

  imagenUrl = '';

  busqueda = '';

  imagenValida = true;

  cargando = true;

  cargandoEdicion = false;

  guardando = false;

  desactivandoId:
    number | null = null;

  mostrarFormulario = false;

  error = '';

  errorFormulario = '';

  mensajeExito = '';

  constructor(
    private ejercicioService:
      EjercicioService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {}


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

          this.cargando = false;

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

          this.cargando = false;

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


  abrirFormulario(): void {

    this.limpiarFormulario();

    this.modoFormulario =
      'crear';

    this.mostrarFormulario =
      true;

    this.mensajeExito = '';

    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  }


  editarEjercicio(
    ejercicio: Ejercicio
  ): void {

    this.limpiarFormulario();

    this.modoFormulario =
      'editar';

    this.idEjercicioEditando =
      ejercicio.idEjercicio;

    this.mostrarFormulario =
      true;

    this.mensajeExito = '';

    this.cargandoEdicion =
      true;

    this.ejercicioService
      .obtenerEjercicio(
        ejercicio.idEjercicio
      )
      .subscribe({

        next: (
          ejercicioCompleto:
            Ejercicio
        ) => {

          this.nombre =
            ejercicioCompleto.nombre;

          this.descripcion =
            ejercicioCompleto.descripcion
            ?? '';

          this.imagenUrl =
            ejercicioCompleto.imagenUrl
            ?? '';

          this.imagenValida =
            true;

          this.cargandoEdicion =
            false;

          this.changeDetector
            .detectChanges();

          window.scrollTo({
            top: 0,
            behavior: 'smooth'
          });
        },

        error: (error) => {

          console.error(
            'Error al cargar ejercicio:',
            error
          );

          this.cargandoEdicion =
            false;

          this.errorFormulario =
            error.error?.mensaje ??
            'No fue posible cargar los datos del ejercicio.';

          this.changeDetector
            .detectChanges();
        }
      });
  }


  cerrarFormulario(): void {

    this.mostrarFormulario =
      false;

    this.limpiarFormulario();
  }


  limpiarFormulario(): void {

    this.modoFormulario =
      'crear';

    this.idEjercicioEditando =
      null;

    this.nombre = '';

    this.descripcion = '';

    this.imagenUrl = '';

    this.imagenValida = true;

    this.cargandoEdicion = false;

    this.guardando = false;

    this.errorFormulario = '';
  }


  cambioImagen(): void {

    this.imagenValida =
      true;
  }


  guardarEjercicio(): void {

    this.errorFormulario = '';

    this.mensajeExito = '';

    const nombreLimpio =
      this.nombre.trim();

    const descripcionLimpia =
      this.descripcion.trim();

    const imagenLimpia =
      this.imagenUrl.trim();

    if (
      !nombreLimpio
    ) {

      this.errorFormulario =
        'El nombre del ejercicio es obligatorio.';

      return;
    }

    if (
      nombreLimpio.length > 120
    ) {

      this.errorFormulario =
        'El nombre no puede superar los 120 caracteres.';

      return;
    }

    const request:
      CrearEjercicioRequest = {

      nombre:
        nombreLimpio,

      descripcion:
        descripcionLimpia
          ? descripcionLimpia
          : null,

      imagenUrl:
        imagenLimpia
          ? imagenLimpia
          : null
    };

    this.guardando = true;


    if (
      this.modoFormulario ===
      'crear'
    ) {

      this.ejercicioService
        .crearEjercicio(
          request
        )
        .subscribe({

          next: (
            ejercicio:
              Ejercicio
          ) => {

            this.finalizarGuardado(
              ejercicio,
              'crear'
            );
          },

          error: (error) => {

            this.manejarErrorGuardado(
              error
            );
          }
        });

      return;
    }


    if (
      this.idEjercicioEditando ===
      null
    ) {

      this.guardando = false;

      this.errorFormulario =
        'No se encontró el ejercicio que deseas editar.';

      return;
    }


    this.ejercicioService
      .actualizarEjercicio(
        this.idEjercicioEditando,
        request
      )
      .subscribe({

        next: (
          ejercicio:
            Ejercicio
        ) => {

          this.finalizarGuardado(
            ejercicio,
            'editar'
          );
        },

        error: (error) => {

          this.manejarErrorGuardado(
            error
          );
        }
      });
  }


  finalizarGuardado(
    ejercicio: Ejercicio,
    modo: ModoFormulario
  ): void {

    this.guardando = false;

    if (
      modo === 'crear'
    ) {

      this.mensajeExito =
        `Ejercicio "${ejercicio.nombre}" creado correctamente.`;

    } else {

      this.mensajeExito =
        `Ejercicio "${ejercicio.nombre}" actualizado correctamente.`;
    }

    this.mostrarFormulario =
      false;

    this.limpiarFormulario();

    this.recargarListadoActual();

    this.changeDetector
      .detectChanges();
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


  manejarErrorGuardado(
    error: any
  ): void {

    console.error(
      'Error al guardar ejercicio:',
      error
    );

    this.guardando = false;

    if (
      error.status === 400
    ) {

      this.errorFormulario =
        error.error?.mensaje ??
        'Los datos del ejercicio no son válidos.';

    } else if (
      error.status === 401
    ) {

      this.errorFormulario =
        'Tu sesión no es válida. Inicia sesión nuevamente.';

    } else if (
      error.status === 403
    ) {

      this.errorFormulario =
        'No tienes permiso para modificar ejercicios.';

    } else if (
      error.status === 404
    ) {

      this.errorFormulario =
        error.error?.mensaje ??
        'El ejercicio no existe.';

    } else if (
      error.status === 0
    ) {

      this.errorFormulario =
        'No fue posible conectar con el servidor.';

    } else {

      this.errorFormulario =
        'No fue posible guardar el ejercicio.';
    }

    this.changeDetector
      .detectChanges();
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