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
  forkJoin
} from 'rxjs';

import {
  RutinaService
} from '../services/rutina.service';

import {
  EntrenadorService
} from '../services/entrenador.service';

import {
  EjercicioService
} from '../services/ejercicio.service';

import {
  CrearRutinaRequest,
  RutinaDetalle,
  RutinaGuardadaResponse
} from '../models/rutina.model';

import {
  ClienteAsignado,
  ClientesEntrenadorResponse
} from '../models/cliente-asignado.model';

import {
  Ejercicio
} from '../models/ejercicio.model';


interface EjercicioFormulario {

  idEjercicio:
    number | null;

  series:
    number | null;

  repeticiones:
    number | null;

  orden: number;
}


interface DiaFormulario {

  dia: string;

  corto: string;

  ejercicios:
    EjercicioFormulario[];
}


@Component({
  selector: 'app-formulario-rutina',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl:
    './formulario-rutina.html',
  styleUrl:
    './formulario-rutina.css'
})
export class FormularioRutina
implements OnInit {

  esEdicion = false;

  idRutina:
    number | null = null;

  clientesAsignados:
    ClienteAsignado[] = [];

  ejerciciosDisponibles:
    Ejercicio[] = [];

  diasRutina:
    DiaFormulario[] =
      this.crearSemanaVacia();

  diaSeleccionado =
    'Lunes';

  idClienteSeleccionado:
    number | null = null;

  nombreRutina = '';

  descripcionRutina = '';

  cargando = true;

  guardando = false;

  error = '';

  errorFormulario = '';

  constructor(
    private route:
      ActivatedRoute,
    private router:
      Router,
    private rutinaService:
      RutinaService,
    private entrenadorService:
      EntrenadorService,
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

      this.cargarNuevaRutina();

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
        'La rutina solicitada no es válida.';

      this.cargando = false;

      return;
    }

    this.esEdicion = true;

    this.idRutina = id;

    this.cargarRutinaExistente();
  }


  crearSemanaVacia():
    DiaFormulario[] {

    return [
      {
        dia: 'Lunes',
        corto: 'Lun',
        ejercicios: []
      },
      {
        dia: 'Martes',
        corto: 'Mar',
        ejercicios: []
      },
      {
        dia: 'Miércoles',
        corto: 'Mié',
        ejercicios: []
      },
      {
        dia: 'Jueves',
        corto: 'Jue',
        ejercicios: []
      },
      {
        dia: 'Viernes',
        corto: 'Vie',
        ejercicios: []
      },
      {
        dia: 'Sábado',
        corto: 'Sáb',
        ejercicios: []
      },
      {
        dia: 'Domingo',
        corto: 'Dom',
        ejercicios: []
      }
    ];
  }


  cargarNuevaRutina(): void {

    this.cargando = true;

    this.error = '';

    this.diasRutina =
      this.crearSemanaVacia();

    forkJoin({

      clientes:
        this.entrenadorService
          .obtenerMisClientes(),

      ejercicios:
        this.ejercicioService
          .listarEjercicios()

    })
      .subscribe({

        next: (
          respuesta
        ) => {

          this.aplicarClientes(
            respuesta.clientes
          );

          this.ejerciciosDisponibles =
            respuesta.ejercicios
            ?? [];

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          this.manejarErrorCarga(
            error
          );
        }
      });
  }


  cargarRutinaExistente(): void {

    if (
      this.idRutina === null
    ) {

      return;
    }

    this.cargando = true;

    this.error = '';

    forkJoin({

      clientes:
        this.entrenadorService
          .obtenerMisClientes(),

      ejercicios:
        this.ejercicioService
          .listarEjercicios(),

      rutina:
        this.rutinaService
          .obtenerRutinaPorId(
            this.idRutina
          )

    })
      .subscribe({

        next: (
          respuesta
        ) => {

          this.aplicarClientes(
            respuesta.clientes
          );

          this.ejerciciosDisponibles =
            respuesta.ejercicios
            ?? [];

          this.aplicarRutina(
            respuesta.rutina
          );

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          this.manejarErrorCarga(
            error
          );
        }
      });
  }


  aplicarClientes(
    respuesta:
      ClientesEntrenadorResponse
  ): void {

    this.clientesAsignados =
      respuesta.clientes
      ?? [];
  }


  aplicarRutina(
    rutina:
      RutinaDetalle
  ): void {

    this.idClienteSeleccionado =
      rutina.idCliente;

    this.nombreRutina =
      rutina.nombre;

    this.descripcionRutina =
      rutina.descripcion
      ?? '';

    this.diasRutina =
      this.crearSemanaVacia();

    for (
      const diaGuardado
      of rutina.dias ?? []
    ) {

      const diaFormulario =
        this.diasRutina.find(
          dia =>
            this.normalizarDia(
              dia.dia
            ) ===
            this.normalizarDia(
              diaGuardado.dia
            )
        );

      if (
        !diaFormulario
      ) {

        continue;
      }

      diaFormulario.ejercicios =
        (diaGuardado.ejercicios ?? [])
          .map(
            ejercicio => ({

              idEjercicio:
                ejercicio.idEjercicio,

              series:
                ejercicio.series,

              repeticiones:
                ejercicio.repeticiones,

              orden:
                ejercicio.orden
            })
          )
          .sort(
            (
              a,
              b
            ) =>
              a.orden -
              b.orden
          );
    }

    const primerDiaConRutina =
      this.diasRutina.find(
        dia =>
          dia.ejercicios.length > 0
      );

    this.diaSeleccionado =
      primerDiaConRutina?.dia
      ?? 'Lunes';
  }


  normalizarDia(
    dia: string
  ): string {

    return dia
      .normalize('NFD')
      .replace(
        /[\u0300-\u036f]/g,
        ''
      )
      .trim()
      .toLowerCase();
  }


  seleccionarDia(
    dia: DiaFormulario
  ): void {

    this.diaSeleccionado =
      dia.dia;

    this.errorFormulario = '';

    this.changeDetector
      .detectChanges();
  }


  esDiaSeleccionado(
    dia: DiaFormulario
  ): boolean {

    return (
      this.normalizarDia(
        dia.dia
      ) ===
      this.normalizarDia(
        this.diaSeleccionado
      )
    );
  }


  obtenerDiaSeleccionado():
    DiaFormulario {

    return (
      this.diasRutina.find(
        dia =>
          this.esDiaSeleccionado(
            dia
          )
      )
      ?? this.diasRutina[0]
    );
  }


  obtenerIndiceDiaSeleccionado():
    number {

    const indice =
      this.diasRutina.findIndex(
        dia =>
          this.esDiaSeleccionado(
            dia
          )
      );

    return indice >= 0
      ? indice
      : 0;
  }


  tieneEntrenamiento(
    dia: DiaFormulario
  ): boolean {

    return (
      dia.ejercicios.length > 0
    );
  }


  agregarEjercicio(): void {

    this.errorFormulario = '';

    const dia =
      this.obtenerDiaSeleccionado();

    dia.ejercicios.push({

      idEjercicio: null,

      series: null,

      repeticiones: null,

      orden:
        dia.ejercicios.length + 1
    });

    this.changeDetector
      .detectChanges();
  }


  eliminarEjercicio(
    indiceEjercicio: number
  ): void {

    const dia =
      this.obtenerDiaSeleccionado();

    dia.ejercicios.splice(
      indiceEjercicio,
      1
    );

    this.actualizarOrdenes(
      dia
    );

    this.changeDetector
      .detectChanges();
  }


  moverEjercicioArriba(
    indiceEjercicio: number
  ): void {

    if (
      indiceEjercicio <= 0
    ) {

      return;
    }

    const dia =
      this.obtenerDiaSeleccionado();

    const ejercicios =
      dia.ejercicios;

    [
      ejercicios[
        indiceEjercicio - 1
      ],
      ejercicios[
        indiceEjercicio
      ]
    ] = [
      ejercicios[
        indiceEjercicio
      ],
      ejercicios[
        indiceEjercicio - 1
      ]
    ];

    this.actualizarOrdenes(
      dia
    );

    this.changeDetector
      .detectChanges();
  }


  moverEjercicioAbajo(
    indiceEjercicio: number
  ): void {

    const dia =
      this.obtenerDiaSeleccionado();

    const ejercicios =
      dia.ejercicios;

    if (
      indiceEjercicio >=
      ejercicios.length - 1
    ) {

      return;
    }

    [
      ejercicios[
        indiceEjercicio
      ],
      ejercicios[
        indiceEjercicio + 1
      ]
    ] = [
      ejercicios[
        indiceEjercicio + 1
      ],
      ejercicios[
        indiceEjercicio
      ]
    ];

    this.actualizarOrdenes(
      dia
    );

    this.changeDetector
      .detectChanges();
  }


  actualizarOrdenes(
    dia: DiaFormulario
  ): void {

    dia.ejercicios
      .forEach(
        (
          ejercicio,
          indice
        ) => {

          ejercicio.orden =
            indice + 1;
        }
      );
  }


  obtenerEjercicioSeleccionado(
    idEjercicio:
      number | null
  ): Ejercicio | null {

    if (
      idEjercicio === null
    ) {

      return null;
    }

    return (
      this.ejerciciosDisponibles
        .find(
          ejercicio =>
            ejercicio.idEjercicio ===
            idEjercicio
        )
      ?? null
    );
  }


  contarDiasEntrenamiento():
    number {

    return this.diasRutina
      .filter(
        dia =>
          dia.ejercicios.length > 0
      )
      .length;
  }


  validarFormulario(): boolean {

    this.errorFormulario = '';

    if (
      this.idClienteSeleccionado ===
      null
    ) {

      this.errorFormulario =
        'Selecciona un cliente para la rutina.';

      return false;
    }

    const nombre =
      this.nombreRutina.trim();

    if (
      !nombre
    ) {

      this.errorFormulario =
        'El nombre de la rutina es obligatorio.';

      return false;
    }

    if (
      nombre.length > 120
    ) {

      this.errorFormulario =
        'El nombre no puede superar los 120 caracteres.';

      return false;
    }

    if (
      this.descripcionRutina
        .trim()
        .length > 500
    ) {

      this.errorFormulario =
        'La descripción no puede superar los 500 caracteres.';

      return false;
    }

    const diasConEntrenamiento =
      this.diasRutina.filter(
        dia =>
          dia.ejercicios.length > 0
      );

    if (
      diasConEntrenamiento.length === 0
    ) {

      this.errorFormulario =
        'Agrega al menos un ejercicio en algún día de la semana.';

      return false;
    }

    for (
      const dia
      of diasConEntrenamiento
    ) {

      const ejerciciosUtilizados =
        new Set<number>();

      for (
        let indiceEjercicio = 0;
        indiceEjercicio <
        dia.ejercicios.length;
        indiceEjercicio++
      ) {

        const ejercicio =
          dia.ejercicios[
            indiceEjercicio
          ];

        if (
          ejercicio.idEjercicio ===
          null
        ) {

          this.diaSeleccionado =
            dia.dia;

          this.errorFormulario =
            `Selecciona el ejercicio ${indiceEjercicio + 1} de ${dia.dia}.`;

          return false;
        }

        if (
          ejerciciosUtilizados.has(
            ejercicio.idEjercicio
          )
        ) {

          this.diaSeleccionado =
            dia.dia;

          this.errorFormulario =
            `No puedes repetir el mismo ejercicio dentro de ${dia.dia}.`;

          return false;
        }

        ejerciciosUtilizados.add(
          ejercicio.idEjercicio
        );

        if (
          ejercicio.series ===
            null ||
          !Number.isInteger(
            ejercicio.series
          ) ||
          ejercicio.series <= 0
        ) {

          this.diaSeleccionado =
            dia.dia;

          this.errorFormulario =
            `Las series del ejercicio ${indiceEjercicio + 1} de ${dia.dia} deben ser un número entero mayor a 0.`;

          return false;
        }

        if (
          ejercicio.repeticiones ===
            null ||
          !Number.isInteger(
            ejercicio.repeticiones
          ) ||
          ejercicio.repeticiones <= 0
        ) {

          this.diaSeleccionado =
            dia.dia;

          this.errorFormulario =
            `Las repeticiones del ejercicio ${indiceEjercicio + 1} de ${dia.dia} deben ser un número entero mayor a 0.`;

          return false;
        }
      }
    }

    return true;
  }


  guardarRutina(): void {

    if (
      !this.validarFormulario()
    ) {

      this.changeDetector
        .detectChanges();

      return;
    }

    const diasConEntrenamiento =
      this.diasRutina
        .filter(
          dia =>
            dia.ejercicios.length > 0
        );

    const request:
      CrearRutinaRequest = {

      idCliente:
        this.idClienteSeleccionado!,

      nombre:
        this.nombreRutina.trim(),

      descripcion:
        this.descripcionRutina
          .trim()
          ? this.descripcionRutina
              .trim()
          : null,

      dias:
        diasConEntrenamiento.map(
          dia => ({

            dia:
              dia.dia,

            ejercicios:
              dia.ejercicios.map(
                ejercicio => ({

                  idEjercicio:
                    ejercicio
                      .idEjercicio!,

                  series:
                    ejercicio
                      .series!,

                  repeticiones:
                    ejercicio
                      .repeticiones!,

                  orden:
                    ejercicio
                      .orden
                })
              )
          })
        )
    };

    this.guardando = true;

    this.errorFormulario = '';

    if (
      !this.esEdicion
    ) {

      this.rutinaService
        .crearRutina(
          request
        )
        .subscribe({

          next: (
            respuesta:
              RutinaGuardadaResponse
          ) => {

            this.finalizarGuardado(
              respuesta
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
      this.idRutina === null
    ) {

      this.guardando = false;

      this.errorFormulario =
        'No se encontró la rutina que deseas editar.';

      return;
    }


    this.rutinaService
      .actualizarRutina(
        this.idRutina,
        request
      )
      .subscribe({

        next: (
          respuesta:
            RutinaGuardadaResponse
        ) => {

          this.finalizarGuardado(
            respuesta
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
    respuesta:
      RutinaGuardadaResponse
  ): void {

    this.guardando = false;

    const mensaje =
      this.esEdicion
        ? `Rutina "${respuesta.nombre}" actualizada correctamente.`
        : `Rutina "${respuesta.nombre}" creada correctamente.`;

    this.router.navigate(
      [
        '/entrenador/rutinas'
      ],
      {
        state: {
          mensaje
        }
      }
    );
  }


  manejarErrorCarga(
    error: any
  ): void {

    console.error(
      'Error al cargar formulario de rutina:',
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
        'No tienes permiso para administrar esta rutina.';

    } else if (
      error.status === 404
    ) {

      this.error =
        error.error?.mensaje ??
        'No se encontró la información solicitada.';

    } else if (
      error.status === 0
    ) {

      this.error =
        'No fue posible conectar con el servidor.';

    } else {

      this.error =
        'No fue posible cargar la información de la rutina.';
    }

    this.changeDetector
      .detectChanges();
  }


  manejarErrorGuardado(
    error: any
  ): void {

    console.error(
      'Error al guardar rutina:',
      error
    );

    this.guardando = false;

    if (
      error.status === 400
    ) {

      this.errorFormulario =
        error.error?.mensaje ??
        'Los datos de la rutina no son válidos.';

    } else if (
      error.status === 401
    ) {

      this.errorFormulario =
        'Tu sesión no es válida. Inicia sesión nuevamente.';

    } else if (
      error.status === 403
    ) {

      this.errorFormulario =
        error.error?.mensaje ??
        'No tienes permiso para modificar esta rutina.';

    } else if (
      error.status === 404
    ) {

      this.errorFormulario =
        error.error?.mensaje ??
        'No se encontró la rutina solicitada.';

    } else if (
      error.status === 0
    ) {

      this.errorFormulario =
        'No fue posible conectar con el servidor.';

    } else {

      this.errorFormulario =
        'No fue posible guardar la rutina.';
    }

    this.changeDetector
      .detectChanges();
  }


  cancelar(): void {

    this.router.navigate([
      '/entrenador/rutinas'
    ]);
  }
}