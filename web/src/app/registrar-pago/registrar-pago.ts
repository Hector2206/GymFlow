
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';

import {
  ClienteConsultaService,
  ClienteResumen
} from '../services/cliente-consulta.service';

import {
  PagoService,
  PagoPendiente,
  TipoPago,
  RegistrarPagoResponse
} from '../services/pago.service';

@Component({
  selector: 'app-registrar-pago',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './registrar-pago.html',
  styleUrl: './registrar-pago.css'
})
export class RegistrarPago implements OnInit {
  clientes: ClienteResumen[] = [];

  idCliente: number | null = null;
  tipoPago: TipoPago | '' = '';

  pendiente: PagoPendiente | null = null;
  respuestaPago: RegistrarPagoResponse | null = null;

  cargandoClientes = false;
  procesandoPago = false;
  operacionTerminada = false;

  errorClientes = '';
  errorFormulario = '';
  errorAlmacenamiento = '';
  exito = '';

  constructor(
    private router: Router,
    private clienteConsultaService: ClienteConsultaService,
    private pagoService: PagoService,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    try {
      this.pendiente = this.pagoService.obtenerPendiente();

      if (this.pendiente) {
        this.idCliente = this.pendiente.idCliente;
        this.tipoPago = this.pendiente.tipoPago;
      }
    } catch (error) {
      this.errorAlmacenamiento =
        error instanceof Error
          ? error.message
          : 'No se pudo recuperar el pago pendiente.';
    }

    this.cargarClientes();
  }

  get hayPendiente(): boolean {
    return this.pendiente !== null;
  }

  get nombreCliente(): string {
    const id = this.pendiente?.idCliente ?? this.idCliente;

    const cliente = this.clientes.find(
      c => c.idCliente === id
    );

    return cliente?.nombreCompleto ?? `Cliente #${id ?? '?'}`;
  }

  cargarClientes(): void {
    this.cargandoClientes = true;
    this.errorClientes = '';

    this.clienteConsultaService.obtenerClientes().subscribe({
      next: clientes => {
        this.clientes = clientes ?? [];
        this.cargandoClientes = false;
        this.cd.detectChanges();
      },
      error: () => {
        this.cargandoClientes = false;
        this.errorClientes =
          'No fue posible consultar el listado de clientes.';
        this.cd.detectChanges();
      }
    });
  }

  registrarPago(): void {
    if (
      this.procesandoPago ||
      this.operacionTerminada ||
      !!this.errorAlmacenamiento
    ) {
      return;
    }

    this.errorFormulario = '';
    this.exito = '';

    const idCliente =
      this.pendiente?.idCliente ?? this.idCliente;

    const tipoPago =
      this.pendiente?.tipoPago ?? this.tipoPago;

    if (
      idCliente === null ||
      !Number.isInteger(idCliente) ||
      idCliente <= 0
    ) {
      this.errorFormulario = 'Selecciona un cliente.';
      return;
    }

    if (
      tipoPago !== 'Mensualidad' &&
      tipoPago !== 'Anualidad'
    ) {
      this.errorFormulario =
        'Selecciona Mensualidad o Anualidad.';
      return;
    }

    if (!this.pendiente &&
        (this.cargandoClientes ||
         !!this.errorClientes ||
         this.clientes.length === 0)) {
      this.errorFormulario =
        'No hay clientes disponibles para registrar pagos.';
      return;
    }

    const cliente =
      this.clientes.find(c => c.idCliente === idCliente);

    const nombre =
      cliente?.nombreCompleto ?? `Cliente #${idCliente}`;

    const aceptado = window.confirm(
      this.pendiente
        ? `REINTENTAR EL MISMO PAGO\n\n` +
          `Cliente: ${nombre}\n` +
          `Concepto: ${tipoPago}\n\n` +
          `Se utilizará el UUID original. ` +
          `No se iniciará un cobro nuevo.`
        : `CONFIRMAR PAGO\n\n` +
          `Cliente: ${nombre}\n` +
          `Concepto: ${tipoPago}\n\n` +
          `El importe será calculado por Backend.\n` +
          `Confirma únicamente dinero ya recibido.`
    );

    if (!aceptado) return;

    let operacion: PagoPendiente;

    try {
      if (this.pendiente) {
        const guardada = this.pagoService.obtenerPendiente();

        if (
          !guardada ||
          guardada.clave !== this.pendiente.clave
        ) {
          throw new Error(
            'No coincide el UUID de la operación pendiente.'
          );
        }
      }

      operacion = this.pagoService.prepararPago({
        idCliente,
        tipoPago
      });

      this.pendiente = operacion;
    } catch (error) {
      this.errorFormulario =
        error instanceof Error
          ? error.message
          : 'No fue posible preparar la operación.';
      return;
    }

    this.procesandoPago = true;
    this.cd.detectChanges();

    this.pagoService.registrarPago(operacion).subscribe({
      next: respuesta => {
        try {
          this.pagoService.confirmarYLimpiar(
            operacion,
            respuesta
          );

          this.pendiente = null;
          this.respuestaPago = respuesta;
          this.operacionTerminada = true;

          this.exito = respuesta.pagoRepetido
            ? 'El pago ya estaba registrado. ' +
              'No se generó otro cobro.'
            : respuesta.mensaje ||
              'Pago registrado correctamente.';
        } catch (error) {
          this.errorFormulario =
            error instanceof Error
              ? error.message
              : 'No se pudo confirmar la operación.';
        } finally {
          this.procesandoPago = false;
          this.cd.detectChanges();
        }
      },

      error: (error: HttpErrorResponse) => {
        this.procesandoPago = false;

        if (error.status === 0 || error.status >= 500) {
          this.errorFormulario =
            'No se pudo confirmar el resultado del pago. ' +
            'La operación seguirá pendiente. ' +
            'Reintenta con el mismo UUID o consulta el historial.';
        } else if (error.status === 401) {
          this.errorFormulario =
            'Tu sesión expiró. El pago pendiente se conservará.';
        } else if (error.status === 403) {
          this.errorFormulario =
            'No tienes permiso para registrar pagos. ' +
            'El UUID se conservará.';
        } else {
          const mensaje = error.error?.mensaje;

          this.errorFormulario =
            typeof mensaje === 'string'
              ? mensaje + ' La operación pendiente se conservará.'
              : 'No fue posible completar la operación. ' +
                'El UUID se conservará para verificarla.';
        }

        this.cd.detectChanges();
      }
    });
  }

  registrarNuevoPago(): void {
    if (
      !this.operacionTerminada ||
      this.procesandoPago ||
      this.pendiente
    ) {
      return;
    }

    this.idCliente = null;
    this.tipoPago = '';
    this.respuestaPago = null;
    this.operacionTerminada = false;
    this.errorFormulario = '';
    this.exito = '';
  }

  descripcionMovimiento(
    respuesta: RegistrarPagoResponse
  ): string {
    if (respuesta.pagoRepetido) {
      return 'Pago ya procesado (sin duplicación)';
    }

    if (respuesta.esRenovacion === true) {
      return 'Renovación';
    }

    if (respuesta.esRenovacion === false) {
      return 'Primer pago';
    }

    return 'Movimiento confirmado';
  }

  formatearFecha(fecha: string | null): string {
    if (!fecha) return 'Sin fecha';

    const coincidencia =
      /^(\d{4})-(\d{2})-(\d{2})/.exec(fecha);

    if (!coincidencia) return fecha;

    return `${coincidencia[3]}/${coincidencia[2]}/${coincidencia[1]}`;
  }

  consultarHistorial(): void {
    this.router.navigate(['/historial-pagos']);
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
