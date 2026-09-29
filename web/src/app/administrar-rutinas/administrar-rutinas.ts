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
  templateUrl: './administrar-rutinas.html',
  styleUrl: './administrar-rutinas.css'
})
export class AdministrarRutinas
implements OnInit {

  rutinas: RutinaResumen[] = [];

  cargando = true;

  error = '';

  constructor(
    private router: Router,
    private rutinaService: RutinaService,
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

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}