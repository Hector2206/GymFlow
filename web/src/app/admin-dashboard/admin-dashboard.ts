
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

import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [FormsModule],
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

  // Pagos registrados
  pagosRegistrados: number | null = null;
  cargandoPagos = false;
  errorPagos = '';
  // Consulta de ingresos por periodo
    fechaDesde = '';
    fechaHasta = '';

    errorPeriodo = '';
    periodoValidado = false;

    


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
    this.cargarPagosRegistrados();
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
          } else if (error.status === 0 || error.status >= 500) {
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

  // PAGOS REGISTRADOS

  cargarPagosRegistrados(): void {

    this.cargandoPagos = true;
    this.errorPagos = '';
    this.pagosRegistrados = null;

    this.dashboardService
      .obtenerPagosRegistrados()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.pagosRegistrados =
            respuesta.pagosRegistrados;

          this.cargandoPagos = false;
          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargandoPagos = false;

          if (error.status === 401) {

            this.errorPagos =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorPagos =
              'No tienes permisos para consultar pagos.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.errorPagos =
              'No fue posible conectar con el servidor. Intenta nuevamente.';

          } else {

            this.errorPagos =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudieron consultar los pagos registrados.';

          }

          this.changeDetector.detectChanges();
        }

      });
  }

  
reiniciarValidacionPeriodo(): void {
  this.errorPeriodo = '';
  this.periodoValidado = false;
}

validarPeriodo(): void {

  this.errorPeriodo = '';
  this.periodoValidado = false;

  if (!this.fechaDesde || !this.fechaHasta) {
    this.errorPeriodo =
      'Debes seleccionar ambas fechas.';
    return;
  }

  if (this.fechaDesde > this.fechaHasta) {
    this.errorPeriodo =
      'La fecha inicial no puede ser posterior a la fecha final.';
    return;
  }

  this.periodoValidado = true;
}


  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
