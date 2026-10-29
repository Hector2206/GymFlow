
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';

import {
  AdminDashboardService
} from '../services/admin-dashboard.service';

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

  // Ingresos por periodo
  fechaDesde = '';
  fechaHasta = '';

  errorPeriodo = '';
  periodoValidado = false;

  ingresosPeriodo: number | null = null;
  ingresosFormateados = '';

  periodoConsultadoDesde = '';
  periodoConsultadoHasta = '';

  cargandoIngresos = false;
  errorIngresos = '';

  private consultaIngresos?: Subscription;

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
          } else if (error.status === 0 || error.status >= 500) {
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

  // VALIDACION DEL PERIODO

  reiniciarValidacionPeriodo(): void {

    // Cancelar una consulta anterior si cambian las fechas.
    this.consultaIngresos?.unsubscribe();
    this.consultaIngresos = undefined;

    this.errorPeriodo = '';
    this.periodoValidado = false;

    this.ingresosPeriodo = null;
    this.ingresosFormateados = '';
    this.errorIngresos = '';
    this.cargandoIngresos = false;

    this.periodoConsultadoDesde = '';
    this.periodoConsultadoHasta = '';
  }

  validarPeriodo(): boolean {

    this.errorPeriodo = '';
    this.periodoValidado = false;

    if (!this.fechaDesde || !this.fechaHasta) {
      this.errorPeriodo =
        'Debes seleccionar ambas fechas.';
      return false;
    }

    if (this.fechaDesde > this.fechaHasta) {
      this.errorPeriodo =
        'La fecha inicial no puede ser posterior a la fecha final.';
      return false;
    }

    this.periodoValidado = true;
    return true;
  }

  // CONSULTA REAL DE INGRESOS

  consultarIngresos(): void {

    if (this.cargandoIngresos) {
      return;
    }

    if (!this.validarPeriodo()) {
      return;
    }

    this.consultaIngresos?.unsubscribe();

    const desde = this.fechaDesde;
    const hasta = this.fechaHasta;

    this.cargandoIngresos = true;
    this.errorIngresos = '';
    this.ingresosPeriodo = null;
    this.ingresosFormateados = '';

    this.consultaIngresos = this.dashboardService
      .obtenerIngresosPeriodo(desde, hasta)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.ingresosPeriodo =
            respuesta.ingresosPeriodo;

          this.periodoConsultadoDesde =
            respuesta.desde;

          this.periodoConsultadoHasta =
            respuesta.hasta;

          this.ingresosFormateados =
            new Intl.NumberFormat('es-MX', {
              style: 'currency',
              currency: 'MXN',
              minimumFractionDigits: 2,
              maximumFractionDigits: 2
            }).format(respuesta.ingresosPeriodo);

          this.cargandoIngresos = false;

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargandoIngresos = false;

          const mensajeServidor =
            typeof error.error?.mensaje === 'string'
              ? error.error.mensaje
              : typeof error.error?.detail === 'string'
                ? error.error.detail
                : typeof error.error?.title === 'string'
                  ? error.error.title
                  : '';

          if (error.status === 401) {
            this.errorIngresos =
              'Tu sesión venció. Inicia sesión nuevamente.';
          } else if (error.status === 403) {
            this.errorIngresos =
              'No tienes permisos para consultar ingresos.';
          } else if (error.status === 0 || error.status >= 500) {
            this.errorIngresos =
              'No fue posible conectar con el servidor. Intenta nuevamente.';
          } else {
            this.errorIngresos =
              mensajeServidor ||
              'No se pudieron consultar los ingresos del periodo.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
