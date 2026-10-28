
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { forkJoin } from 'rxjs';

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
  MetodoPagoNominaAdmin,
  RegistrarPagoNominaAdminRequest
} from '../models/admin-nomina.model';

@Component({
  selector: 'app-admin-nomina-pago',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-nomina-pago.html',
  styleUrl: './admin-nomina-pago.css'
})
export class AdminNominaPago implements OnInit {

  idPersonal = 0;

  empleado: PersonalAdmin | null = null;

  salarios: SalarioPersonalAdmin[] = [];
  pagos: PagoNominaAdmin[] = [];

  cargando = false;
  errorCarga = '';

  // FORMULARIO

  periodoInicio = '';
  periodoFin = '';
  monto: number | null = null;
  fechaPago = '';

  metodo: MetodoPagoNominaAdmin = 'Efectivo';
  referencia = '';
  observaciones = '';

  aceptoConfirmacion = false;

  // REGISTRO

  mostrarConfirmacion = false;
  guardando = false;

  errorRegistro = '';
  resultadoIncierto = false;

  readonly fechaActual = this.hoyLocal();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private personalService: AdminPersonalService,
    private nominaService: AdminNominaService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {

    const id = Number(
      this.route.snapshot.paramMap.get('id')
    );

    if (!Number.isInteger(id) || id <= 0) {

      this.errorCarga =
        'El identificador del empleado no es válido.';

      return;
    }

    this.idPersonal = id;
    this.cargarExpediente();
  }

  // FECHA LOCAL

  private hoyLocal(): string {

    const ahora = new Date();

    const anio = ahora.getFullYear();

    const mes = String(
      ahora.getMonth() + 1
    ).padStart(2, '0');

    const dia = String(
      ahora.getDate()
    ).padStart(2, '0');

    return `${anio}-${mes}-${dia}`;
  }

  // CONSULTAR EMPLEADO Y SUS HISTORIALES

  cargarExpediente(): void {

    if (
      this.cargando ||
      this.guardando ||
      this.idPersonal <= 0
    ) {
      return;
    }

    this.cargando = true;
    this.errorCarga = '';
    this.empleado = null;
    this.salarios = [];
    this.pagos = [];

    forkJoin({

      empleado:
        this.personalService.obtenerPersonalPorId(
          this.idPersonal
        ),

      salarios:
        this.nominaService.obtenerHistorialSalarial(
          this.idPersonal
        ),

      pagos:
        this.nominaService.obtenerHistorialNomina(
          this.idPersonal
        )

    })
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe({

      next: respuesta => {

        this.cargando = false;

        if (
          !respuesta.empleado ||
          respuesta.empleado.idPersonal !== this.idPersonal ||
          !Array.isArray(respuesta.salarios) ||
          !Array.isArray(respuesta.pagos)
        ) {

          this.errorCarga =
            'El servidor devolvió información inesperada.';

          this.changeDetector.detectChanges();
          return;
        }

        this.empleado = respuesta.empleado;
        this.salarios = respuesta.salarios;
        this.pagos = respuesta.pagos;

        this.changeDetector.detectChanges();
      },

      error: (error: HttpErrorResponse) => {

        this.cargando = false;

        this.errorCarga = this.mensajeError(
          error,
          'No fue posible cargar el expediente de nómina.'
        );

        this.changeDetector.detectChanges();
      }
    });
  }

  // VALIDAR FECHAS REALES

  private fechaValida(fecha: string): boolean {

    if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha)) {
      return false;
    }

    const fechaUTC = new Date(
      `${fecha}T00:00:00Z`
    );

    return (
      !Number.isNaN(fechaUTC.getTime()) &&
      fechaUTC.toISOString().slice(0, 10) === fecha
    );
  }

  // REGLAS DEL REGISTRO

  private validarFormulario(): string {

    const empleado = this.empleado;

    if (!empleado) {
      return 'No se encontró el empleado seleccionado.';
    }

    if (
      !this.fechaValida(this.periodoInicio) ||
      !this.fechaValida(this.periodoFin)
    ) {
      return 'Selecciona fechas válidas para el periodo.';
    }

    if (this.periodoFin < this.periodoInicio) {

      return 'El fin del periodo no puede ser anterior al inicio.';
    }

    if (
      this.periodoInicio <
      empleado.fechaContratacion.slice(0, 10)
    ) {

      return 'El periodo no puede iniciar antes de la contratación.';
    }

    if (
      empleado.fechaBaja &&
      this.periodoFin > empleado.fechaBaja.slice(0, 10)
    ) {

      return 'El periodo no puede terminar después de la baja laboral.';
    }

    if (
      empleado.estatus === 'Inactivo' &&
      !empleado.fechaBaja
    ) {

      return 'El empleado está inactivo sin fecha de baja. Revisa su expediente.';
    }

    // VALIDAR QUE UN SALARIO CUBRA EL PERIODO

    const salariosValidos = this.salarios.filter(
      salario =>
        salario.periodicidad === 'Mensual' &&
        salario.vigenteDesde <= this.periodoInicio &&
        (
          salario.vigenteHasta === null ||
          salario.vigenteHasta >= this.periodoFin
        )
    );

    if (salariosValidos.length !== 1) {

      return (
        'El periodo debe estar cubierto por un solo ' +
        'salario mensual. Si hubo un cambio salarial, ' +
        'divide el pago en periodos separados.'
      );
    }

    // EVITAR PAGOS DUPLICADOS

    const duplicado = this.pagos.some(
      pago =>
        pago.estado.toLowerCase() === 'pagado' &&
        pago.periodoInicio <= this.periodoFin &&
        pago.periodoFin >= this.periodoInicio
    );

    if (duplicado) {

      return 'Ya existe un pago registrado que coincide con ese periodo.';
    }

    // VALIDAR MONTO

    if (
      typeof this.monto !== 'number' ||
      !Number.isFinite(this.monto) ||
      this.monto <= 0 ||
      this.monto > 9999999999.99 ||
      Math.abs(
        this.monto * 100 -
        Math.round(this.monto * 100)
      ) >= 0.000001
    ) {

      return 'Ingresa un monto positivo con máximo dos decimales.';
    }

    // VALIDAR FECHA DE PAGO

    if (
      !this.fechaValida(this.fechaPago) ||
      this.fechaPago > this.hoyLocal()
    ) {

      return 'La fecha de pago es obligatoria y no puede ser futura.';
    }

    if (
      this.metodo !== 'Efectivo' &&
      this.metodo !== 'Transferencia'
    ) {

      return 'Selecciona un método de pago válido.';
    }

    if (this.referencia.trim().length > 100) {

      return 'La referencia no puede superar 100 caracteres.';
    }

    if (
      this.metodo === 'Transferencia' &&
      !this.referencia.trim()
    ) {

      return 'Ingresa la referencia de la transferencia.';
    }

    if (!this.aceptoConfirmacion) {

      return 'Confirma que el pago ya fue realizado.';
    }

    return '';
  }

  // REVISAR ANTES DE GUARDAR

  prepararPago(): void {

    if (
      this.guardando ||
      this.cargando ||
      this.resultadoIncierto ||
      this.mostrarConfirmacion
    ) {
      return;
    }

    this.errorRegistro = '';

    const error = this.validarFormulario();

    if (error) {

      this.errorRegistro = error;
      return;
    }

    this.mostrarConfirmacion = true;
  }

  // CERRAR CONFIRMACION

  cerrarConfirmacion(): void {

    if (!this.guardando) {
      this.mostrarConfirmacion = false;
    }
  }

  // REGISTRAR PAGO REAL

  guardarPago(): void {

    if (
      !this.mostrarConfirmacion ||
      this.guardando ||
      this.resultadoIncierto
    ) {
      return;
    }

    const error = this.validarFormulario();

    if (error) {

      this.errorRegistro = error;
      this.mostrarConfirmacion = false;
      return;
    }

    const datos: RegistrarPagoNominaAdminRequest = {

      periodoInicio: this.periodoInicio,

      periodoFin: this.periodoFin,

      monto: this.monto!,

      fechaPago: this.fechaPago,

      metodo: this.metodo,

      referencia: this.referencia.trim() || null,

      observaciones: this.observaciones.trim() || null

    };

    this.guardando = true;
    this.errorRegistro = '';
    this.mostrarConfirmacion = false;

    this.nominaService
      .registrarPagoNomina(this.idPersonal, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: respuesta => {

          this.guardando = false;

          if (
            respuesta?.idPersonal !== this.idPersonal ||
            !Number.isInteger(respuesta.idPago) ||
            respuesta.idPago <= 0
          ) {

            this.resultadoIncierto = true;

            this.errorRegistro =
              'El servidor respondió de forma inesperada. ' +
              'Verifica el historial antes de registrar otro pago.';

            this.changeDetector.detectChanges();
            return;
          }

          // REGRESAR A NOMINA CON EL EMPLEADO SELECCIONADO

          this.router.navigate(
            ['/admin/personal/nomina'],
            {
              queryParams: {
                empleado: this.idPersonal
              },
              state: {
                pagoRegistradoId: respuesta.idPago
              }
            }
          );
        },

        error: (error: HttpErrorResponse) => {

          this.guardando = false;

          if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.resultadoIncierto = true;

            this.errorRegistro =
              'No se pudo confirmar si el pago fue registrado. ' +
              'Regresa a Nómina y revisa el historial antes ' +
              'de intentar nuevamente.';

          } else {

            this.errorRegistro = this.mensajeError(
              error,
              'No fue posible registrar el pago.'
            );
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // ERRORES DEL SERVIDOR

  private mensajeError(
    error: HttpErrorResponse,
    predeterminado: string
  ): string {

    if (error.status === 401) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }

    if (error.status === 403) {
      return 'No tienes permisos para registrar pagos.';
    }

    if (error.status === 404) {
      return 'No se encontró el empleado solicitado.';
    }

    if (typeof error.error?.mensaje === 'string') {
      return error.error.mensaje;
    }

    if (typeof error.error?.detail === 'string') {
      return error.error.detail;
    }

    if (error.status === 0 || error.status >= 500) {
      return 'No fue posible conectar con el servidor.';
    }

    return predeterminado;
  }

  // FORMATOS

  mostrarMonto(monto: number | null): string {

    if (
      monto === null ||
      !Number.isFinite(Number(monto))
    ) {
      return '—';
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

  // VOLVER A NOMINA

  volverNomina(): void {

    if (this.guardando) {
      return;
    }

    this.router.navigate(
      ['/admin/personal/nomina'],
      {
        queryParams: {
          empleado: this.idPersonal
        }
      }
    );
  }
}
