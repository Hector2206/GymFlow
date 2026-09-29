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
  EntrenadorService
} from '../services/entrenador.service';

import {
  ClienteAsignado,
  ClientesEntrenadorResponse
} from '../models/cliente-asignado.model';

@Component({
  selector: 'app-mis-clientes-entrenador',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './mis-clientes-entrenador.html',
  styleUrl: './mis-clientes-entrenador.css'
})
export class MisClientesEntrenador
implements OnInit {

  clientes: ClienteAsignado[] = [];

  idEntrenador: number | null = null;

  cargando = true;

  error = '';

  constructor(
    private router: Router,
    private entrenadorService: EntrenadorService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {

    this.cargarClientes();
  }

  cargarClientes(): void {

    this.cargando = true;
    this.error = '';

    this.entrenadorService
      .obtenerMisClientes()
      .subscribe({

        next: (
          respuesta: ClientesEntrenadorResponse
        ) => {

          this.idEntrenador =
            respuesta.idEntrenador;

          this.clientes =
            respuesta.clientes ?? [];

          this.cargando = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar clientes del entrenador:',
            error
          );

          this.cargando = false;
          this.clientes = [];

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar los clientes del entrenador.';

          } else if (
            error.status === 404
          ) {

            this.error =
              'No se encontró información del entrenador.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar tus clientes asignados.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  obtenerIniciales(
    nombre: string
  ): string {

    const partes =
      nombre
        .trim()
        .split(/\s+/)
        .filter(
          parte =>
            parte.length > 0
        );

    if (
      partes.length === 0
    ) {
      return '?';
    }

    if (
      partes.length === 1
    ) {
      return partes[0]
        .charAt(0)
        .toUpperCase();
    }

    return (
      partes[0].charAt(0) +
      partes[1].charAt(0)
    ).toUpperCase();
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}