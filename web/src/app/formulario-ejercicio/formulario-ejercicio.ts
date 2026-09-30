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
  ActivatedRoute,
  Router
} from '@angular/router';

import {
  EjercicioService
} from '../services/ejercicio.service';

import {
  ActualizarEjercicioRequest,
  CrearEjercicioRequest,
  Ejercicio
} from '../models/ejercicio.model';

@Component({
  selector: 'app-formulario-ejercicio',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl:
    './formulario-ejercicio.html',
  styleUrl:
    './formulario-ejercicio.css'
})
export class FormularioEjercicio
implements OnInit {

  esEdicion = false;

  idEjercicio:
    number | null = null;

  nombre = '';

  descripcion = '';

  imagenUrl = '';

  estadoEjercicio = true;

  imagenValida = true;

  cargando = true;

  guardando = false;

  error = '';

  errorFormulario = '';

  constructor(
    private route:
      ActivatedRoute,
    private router:
      Router,
    private ejercicioService:
      EjercicioService,
    private changeDetector:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {

    const idParametro =
      this.route.snapshot
        .paramMap
        .get('id');

    if (
      idParametro === null
    ) {

      this.esEdicion = false;

      this.cargando = false;

      return;
    }

    const id =
      Number(
        idParametro
      );

    if (
      !Number.isInteger(id) ||
      id <= 0
    ) {

      this.error =
        'El ejercicio solicitado no es válido.';

      this.cargando = false;

      return;
    }

    this.esEdicion = true;

    this.idEjercicio = id;

    this.cargarEjercicio();
  }


  cargarEjercicio(): void {

    if (
      this.idEjercicio === null
    ) {

      return;
    }

    this.cargando = true;

    this.error = '';

    this.ejercicioService
      .obtenerEjercicio(
        this.idEjercicio
      )
      .subscribe({

        next: (
          ejercicio:
            Ejercicio
        ) => {

          this.nombre =
            ejercicio.nombre;

          this.descripcion =
            ejercicio.descripcion
            ?? '';

          this.imagenUrl =
            ejercicio.imagenUrl
            ?? '';

          this.estadoEjercicio =
            ejercicio.estado;

          this.imagenValida =
            true;

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al cargar ejercicio:',
            error
          );

          this.cargando =
            false;

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para editar ejercicios.';

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
              'No fue posible cargar el ejercicio.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  cambioImagen(): void {

    this.imagenValida =
      true;
  }


  guardarEjercicio(): void {

    this.errorFormulario = '';

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


    if (
      !this.esEdicion
    ) {

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

      this.ejercicioService
        .crearEjercicio(
          request
        )
        .subscribe({

          next: (
            ejercicio:
              Ejercicio
          ) => {

            this.router.navigate(
              [
                '/entrenador/ejercicios'
              ],
              {
                state: {
                  mensaje:
                    `Ejercicio "${ejercicio.nombre}" creado correctamente.`
                }
              }
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
      this.idEjercicio === null
    ) {

      this.errorFormulario =
        'No se encontró el ejercicio que deseas editar.';

      return;
    }


    const request:
      ActualizarEjercicioRequest = {

      nombre:
        nombreLimpio,

      descripcion:
        descripcionLimpia
          ? descripcionLimpia
          : null,

      imagenUrl:
        imagenLimpia
          ? imagenLimpia
          : null,

      estado:
        this.estadoEjercicio
    };

    this.guardando = true;

    this.ejercicioService
      .actualizarEjercicio(
        this.idEjercicio,
        request
      )
      .subscribe({

        next: (
          ejercicio:
            Ejercicio
        ) => {

          this.router.navigate(
            [
              '/entrenador/ejercicios'
            ],
            {
              state: {
                mensaje:
                  `Ejercicio "${ejercicio.nombre}" actualizado correctamente.`
              }
            }
          );
        },

        error: (error) => {

          this.manejarErrorGuardado(
            error
          );
        }
      });
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


  volverEjercicios(): void {

    this.router.navigate([
      '/entrenador/ejercicios'
    ]);
  }
}