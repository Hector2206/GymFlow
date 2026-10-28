
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';

import {
  ActivatedRoute,
  Router
} from '@angular/router';

import {
  takeUntilDestroyed
} from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  PersonalAdmin,
  EditarPersonalAdminRequest
} from '../models/admin-personal.model';

@Component({
  selector: 'app-admin-personal-editar',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal-editar.html',
  styleUrl: './admin-personal-editar.css'
})
export class AdminPersonalEditar implements OnInit {

  idPersonal = 0;

  empleado: PersonalAdmin | null = null;

  cargando = false;
  errorCarga = '';

  guardando = false;
  errorGuardado = '';
  resultadoIncierto = false;

  formulario: EditarPersonalAdminRequest = {
    nombreCompleto: '',
    correo: '',
    telefono: '',
    horario: ''
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private personalService: AdminPersonalService,
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
    this.cargarEmpleado();
  }

  // CONSULTAR EXPEDIENTE REAL

  cargarEmpleado(): void {

    if (
      this.cargando ||
      this.guardando ||
      this.idPersonal <= 0
    ) {
      return;
    }

    this.cargando = true;
    this.errorCarga = '';
    this.errorGuardado = '';
    this.empleado = null;

    this.personalService
      .obtenerPersonalPorId(this.idPersonal)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: PersonalAdmin) => {

          this.cargando = false;

          if (
            !respuesta ||
            respuesta.idPersonal !== this.idPersonal
          ) {
            this.errorCarga =
              'El servidor devolvió un expediente inesperado.';

            this.changeDetector.detectChanges();
            return;
          }

          this.empleado = respuesta;

          this.formulario = {
            nombreCompleto: respuesta.nombreCompleto,
            correo: respuesta.correo,
            telefono: respuesta.telefono,
            horario: respuesta.horario || ''
          };

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargando = false;

          if (error.status === 401) {
            this.errorCarga =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {
            this.errorCarga =
              'No tienes permisos para consultar empleados.';

          } else if (error.status === 404) {
            this.errorCarga =
              'No se encontró el empleado solicitado.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {
            this.errorCarga =
              'No fue posible conectar con el servidor. Intenta nuevamente.';

          } else {
            this.errorCarga =
              this.obtenerMensajeServidor(error) ||
              'No se pudo consultar el expediente.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // DETECTAR CAMBIOS

  get hayCambios(): boolean {

    if (!this.empleado) {
      return false;
    }

    return (
      this.formulario.nombreCompleto.trim() !==
        this.empleado.nombreCompleto.trim() ||

      this.formulario.correo.trim().toLowerCase() !==
        this.empleado.correo.trim().toLowerCase() ||

      this.formulario.telefono.trim() !==
        this.empleado.telefono.trim() ||

      this.formulario.horario.trim() !==
        (this.empleado.horario || '').trim()
    );
  }

  // GUARDAR CAMBIOS EN POSTGRESQL

  guardarCambios(): void {

    if (
      this.guardando ||
      this.cargando ||
      this.resultadoIncierto ||
      !this.empleado ||
      this.empleado.estatus !== 'Activo'
    ) {
      return;
    }

    this.errorGuardado = '';

    const nombre =
      this.formulario.nombreCompleto.trim();

    const correo =
      this.formulario.correo.trim().toLowerCase();

    const telefono =
      this.formulario.telefono.trim();

    const horario =
      this.formulario.horario.trim();

    // CAMPOS OBLIGATORIOS

    if (!nombre || !correo || !telefono || !horario) {

      this.errorGuardado =
        'Completa todos los campos obligatorios.';
      return;
    }

    // LONGITUDES PERMITIDAS POR EL BACKEND

    if (nombre.length > 150) {

      this.errorGuardado =
        'El nombre no puede superar 150 caracteres.';
      return;
    }

    if (
      correo.length > 150 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)
    ) {

      this.errorGuardado =
        'Ingresa un correo electrónico válido.';
      return;
    }

    if (telefono.length > 20) {

      this.errorGuardado =
        'El teléfono no puede superar 20 caracteres.';
      return;
    }

    if (horario.length > 100) {

      this.errorGuardado =
        'El horario no puede superar 100 caracteres.';
      return;
    }

    if (!this.hayCambios) {

      this.errorGuardado =
        'No hay cambios que guardar.';
      return;
    }

    const datos: EditarPersonalAdminRequest = {
      nombreCompleto: nombre,
      correo,
      telefono,
      horario
    };

    this.guardando = true;

    // ACTUALIZACION REAL

    this.personalService
      .editarPersonal(this.idPersonal, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.guardando = false;

          if (respuesta.idPersonal !== this.idPersonal) {

            this.resultadoIncierto = true;
            this.errorGuardado =
              'El servidor respondió con un identificador inesperado. ' +
              'Verifica los datos del empleado antes de volver a editar.';

            this.changeDetector.detectChanges();
            return;
          }

          // VOLVER AL DIRECTORIO CON CONFIRMACION

          this.router.navigate(
            ['/admin/personal'],
            {
              state: {
                empleadoEditadoId: this.idPersonal
              }
            }
          );
        },

        error: (error: HttpErrorResponse) => {

          this.guardando = false;

          const mensajeServidor =
            this.obtenerMensajeServidor(error);

          if (error.status === 400) {

            this.errorGuardado =
              mensajeServidor ||
              'Revisa los datos del formulario.';

          } else if (error.status === 401) {

            this.errorGuardado =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorGuardado =
              'No tienes permisos para editar empleados.';

          } else if (error.status === 404) {

            this.errorGuardado =
              'No se encontró el empleado solicitado.';

          } else if (error.status === 409) {

            this.errorGuardado =
              mensajeServidor ||
              'No se pudo actualizar: hay datos duplicados o el empleado está inactivo.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.resultadoIncierto = true;

            this.errorGuardado =
              'No se pudo confirmar si los cambios se guardaron. ' +
              'Vuelve al directorio y revisa el expediente antes de intentarlo nuevamente.';

          } else {

            this.errorGuardado =
              mensajeServidor ||
              'No fue posible guardar los cambios.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // LEER MENSAJES DE ERROR DEL SERVIDOR

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

  // REGRESAR SIN GUARDAR

  volverDirectorio(): void {

    if (this.guardando) {
      return;
    }

    this.router.navigate(['/admin/personal']);
  }
}
