
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  AdminNominaService
} from '../services/admin-nomina.service';

import {
  PersonalAdmin
} from '../models/admin-personal.model';

import {
  SalarioPersonalAdmin,
  PagoNominaAdmin
} from '../models/admin-nomina.model';

@Component({
  selector: 'app-admin-nomina',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-nomina.html',
  styleUrl: './admin-nomina.css'
})
export class AdminNomina implements OnInit {

  empleados: PersonalAdmin[] = [];

  idPersonalSeleccionado: number | null = null;

  salarios: SalarioPersonalAdmin[] = [];
  pagos: PagoNominaAdmin[] = [];

  cargandoEmpleados = false;
  cargandoSalarios = false;
  cargandoPagos = false;

  consultaSalariosRealizada = false;
  consultaPagosRealizada = false;

  errorEmpleados = '';
  errorSalarios = '';
  errorPagos = '';

  private versionConsulta = 0;

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private nominaService: AdminNominaService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarEmpleados();
  }

  // CONSULTAR EMPLEADOS

  cargarEmpleados(): void {

    if (this.cargandoEmpleados) {
      return;
    }

    this.cargandoEmpleados = true;
    this.errorEmpleados = '';

    this.personalService
      .obtenerPersonal()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: PersonalAdmin[]) => {

          this.cargandoEmpleados = false;

          if (!Array.isArray(respuesta)) {

            this.errorEmpleados =
              'El servidor devolvió una respuesta inesperada.';

          } else {

            this.empleados = [...respuesta].sort(
              (a, b) =>
                a.nombreCompleto.localeCompare(
                  b.nombreCompleto,
                  'es'
                )
            );
          }

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargandoEmpleados = false;

          this.errorEmpleados =
            this.obtenerMensajeError(
              error,
              'No fue posible consultar empleados.'
            );

          this.changeDetector.detectChanges();
        }
      });
  }

  // EMPLEADO ELEGIDO

  get empleadoSeleccionado(): PersonalAdmin | null {

    if (this.idPersonalSeleccionado === null) {
      return null;
    }

    return this.empleados.find(
      empleado =>
        empleado.idPersonal ===
        this.idPersonalSeleccionado
    ) || null;
  }

  // CAMBIAR DE EMPLEADO

  cambiarEmpleado(): void {
    this.cargarDetalles();
  }

  // CONSULTAR SALARIOS Y PAGOS

  cargarDetalles(): void {

    this.versionConsulta++;

    const version = this.versionConsulta;
    const empleado = this.empleadoSeleccionado;

    this.salarios = [];
    this.pagos = [];

    this.errorSalarios = '';
    this.errorPagos = '';

    this.cargandoSalarios = false;
    this.cargandoPagos = false;

    this.consultaSalariosRealizada = false;
    this.consultaPagosRealizada = false;

    if (!empleado) {
      return;
    }

    const id = empleado.idPersonal;

    this.cargandoSalarios = true;
    this.cargandoPagos = true;

    // HISTORIAL SALARIAL

    this.nominaService
      .obtenerHistorialSalarial(id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: SalarioPersonalAdmin[]) => {

          if (version !== this.versionConsulta) {
            return;
          }

          this.cargandoSalarios = false;
          this.consultaSalariosRealizada = true;

          if (!Array.isArray(respuesta)) {

            this.errorSalarios =
              'La respuesta del historial salarial no es válida.';

          } else {

            this.salarios = respuesta;
          }

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          if (version !== this.versionConsulta) {
            return;
          }

          this.cargandoSalarios = false;
          this.consultaSalariosRealizada = true;

          this.errorSalarios =
            this.obtenerMensajeError(
              error,
              'No se pudo consultar el historial salarial.'
            );

          this.changeDetector.detectChanges();
        }
      });

    // HISTORIAL DE NOMINA

    this.nominaService
      .obtenerHistorialNomina(id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: PagoNominaAdmin[]) => {

          if (version !== this.versionConsulta) {
            return;
          }

          this.cargandoPagos = false;
          this.consultaPagosRealizada = true;

          if (!Array.isArray(respuesta)) {

            this.errorPagos =
              'La respuesta del historial de nómina no es válida.';

          } else {

            this.pagos = respuesta;
          }

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          if (version !== this.versionConsulta) {
            return;
          }

          this.cargandoPagos = false;
          this.consultaPagosRealizada = true;

          this.errorPagos =
            this.obtenerMensajeError(
              error,
              'No se pudo consultar el historial de nómina.'
            );

          this.changeDetector.detectChanges();
        }
      });
  }

  // SALARIO VIGENTE EN EL HISTORIAL

  get salarioVigente(): SalarioPersonalAdmin | null {

    return this.salarios.find(
      salario => salario.vigenteHasta === null
    ) || null;
  }

  // FORMATO DE MONEDA

  mostrarMonto(monto: number): string {

    if (
      monto === null ||
      monto === undefined ||
      !Number.isFinite(Number(monto))
    ) {
      return 'No disponible';
    }

    return new Intl.NumberFormat('es-MX', {
      style: 'currency',
      currency: 'MXN',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(monto);
  }

  // FORMATO DE FECHA

  mostrarFecha(fecha: string | null): string {

    if (!fecha) {
      return '—';
    }

    const fechaCorta = fecha.slice(0, 10);
    const partes = fechaCorta.split('-');

    if (partes.length !== 3) {
      return fechaCorta;
    }

    return `${partes[2]}/${partes[1]}/${partes[0]}`;
  }

  // ERRORES DE CONEXION

  private obtenerMensajeError(
    error: HttpErrorResponse,
    mensajeDefault: string
  ): string {

    if (error.status === 401) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }

    if (error.status === 403) {
      return 'No tienes permisos para consultar nómina.';
    }

    if (error.status === 404) {
      return 'El expediente del empleado no fue encontrado.';
    }

    if (error.status === 0 || error.status >= 500) {
      return 'No fue posible conectar con el servidor. Intenta nuevamente.';
    }

    if (typeof error.error?.mensaje === 'string') {
      return error.error.mensaje;
    }

    if (typeof error.error?.detail === 'string') {
      return error.error.detail;
    }

    return mensajeDefault;
  }

  // VOLVER AL DIRECTORIO

  volverDirectorio(): void {

    this.router.navigate([
      '/admin/personal'
    ]);
  }
}
