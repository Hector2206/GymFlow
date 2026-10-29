
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  AdminAsistenciaPersonalService
} from '../services/admin-asistencia-personal.service';

import {
  PersonalAdmin
} from '../models/admin-personal.model';

import {
  AsistenciaPersonal
} from '../models/asistencia-personal.model';

@Component({
  selector: 'app-admin-personal-operaciones',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-personal-operaciones.html',
  styleUrl: './admin-personal-operaciones.css'
})
export class AdminPersonalOperaciones implements OnInit {
  empleados: PersonalAdmin[] = [];
  asistencias: AsistenciaPersonal[] = [];

  seccion: 'asistencias' | 'horarios' = 'asistencias';

  idPersonalEntrada: number | null = null;
  fechaEntrada = this.fechaLocal();
  horaEntrada = this.horaLocal();

  filtroIdPersonal: number | null = null;
  fechaInicio = '';
  fechaFin = '';

  idAsistenciaSalida: number | null = null;
  horaSalida = this.horaLocal();

  cargandoEmpleados = false;
  cargandoHistorial = false;
  guardando = false;
  revisionNecesaria = false;

  errorEmpleados = '';
  errorHistorial = '';
  errorOperacion = '';
  mensajeExito = '';

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private asistenciaService: AdminAsistenciaPersonalService,
    private cd: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarEmpleados();
    this.cargarHistorial();
  }

  private fechaLocal(): string {
    const hoy = new Date();
    const y = hoy.getFullYear();
    const m = String(hoy.getMonth() + 1).padStart(2, '0');
    const d = String(hoy.getDate()).padStart(2, '0');

    return `${y}-${m}-${d}`;
  }

  private horaLocal(): string {
    const ahora = new Date();

    return (
      String(ahora.getHours()).padStart(2, '0') +
      ':' +
      String(ahora.getMinutes()).padStart(2, '0')
    );
  }

  get fechaActual(): string {
    return this.fechaLocal();
  }

  get empleadosActivos(): PersonalAdmin[] {
    return this.empleados.filter(
      e => e.estatus === 'Activo' && !e.fechaBaja
    );
  }

  get empleadoEntrada(): PersonalAdmin | undefined {
    return this.empleadosActivos.find(
      e => e.idPersonal === this.idPersonalEntrada
    );
  }

  get pendientesSalida(): AsistenciaPersonal[] {
    return this.asistencias.filter(
      a => a.horaSalida === null
    );
  }

  get asistenciaSalida(): AsistenciaPersonal | undefined {
    return this.pendientesSalida.find(
      a => a.idAsistenciaPersonal === this.idAsistenciaSalida
    );
  }

  cargarEmpleados(): void {
    if (this.cargandoEmpleados) return;

    this.cargandoEmpleados = true;
    this.errorEmpleados = '';

    this.personalService.obtenerPersonal()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: datos => {
          this.empleados = Array.isArray(datos)
            ? [...datos].sort(
                (a, b) => a.nombreCompleto.localeCompare(
                  b.nombreCompleto,
                  'es'
                )
              )
            : [];

          this.cargandoEmpleados = false;
          this.cd.detectChanges();
        },

        error: (err: HttpErrorResponse) => {
          this.cargandoEmpleados = false;
          this.errorEmpleados = this.mensajeError(err);
          this.cd.detectChanges();
        }
      });
  }

  cargarHistorial(): void {
    if (this.cargandoHistorial || this.guardando) return;

    this.errorHistorial = '';

    if (
      this.fechaInicio &&
      this.fechaFin &&
      this.fechaInicio > this.fechaFin
    ) {
      this.errorHistorial =
        'La fecha inicial no puede ser posterior a la final.';
      return;
    }

    this.cargandoHistorial = true;

    this.asistenciaService.obtenerHistorial({
      idPersonal: this.filtroIdPersonal ?? undefined,
      fechaInicio: this.fechaInicio || undefined,
      fechaFin: this.fechaFin || undefined
    })
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe({
      next: datos => {
        this.asistencias = Array.isArray(datos) ? datos : [];
        this.cargandoHistorial = false;

        if (
          this.idAsistenciaSalida !== null &&
          !this.pendientesSalida.some(
            a => a.idAsistenciaPersonal === this.idAsistenciaSalida
          )
        ) {
          this.idAsistenciaSalida = null;
        }

        this.cd.detectChanges();
      },

      error: (err: HttpErrorResponse) => {
        this.cargandoHistorial = false;
        this.errorHistorial = this.mensajeError(err);
        this.asistencias = [];
        this.cd.detectChanges();
      }
    });
  }

  limpiarFiltros(): void {
    this.filtroIdPersonal = null;
    this.fechaInicio = '';
    this.fechaFin = '';
    this.idAsistenciaSalida = null;
    this.cargarHistorial();
  }

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

  private horaValida(hora: string): boolean {
    return /^([01]\d|2[0-3]):[0-5]\d$/.test(hora);
  }

  registrarEntrada(): void {
    if (
      this.guardando ||
      this.revisionNecesaria ||
      this.cargandoEmpleados
    ) {
      return;
    }

    this.errorOperacion = '';
    this.mensajeExito = '';

    const empleado = this.empleadoEntrada;

    if (!empleado) {
      this.errorOperacion = 'Selecciona un empleado activo.';
      return;
    }

    if (
      !this.fechaValida(this.fechaEntrada) ||
      this.fechaEntrada > this.fechaLocal()
    ) {
      this.errorOperacion =
        'Selecciona una fecha válida que no sea futura.';
      return;
    }

    if (!this.horaValida(this.horaEntrada)) {
      this.errorOperacion = 'Selecciona una hora de entrada válida.';
      return;
    }

    const confirmado = window.confirm(
      `¿Registrar entrada laboral?\n\n` +
      `Empleado: ${empleado.nombreCompleto}\n` +
      `Fecha: ${this.fechaEntrada}\n` +
      `Hora: ${this.horaEntrada}\n\n` +
      'Esta operación se guardará en PostgreSQL.'
    );

    if (!confirmado) return;

    this.guardando = true;

    this.asistenciaService.registrarEntrada({
      idPersonal: empleado.idPersonal,
      fecha: this.fechaEntrada,
      horaEntrada: `${this.horaEntrada}:00`
    })
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe({
      next: respuesta => {
        this.guardando = false;
        this.mensajeExito =
          `Entrada registrada. Folio #${respuesta.idAsistenciaPersonal}.`;

        this.cargarHistorial();
        this.cd.detectChanges();
      },

      error: (err: HttpErrorResponse) => {
        this.guardando = false;
        this.errorOperacion = this.mensajeError(err);

        if (err.status === 0 || err.status >= 500) {
          this.revisionNecesaria = true;
          this.errorOperacion +=
            ' El registro pudo haberse guardado. ' +
            'Revisa el historial antes de repetir la operación.';
        }

        if (err.status === 409) {
          this.cargarHistorial();
        }

        this.cd.detectChanges();
      }
    });
  }

  seleccionarSalida(asistencia: AsistenciaPersonal): void {
    if (asistencia.horaSalida !== null) return;

    this.idAsistenciaSalida = asistencia.idAsistenciaPersonal;
    this.horaSalida = this.horaLocal();
    this.errorOperacion = '';
  }

  registrarSalida(): void {
    if (this.guardando || this.revisionNecesaria) return;

    this.errorOperacion = '';
    this.mensajeExito = '';

    const asistencia = this.asistenciaSalida;

    if (!asistencia) {
      this.errorOperacion =
        'Selecciona una asistencia pendiente de salida.';
      return;
    }

    if (!this.horaValida(this.horaSalida)) {
      this.errorOperacion = 'Ingresa una hora de salida válida.';
      return;
    }

    if (
      this.horaSalida <
      asistencia.horaEntrada.slice(0, 5)
    ) {
      this.errorOperacion =
        'La salida no puede ser anterior a la entrada.';
      return;
    }

    const confirmado = window.confirm(
      `¿Registrar salida laboral?\n\n` +
      `Empleado: ${asistencia.nombreCompleto}\n` +
      `Fecha: ${asistencia.fecha}\n` +
      `Hora de salida: ${this.horaSalida}\n\n` +
      'La salida no podrá sobrescribirse después.'
    );

    if (!confirmado) return;

    this.guardando = true;

    this.asistenciaService.registrarSalida(
      asistencia.idAsistenciaPersonal,
      `${this.horaSalida}:00`
    )
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe({
      next: respuesta => {
        this.guardando = false;
        this.idAsistenciaSalida = null;
        this.mensajeExito =
          `Salida registrada. Folio #${respuesta.idAsistenciaPersonal}.`;

        this.cargarHistorial();
        this.cd.detectChanges();
      },

      error: (err: HttpErrorResponse) => {
        this.guardando = false;
        this.errorOperacion = this.mensajeError(err);

        if (err.status === 0 || err.status >= 500) {
          this.revisionNecesaria = true;
          this.errorOperacion +=
            ' La salida podría estar registrada. ' +
            'Comprueba el historial antes de volver a intentar.';
        }

        if (err.status === 409) {
          this.cargarHistorial();
        }

        this.cd.detectChanges();
      }
    });
  }

  private mensajeError(err: HttpErrorResponse): string {
    if (err.status === 401) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }

    if (err.status === 403) {
      return 'Solo un Administrador autorizado puede realizar esta acción.';
    }

    const mensaje = err.error?.mensaje;

    if (typeof mensaje === 'string' && mensaje.trim()) {
      return mensaje;
    }

    if (err.status === 409) {
      return 'Existe un conflicto. Revisa el historial actualizado.';
    }

    if (err.status === 0) {
      return 'No se pudo confirmar la respuesta de Backend.';
    }

    return `No fue posible completar la operación (HTTP ${err.status}).`;
  }

  mostrarFecha(fecha: string | null): string {
    if (!fecha) return '—';

    const partes = /^(\d{4})-(\d{2})-(\d{2})/.exec(fecha);

    return partes
      ? `${partes[3]}/${partes[2]}/${partes[1]}`
      : fecha;
  }

  volverPersonal(): void {
    this.router.navigate(['/admin/personal']);
  }
}
