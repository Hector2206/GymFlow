import {
  Component
} from '@angular/core';

import {
  Router
} from '@angular/router';

@Component({
  selector: 'app-mis-clientes-entrenador',
  standalone: true,
  imports: [],
  templateUrl: './mis-clientes-entrenador.html',
  styleUrl: './mis-clientes-entrenador.css'
})
export class MisClientesEntrenador {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}