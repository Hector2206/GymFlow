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
  ClienteConsultaService,
  ClienteResumen
} from '../services/cliente-consulta.service';

import {
  PagoCliente,
  PagoService,
  HistorialPagosResponse
} from '../services/pago.service';

@Component({
  selector: 'app-historial-pagos',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './historial-pagos.html',
  styleUrl: './historial-pagos.css'
})
export class HistorialPagos implements OnInit {

  clientes: ClienteResumen[] = [];

  idCliente: number | null = null;

  pagos: PagoCliente[] = [];

  cargandoClientes = false;
  cargandoPagos = false;

  error = '';

  consultaRealizada = false;

  constructor(
    private router: Router,
    private clienteConsultaService: ClienteConsultaService,
    private pagoService: PagoService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {

    this.cargarClientes();
  }

  cargarClientes(): void {

    this.cargandoClientes = true;
    this.error = '';

    this.clienteConsultaService
      .obtenerClientes()
      .subscribe({

        next: (clientes) => {

          this.clientes =
            clientes ?? [];

          this.cargandoClientes = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al cargar clientes:',
            error
          );

          this.cargandoClientes = false;

          this.error =
            'No fue posible cargar los clientes.';

          this.changeDetector
            .detectChanges();
        }
      });
  }

  consultarPagos(): void {

    this.error = '';
    this.pagos = [];
    this.consultaRealizada = false;

    if (
      this.idCliente === null ||
      this.idCliente <= 0
    ) {

      this.error =
        'Selecciona un cliente.';

      this.changeDetector
        .detectChanges();

      return;
    }

    this.cargandoPagos = true;

    this.changeDetector
      .detectChanges();

    this.pagoService
      .consultarPagosCliente(
        this.idCliente
      )
      .subscribe({

        next: (
          respuesta: HistorialPagosResponse
        ) => {

          this.pagos =
            respuesta.pagos ?? [];

          this.cargandoPagos = false;

          this.consultaRealizada = true;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar pagos:',
            error
          );

          this.cargandoPagos = false;
          this.consultaRealizada = true;

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar pagos.';

          } else if (
            error.status === 404
          ) {

            this.error =
              'El cliente seleccionado no existe.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible consultar los pagos.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  formatearFecha(
    fechaHora: string
  ): string {

    if (!fechaHora) {
      return 'Sin fecha';
    }

    return new Date(
      fechaHora
    ).toLocaleDateString(
      'es-MX',
      {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }
    );
  }

  formatearHora(
    fechaHora: string
  ): string {

    if (!fechaHora) {
      return 'Sin hora';
    }

    return new Date(
      fechaHora
    ).toLocaleTimeString(
      'es-MX',
      {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }
    );
  }

  formatearMonto(
    monto: number
  ): string {

    return Number(
      monto
    ).toLocaleString(
      'es-MX',
      {
        style: 'currency',
        currency: 'MXN'
      }
    );
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}