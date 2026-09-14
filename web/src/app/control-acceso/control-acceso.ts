import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-control-acceso',
  standalone: true,
  imports: [],
  templateUrl: './control-acceso.html',
  styleUrl: './control-acceso.css'
})
export class ControlAcceso {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}