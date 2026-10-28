
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  AdminDashboardService
} from '../services/admin-dashboard.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './admin-dashboard.html',
  styleUrl: './admin-dashboard.css'
})
export class AdminDashboard implements OnInit {

  // Total de clientes
  totalClientes: number | null = null;
  cargandoClientes = false;
  errorClientes = '';

  // Membresias activas
  membresiasActivas: number | null = null;
  cargandoMembresias = false;
  errorMembresias = '';

  // Asistencias del dia
  asistenciasDia: number | null = null;
  cargandoAsistencias = false;
  errorAsistencias = '';

  constructor(
    private router: Router,
    private dashboardService: AdminDashboardService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarTotalClientes();
    this.cargarMembresiasActivas();
    this.cargarAsistenciasDia();
  }

  // TOTAL DE CLIENTES

  cargarTotalClientes(): void {

    this.cargandoClientes = true;
    this.errorClientes = '';
    this.totalClientes = null;

    this.dashboardService
      .obtenerTotalClientes()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {
          this.totalClientes = respuesta.totalClientes;
          this.cargandoClientes = false;
          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {
          this.cargandoClientes = false;

          if (error.status === 401) {
            this.errorClientes =
              'Tu sesión venció. Inicia sesión nuevamente.';
          } else if (error.status === 403) {
            this.errorClientes =
              'No tienes permisos para consultar esta información.';
          } else if (error.status === 0 || error.status >= 500) {
            this.errorClientes =
              'No fue posible conectar con el servidor. Intenta nuevamente.';
          } else {
            this.errorClientes =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudo consultar el total de clientes.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // MEMBRESIAS ACTIVAS

  cargarMembresiasActivas(): void {

    this.cargandoMembresias = true;
    this.errorMembresias = '';
    this.membresiasActivas = null;

    this.dashboardService
      .obtenerMembresiasActivas()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {
          this.membresiasActivas =
            respuesta.membresiasActivas;

          this.cargandoMembresias = false;
          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {
          this.cargandoMembresias = false;

          if (error.status === 401) {
            this.errorMembresias =
              'Tu sesión venció. Inicia sesión nuevamente.';
          } else if (error.status === 403) {
            this.errorMembresias =
              'No tienes permisos para consultar las membresías.';
          } else if (error.status === 0 || error.status >= 500) {
            this.errorMembresias =
              'No fue posible conectar con el servidor. Intenta nuevamente.';
          } else {
            this.errorMembresias =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudieron consultar las membresías activas.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // ASISTENCIAS DEL DIA

  cargarAsistenciasDia(): void {

    this.cargandoAsistencias = true;
    this.errorAsistencias = '';
    this.asistenciasDia = null;

    this.dashboardService
      .obtenerAsistenciasDia()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.asistenciasDia = respuesta.asistenciasDia;
          this.cargandoAsistencias = false;

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargandoAsistencias = false;

          if (error.status === 401) {

            this.errorAsistencias =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorAsistencias =
              'No tienes permisos para consultar asistencias.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.errorAsistencias =
              'No fue posible conectar con el servidor. Intenta nuevamente.';

          } else {

            this.errorAsistencias =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudieron consultar las asistencias del día.';

          }

          this.changeDetector.detectChanges();
        }

      });
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
