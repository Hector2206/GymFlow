
import {
  ChangeDetectorRef,
  Component,
  DestroyRef
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  CrearPersonalAdminRequest,
  PuestoPersonalAdmin
} from '../models/admin-personal.model';

@Component({
  selector: 'app-admin-personal-alta',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal-alta.html',
  styleUrl: './admin-personal-alta.css'
})
export class AdminPersonalAlta {

  nuevoEmpleado = {
    nombreCompleto: '',
    correo: '',
    telefono: '',
    fechaContratacion: '',
    puesto: '' as PuestoPersonalAdmin | '',
    sueldo: null as number | null,
    password: ''
  };

  fechaMaxima = this.obtenerFechaHoy();

  guardandoAlta = false;
  errorAlta = '';
  resultadoIncierto = false;

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  // FECHA LOCAL

  private obtenerFechaHoy(): string {

    const hoy = new Date();

    const anio = hoy.getFullYear();

    const mes = String(
      hoy.getMonth() + 1
    ).padStart(2, '0');

    const dia = String(
      hoy.getDate()
    ).padStart(2, '0');

    return `${anio}-${mes}-${dia}`;
  }

  // REGRESAR SIN GUARDAR

  volverDirectorio(): void {

    if (this.guardandoAlta) {
      return;
    }

    this.nuevoEmpleado.password = '';

    this.router.navigate([
      '/admin/personal'
    ]);
  }

  // VALIDAR Y REGISTRAR EMPLEADO

  guardarEmpleado(): void {

    if (
      this.guardandoAlta ||
      this.resultadoIncierto
    ) {
      return;
    }

    this.errorAlta = '';

    const nombre =
      this.nuevoEmpleado.nombreCompleto.trim();

    const correo =
      this.nuevoEmpleado.correo.trim().toLowerCase();

    const telefono =
      this.nuevoEmpleado.telefono.trim();

    const puesto =
      this.nuevoEmpleado.puesto;

    const fecha =
      this.nuevoEmpleado.fechaContratacion;

    const sueldo =
      this.nuevoEmpleado.sueldo;

    const password =
      this.nuevoEmpleado.password;

    // CAMPOS OBLIGATORIOS

    if (
      !nombre ||
      !correo ||
      !telefono ||
      !puesto ||
      !fecha ||
      sueldo === null ||
      sueldo === undefined ||
      !password
    ) {

      this.errorAlta =
        'Completa todos los campos obligatorios.';

      return;
    }

    // NOMBRE

    if (nombre.length > 150) {

      this.errorAlta =
        'El nombre no puede superar 150 caracteres.';

      return;
    }

    // CORREO

    const correoValido =
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo);

    if (
      !correoValido ||
      correo.length > 150
    ) {

      this.errorAlta =
        'Ingresa un correo electrónico válido.';

      return;
    }

    // TELEFONO

    const digitos =
      telefono.replace(/\D/g, '');

    if (
      telefono.length > 20 ||
      !/^[+0-9()\s-]+$/.test(telefono) ||
      digitos.length < 7
    ) {

      this.errorAlta =
        'Ingresa un teléfono válido de máximo 20 caracteres.';

      return;
    }

    // PUESTO

    if (
      puesto !== 'Entrenador' &&
      puesto !== 'Recepcionista'
    ) {

      this.errorAlta =
        'Selecciona un puesto válido.';

      return;
    }

    // FECHA DE CONTRATACION

    const formatoValido =
      /^\d{4}-\d{2}-\d{2}$/.test(fecha);

    const fechaInterpretada =
      new Date(`${fecha}T12:00:00`);

    const fechaExiste =
      formatoValido &&
      !Number.isNaN(fechaInterpretada.getTime()) &&
      fechaInterpretada.getFullYear() ===
        Number(fecha.slice(0, 4)) &&
      fechaInterpretada.getMonth() + 1 ===
        Number(fecha.slice(5, 7)) &&
      fechaInterpretada.getDate() ===
        Number(fecha.slice(8, 10));

    if (
      !fechaExiste ||
      fecha > this.obtenerFechaHoy()
    ) {

      this.errorAlta =
        'La fecha de contratación no es válida o es futura.';

      return;
    }

    // SUELDO MENSUAL

    if (
      typeof sueldo !== 'number' ||
      !Number.isFinite(sueldo) ||
      sueldo < 0 ||
      sueldo > 99999999.99 ||
      Math.round(sueldo * 100) / 100 !== sueldo
    ) {

      this.errorAlta =
        'El sueldo debe ser válido, no negativo y tener máximo dos decimales.';

      return;
    }

    // CONTRASENA

    if (password.length < 8) {

      this.errorAlta =
        'La contraseña debe tener al menos 8 caracteres.';

      return;
    }

    // DATOS PARA EL BACKEND

    const datos: CrearPersonalAdminRequest = {
      nombreCompleto: nombre,
      correo,
      telefono,
      fechaContratacion: fecha,
      puesto,
      sueldo,
      password
    };

    this.guardandoAlta = true;

    // REGISTRO REAL

    this.personalService
      .crearPersonal(datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.guardandoAlta = false;

          // Limpiar la contrasena de la memoria
          this.nuevoEmpleado.password = '';

          // Volver al directorio con confirmacion
          this.router.navigate(
            ['/admin/personal'],
            {
              state: {
                empleadoRegistradoId:
                  respuesta.idPersonal
              }
            }
          );
        },

        error: (error: HttpErrorResponse) => {

          this.guardandoAlta = false;

          const mensajeServidor =
            typeof error.error?.mensaje === 'string'
              ? error.error.mensaje
              : typeof error.error?.detail === 'string'
                ? error.error.detail
                : '';

          if (error.status === 400) {

            this.errorAlta =
              mensajeServidor ||
              'Revisa los datos del formulario.';

          } else if (error.status === 401) {

            this.errorAlta =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorAlta =
              'No tienes permisos para registrar empleados.';

          } else if (error.status === 409) {

            this.errorAlta =
              mensajeServidor ||
              'Ya existe un empleado con esos datos.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            // Evitar un segundo envio si el servidor
            // pudo haber completado el registro.
            this.resultadoIncierto = true;

            this.nuevoEmpleado.password = '';

            this.errorAlta =
              'No se pudo confirmar si el registro se completó. ' +
              'Regresa al directorio y revisa si aparece ' +
              'el empleado antes de intentar nuevamente.';

          } else {

            this.errorAlta =
              mensajeServidor ||
              'No fue posible registrar al empleado.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }
}
