import {
  Component
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
export class RegistrarPago {

  monto: number | null = null;

  tipoPago = '';

  errorMonto = '';

  constructor(
    private router: Router
  ) {}

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

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}