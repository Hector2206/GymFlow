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

  errorClientes = '';

  cargandoClientes = false;

  constructor(
    private router: Router,
    private clienteConsultaService: ClienteConsultaService,
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
      Number(this.monto) > 100000
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

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}