
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
  PagoNominaAdmin,
  CambiarSalarioAdminRequest
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

  // CAMBIO SALARIAL

  mostrarFormularioCambio = false;
  mostrarConfirmacionFinal = false;

  montoNuevo: number | null = null;
  motivoCambio = '';
  confirmacionLeida = false;

  cambiandoSalario = false;
  resultadoIncierto = false;

  errorCambio = '';
  mensajeCambio = '';

  fechaVigencia = this.obtenerFechaOperacion();

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

  // FECHA OPERATIVA

  private obtenerFechaOperacion(): string {

    // Se utiliza UTC como referencia inicial.
    // El backend valida la fecha definitiva
    // contra CURRENT_DATE de PostgreSQL.

    return new Date().toISOString().slice(0, 10);
  }

  // CONSULTAR EMPLEADOS

  cargarEmpleados(): void {

    if (this.cargandoEmpleados || this.cambiandoSalario) {
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

          this.errorEmpleados = this.obtenerMensajeError(
            error,
            'No fue posible consultar empleados.'
          );

          this.changeDetector.detectChanges();
        }
      });
  }

  // EMPLEADO SELECCIONADO

  get empleadoSeleccionado(): PersonalAdmin | null {

    if (this.idPersonalSeleccionado === null) {
      return null;
    }

    return this.empleados.find(
      empleado =>
        empleado.idPersonal === this.idPersonalSeleccionado
    ) || null;
  }

  cambiarEmpleado(): void {

    if (this.cambiandoSalario) {
      return;
    }

    this.cancelarFormulario();
    this.mensajeCambio = '';
    this.cargarDetalles();
  }

  // CONSULTAR HISTORIALES

  cargarDetalles(): void {

    if (this.cambiandoSalario) {
      return;
    }

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
              'La respuesta salarial no es válida.';

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

          this.errorSalarios = this.obtenerMensajeError(
            error,
            'No se pudo consultar el historial salarial.'
          );

          this.changeDetector.detectChanges();
        }
      });

    // PAGOS DE NOMINA

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
              'La respuesta de nómina no es válida.';

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

          this.errorPagos = this.obtenerMensajeError(
            error,
            'No se pudo consultar el historial de nómina.'
          );

          this.changeDetector.detectChanges();
        }
      });
  }

  // SALARIO VIGENTE

  get salarioVigente(): SalarioPersonalAdmin | null {

    return this.salarios.find(
      salario => salario.vigenteHasta === null
    ) || null;
  }

  // CONDICIONES DEL BACKEND PARA CAMBIAR SUELDO

  get puedeAbrirCambio(): boolean {

    const empleado = this.empleadoSeleccionado;
    const vigente = this.salarioVigente;

    if (
      !empleado ||
      !vigente ||
      empleado.estatus !== 'Activo' ||
      this.cargandoSalarios ||
      this.cargandoEmpleados ||
      !!this.errorSalarios ||
      this.cambiandoSalario ||
      this.resultadoIncierto
    ) {
      return false;
    }

    if (vigente.periodicidad !== 'Mensual') {
      return false;
    }

    if (Number(vigente.monto) !== Number(empleado.salario)) {
      return false;
    }

    return vigente.vigenteDesde < this.obtenerFechaOperacion();
  }

  // ABRIR FORMULARIO

  abrirCambioSalario(): void {

    if (!this.puedeAbrirCambio) {
      return;
    }

    this.fechaVigencia = this.obtenerFechaOperacion();

    this.montoNuevo = null;
    this.motivoCambio = '';
    this.confirmacionLeida = false;

    this.errorCambio = '';
    this.mensajeCambio = '';

    this.mostrarFormularioCambio = true;
    this.mostrarConfirmacionFinal = false;
  }

  // CERRAR FORMULARIO

  cancelarFormulario(): void {

    if (this.cambiandoSalario) {
      return;
    }

    this.mostrarFormularioCambio = false;
    this.mostrarConfirmacionFinal = false;

    this.montoNuevo = null;
    this.motivoCambio = '';
    this.confirmacionLeida = false;

    this.errorCambio = '';
  }

  // VALIDAR MONTO

  private montoValido(monto: number | null): boolean {

    return (
      typeof monto === 'number' &&
      Number.isFinite(monto) &&
      monto >= 0 &&
      monto <= 99999999.99 &&
      Math.round(monto * 100) / 100 === monto
    );
  }

  get puedeConfirmarCambio(): boolean {

    const vigente = this.salarioVigente;

    if (
      !this.mostrarFormularioCambio ||
      !this.puedeAbrirCambio ||
      !vigente ||
      !this.montoValido(this.montoNuevo) ||
      !this.confirmacionLeida ||
      !this.motivoCambio.trim()
    ) {
      return false;
    }

    return (
      this.montoNuevo !== Number(vigente.monto) &&
      this.fechaVigencia === this.obtenerFechaOperacion()
    );
  }

  // PREPARAR CONFIRMACION FINAL

  prepararCambio(): void {

    this.errorCambio = '';

    if (!this.puedeConfirmarCambio) {

      this.errorCambio =
        'Verifica el sueldo, el motivo y la confirmación. ' +
        'El nuevo monto debe ser distinto del actual.';

      return;
    }

    this.mostrarConfirmacionFinal = true;
  }

  cancelarConfirmacion(): void {

    if (this.cambiandoSalario) {
      return;
    }

    this.mostrarConfirmacionFinal = false;
  }

  // REGISTRAR CAMBIO REAL EN POSTGRESQL

  confirmarCambioSalario(): void {

    if (
      !this.mostrarConfirmacionFinal ||
      !this.puedeConfirmarCambio
    ) {
      return;
    }

    const empleado = this.empleadoSeleccionado;
    const monto = this.montoNuevo;

    if (!empleado || monto === null) {
      return;
    }

    const idPersonal = empleado.idPersonal;

    const datos: CambiarSalarioAdminRequest = {
      monto,
      vigenteDesde: this.fechaVigencia,
      motivo: this.motivoCambio.trim()
    };

    this.cambiandoSalario = true;
    this.errorCambio = '';

    this.nominaService
      .cambiarSalario(idPersonal, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.cambiandoSalario = false;

          if (
            !respuesta ||
            respuesta.idPersonal !== idPersonal ||
            typeof respuesta.idSalario !== 'number' ||
            !Number.isInteger(respuesta.idSalario) ||
            respuesta.idSalario <= 0
          ) {

            this.resultadoIncierto = true;

            this.errorCambio =
              'El servidor respondió de forma inesperada. ' +
              'Comprueba el historial antes de intentar otro cambio.';

            this.mostrarConfirmacionFinal = false;
            this.changeDetector.detectChanges();
            return;
          }

          this.mostrarFormularioCambio = false;
          this.mostrarConfirmacionFinal = false;

          this.montoNuevo = null;
          this.motivoCambio = '';
          this.confirmacionLeida = false;

          this.mensajeCambio =
            'Sueldo actualizado correctamente. ' +
            `Registro salarial: #${respuesta.idSalario}.`;

          // RECARGAR SUELDO E HISTORIALES

          this.cargarEmpleados();
          this.cargarDetalles();

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cambiandoSalario = false;
          this.mostrarConfirmacionFinal = false;

          const mensajeServidor = this.obtenerMensajeError(
            error,
            'No fue posible actualizar el sueldo.'
          );

          if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.resultadoIncierto = true;

            this.errorCambio =
              'No se pudo confirmar si el cambio se guardó. ' +
              'Revisa el historial salarial antes de volver a intentarlo.';

          } else if (error.status === 409) {

            this.resultadoIncierto = true;

            this.errorCambio =
              mensajeServidor +
              ' Actualiza la consulta para revisar el salario.';

          } else {

            this.errorCambio = mensajeServidor;
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // FORMATOS

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

  mostrarFecha(fecha: string | null): string {

    if (!fecha) {
      return '—';
    }

    const corta = fecha.slice(0, 10);
    const partes = corta.split('-');

    if (partes.length !== 3) {
      return corta;
    }

    return `${partes[2]}/${partes[1]}/${partes[0]}`;
  }

  // ERRORES

  private obtenerMensajeError(
    error: HttpErrorResponse,
    mensajeDefault: string
  ): string {

    if (error.status === 401) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }

    if (error.status === 403) {
      return 'No tienes permisos para consultar o modificar nómina.';
    }

    if (error.status === 404) {
      return 'El empleado solicitado no fue encontrado.';
    }

    if (error.status === 0 || error.status >= 500) {
      return 'No fue posible conectar con el servidor.';
    }

    if (typeof error.error?.mensaje === 'string') {
      return error.error.mensaje;
    }

    if (typeof error.error?.detail === 'string') {
      return error.error.detail;
    }

    return mensajeDefault;
  }

  volverDirectorio(): void {

    if (this.cambiandoSalario) {
      return;
    }

    this.router.navigate(['/admin/personal']);
  }
}
