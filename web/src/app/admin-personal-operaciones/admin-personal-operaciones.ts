
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

type SeccionLaboral = 'horarios' | 'asistencias';

type DiaSemana =
  | 'Lunes'
  | 'Martes'
  | 'Miércoles'
  | 'Jueves'
  | 'Viernes'
  | 'Sábado'
  | 'Domingo';

type TipoMovimiento = 'Entrada' | 'Salida';

@Component({
  selector: 'app-admin-personal-operaciones',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal-operaciones.html',
  styleUrl: './admin-personal-operaciones.css'
})
export class AdminPersonalOperaciones implements OnInit {

  // EMPLEADOS REALES

  empleados: PersonalAdmin[] = [];
  idPersonalSeleccionado: number | null = null;

  cargando = false;
  consultaRealizada = false;
  errorEmpleados = '';

  // NAVEGACION ENTRE SECCIONES

  seccion: SeccionLaboral = 'horarios';

  // FORMULARIO DE HORARIOS

  readonly diasSemana: DiaSemana[] = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  diaSemana: DiaSemana | '' = '';
  horaEntradaHorario = '';
  horaSalidaHorario = '';
  fechaVigencia = this.obtenerFechaLocal();

  errorHorario = '';
  horarioRevisado = false;

  // FORMULARIO DE ASISTENCIAS

  tipoMovimiento: TipoMovimiento = 'Entrada';
  fechaAsistencia = this.obtenerFechaLocal();
  horaAsistencia = this.obtenerHoraLocal();

  errorAsistencia = '';
  asistenciaRevisada = false;

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarEmpleados();
  }

  // FECHAS LOCALES

  private obtenerFechaLocal(): string {

    const fecha = new Date();

    const anio = fecha.getFullYear();
    const mes = String(fecha.getMonth() + 1).padStart(2, '0');
    const dia = String(fecha.getDate()).padStart(2, '0');

    return `${anio}-${mes}-${dia}`;
  }

  private obtenerHoraLocal(): string {

    const fecha = new Date();

    const horas = String(fecha.getHours()).padStart(2, '0');
    const minutos = String(fecha.getMinutes()).padStart(2, '0');

    return `${horas}:${minutos}`;
  }

  get fechaActual(): string {
    return this.obtenerFechaLocal();
  }

  // CONSULTA REAL AL BACKEND EXISTENTE

  cargarEmpleados(): void {

    if (this.cargando) {
      return;
    }

    this.cargando = true;
    this.consultaRealizada = false;
    this.errorEmpleados = '';

    this.personalService
      .obtenerPersonal()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: PersonalAdmin[]) => {

          this.cargando = false;
          this.consultaRealizada = true;

          if (!Array.isArray(respuesta)) {

            this.errorEmpleados =
              'El servidor devolvió una respuesta inesperada.';

            this.empleados = [];

          } else {

            this.empleados = [...respuesta].sort(
              (a, b) =>
                a.nombreCompleto.localeCompare(
                  b.nombreCompleto,
                  'es'
                )
            );

            if (
              this.idPersonalSeleccionado !== null &&
              !this.empleados.some(
                e => e.idPersonal === this.idPersonalSeleccionado
              )
            ) {
              this.idPersonalSeleccionado = null;
              this.reiniciarFormularios();
            }
          }

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargando = false;
          this.consultaRealizada = true;
          this.empleados = [];

          if (error.status === 401) {

            this.errorEmpleados =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorEmpleados =
              'No tienes permisos para consultar empleados.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.errorEmpleados =
              'No fue posible conectar con el servidor.';

          } else {

            this.errorEmpleados =
              typeof error.error?.mensaje === 'string'
                ? error.error.mensaje
                : 'No fue posible obtener el personal.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  get empleadoSeleccionado(): PersonalAdmin | null {

    return this.empleados.find(
      empleado =>
        empleado.idPersonal === this.idPersonalSeleccionado
    ) || null;
  }

  get empleadoActivo(): boolean {

    return this.empleadoSeleccionado?.estatus === 'Activo';
  }

  // CAMBIAR EMPLEADO Y PESTAÑA

  cambiarEmpleado(): void {
    this.reiniciarFormularios();
  }

  cambiarSeccion(seccion: SeccionLaboral): void {

    this.seccion = seccion;
  }

  private reiniciarFormularios(): void {

    this.diaSemana = '';
    this.horaEntradaHorario = '';
    this.horaSalidaHorario = '';
    this.fechaVigencia = this.obtenerFechaLocal();

    this.tipoMovimiento = 'Entrada';
    this.fechaAsistencia = this.obtenerFechaLocal();
    this.horaAsistencia = this.obtenerHoraLocal();

    this.reiniciarHorario();
    this.reiniciarAsistencia();
  }

  // VALIDACIONES GENERALES

  private fechaValida(valor: string): boolean {

    if (!/^\d{4}-\d{2}-\d{2}$/.test(valor)) {
      return false;
    }

    const fecha = new Date(`${valor}T00:00:00Z`);

    return (
      !Number.isNaN(fecha.getTime()) &&
      fecha.toISOString().slice(0, 10) === valor
    );
  }

  private horaValida(valor: string): boolean {

    return /^([01]\d|2[0-3]):[0-5]\d$/.test(valor);
  }

  // HORARIOS

  reiniciarHorario(): void {

    this.errorHorario = '';
    this.horarioRevisado = false;
  }

  revisarHorario(): void {

    this.reiniciarHorario();

    const empleado = this.empleadoSeleccionado;

    if (!empleado) {

      this.errorHorario =
        'Selecciona un empleado.';

      return;
    }

    if (empleado.estatus !== 'Activo') {

      this.errorHorario =
        'No se pueden asignar horarios nuevos a empleados inactivos.';

      return;
    }

    if (!this.diaSemana) {

      this.errorHorario =
        'Selecciona un día de la semana.';

      return;
    }

    if (
      !this.horaValida(this.horaEntradaHorario) ||
      !this.horaValida(this.horaSalidaHorario)
    ) {

      this.errorHorario =
        'Ingresa horas de entrada y salida válidas.';

      return;
    }

    if (
      this.horaSalidaHorario <= this.horaEntradaHorario
    ) {

      this.errorHorario =
        'La hora de salida debe ser posterior a la entrada. ' +
        'Los turnos nocturnos se definirán con Backend.';

      return;
    }

    if (!this.fechaValida(this.fechaVigencia)) {

      this.errorHorario =
        'Selecciona una fecha de vigencia válida.';

      return;
    }

    // Validación local: no se llama a ningún endpoint.
    this.horarioRevisado = true;
  }

  // ASISTENCIAS

  reiniciarAsistencia(): void {

    this.errorAsistencia = '';
    this.asistenciaRevisada = false;
  }

  revisarAsistencia(): void {

    this.reiniciarAsistencia();

    const empleado = this.empleadoSeleccionado;

    if (!empleado) {

      this.errorAsistencia =
        'Selecciona un empleado.';

      return;
    }

    if (empleado.estatus !== 'Activo') {

      this.errorAsistencia =
        'No se pueden registrar asistencias nuevas ' +
        'de empleados inactivos.';

      return;
    }

    if (
      this.tipoMovimiento !== 'Entrada' &&
      this.tipoMovimiento !== 'Salida'
    ) {

      this.errorAsistencia =
        'Selecciona entrada o salida.';

      return;
    }

    if (!this.fechaValida(this.fechaAsistencia)) {

      this.errorAsistencia =
        'Selecciona una fecha válida.';

      return;
    }

    const hoy = this.obtenerFechaLocal();

    if (this.fechaAsistencia > hoy) {

      this.errorAsistencia =
        'La fecha de asistencia no puede ser futura.';

      return;
    }

    if (!this.horaValida(this.horaAsistencia)) {

      this.errorAsistencia =
        'Selecciona una hora válida.';

      return;
    }

    if (
      this.fechaAsistencia === hoy &&
      this.horaAsistencia > this.obtenerHoraLocal()
    ) {

      this.errorAsistencia =
        'La hora de asistencia no puede ser futura.';

      return;
    }

    if (
      this.fechaAsistencia <
      empleado.fechaContratacion.slice(0, 10)
    ) {

      this.errorAsistencia =
        'No puedes registrar asistencias anteriores ' +
        'a la contratación.';

      return;
    }

    // No se afirma que exista entrada previa.
    // Esa comprobación corresponderá al backend.
    this.asistenciaRevisada = true;
  }

  // FORMATO DE FECHA

  mostrarFecha(fecha: string | null): string {

    if (!fecha) {
      return '—';
    }

    const partes = fecha.slice(0, 10).split('-');

    return partes.length === 3
      ? `${partes[2]}/${partes[1]}/${partes[0]}`
      : fecha;
  }

  // REGRESAR AL MODULO DE PERSONAL

  volverPersonal(): void {

    this.router.navigate([
      '/admin/personal'
    ]);
  }
}
