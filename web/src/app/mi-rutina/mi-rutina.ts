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
  DiaRutinaDetalle,
  EjercicioRutinaDetalle,
  RutinaDetalle
} from '../models/rutina.model';

interface DiaSemana {
  nombre: string;
  corto: string;
}

@Component({
  selector: 'app-mi-rutina',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl:
    './mi-rutina.html',
  styleUrl:
    './mi-rutina.css'
})
export class MiRutina
implements OnInit {

  rutina:
    RutinaDetalle | null = null;

  cargando = true;

  error = '';

  sinRutina = false;

  diaSeleccionado =
    'Lunes';

  imagenesConError =
    new Set<number>();

  indiceEjercicioPorDia:
    Record<number, number> = {};

  diasSemana:
    DiaSemana[] = [
      {
        nombre: 'Lunes',
        corto: 'Lun'
      },
      {
        nombre: 'Martes',
        corto: 'Mar'
      },
      {
        nombre: 'Miércoles',
        corto: 'Mié'
      },
      {
        nombre: 'Jueves',
        corto: 'Jue'
      },
      {
        nombre: 'Viernes',
        corto: 'Vie'
      },
      {
        nombre: 'Sábado',
        corto: 'Sáb'
      },
      {
        nombre: 'Domingo',
        corto: 'Dom'
      }
    ];

  constructor(
    private rutinaService:
      RutinaService,
    private router:
      Router,
    private changeDetector:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {

    this.cargarRutina();
  }


  cargarRutina(): void {

    this.cargando = true;

    this.error = '';

    this.sinRutina = false;

    this.rutina = null;

    this.imagenesConError
      .clear();

    this.indiceEjercicioPorDia =
      {};

    this.rutinaService
      .obtenerMiRutina()
      .subscribe({

        next: (
          rutina:
            RutinaDetalle
        ) => {

          this.rutina =
            rutina;

          this.inicializarNavegacion(
            rutina
          );

          this.seleccionarDiaInicial(
            rutina
          );

          this.cargando =
            false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar mi rutina:',
            error
          );

          this.cargando =
            false;

          this.rutina =
            null;

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
                    '/rutinas'
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
            error.status === 404
          ) {

            this.sinRutina =
              true;

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar tu rutina en este momento.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }


  inicializarNavegacion(
    rutina:
      RutinaDetalle
  ): void {

    rutina.dias.forEach(
      dia => {

        this.indiceEjercicioPorDia[
          dia.idDia
        ] = 0;
      }
    );
  }


  seleccionarDiaInicial(
    rutina:
      RutinaDetalle
  ): void {

    const diaActual =
      this.obtenerDiaActual();

    const tieneDiaActual =
      rutina.dias.some(
        dia =>
          this.normalizarDia(
            dia.dia
          ) ===
          this.normalizarDia(
            diaActual
          )
      );

    if (
      tieneDiaActual
    ) {

      this.diaSeleccionado =
        diaActual;

      return;
    }

    if (
      rutina.dias.length > 0
    ) {

      this.diaSeleccionado =
        rutina.dias[0].dia;

      return;
    }

    this.diaSeleccionado =
      'Lunes';
  }


  obtenerDiaActual(): string {

    const dias = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];

    return dias[
      new Date().getDay()
    ];
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
    dia: string
  ): void {

    this.diaSeleccionado =
      dia;

    this.changeDetector
      .detectChanges();
  }


  obtenerDiaSeleccionado():
    DiaRutinaDetalle | null {

    if (
      !this.rutina
    ) {

      return null;
    }

    const diaBuscado =
      this.normalizarDia(
        this.diaSeleccionado
      );

    return (
      this.rutina.dias.find(
        dia =>
          this.normalizarDia(
            dia.dia
          ) ===
          diaBuscado
      )
      ?? null
    );
  }


  diaTieneRutina(
    nombreDia: string
  ): boolean {

    if (
      !this.rutina
    ) {

      return false;
    }

    const diaBuscado =
      this.normalizarDia(
        nombreDia
      );

    return this.rutina.dias.some(
      dia =>
        this.normalizarDia(
          dia.dia
        ) ===
        diaBuscado
    );
  }


  esDiaSeleccionado(
    nombreDia: string
  ): boolean {

    return (
      this.normalizarDia(
        nombreDia
      ) ===
      this.normalizarDia(
        this.diaSeleccionado
      )
    );
  }


  obtenerIndiceActual(
    dia:
      DiaRutinaDetalle
  ): number {

    const indice =
      this.indiceEjercicioPorDia[
        dia.idDia
      ];

    if (
      indice === undefined ||
      indice < 0
    ) {

      return 0;
    }

    if (
      indice >=
      dia.ejercicios.length
    ) {

      return Math.max(
        dia.ejercicios.length - 1,
        0
      );
    }

    return indice;
  }


  obtenerEjercicioActual(
    dia:
      DiaRutinaDetalle
  ):
    EjercicioRutinaDetalle | null {

    if (
      dia.ejercicios.length === 0
    ) {

      return null;
    }

    return (
      dia.ejercicios[
        this.obtenerIndiceActual(
          dia
        )
      ] ?? null
    );
  }


  seleccionarEjercicio(
    dia:
      DiaRutinaDetalle,
    indice: number
  ): void {

    if (
      indice < 0 ||
      indice >=
        dia.ejercicios.length
    ) {

      return;
    }

    this.indiceEjercicioPorDia[
      dia.idDia
    ] = indice;

    this.changeDetector
      .detectChanges();
  }


  ejercicioAnterior(
    dia:
      DiaRutinaDetalle
  ): void {

    const indiceActual =
      this.obtenerIndiceActual(
        dia
      );

    if (
      indiceActual <= 0
    ) {

      return;
    }

    this.seleccionarEjercicio(
      dia,
      indiceActual - 1
    );
  }


  ejercicioSiguiente(
    dia:
      DiaRutinaDetalle
  ): void {

    const indiceActual =
      this.obtenerIndiceActual(
        dia
      );

    if (
      indiceActual >=
      dia.ejercicios.length - 1
    ) {

      return;
    }

    this.seleccionarEjercicio(
      dia,
      indiceActual + 1
    );
  }


  esPrimerEjercicio(
    dia:
      DiaRutinaDetalle
  ): boolean {

    return (
      this.obtenerIndiceActual(
        dia
      ) === 0
    );
  }


  esUltimoEjercicio(
    dia:
      DiaRutinaDetalle
  ): boolean {

    return (
      this.obtenerIndiceActual(
        dia
      ) ===
      dia.ejercicios.length - 1
    );
  }


  marcarImagenConError(
    idEjercicioRutina:
      number
  ): void {

    this.imagenesConError
      .add(
        idEjercicioRutina
      );

    this.changeDetector
      .detectChanges();
  }


  mostrarImagen(
    ejercicio:
      EjercicioRutinaDetalle
  ): boolean {

    return (
      !!ejercicio.imagenUrl &&
      !this.imagenesConError
        .has(
          ejercicio.idEjercicioRutina
        )
    );
  }


  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}