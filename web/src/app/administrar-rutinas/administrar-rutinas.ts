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
  RutinaResumen
} from '../models/rutina.model';

import {
  ClienteAsignado,
  ClientesEntrenadorResponse
} from '../models/cliente-asignado.model';

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

  idClienteSeleccionado: number | null = null;

  nombreRutina = '';

  descripcionRutina = '';

  cargando = true;

  cargandoClientes = false;

  error = '';

  errorClientes = '';

  mostrarFormularioNuevaRutina = false;

  constructor(
    private router: Router,
    private rutinaService: RutinaService,
    private entrenadorService: EntrenadorService,
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

    this.mostrarFormularioNuevaRutina = true;

    this.cargarClientesAsignados();
  }

  cerrarFormularioNuevaRutina(): void {

    this.mostrarFormularioNuevaRutina = false;

    this.idClienteSeleccionado = null;

    this.nombreRutina = '';

    this.descripcionRutina = '';

    this.errorClientes = '';
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

            this.errorClientes =
              'No se encontró información del entrenador.';

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

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}