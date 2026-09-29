import {
  Component
} from '@angular/core';

import {
  Router
} from '@angular/router';

@Component({
  selector: 'app-administrar-rutinas',
  standalone: true,
  imports: [],
  templateUrl: './administrar-rutinas.html',
  styleUrl: './administrar-rutinas.css'
})
export class AdministrarRutinas {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}