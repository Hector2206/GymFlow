
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

  // CONTROL DE LA OPERACION

  mostrarConfirmacionFinal = false;
  guardando = false;
  errorBaja = '';
  resultadoIncierto = false;

  readonly maximoMotivo = 200;

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

    if (this.cargando || this.guardando) {
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

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.error =
              'No fue posible conectar con el servidor. Intenta nuevamente.';

          } else {

            this.error =
              this.obtenerMensajeServidor(error) ||
              'No se pudo consultar el personal.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // EMPLEADOS ACTIVOS

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

  // REINICIAR FORMULARIO AL CAMBIAR EMPLEADO

  cambiarEmpleado(): void {

    if (this.guardando || this.resultadoIncierto) {
      return;
    }

    this.motivoBaja = '';
    this.confirmacionLeida = false;
    this.errorBaja = '';
    this.mostrarConfirmacionFinal = false;
  }

  // VALIDACIONES

  get puedeRegistrarBaja(): boolean {

    const motivo = this.motivoBaja.trim();

    return (
      !this.cargando &&
      !this.guardando &&
      !this.resultadoIncierto &&
      this.empleadoSeleccionado !== null &&
      motivo.length > 0 &&
      motivo.length <= this.maximoMotivo &&
      this.confirmacionLeida
    );
  }

  // ABRIR CONFIRMACION DEFINITIVA

  prepararBaja(): void {

    this.errorBaja = '';

    if (!this.empleadoSeleccionado) {

      this.errorBaja =
        'Selecciona un empleado activo.';

      return;
    }

    const motivo = this.motivoBaja.trim();

    if (
      !motivo ||
      motivo.length > this.maximoMotivo
    ) {

      this.errorBaja =
        'Escribe un motivo de baja válido.';

      return;
    }

    if (!this.confirmacionLeida) {

      this.errorBaja =
        'Debes aceptar la confirmación antes de continuar.';

      return;
    }

    if (!this.puedeRegistrarBaja) {
      return;
    }

    this.mostrarConfirmacionFinal = true;
  }

  // CANCELAR ULTIMA CONFIRMACION

  cancelarConfirmacionFinal(): void {

    if (this.guardando) {
      return;
    }

    this.mostrarConfirmacionFinal = false;
  }

  // REGISTRAR BAJA REAL

  confirmarBaja(): void {

    if (
      !this.mostrarConfirmacionFinal ||
      !this.puedeRegistrarBaja
    ) {
      return;
    }

    const empleado = this.empleadoSeleccionado;

    if (!empleado) {
      return;
    }

    const idPersonal = empleado.idPersonal;
    const motivo = this.motivoBaja.trim();

    this.guardando = true;
    this.errorBaja = '';
    this.mostrarConfirmacionFinal = false;

    this.personalService
      .darDeBajaPersonal(idPersonal, motivo)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.guardando = false;

          // EVITAR MOSTRAR EXITO CON RESPUESTA INESPERADA

          if (
            !respuesta ||
            respuesta.idPersonal !== idPersonal ||
            !Number.isInteger(
              respuesta.clientesDesasignados
            ) ||
            respuesta.clientesDesasignados < 0
          ) {

            this.resultadoIncierto = true;

            this.errorBaja =
              'El servidor respondió de forma inesperada. ' +
              'Regresa al directorio y comprueba ' +
              'el estatus del empleado.';

            this.changeDetector.detectChanges();
            return;
          }

          // VOLVER AL DIRECTORIO

          this.router.navigate(
            ['/admin/personal'],
            {
              state: {
                empleadoBajaId: respuesta.idPersonal,
                clientesDesasignados:
                  respuesta.clientesDesasignados
              }
            }
          );
        },

        error: (error: HttpErrorResponse) => {

          this.guardando = false;

          const mensajeServidor =
            this.obtenerMensajeServidor(error);

          if (error.status === 400) {

            this.errorBaja =
              mensajeServidor ||
              'El empleado no está disponible para baja o el motivo es inválido.';

          } else if (error.status === 401) {

            this.errorBaja =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorBaja =
              'No tienes permisos para dar de baja empleados.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            // NO REINTENTAR AUTOMATICAMENTE

            this.resultadoIncierto = true;

            this.errorBaja =
              'No se pudo confirmar si la baja se realizó. ' +
              'Vuelve al directorio y revisa el estatus ' +
              'del empleado antes de intentar otra operación.';

          } else {

            this.errorBaja =
              mensajeServidor ||
              'No fue posible registrar la baja.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // EXTRAER ERROR DEL BACKEND

  private obtenerMensajeServidor(
    error: HttpErrorResponse
  ): string {

    if (typeof error.error?.mensaje === 'string') {
      return error.error.mensaje;
    }

    if (typeof error.error?.detail === 'string') {
      return error.error.detail;
    }

    if (typeof error.error?.title === 'string') {
      return error.error.title;
    }

    return '';
  }

  // REGRESAR AL DIRECTORIO

  volverDirectorio(): void {

    if (this.guardando) {
      return;
    }

    this.router.navigate([
      '/admin/personal'
    ]);
  }
}
