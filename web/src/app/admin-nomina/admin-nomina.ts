
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
  CambiarSalarioAdminRequest,
  MetodoPagoNominaAdmin,
  RegistrarPagoNominaAdminRequest
} from '../models/admin-nomina.model';

interface FormularioPagoNomina {
  periodoInicio: string;
  periodoFin: string;
  monto: number | null;
  fechaPago: string;
  metodo: MetodoPagoNominaAdmin;
  referencia: string;
  observaciones: string;
}

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

  // CAMBIO SALARIAL EXISTENTE

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

  // REGISTRO DE PAGO DE NÓMINA

  mostrarFormularioPago = false;
  mostrarConfirmacionPago = false;

  registrandoPago = false;
  resultadoPagoIncierto = false;

  errorRegistroPago = '';
  mensajeRegistroPago = '';

  formularioPago: FormularioPagoNomina =
    this.crearFormularioPago();

  confirmacionPagoLeida = false;

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

  // FECHA DE OPERACIÓN

  private obtenerFechaOperacion(): string {

    // PostgreSQL validará la fecha definitiva.

    return new Date().toISOString().slice(0, 10);
  }

  get fechaActual(): string {
    return this.obtenerFechaOperacion();
  }

  private crearFormularioPago(): FormularioPagoNomina {

    return {
      periodoInicio: '',
      periodoFin: '',
      monto: null,
      fechaPago: this.obtenerFechaOperacion(),
      metodo: 'Efectivo',
      referencia: '',
      observaciones: ''
    };
  }

  // CONSULTAR EMPLEADOS

  cargarEmpleados(): void {

    if (
      this.cargandoEmpleados ||
      this.cambiandoSalario ||
      this.registrandoPago
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
        empleado.idPersonal ===
        this.idPersonalSeleccionado
    ) || null;
  }

  // CAMBIAR EMPLEADO

  cambiarEmpleado(): void {

    if (this.cambiandoSalario || this.registrandoPago) {
      return;
    }

    this.cancelarFormulario();
    this.cancelarFormularioPago();

    this.mensajeCambio = '';
    this.mensajeRegistroPago = '';

    this.cargarDetalles();
  }

  // CONSULTAR HISTORIALES

  cargarDetalles(): void {

    if (this.cambiandoSalario || this.registrandoPago) {
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

  // CAMBIO SALARIAL

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
      this.registrandoPago ||
      this.mostrarFormularioPago ||
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

  private montoSalarioValido(
    monto: number | null
  ): boolean {

    return (
      typeof monto === 'number' &&
      Number.isFinite(monto) &&
      monto >= 0 &&
      monto <= 99999999.99 &&
      Math.abs(
        monto * 100 - Math.round(monto * 100)
      ) < 0.000001
    );
  }

  get puedeConfirmarCambio(): boolean {

    const vigente = this.salarioVigente;

    if (
      !this.mostrarFormularioCambio ||
      !this.puedeAbrirCambio ||
      !vigente ||
      !this.montoSalarioValido(this.montoNuevo) ||
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

  // VALIDAR FECHAS DE PAGO

  private fechaValida(fecha: string): boolean {

    if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha)) {
      return false;
    }

    const valor = new Date(`${fecha}T00:00:00Z`);

    return (
      !Number.isNaN(valor.getTime()) &&
      valor.toISOString().slice(0, 10) === fecha
    );
  }

  // ABRIR REGISTRO DE PAGO

  get puedeAbrirRegistroPago(): boolean {

    return (
      this.empleadoSeleccionado !== null &&
      this.consultaSalariosRealizada &&
      this.consultaPagosRealizada &&
      !this.cargandoEmpleados &&
      !this.cargandoSalarios &&
      !this.cargandoPagos &&
      !this.cambiandoSalario &&
      !this.registrandoPago &&
      !this.mostrarFormularioCambio &&
      !this.resultadoIncierto &&
      !this.resultadoPagoIncierto &&
      !this.errorSalarios &&
      !this.errorPagos &&
      this.salarios.some(s => s.periodicidad === 'Mensual')
    );
  }

  abrirRegistroPago(): void {

    if (!this.puedeAbrirRegistroPago) {
      return;
    }

    this.formularioPago = this.crearFormularioPago();

    this.confirmacionPagoLeida = false;
    this.errorRegistroPago = '';
    this.mensajeRegistroPago = '';

    this.mostrarFormularioPago = true;
    this.mostrarConfirmacionPago = false;
  }

  cancelarFormularioPago(): void {

    if (this.registrandoPago) {
      return;
    }

    this.mostrarFormularioPago = false;
    this.mostrarConfirmacionPago = false;

    this.confirmacionPagoLeida = false;
    this.errorRegistroPago = '';

    this.formularioPago = this.crearFormularioPago();
  }

  // VERIFICAR PERIODO Y DATOS

  private validarPago(): string {

    const empleado = this.empleadoSeleccionado;
    const pago = this.formularioPago;

    if (!empleado) {
      return 'Selecciona un empleado.';
    }

    if (
      !this.fechaValida(pago.periodoInicio) ||
      !this.fechaValida(pago.periodoFin)
    ) {
      return 'Selecciona el inicio y el fin del periodo.';
    }

    if (pago.periodoFin < pago.periodoInicio) {
      return 'El fin del periodo debe ser igual o posterior al inicio.';
    }

    if (
      pago.periodoInicio <
      empleado.fechaContratacion.slice(0, 10)
    ) {
      return 'El periodo no puede empezar antes de la contratación.';
    }

    if (
      empleado.fechaBaja &&
      pago.periodoFin > empleado.fechaBaja.slice(0, 10)
    ) {
      return 'El periodo no puede terminar después de la baja laboral.';
    }

    const salariosQueCubrenPeriodo = this.salarios.filter(
      salario =>
        salario.periodicidad === 'Mensual' &&
        salario.vigenteDesde <= pago.periodoInicio &&
        (
          salario.vigenteHasta === null ||
          salario.vigenteHasta >= pago.periodoFin
        )
    );

    if (salariosQueCubrenPeriodo.length !== 1) {
      return (
        'El periodo debe estar cubierto por un único ' +
        'salario mensual. Si cruza un cambio salarial, ' +
        'divide el pago en periodos separados.'
      );
    }

    const duplicado = this.pagos.some(
      pagoExistente =>
        pagoExistente.estado.toLowerCase() === 'pagado' &&
        pagoExistente.periodoInicio <= pago.periodoFin &&
        pagoExistente.periodoFin >= pago.periodoInicio
    );

    if (duplicado) {
      return 'El periodo se solapa con un pago ya registrado.';
    }

    if (
      typeof pago.monto !== 'number' ||
      !Number.isFinite(pago.monto) ||
      pago.monto <= 0 ||
      pago.monto > 9999999999.99 ||
      Math.abs(
        pago.monto * 100 - Math.round(pago.monto * 100)
      ) >= 0.000001
    ) {
      return 'Ingresa un monto positivo con máximo dos decimales.';
    }

    if (
      !this.fechaValida(pago.fechaPago) ||
      pago.fechaPago > this.obtenerFechaOperacion()
    ) {
      return 'La fecha de pago no puede ser futura.';
    }

    if (
      pago.metodo !== 'Efectivo' &&
      pago.metodo !== 'Transferencia'
    ) {
      return 'Selecciona un método de pago válido.';
    }

    if (pago.referencia.trim().length > 100) {
      return 'La referencia no puede superar 100 caracteres.';
    }

    if (
      pago.metodo === 'Transferencia' &&
      !pago.referencia.trim()
    ) {
      return 'La referencia es obligatoria para transferencias.';
    }

    if (!this.confirmacionPagoLeida) {
      return 'Confirma que el pago ya fue realizado.';
    }

    return '';
  }

  // VALIDACIONES PARA ENVIAR

  get puedeRegistrarPago(): boolean {

    return (
      this.mostrarFormularioPago &&
      !this.mostrarConfirmacionPago &&
      !this.registrandoPago &&
      !this.cambiandoSalario &&
      !this.resultadoPagoIncierto &&
      this.consultaSalariosRealizada &&
      this.consultaPagosRealizada &&
      !this.errorSalarios &&
      !this.errorPagos &&
      this.validarPago() === ''
    );
  }

  prepararRegistroPago(): void {

    this.errorRegistroPago = '';

    if (
      this.registrandoPago ||
      this.cambiandoSalario ||
      this.resultadoPagoIncierto ||
      !this.mostrarFormularioPago ||
      this.mostrarConfirmacionPago ||
      !this.consultaSalariosRealizada ||
      !this.consultaPagosRealizada ||
      !!this.errorSalarios ||
      !!this.errorPagos
    ) {
      return;
    }

    const error = this.validarPago();

    if (error) {
      this.errorRegistroPago = error;
      return;
    }

    this.mostrarConfirmacionPago = true;
  }

  cancelarConfirmacionPago(): void {

    if (this.registrandoPago) {
      return;
    }

    this.mostrarConfirmacionPago = false;
  }

  // REGISTRAR PAGO REAL

  confirmarRegistroPago(): void {

    if (
      !this.mostrarConfirmacionPago ||
      this.registrandoPago ||
      this.resultadoPagoIncierto
    ) {
      return;
    }

    const empleado = this.empleadoSeleccionado;

    if (!empleado) {
      return;
    }

    const error = this.validarPago();

    if (error) {
      this.mostrarConfirmacionPago = false;
      this.errorRegistroPago = error;
      return;
    }

    const idPersonal = empleado.idPersonal;
    const pago = this.formularioPago;

    const datos: RegistrarPagoNominaAdminRequest = {
      periodoInicio: pago.periodoInicio,
      periodoFin: pago.periodoFin,
      monto: pago.monto!,
      fechaPago: pago.fechaPago,
      metodo: pago.metodo,
      referencia: pago.referencia.trim() || null,
      observaciones: pago.observaciones.trim() || null
    };

    this.registrandoPago = true;
    this.errorRegistroPago = '';
    this.mostrarConfirmacionPago = false;

    this.nominaService
      .registrarPagoNomina(idPersonal, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.registrandoPago = false;

          if (
            !respuesta ||
            respuesta.idPersonal !== idPersonal ||
            !Number.isInteger(respuesta.idPago) ||
            respuesta.idPago <= 0
          ) {

            this.resultadoPagoIncierto = true;

            this.errorRegistroPago =
              'El servidor respondió de forma inesperada. ' +
              'Revisa el historial de pagos antes de registrar otro.';

            this.changeDetector.detectChanges();
            return;
          }

          this.mostrarFormularioPago = false;
          this.confirmacionPagoLeida = false;
          this.formularioPago = this.crearFormularioPago();

          this.mensajeRegistroPago =
            'Pago de nómina registrado correctamente. ' +
            `Folio: #${respuesta.idPago}.`;

          this.cargarDetalles();

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.registrandoPago = false;

          const mensaje = this.obtenerMensajeError(
            error,
            'No fue posible registrar el pago.'
          );

          if (error.status === 0 || error.status >= 500) {

            this.resultadoPagoIncierto = true;

            this.errorRegistroPago =
              'No se pudo confirmar si el pago se registró. ' +
              'Consulta el historial antes de intentar nuevamente.';

          } else if (error.status === 409) {

            this.resultadoPagoIncierto = true;

            this.errorRegistroPago =
              mensaje +
              ' Revisa los pagos antes de registrar otro.';

          } else {

            this.errorRegistroPago = mensaje;
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

  // MANEJAR ERRORES

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

    if (this.cambiandoSalario || this.registrandoPago) {
      return;
    }

    this.router.navigate(['/admin/personal']);
  }
}
