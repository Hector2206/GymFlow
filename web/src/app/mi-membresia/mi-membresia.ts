
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';

import {
  MiMembresiaResponse
} from '../models/mi-membresia.model';

import {
  MiMembresiaService
} from '../services/mi-membresia.service';

@Component({
  selector: 'app-mi-membresia',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './mi-membresia.html',
  styleUrl: './mi-membresia.css'
})
export class MiMembresia implements OnInit {
  datos: MiMembresiaResponse | null = null;

  cargando = true;
  error = '';

  constructor(
    private servicio: MiMembresiaService,
    private router: Router,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargar();
  }

  cargar(): void {
    if (this.cargando && this.datos !== null) {
      return;
    }

    this.cargando = true;
    this.error = '';
    this.datos = null;

    this.servicio.obtenerMiMembresia().subscribe({
      next: (respuesta) => {
        if (
          !respuesta ||
          !['Vigente', 'Vencida', 'SinPagos']
            .includes(respuesta.estado) ||
          !respuesta.nombrePlan ||
          !Number.isFinite(respuesta.costoMensual) ||
          !Number.isFinite(respuesta.costoAnualidad)
        ) {
          this.error =
            'El servidor devolvió datos de membresía no válidos.';
        } else {
          this.datos = respuesta;
        }

        this.cargando = false;
        this.cd.detectChanges();
      },

      error: (err: HttpErrorResponse) => {
        this.cargando = false;

        if (err.status === 401) {
          this.error =
            'Tu sesión expiró. Inicia sesión nuevamente.';
        } else if (err.status === 403) {
          this.error =
            'Solo los clientes pueden consultar su membresía.';
        } else if (err.status === 404) {
          this.error =
            err.error?.mensaje ||
            'No se encontró una membresía asociada a tu cuenta.';
        } else if (err.status === 0) {
          this.error =
            'No fue posible conectar con el servidor.';
        } else {
          this.error =
            'No fue posible consultar tu membresía.';
        }

        this.cd.detectChanges();
      }
    });
  }

  get etiquetaEstado(): string {
    switch (this.datos?.estado) {
      case 'Vigente':
        return 'Vigente';
      case 'Vencida':
        return 'Vencida';
      case 'SinPagos':
        return 'Sin pagos registrados';
      default:
        return 'Desconocido';
    }
  }

  formatearFecha(fecha: string | null): string {
    if (!fecha) {
      return 'Sin fecha de vencimiento';
    }

    const partes =
      /^(\d{4})-(\d{2})-(\d{2})/.exec(fecha);

    if (!partes) {
      return 'Fecha no disponible';
    }

    return `${partes[3]}/${partes[2]}/${partes[1]}`;
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }

  irMisPagos(): void {
    this.router.navigate(['/mis-pagos']);
  }
}
