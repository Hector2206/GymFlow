
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import {
  PuestoPersonalAdmin
} from '../models/admin-personal.model';

@Component({
  selector: 'app-admin-personal-alta',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal-alta.html',
  styleUrl: './admin-personal-alta.css'
})
export class AdminPersonalAlta {

  nuevoEmpleado = {
    nombreCompleto: '',
    correo: '',
    telefono: '',
    fechaContratacion: '',
    puesto: '' as PuestoPersonalAdmin | '',
    sueldo: null as number | null,
    password: ''
  };

  fechaMaxima = this.obtenerFechaHoy();

  constructor(
    private router: Router
  ) {}

  private obtenerFechaHoy(): string {

    const hoy = new Date();

    const anio = hoy.getFullYear();

    const mes = String(
      hoy.getMonth() + 1
    ).padStart(2, '0');

    const dia = String(
      hoy.getDate()
    ).padStart(2, '0');

    return `${anio}-${mes}-${dia}`;
  }

  volverDirectorio(): void {

    this.router.navigate([
      '/admin/personal'
    ]);
  }
}
