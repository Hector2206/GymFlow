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
  PagoService,
  RegistrarPagoResponse
} from '../services/pago.service';

@Component({
  selector: 'app-registrar-pago',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './registrar-pago.html',
  styleUrl: './registrar-pago.css'
})
export class RegistrarPago implements OnInit {

  clientes: ClienteResumen[] = [];

  idCliente: number | null = null;

  monto: number | null = null;

  tipoPago = '';

  errorMonto = '';
  errorFormulario = '';
  errorClientes = '';

  exito = '';

  respuestaPago:
    RegistrarPagoResponse | null = null;

  cargandoClientes = false;
  procesandoPago = false;

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
    this.errorClientes = '';

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

          this.errorClientes =
            'No fue posible cargar los clientes.';

          this.changeDetector
            .detectChanges();
        }
      });
  }

  validarMonto(): boolean {

    this.errorMonto = '';

    if (
      this.monto === null ||
      this.monto === undefined
    ) {

      this.errorMonto =
        'Ingresa el monto del pago.';

      return false;
    }

    if (
      !Number.isFinite(
        Number(this.monto)
      )
    ) {

      this.errorMonto =
        'El monto ingresado no es válido.';

      return false;
    }

    if (
      Number(this.monto) <= 0
    ) {

      this.errorMonto =
        'El monto debe ser mayor a $0.';

      return false;
    }

    if (
      Number(this.monto) >
      100000
    ) {

      this.errorMonto =
        'Verifica el monto ingresado.';

      return false;
    }

    return true;
  }

  montoCambio(): void {

    if (
      this.monto === null
    ) {

      this.errorMonto = '';

      return;
    }

    this.validarMonto();
  }

  registrarPago(): void {

    this.errorFormulario = '';
    this.exito = '';
    this.respuestaPago = null;

    if (
      this.idCliente === null ||
      this.idCliente <= 0
    ) {

      this.errorFormulario =
        'Selecciona un cliente.';

      this.changeDetector
        .detectChanges();

      return;
    }

    if (!this.validarMonto()) {

      this.changeDetector
        .detectChanges();

      return;
    }

    if (
      this.tipoPago !== 'Mensualidad' &&
      this.tipoPago !== 'Anualidad'
    ) {

      this.errorFormulario =
        'Selecciona el concepto del pago.';

      this.changeDetector
        .detectChanges();

      return;
    }

    if (this.procesandoPago) {
      return;
    }

    this.procesandoPago = true;

    this.changeDetector
      .detectChanges();

    this.pagoService
      .registrarPago({
        idCliente:
          this.idCliente,
        monto:
          Number(this.monto),
        tipoPago:
          this.tipoPago
      })
      .subscribe({

        next: (
          respuesta: RegistrarPagoResponse
        ) => {

          console.log(
            'Pago registrado:',
            respuesta
          );

          this.procesandoPago = false;

          this.respuestaPago =
            respuesta;

          this.exito =
            respuesta.mensaje ||
            'Pago registrado correctamente.';

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al registrar pago:',
            error
          );

          this.procesandoPago = false;

          if (
            error.error &&
            typeof error.error === 'object' &&
            error.error.mensaje
          ) {

            this.errorFormulario =
              error.error.mensaje;

          } else if (
            error.status === 404
          ) {

            this.errorFormulario =
              'El cliente seleccionado no existe.';

          } else if (
            error.status === 401
          ) {

            this.errorFormulario =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.errorFormulario =
              'No tienes permiso para registrar pagos.';

          } else if (
            error.status === 0
          ) {

            this.errorFormulario =
              'No fue posible conectar con el servidor.';

          } else {

            this.errorFormulario =
              'No fue posible registrar el pago. Intenta nuevamente.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  formatearFecha(
    fecha: string
  ): string {

    if (!fecha) {
      return '';
    }

    return new Date(
      fecha
    ).toLocaleDateString(
      'es-MX',
      {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }
    );
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}