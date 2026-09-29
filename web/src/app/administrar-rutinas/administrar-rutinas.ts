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
  RutinaGuardadaResponse,
  RutinaResumen
} from '../models/rutina.model';

import {
  ClienteAsignado,
  ClientesEntrenadorResponse
} from '../models/cliente-asignado.model';

import {
  Ejercicio
} from '../models/ejercicio.model';


interface EjercicioFormulario {

  idEjercicio: number | null;

  series: number | null;

  repeticiones: number | null;

  orden: number;
}


interface DiaFormulario {

  dia: string;

  ejercicios: EjercicioFormulario[];
}


type ModoFormulario =
  'crear' |
  'editar' |
  'asignar';


@Component({
  selector: 'app-administrar-rutinas',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './administrar-rutinas.html',
  styleUrl: './administrar-rutinas.css'
})
export class AdministrarRutinas
implements OnInit {

  rutinas: RutinaResumen[] = [];

  clientesAsignados: ClienteAsignado[] = [];

  ejerciciosDisponibles: Ejercicio[] = [];

  diasRutina: DiaFormulario[] = [];

  opcionesDias: string[] = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  idClienteSeleccionado:
    number | null = null;

  idRutinaEditando:
    number | null = null;

  nombreRutina = '';

  descripcionRutina = '';

  modoFormulario:
    ModoFormulario = 'crear';

  cargando = true;

  cargandoClientes = false;

  cargandoEjercicios = false;

  guardandoRutina = false;

  error = '';

  errorClientes = '';

  errorEjercicios = '';

  errorFormulario = '';

  mensajeExito = '';

  mostrarFormularioNuevaRutina =
    false;

  constructor(
    private router: Router,
    private rutinaService: RutinaService,
    private entrenadorService: EntrenadorService,
    private ejercicioService: EjercicioService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {

    this.cargarRutinas();
  }


  cargarRutinas(): void {

    this.cargando = true;

    this.error = '';

    this.rutinaService
      .listarRutinas()
      .subscribe({

        next: (
          rutinas: RutinaResumen[]
        ) => {

          this.rutinas =
            rutinas ?? [];

          this.cargando = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar rutinas:',
            error
          );

          this.cargando = false;

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


  abrirFormularioNuevaRutina(): void {

    this.limpiarFormulario();

    this.modoFormulario =
      'crear';

    this.mostrarFormularioNuevaRutina =
      true;

    this.mensajeExito = '';

    this.cargarClientesAsignados();

    this.cargarEjercicios();
  }


  editarRutina(
    rutina: RutinaResumen
  ): void {

    this.limpiarFormulario();

    this.modoFormulario =
      'editar';

    this.idRutinaEditando =
      rutina.idRutina;

    this.idClienteSeleccionado =
      rutina.idCliente;

    this.nombreRutina =
      rutina.nombre;

    this.descripcionRutina =
      rutina.descripcion ?? '';

    this.mostrarFormularioNuevaRutina =
      true;

    this.mensajeExito = '';

    this.cargarClientesAsignados();

    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  }


  asignarRutina(
    rutina: RutinaResumen
  ): void {

    this.limpiarFormulario();

    this.modoFormulario =
      'asignar';

    this.idRutinaEditando =
      rutina.idRutina;

    this.idClienteSeleccionado =
      rutina.idCliente;

    this.nombreRutina =
      rutina.nombre;

    this.descripcionRutina =
      rutina.descripcion ?? '';

    this.mostrarFormularioNuevaRutina =
      true;

    this.mensajeExito = '';

    this.cargarClientesAsignados();

    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  }


  cerrarFormularioNuevaRutina(): void {

    this.mostrarFormularioNuevaRutina =
      false;

    this.limpiarFormulario();
  }


  limpiarFormulario(): void {

    this.idClienteSeleccionado = null;

    this.idRutinaEditando = null;

    this.nombreRutina = '';

    this.descripcionRutina = '';

    this.diasRutina = [];

    this.errorClientes = '';

    this.errorEjercicios = '';

    this.errorFormulario = '';

    this.guardandoRutina = false;

    this.modoFormulario =
      'crear';
  }


  cargarClientesAsignados(): void {

    this.cargandoClientes = true;

    this.errorClientes = '';

    this.entrenadorService
      .obtenerMisClientes()
      .subscribe({

        next: (
          respuesta: ClientesEntrenadorResponse
        ) => {

          this.clientesAsignados =
            respuesta.clientes ?? [];

          this.cargandoClientes = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar clientes asignados:',
            error
          );

          this.cargandoClientes = false;

          this.clientesAsignados = [];

          if (
            error.status === 401
          ) {

            this.errorClientes =
              'Tu sesión no es válida.';

          } else if (
            error.status === 403
          ) {

            this.errorClientes =
              'No tienes permiso para consultar clientes.';

          } else if (
            error.status === 404
          ) {

            this.errorClientes = '';

          } else if (
            error.status === 0
          ) {

            this.errorClientes =
              'No fue posible conectar con el servidor.';

          } else {

            this.errorClientes =
              'No fue posible cargar tus clientes.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  cargarEjercicios(): void {

    this.cargandoEjercicios = true;

    this.errorEjercicios = '';

    this.ejercicioService
      .listarEjercicios()
      .subscribe({

        next: (
          ejercicios: Ejercicio[]
        ) => {

          this.ejerciciosDisponibles =
            (ejercicios ?? [])
              .filter(
                ejercicio =>
                  ejercicio.estado
              );

          this.cargandoEjercicios =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar ejercicios:',
            error
          );

          this.ejerciciosDisponibles = [];

          this.cargandoEjercicios =
            false;

          if (
            error.status === 401
          ) {

            this.errorEjercicios =
              'Tu sesión no es válida.';

          } else if (
            error.status === 403
          ) {

            this.errorEjercicios =
              'No tienes permiso para consultar ejercicios.';

          } else if (
            error.status === 0
          ) {

            this.errorEjercicios =
              'No fue posible conectar con el servidor.';

          } else {

            this.errorEjercicios =
              'No fue posible cargar los ejercicios.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  agregarDia(): void {

    this.errorFormulario = '';

    this.diasRutina.push({
      dia: '',
      ejercicios: []
    });
  }


  agregarEjercicio(
    indiceDia: number
  ): void {

    this.errorFormulario = '';

    this.diasRutina[
      indiceDia
    ].ejercicios.push({

      idEjercicio: null,

      series: null,

      repeticiones: null,

      orden:
        this.diasRutina[
          indiceDia
        ].ejercicios.length + 1
    });
  }


  moverEjercicioArriba(
    indiceDia: number,
    indiceEjercicio: number
  ): void {

    if (
      indiceEjercicio <= 0
    ) {

      return;
    }

    const ejercicios =
      this.diasRutina[
        indiceDia
      ].ejercicios;

    const temporal =
      ejercicios[
        indiceEjercicio - 1
      ];

    ejercicios[
      indiceEjercicio - 1
    ] =
      ejercicios[
        indiceEjercicio
      ];

    ejercicios[
      indiceEjercicio
    ] =
      temporal;

    this.actualizarOrdenes(
      indiceDia
    );
  }


  moverEjercicioAbajo(
    indiceDia: number,
    indiceEjercicio: number
  ): void {

    const ejercicios =
      this.diasRutina[
        indiceDia
      ].ejercicios;

    if (
      indiceEjercicio >=
      ejercicios.length - 1
    ) {

      return;
    }

    const temporal =
      ejercicios[
        indiceEjercicio + 1
      ];

    ejercicios[
      indiceEjercicio + 1
    ] =
      ejercicios[
        indiceEjercicio
      ];

    ejercicios[
      indiceEjercicio
    ] =
      temporal;

    this.actualizarOrdenes(
      indiceDia
    );
  }


  actualizarOrdenes(
    indiceDia: number
  ): void {

    this.diasRutina[
      indiceDia
    ].ejercicios.forEach(
      (
        ejercicio,
        indice
      ) => {

        ejercicio.orden =
          indice + 1;
      }
    );
  }


  validarFormulario(): boolean {

    this.errorFormulario = '';

    if (
      this.idClienteSeleccionado === null
    ) {

      this.errorFormulario =
        'Selecciona un cliente para la rutina.';

      return false;
    }

    if (
      !this.nombreRutina.trim()
    ) {

      this.errorFormulario =
        'El nombre de la rutina es obligatorio.';

      return false;
    }

    if (
      this.modoFormulario !== 'crear'
    ) {

      return true;
    }

    if (
      this.diasRutina.length === 0
    ) {

      this.errorFormulario =
        'La rutina debe tener al menos un día de entrenamiento.';

      return false;
    }

    for (
      let indiceDia = 0;
      indiceDia < this.diasRutina.length;
      indiceDia++
    ) {

      const dia =
        this.diasRutina[
          indiceDia
        ];

      if (
        !dia.dia.trim()
      ) {

        this.errorFormulario =
          `Selecciona el día de entrenamiento en el bloque ${indiceDia + 1}.`;

        return false;
      }

      if (
        dia.ejercicios.length === 0
      ) {

        this.errorFormulario =
          `${dia.dia} debe tener al menos un ejercicio.`;

        return false;
      }

      for (
        let indiceEjercicio = 0;
        indiceEjercicio < dia.ejercicios.length;
        indiceEjercicio++
      ) {

        const ejercicio =
          dia.ejercicios[
            indiceEjercicio
          ];

        if (
          ejercicio.idEjercicio === null
        ) {

          this.errorFormulario =
            `Selecciona el ejercicio ${indiceEjercicio + 1} de ${dia.dia}.`;

          return false;
        }

        if (
          ejercicio.series === null ||
          ejercicio.series <= 0
        ) {

          this.errorFormulario =
            `Las series del ejercicio ${indiceEjercicio + 1} de ${dia.dia} deben ser mayores a 0.`;

          return false;
        }

        if (
          ejercicio.repeticiones === null ||
          ejercicio.repeticiones <= 0
        ) {

          this.errorFormulario =
            `Las repeticiones del ejercicio ${indiceEjercicio + 1} de ${dia.dia} deben ser mayores a 0.`;

          return false;
        }
      }
    }

    return true;
  }


  guardarRutina(): void {

    this.mensajeExito = '';

    if (
      !this.validarFormulario()
    ) {

      this.changeDetector
        .detectChanges();

      return;
    }

    const modoActual =
      this.modoFormulario;

    const request:
      CrearRutinaRequest = {

      idCliente:
        this.idClienteSeleccionado!,

      nombre:
        this.nombreRutina.trim(),

      descripcion:
        this.descripcionRutina.trim()
          ? this.descripcionRutina.trim()
          : null,

      dias:
        modoActual === 'crear'
          ? this.diasRutina.map(
              dia => ({

                dia:
                  dia.dia,

                ejercicios:
                  dia.ejercicios.map(
                    ejercicio => ({

                      idEjercicio:
                        ejercicio.idEjercicio!,

                      series:
                        ejercicio.series!,

                      repeticiones:
                        ejercicio.repeticiones!,

                      orden:
                        ejercicio.orden
                    })
                  )
              })
            )
          : []
    };

    this.guardandoRutina = true;

    this.errorFormulario = '';

    if (
      modoActual === 'crear'
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
              respuesta,
              modoActual
            );
          },

          error: (error) => {

            this.manejarErrorGuardado(
              error,
              modoActual
            );
          }
        });

      return;
    }


    if (
      this.idRutinaEditando === null
    ) {

      this.guardandoRutina = false;

      this.errorFormulario =
        'No se encontró la rutina que deseas modificar.';

      return;
    }


    this.rutinaService
      .actualizarRutina(
        this.idRutinaEditando,
        request
      )
      .subscribe({

        next: (
          respuesta:
            RutinaGuardadaResponse
        ) => {

          this.finalizarGuardado(
            respuesta,
            modoActual
          );
        },

        error: (error) => {

          this.manejarErrorGuardado(
            error,
            modoActual
          );
        }
      });
  }


  finalizarGuardado(
    respuesta: RutinaGuardadaResponse,
    modo: ModoFormulario
  ): void {

    this.guardandoRutina = false;

    if (
      modo === 'crear'
    ) {

      this.mensajeExito =
        `Rutina "${respuesta.nombre}" creada correctamente.`;

    } else if (
      modo === 'editar'
    ) {

      this.mensajeExito =
        `Rutina "${respuesta.nombre}" actualizada correctamente.`;

    } else {

      this.mensajeExito =
        `Rutina "${respuesta.nombre}" asignada correctamente.`;
    }

    this.mostrarFormularioNuevaRutina =
      false;

    this.limpiarFormulario();

    this.cargarRutinas();

    this.changeDetector
      .detectChanges();
  }


  manejarErrorGuardado(
    error: any,
    modo: ModoFormulario
  ): void {

    console.error(
      'Error al guardar rutina:',
      error
    );

    this.guardandoRutina = false;

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

    } else if (
      modo === 'crear'
    ) {

      this.errorFormulario =
        'No fue posible crear la rutina.';

    } else {

      this.errorFormulario =
        'No fue posible actualizar la rutina.';
    }

    this.changeDetector
      .detectChanges();
  }


  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}