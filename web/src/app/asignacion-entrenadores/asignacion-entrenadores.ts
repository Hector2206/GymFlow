
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import {
  ClienteConsultaService,
  ClienteResumen
} from '../services/cliente-consulta.service';

import {
  AsignacionEntrenadorService
} from '../services/asignacion-entrenador.service';

import {
  EntrenadorResumen
} from '../models/asignacion-entrenador.model';

@Component({
  selector: 'app-asignacion-entrenadores',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './asignacion-entrenadores.html',
  styleUrl: './asignacion-entrenadores.css'
})
export class AsignacionEntrenadores implements OnInit {

  clientes: ClienteResumen[] = [];
  entrenadores: EntrenadorResumen[] = [];

  idClienteSeleccionado: number | null = null;
  idEntrenadorSeleccionado: number | null = null;

  cargandoClientes = true;
  cargandoEntrenadores = true;
  guardando = false;
  quitando = false;

  error = '';
  mensajeExito = '';

  // Se conservan para compatibilidad con la pantalla actual.
  entrenadorAsignadoSesion: EntrenadorResumen | null = null;
  clienteAsignadoSesion: number | null = null;

  constructor(
    private clienteConsultaService: ClienteConsultaService,
    private asignacionEntrenadorService: AsignacionEntrenadorService,
    private router: Router,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarClientes();
    this.cargarEntrenadores();
  }

  cargarClientes(): void {
    this.cargandoClientes = true;

    this.clienteConsultaService
      .obtenerClientes()
      .subscribe({
        next: (clientes) => {
          this.clientes = clientes;
          this.cargandoClientes = false;
          this.changeDetector.detectChanges();
        },
        error: (error) => {
          console.error(
            'Error al consultar clientes:',
            error
          );

          this.cargandoClientes = false;

          this.manejarErrorCarga(
            error,
            'No fue posible cargar los clientes.'
          );
        }
      });
  }

  cargarEntrenadores(): void {
    this.cargandoEntrenadores = true;

    this.asignacionEntrenadorService
      .obtenerEntrenadores()
      .subscribe({
        next: (entrenadores) => {
          this.entrenadores = entrenadores;
          this.cargandoEntrenadores = false;
          this.changeDetector.detectChanges();
        },
        error: (error) => {
          console.error(
            'Error al consultar entrenadores:',
            error
          );

          this.cargandoEntrenadores = false;

          this.manejarErrorCarga(
            error,
            'No fue posible cargar los entrenadores.'
          );
        }
      });
  }

  alCambiarCliente(): void {
    this.error = '';
    this.mensajeExito = '';

    this.idEntrenadorSeleccionado = null;

    this.sincronizarEntrenadorActual();

    this.changeDetector.detectChanges();
  }

  private sincronizarEntrenadorActual(): void {
    const cliente = this.clienteSeleccionado;

    this.clienteAsignadoSesion =
      cliente?.idCliente ?? null;

    if (
      cliente &&
      typeof cliente.idEntrenador === 'number' &&
      cliente.idEntrenador > 0
    ) {
      this.entrenadorAsignadoSesion = {
        idEntrenador: cliente.idEntrenador,
        nombreCompleto:
          cliente.nombreEntrenador ||
          this.entrenadores.find(
            e => e.idEntrenador === cliente.idEntrenador
          )?.nombreCompleto ||
          'Entrenador asignado'
      };
    } else {
      this.entrenadorAsignadoSesion = null;
    }
  }

  get clienteSeleccionado(): ClienteResumen | null {
    if (this.idClienteSeleccionado === null) {
      return null;
    }

    return this.clientes.find(
      cliente =>
        cliente.idCliente === this.idClienteSeleccionado
    ) ?? null;
  }

  get puedeMostrarAsignacionSesion(): boolean {
    return (
      this.clienteSeleccionado !== null &&
      this.entrenadorAsignadoSesion !== null &&
      this.clienteAsignadoSesion ===
        this.idClienteSeleccionado
    );
  }

  get puedeQuitarEntrenador(): boolean {
    return (
      this.puedeMostrarAsignacionSesion &&
      !this.guardando &&
      !this.quitando
    );
  }

  asignarEntrenador(): void {
    this.error = '';
    this.mensajeExito = '';

    if (
      this.guardando ||
      this.quitando
    ) {
      return;
    }

    const cliente = this.clienteSeleccionado;

    if (!cliente) {
      this.error = 'Selecciona un cliente.';
      return;
    }

    const idEntrenador =
      this.idEntrenadorSeleccionado;

    if (idEntrenador === null || idEntrenador <= 0) {
      this.error = 'Selecciona un entrenador.';
      return;
    }

    const entrenador = this.entrenadores.find(
      item => item.idEntrenador === idEntrenador
    );

    if (!entrenador) {
      this.error =
        'El entrenador seleccionado no está disponible.';
      return;
    }

    const idCliente = cliente.idCliente;

    this.guardando = true;

    this.asignacionEntrenadorService
      .asignarEntrenador(idCliente, idEntrenador)
      .subscribe({
        next: (response) => {
          this.guardando = false;

          const clienteActualizado = this.clientes.find(
            item => item.idCliente === idCliente
          );

          if (clienteActualizado) {
            clienteActualizado.idEntrenador =
              response.idEntrenador;

            clienteActualizado.nombreEntrenador =
              response.nombreEntrenador;
          }

          if (this.idClienteSeleccionado === idCliente) {
            this.sincronizarEntrenadorActual();

            this.mensajeExito =
              response.mensaje ||
              'Entrenador asignado correctamente.';
          }

          this.changeDetector.detectChanges();
        },
        error: (error) => {
          console.error(
            'Error al asignar entrenador:',
            error
          );

          this.guardando = false;

          this.manejarErrorAccion(
            error,
            'No fue posible asignar el entrenador.'
          );
        }
      });
  }

  quitarEntrenador(): void {
    this.error = '';
    this.mensajeExito = '';

    if (
      !this.puedeQuitarEntrenador
    ) {
      return;
    }

    const cliente = this.clienteSeleccionado;

    if (!cliente) {
      this.error = 'Selecciona un cliente.';
      return;
    }

    const idCliente = cliente.idCliente;

    const confirmar = window.confirm(
    `¿Estás seguro de que deseas quitar el entrenador asignado a ${cliente.nombreCompleto}?`
    );

    if (!confirmar) {
    return;
    }

    this.quitando = true;

    this.asignacionEntrenadorService
      .quitarEntrenador(idCliente)
      .subscribe({
        next: (response) => {
          this.quitando = false;

          const clienteActualizado = this.clientes.find(
            item => item.idCliente === idCliente
          );

          if (clienteActualizado) {
            clienteActualizado.idEntrenador = null;
            clienteActualizado.nombreEntrenador = null;
          }

          if (this.idClienteSeleccionado === idCliente) {
            this.sincronizarEntrenadorActual();

            this.idEntrenadorSeleccionado = null;

            this.mensajeExito =
              response.mensaje ||
              'Entrenador retirado correctamente.';
          }

          this.changeDetector.detectChanges();
        },
        error: (error) => {
          console.error(
            'Error al quitar entrenador:',
            error
          );

          this.quitando = false;

          this.manejarErrorAccion(
            error,
            'No fue posible quitar el entrenador.'
          );
        }
      });
  }

  manejarErrorCarga(
    error: any,
    mensajePredeterminado: string
  ): void {
    if (error.status === 401) {
      this.router.navigate(
        ['/login'],
        {
          queryParams: {
            returnUrl: '/asignacion-entrenadores'
          }
        }
      );
      return;
    }

    if (error.status === 403) {
      this.error =
        'Esta sección está disponible únicamente para recepción.';
    } else if (error.status === 0) {
      this.error =
        'No fue posible conectar con el servidor.';
    } else {
      this.error = mensajePredeterminado;
    }

    this.changeDetector.detectChanges();
  }

  manejarErrorAccion(
    error: any,
    mensajePredeterminado: string
  ): void {
    if (error.status === 401) {
      this.router.navigate(
        ['/login'],
        {
          queryParams: {
            returnUrl: '/asignacion-entrenadores'
          }
        }
      );
      return;
    }

    if (error.status === 400) {
      this.error =
        error.error?.mensaje ||
        mensajePredeterminado;
    } else if (error.status === 403) {
      this.error =
        'No tienes permisos para realizar esta operación.';
    } else if (error.status === 404) {
      this.error =
        error.error?.mensaje ||
        'El cliente o entrenador no existe.';
    } else if (error.status === 0) {
      this.error =
        'No fue posible conectar con el servidor.';
    } else {
      this.error =
        error.error?.mensaje ||
        mensajePredeterminado;
    }

    this.changeDetector.detectChanges();
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
