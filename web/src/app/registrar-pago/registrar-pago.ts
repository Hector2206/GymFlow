import {
  Component
} from '@angular/core';

import {
  Router
} from '@angular/router';

@Component({
  selector: 'app-registrar-pago',
  standalone: true,
  imports: [],
  templateUrl: './registrar-pago.html',
  styleUrl: './registrar-pago.css'
})
export class RegistrarPago {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}