import {
  Component
} from '@angular/core';

import {
  Router
} from '@angular/router';

@Component({
  selector: 'app-historial-asistencias',
  standalone: true,
  imports: [],
  templateUrl: './historial-asistencias.html',
  styleUrl: './historial-asistencias.css'
})
export class HistorialAsistencias {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}