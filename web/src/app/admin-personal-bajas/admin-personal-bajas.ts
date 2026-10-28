
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import {
  takeUntilDestroyed
} from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  PersonalAdmin
} from '../models/admin-personal.model';

@Component({
  selector: 'app-admin-personal-bajas',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal-bajas.html',
  styleUrl: './admin-personal-bajas.css'
})
export class AdminPersonalBajas implements OnInit {

  empleados: PersonalAdmin[] = [];

  cargando = false;
  error = '';

  idPersonalSeleccionado: number | null = null;

  motivoBaja = '';
  confirmacionLeida = false;

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarEmpleados();
  }

  // CONSULTAR PERSONAL REAL

  cargarEmpleados(): void {

    if (this.cargando) {
      return;
    }

    this.cargando = true;
    this.error = '';
    this.empleados = [];

    this.personalService
      .obtenerPersonal()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: PersonalAdmin[]) => {

          this.cargando = false;

          if (!Array.isArray(respuesta)) {

            this.error =
              'El servidor devolvió una respuesta inesperada.';

          } else {

            this.empleados = respuesta;
          }

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargando = false;

          if (error.status === 401) {

            this.error =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.error =
              'No tienes permisos para consultar empleados.';

          } else if (error.status === 0 || error.status >= 500) {

            this.error =
              'No fue posible conectar con el servidor. Intenta nuevamente.';

          } else {

            this.error =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudo consultar el personal.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // PERSONAL DISPONIBLE PARA BAJA

  get empleadosActivos(): PersonalAdmin[] {

    return this.empleados.filter(
      empleado => empleado.estatus === 'Activo'
    );
  }

  // EMPLEADO SELECCIONADO

  get empleadoSeleccionado(): PersonalAdmin | null {

    if (this.idPersonalSeleccionado === null) {
      return null;
    }

    return this.empleadosActivos.find(
      empleado =>
        empleado.idPersonal === this.idPersonalSeleccionado
    ) || null;
  }

  // CAMBIAR SELECCION

  cambiarEmpleado(): void {

    this.motivoBaja = '';
    this.confirmacionLeida = false;
  }

  // VOLVER AL DIRECTORIO

  volverDirectorio(): void {

    this.router.navigate([
      '/admin/personal'
    ]);
  }
}
