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
  EjercicioRutinaDetalle,
  RutinaDetalle
} from '../models/rutina.model';

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

  imagenesConError =
    new Set<number>();

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

    this.imagenesConError.clear();

    this.rutinaService
      .obtenerMiRutina()
      .subscribe({

        next: (
          rutina: RutinaDetalle
        ) => {

          this.rutina =
            rutina;

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


  marcarImagenConError(
    idEjercicioRutina: number
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