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
  ProgresoService
} from '../services/progreso.service';

import {
  EjercicioService
} from '../services/ejercicio.service';

import {
  Progreso
} from '../models/progreso.model';

import {
  Ejercicio
} from '../models/ejercicio.model';


interface EjercicioConProgreso {
  idEjercicio: number;
  nombreEjercicio: string;
  cantidadRegistros: number;
  ultimoPeso: number;
}


interface PuntoGrafica {
  x: number;
  y: number;
  peso: number;
  fecha: string;
}


@Component({
  selector: 'app-mi-progreso',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './mi-progreso.html',
  styleUrl: './mi-progreso.css'
})
export class MiProgreso
implements OnInit {

  progresos: Progreso[] = [];

  ejercicios: Ejercicio[] = [];

  ejerciciosConProgreso:
    EjercicioConProgreso[] = [];

  progresoEjercicio:
    Progreso[] = [];

  puntosGrafica:
    PuntoGrafica[] = [];

  idEjercicioSeleccionado:
    number | null = null;

  idEjercicioGrafica:
    number | null = null;

  pesoUtilizado:
    number | null = null;

  cargando = true;

  cargandoEjercicios = true;

  cargandoGrafica = false;

  guardando = false;

  error = '';

  errorRegistro = '';

  errorGrafica = '';

  mensajeExito = '';


  constructor(
    private progresoService:
      ProgresoService,
    private ejercicioService:
      EjercicioService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {

    this.cargarProgreso();

    this.cargarEjercicios();
  }


  cargarProgreso(
    seleccionarEjercicioId?:
      number
  ): void {

    this.cargando = true;

    this.error = '';

    this.progresoService
      .obtenerMiProgreso()
      .subscribe({

        next: (
          progresos: Progreso[]
        ) => {

          this.progresos =
            progresos;

          this.construirResumenEjercicios();

          this.cargando =
            false;

          if (
            seleccionarEjercicioId
          ) {

            const existe =
              this.ejerciciosConProgreso
                .some(
                  ejercicio =>
                    ejercicio.idEjercicio ===
                    seleccionarEjercicioId
                );

            if (
              existe
            ) {

              this.seleccionarEjercicio(
                seleccionarEjercicioId
              );

            } else {

              this.seleccionarPrimerEjercicio();
            }

          } else {

            this.seleccionarPrimerEjercicio();
          }

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


  cargarEjercicios(): void {

    this.cargandoEjercicios =
      true;

    this.ejercicioService
      .listarEjercicios()
      .subscribe({

        next: (
          ejercicios: Ejercicio[]
        ) => {

          this.ejercicios =
            ejercicios.filter(
              ejercicio =>
                ejercicio.estado
            );

          this.cargandoEjercicios =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (
          error
        ) => {

          console.error(
            'Error al consultar ejercicios:',
            error
          );

          this.cargandoEjercicios =
            false;

          this.errorRegistro =
            'No fue posible cargar los ejercicios disponibles.';

          this.changeDetector
            .detectChanges();
        }
      });
  }


  construirResumenEjercicios(): void {

    const mapa =
      new Map<
        number,
        EjercicioConProgreso
      >();

    for (
      const progreso
      of this.progresos
    ) {

      const existente =
        mapa.get(
          progreso.idEjercicio
        );

      if (
        existente
      ) {

        existente.cantidadRegistros++;

        continue;
      }

      mapa.set(
        progreso.idEjercicio,
        {
          idEjercicio:
            progreso.idEjercicio,

          nombreEjercicio:
            progreso.nombreEjercicio,

          cantidadRegistros: 1,

          ultimoPeso:
            progreso.pesoUtilizado
        }
      );
    }

    this.ejerciciosConProgreso =
      Array.from(
        mapa.values()
      );
  }


  seleccionarPrimerEjercicio(): void {

    if (
      this.ejerciciosConProgreso
        .length === 0
    ) {

      this.idEjercicioGrafica =
        null;

      this.progresoEjercicio =
        [];

      this.puntosGrafica =
        [];

      return;
    }

    const seleccionadoExiste =
      this.ejerciciosConProgreso
        .some(
          ejercicio =>
            ejercicio.idEjercicio ===
            this.idEjercicioGrafica
        );

    if (
      seleccionadoExiste &&
      this.idEjercicioGrafica !== null
    ) {

      this.seleccionarEjercicio(
        this.idEjercicioGrafica
      );

      return;
    }

    this.seleccionarEjercicio(
      this.ejerciciosConProgreso[0]
        .idEjercicio
    );
  }


  seleccionarEjercicio(
    idEjercicio: number
  ): void {

    this.idEjercicioGrafica =
      idEjercicio;

    this.cargarProgresoEjercicio(
      idEjercicio
    );
  }


  cargarProgresoEjercicio(
    idEjercicio: number
  ): void {

    this.cargandoGrafica =
      true;

    this.errorGrafica = '';

    this.progresoEjercicio =
      [];

    this.puntosGrafica =
      [];

    this.progresoService
      .obtenerProgresoPorEjercicio(
        idEjercicio
      )
      .subscribe({

        next: (
          progresos: Progreso[]
        ) => {

          if (
            this.idEjercicioGrafica !==
            idEjercicio
          ) {

            return;
          }

          this.progresoEjercicio =
            progresos;

          this.construirGrafica();

          this.cargandoGrafica =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (
          error
        ) => {

          console.error(
            'Error al consultar progreso por ejercicio:',
            error
          );

          if (
            this.idEjercicioGrafica !==
            idEjercicio
          ) {

            return;
          }

          this.cargandoGrafica =
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
            error.status === 0
          ) {

            this.errorGrafica =
              'No fue posible conectar con el servidor.';

          } else {

            this.errorGrafica =
              'No fue posible cargar la evolución de este ejercicio.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  construirGrafica(): void {

    this.puntosGrafica = [];

    if (
      this.progresoEjercicio
        .length === 0
    ) {

      return;
    }

    const pesos =
      this.progresoEjercicio
        .map(
          progreso =>
            Number(
              progreso.pesoUtilizado
            )
        );

    const minimo =
      Math.min(
        ...pesos
      );

    const maximo =
      Math.max(
        ...pesos
      );

    const rango =
      maximo - minimo;

    const total =
      this.progresoEjercicio
        .length;

    this.puntosGrafica =
      this.progresoEjercicio
        .map(
          (
            progreso,
            indice
          ) => {

            const peso =
              Number(
                progreso.pesoUtilizado
              );

            const x =
              total === 1
                ? 50
                : 8 +
                  (
                    indice /
                    (total - 1)
                  ) *
                  84;

            const y =
              rango === 0
                ? 50
                : 82 -
                  (
                    (
                      peso -
                      minimo
                    ) /
                    rango
                  ) *
                  64;

            return {
              x,
              y,
              peso,
              fecha:
                progreso.fechaRegistro
            };
          }
        );
  }


  registrarProgreso(): void {

    this.errorRegistro = '';

    this.mensajeExito = '';

    if (
      this.idEjercicioSeleccionado ===
        null ||
      this.idEjercicioSeleccionado <= 0
    ) {

      this.errorRegistro =
        'Selecciona un ejercicio.';

      return;
    }

    if (
      this.pesoUtilizado === null ||
      this.pesoUtilizado <= 0
    ) {

      this.errorRegistro =
        'Ingresa un peso mayor a 0 kg.';

      return;
    }

    if (
      this.pesoUtilizado >
      99999999.99
    ) {

      this.errorRegistro =
        'El peso ingresado supera el valor permitido.';

      return;
    }

    const ejercicioRegistrado =
      this.idEjercicioSeleccionado;

    this.guardando = true;

    this.progresoService
      .registrarProgreso({
        idEjercicio:
          ejercicioRegistrado,

        pesoUtilizado:
          this.pesoUtilizado
      })
      .subscribe({

        next: (
          response
        ) => {

          this.guardando =
            false;

          this.mensajeExito =
            response.mensaje ||
            'Progreso registrado correctamente.';

          this.idEjercicioSeleccionado =
            null;

          this.pesoUtilizado =
            null;

          this.cargarProgreso(
            ejercicioRegistrado
          );

          this.changeDetector
            .detectChanges();
        },

        error: (
          error
        ) => {

          console.error(
            'Error al registrar progreso:',
            error
          );

          this.guardando =
            false;

          if (
            error.status === 400
          ) {

            this.errorRegistro =
              error.error?.message ||
              error.error?.mensaje ||
              'Verifica los datos ingresados.';

          } else if (
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

          } else if (
            error.status === 403
          ) {

            this.errorRegistro =
              'No tienes permisos para registrar progreso.';

          } else if (
            error.status === 404
          ) {

            this.errorRegistro =
              'El ejercicio seleccionado no está disponible.';

          } else if (
            error.status === 0
          ) {

            this.errorRegistro =
              'No fue posible conectar con el servidor.';

          } else {

            this.errorRegistro =
              'No fue posible registrar el progreso.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  get ejercicioActual():
    EjercicioConProgreso | null {

    if (
      this.idEjercicioGrafica === null
    ) {

      return null;
    }

    return (
      this.ejerciciosConProgreso
        .find(
          ejercicio =>
            ejercicio.idEjercicio ===
            this.idEjercicioGrafica
        ) ||
      null
    );
  }


  get pesoInicial(): number {

    if (
      this.progresoEjercicio
        .length === 0
    ) {

      return 0;
    }

    return Number(
      this.progresoEjercicio[0]
        .pesoUtilizado
    );
  }


  get pesoActual(): number {

    if (
      this.progresoEjercicio
        .length === 0
    ) {

      return 0;
    }

    return Number(
      this.progresoEjercicio[
        this.progresoEjercicio.length -
        1
      ].pesoUtilizado
    );
  }


  get cambioPeso(): number {

    return Number(
      (
        this.pesoActual -
        this.pesoInicial
      ).toFixed(2)
    );
  }


  get lineaGrafica(): string {

    return this.puntosGrafica
      .map(
        punto =>
          `${punto.x},${punto.y}`
      )
      .join(' ');
  }


  get tieneEvolucion(): boolean {

    return (
      this.progresoEjercicio
        .length >= 2
    );
  }


  claseCambio(): string {

    if (
      this.cambioPeso > 0
    ) {

      return 'positive';
    }

    if (
      this.cambioPeso < 0
    ) {

      return 'negative';
    }

    return 'neutral';
  }


  simboloCambio(): string {

    if (
      this.cambioPeso > 0
    ) {

      return '+';
    }

    return '';
  }


  formatearPeso(
    peso: number
  ): string {

    return Number(
      peso
    ).toLocaleString(
      'es-MX',
      {
        maximumFractionDigits: 2
      }
    );
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


  formatearFechaCorta(
    fecha: string
  ): string {

    if (
      !fecha
    ) {

      return '';
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
      .toLocaleDateString(
        'es-MX',
        {
          day: '2-digit',
          month: 'short'
        }
      );
  }


  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}