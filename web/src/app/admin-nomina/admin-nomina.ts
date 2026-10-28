
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { Location } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
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
  CambiarSalarioAdminRequest,
  CancelarPagoNominaAdminRequest
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

  fechaVigencia = this.obtenerFechaActual();

  // REGISTRO DE PAGO (PANTALLA INDEPENDIENTE)

  mensajeRegistroPago = '';

  // CANCELACIÓN DE PAGOS

  pagoParaCancelar: PagoNominaAdmin | null = null;

  motivoCancelacion = '';
  confirmacionCancelacionLeida = false;

  cancelandoPago = false;
  errorCancelacion = '';
  mensajeCancelacion = '';

  resultadoCancelacionIncierto = false;

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private location: Location,
    private personalService: AdminPersonalService,
    private nominaService: AdminNominaService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {

    const estado = this.location.getState();

    if (
      estado &&
      typeof estado === 'object' &&
      'pagoRegistradoId' in estado
    ) {

      const id = (
        estado as { pagoRegistradoId?: unknown }
      ).pagoRegistradoId;

      if (
        typeof id === 'number' &&
        Number.isInteger(id) &&
        id > 0
      ) {

        this.mensajeRegistroPago =
          `Pago registrado correctamente. Folio #${id}.`;

        this.location.replaceState(
          this.router.url,
          '',
          {}
        );
      }
    }

    this.cargarEmpleados();
  }

  // FECHA LOCAL

  private obtenerFechaActual(): string {

    const fecha = new Date();

    const anio = fecha.getFullYear();
    const mes = String(fecha.getMonth() + 1).padStart(2, '0');
    const dia = String(fecha.getDate()).padStart(2, '0');

    return `${anio}-${mes}-${dia}`;
  }

  // CONSULTAR PERSONAL

  cargarEmpleados(): void {

    if (
      this.cargandoEmpleados ||
      this.cambiandoSalario ||
      this.cancelandoPago
    ) {
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
              'La respuesta del servidor no es válida.';

          } else {

            this.empleados = [...respuesta].sort(
              (a, b) =>
                a.nombreCompleto.localeCompare(
                  b.nombreCompleto,
                  'es'
                )
            );

            const idUrl = Number(
              this.route.snapshot.queryParamMap.get('empleado')
            );

            if (
              Number.isInteger(idUrl) &&
              idUrl > 0 &&
              this.empleados.some(e => e.idPersonal === idUrl)
            ) {
              this.idPersonalSeleccionado = idUrl;
            }

            if (this.empleadoSeleccionado) {
              this.cargarDetalles();
            }
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

  get empleadoSeleccionado(): PersonalAdmin | null {

    return this.empleados.find(
      e => e.idPersonal === this.idPersonalSeleccionado
    ) || null;
  }

  cambiarEmpleado(): void {

    if (
      this.cambiandoSalario ||
      this.cancelandoPago ||
      this.pagoParaCancelar
    ) {
      return;
    }

    this.cancelarFormulario();

    this.mensajeCambio = '';
    this.mensajeRegistroPago = '';
    this.mensajeCancelacion = '';
    this.errorCancelacion = '';

    this.cargarDetalles();
  }

  // CONSULTAR HISTORIALES

  cargarDetalles(): void {

    if (this.cambiandoSalario || this.cancelandoPago) {
      return;
    }

    const empleado = this.empleadoSeleccionado;
    const version = ++this.versionConsulta;

    this.salarios = [];
    this.pagos = [];

    this.errorSalarios = '';
    this.errorPagos = '';

    this.consultaSalariosRealizada = false;
    this.consultaPagosRealizada = false;

    this.cargandoSalarios = false;
    this.cargandoPagos = false;

    if (!empleado) {
      return;
    }

    const id = empleado.idPersonal;

    this.cargandoSalarios = true;
    this.cargandoPagos = true;

    // SALARIOS

    this.nominaService
      .obtenerHistorialSalarial(id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: respuesta => {

          if (version !== this.versionConsulta) {
            return;
          }

          this.cargandoSalarios = false;
          this.consultaSalariosRealizada = true;

          if (Array.isArray(respuesta)) {

            this.salarios = respuesta;

          } else {

            this.errorSalarios =
              'El historial salarial no es válido.';
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

    // PAGOS

    this.nominaService
      .obtenerHistorialNomina(id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: respuesta => {

          if (version !== this.versionConsulta) {
            return;
          }

          this.cargandoPagos = false;
          this.consultaPagosRealizada = true;

          if (Array.isArray(respuesta)) {

            this.pagos = respuesta;

          } else {

            this.errorPagos =
              'El historial de nómina no es válido.';
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

  get salarioVigente(): SalarioPersonalAdmin | null {

    return this.salarios.find(
      s => s.vigenteHasta === null
    ) || null;
  }

  // CAMBIO DE SUELDO

  get puedeAbrirCambio(): boolean {

    const empleado = this.empleadoSeleccionado;
    const vigente = this.salarioVigente;

    return !!(
      empleado &&
      vigente &&
      empleado.estatus === 'Activo' &&
      vigente.periodicidad === 'Mensual' &&
      Number(vigente.monto) === Number(empleado.salario) &&
      vigente.vigenteDesde < this.obtenerFechaActual() &&
      !this.cargandoSalarios &&
      !this.cambiandoSalario &&
      !this.cancelandoPago &&
      !this.pagoParaCancelar &&
      !this.errorSalarios &&
      !this.resultadoIncierto &&
      !this.resultadoCancelacionIncierto
    );
  }

  abrirCambioSalario(): void {

    if (!this.puedeAbrirCambio) {
      return;
    }

    this.fechaVigencia = this.obtenerFechaActual();

    this.montoNuevo = null;
    this.motivoCambio = '';
    this.confirmacionLeida = false;

    this.errorCambio = '';
    this.mensajeCambio = '';

    this.mostrarFormularioCambio = true;
    this.mostrarConfirmacionFinal = false;
  }

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

  get puedeConfirmarCambio(): boolean {

    const vigente = this.salarioVigente;
    const monto = this.montoNuevo;

    return !!(
      this.mostrarFormularioCambio &&
      this.puedeAbrirCambio &&
      vigente &&
      typeof monto === 'number' &&
      Number.isFinite(monto) &&
      monto >= 0 &&
      monto <= 99999999.99 &&
      Math.abs(
        monto * 100 - Math.round(monto * 100)
      ) < 0.000001 &&
      monto !== Number(vigente.monto) &&
      this.motivoCambio.trim() &&
      this.confirmacionLeida &&
      this.fechaVigencia === this.obtenerFechaActual()
    );
  }

  prepararCambio(): void {

    this.errorCambio = '';

    if (!this.puedeConfirmarCambio) {

      this.errorCambio =
        'Revisa el monto, el motivo y la autorización.';

      return;
    }

    this.mostrarConfirmacionFinal = true;
  }

  cancelarConfirmacion(): void {

    if (!this.cambiandoSalario) {
      this.mostrarConfirmacionFinal = false;
    }
  }

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

    const datos: CambiarSalarioAdminRequest = {
      monto,
      vigenteDesde: this.fechaVigencia,
      motivo: this.motivoCambio.trim()
    };

    this.cambiandoSalario = true;
    this.errorCambio = '';

    this.nominaService
      .cambiarSalario(empleado.idPersonal, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: respuesta => {

          this.cambiandoSalario = false;
          this.mostrarConfirmacionFinal = false;

          if (
            respuesta?.idPersonal !== empleado.idPersonal ||
            !Number.isInteger(respuesta.idSalario) ||
            respuesta.idSalario <= 0
          ) {

            this.resultadoIncierto = true;

            this.errorCambio =
              'Respuesta inesperada. Consulta el historial ' +
              'antes de intentar otro cambio.';

            this.changeDetector.detectChanges();
            return;
          }

          this.cancelarFormulario();

          this.mensajeCambio =
            `Sueldo actualizado. Registro #${respuesta.idSalario}.`;

          this.cargarEmpleados();
          this.cargarDetalles();

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cambiandoSalario = false;
          this.mostrarConfirmacionFinal = false;

          if (
            error.status === 0 ||
            error.status >= 500 ||
            error.status === 409
          ) {
            this.resultadoIncierto = true;
          }

          this.errorCambio = this.obtenerMensajeError(
            error,
            'No fue posible cambiar el sueldo.'
          );

          this.changeDetector.detectChanges();
        }
      });
  }

  // REGISTRO DE PAGOS EN PANTALLA INDEPENDIENTE

  get puedeAbrirRegistroPago(): boolean {

    return !!(
      this.empleadoSeleccionado &&
      this.consultaSalariosRealizada &&
      this.consultaPagosRealizada &&
      !this.cargandoSalarios &&
      !this.cargandoPagos &&
      !this.cambiandoSalario &&
      !this.cancelandoPago &&
      !this.pagoParaCancelar &&
      !this.mostrarFormularioCambio &&
      !this.resultadoIncierto &&
      !this.resultadoCancelacionIncierto &&
      !this.errorSalarios &&
      !this.errorPagos &&
      this.salarios.some(s => s.periodicidad === 'Mensual')
    );
  }

  abrirRegistroPago(): void {

    const empleado = this.empleadoSeleccionado;

    if (!empleado || !this.puedeAbrirRegistroPago) {
      return;
    }

    this.router.navigate([
      '/admin/personal/nomina/pago',
      empleado.idPersonal
    ]);
  }

  // CANCELAR PAGO REGISTRADO

  puedeCancelarPago(pago: PagoNominaAdmin): boolean {

    return !!(
      this.empleadoSeleccionado &&
      pago.idPersonal === this.empleadoSeleccionado.idPersonal &&
      pago.estado === 'Pagado' &&
      this.consultaPagosRealizada &&
      !this.cargandoPagos &&
      !this.cambiandoSalario &&
      !this.cancelandoPago &&
      !this.mostrarFormularioCambio &&
      !this.pagoParaCancelar &&
      !this.resultadoIncierto &&
      !this.resultadoCancelacionIncierto
    );
  }

  abrirCancelacion(pago: PagoNominaAdmin): void {

    if (!this.puedeCancelarPago(pago)) {
      return;
    }

    this.pagoParaCancelar = pago;
    this.motivoCancelacion = '';
    this.confirmacionCancelacionLeida = false;
    this.errorCancelacion = '';
    this.mensajeCancelacion = '';
  }

  cerrarCancelacion(): void {

    if (this.cancelandoPago) {
      return;
    }

    this.pagoParaCancelar = null;
    this.motivoCancelacion = '';
    this.confirmacionCancelacionLeida = false;

    if (!this.resultadoCancelacionIncierto) {
      this.errorCancelacion = '';
    }
  }

  get puedeConfirmarCancelacion(): boolean {

    const pago = this.pagoParaCancelar;
    const empleado = this.empleadoSeleccionado;

    return !!(
      pago &&
      empleado &&
      pago.idPersonal === empleado.idPersonal &&
      pago.estado === 'Pagado' &&
      this.pagos.some(
        registro =>
          registro.idPago === pago.idPago &&
          registro.estado === 'Pagado'
      ) &&
      this.motivoCancelacion.trim().length > 0 &&
      this.confirmacionCancelacionLeida &&
      !this.cambiandoSalario &&
      !this.cancelandoPago &&
      !this.resultadoCancelacionIncierto
    );
  }

  confirmarCancelacion(): void {

    if (!this.puedeConfirmarCancelacion) {
      return;
    }

    const pago = this.pagoParaCancelar;
    const empleado = this.empleadoSeleccionado;

    if (!pago || !empleado) {
      return;
    }

    const idPersonal = empleado.idPersonal;
    const idPago = pago.idPago;

    const datos: CancelarPagoNominaAdminRequest = {
      motivo: this.motivoCancelacion.trim()
    };

    this.cancelandoPago = true;
    this.errorCancelacion = '';

    this.nominaService
      .cancelarPagoNomina(idPersonal, idPago, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: respuesta => {

          this.cancelandoPago = false;

          if (
            !respuesta ||
            respuesta.idPersonal !== idPersonal ||
            respuesta.idPago !== idPago
          ) {

            this.resultadoCancelacionIncierto = true;

            this.errorCancelacion =
              'El servidor respondió de forma inesperada. ' +
              'Revisa el historial antes de intentar otra operación.';

            this.pagoParaCancelar = null;
            this.changeDetector.detectChanges();
            return;
          }

          this.cerrarCancelacion();

          this.mensajeCancelacion =
            `El pago #${idPago} se canceló correctamente. ` +
            'El registro permanece en el historial.';

          this.cargarDetalles();
          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cancelandoPago = false;

          if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.resultadoCancelacionIncierto = true;

            this.errorCancelacion =
              'No se pudo confirmar si el registro fue cancelado. ' +
              'Revisa el historial antes de realizar otra operación.';

            this.pagoParaCancelar = null;

          } else {

            this.errorCancelacion = this.obtenerMensajeError(
              error,
              'No fue posible cancelar el pago.'
            );
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // FORMATOS

  mostrarMonto(monto: number): string {

    if (!Number.isFinite(Number(monto))) {
      return 'No disponible';
    }

    return new Intl.NumberFormat('es-MX', {
      style: 'currency',
      currency: 'MXN'
    }).format(monto);
  }

  mostrarFecha(fecha: string | null): string {

    if (!fecha) {
      return '—';
    }

    const partes = fecha.slice(0, 10).split('-');

    return partes.length === 3
      ? `${partes[2]}/${partes[1]}/${partes[0]}`
      : fecha;
  }

  private obtenerMensajeError(
    error: HttpErrorResponse,
    predeterminado: string
  ): string {

    if (error.status === 401) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }

    if (error.status === 403) {
      return 'No tienes permisos para esta operación.';
    }

    if (error.status === 404) {
      return 'El expediente o pago no fue encontrado.';
    }

    if (error.status === 0 || error.status >= 500) {
      return 'No fue posible confirmar la operación con el servidor.';
    }

    if (typeof error.error?.mensaje === 'string') {
      return error.error.mensaje;
    }

    if (typeof error.error?.detail === 'string') {
      return error.error.detail;
    }

    return predeterminado;
  }

  volverDirectorio(): void {

    if (!this.cambiandoSalario && !this.cancelandoPago) {
      this.router.navigate(['/admin/personal']);
    }
  }
}
