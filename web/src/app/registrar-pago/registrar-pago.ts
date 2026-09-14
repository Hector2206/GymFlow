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

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}