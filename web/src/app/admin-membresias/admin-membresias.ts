
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';

import {
  AdminMembresiaService,
  AdminMembresia,
  GuardarMembresiaRequest,
  HistorialPrecio
} from '../services/admin-membresia.service';

interface FormularioMembresia {
  nombrePlan: string;
  descripcion: string;
  costoMensual: number | null;
  costoAnualidad: number | null;
}

@Component({
  selector: 'app-admin-membresias',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-membresias.html',
  styleUrl: './admin-membresias.css'
})
export class AdminMembresias implements OnInit {
  membresias: AdminMembresia[] = [];
  historial: HistorialPrecio[] = [];

  cargando = false;
  guardando = false;
  cargandoHistorial = false;
  operacionIncierta = false;

  mostrarFormulario = false;
  idEditando: number | null = null;
  idHistorial: number | null = null;

  error = '';
  exito = '';
  errorHistorial = '';

  formulario: FormularioMembresia =
    this.formularioVacio();

  constructor(
    private router: Router,
    private servicio: AdminMembresiaService,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarCatalogo();
  }

  private formularioVacio(): FormularioMembresia {
    return {
      nombrePlan: '',
      descripcion: '',
      costoMensual: null,
      costoAnualidad: null
    };
  }

  private obtenerError(error: HttpErrorResponse): string {
    if (error.status === 401) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }

    if (error.status === 403) {
      return 'No tienes permiso para administrar membresías.';
    }

    if (error.status === 404) {
      return 'No se encontró la membresía solicitada.';
    }

    const mensaje = error.error?.mensaje;

    if (typeof mensaje === 'string' && mensaje.trim()) {
      return mensaje;
    }

    if (error.status === 409) {
      return 'Ya existe una membresía con ese nombre.';
    }

    if (error.status === 0) {
      return 'No fue posible establecer conexión con Backend.';
    }

    return `No se pudo completar la operación (HTTP ${error.status}).`;
  }

  cargarCatalogo(): void {
    if (this.guardando) return;

    this.cargando = true;
    this.error = '';

    this.servicio.obtenerCatalogo().subscribe({
      next: (datos) => {
        this.membresias = datos ?? [];
        this.cargando = false;
        this.operacionIncierta = false;
        this.cd.detectChanges();
      },
      error: (error: HttpErrorResponse) => {
        this.cargando = false;
        this.error = this.obtenerError(error);
        this.cd.detectChanges();
      }
    });
  }

  nuevoPlan(): void {
    if (this.guardando || this.operacionIncierta) return;

    this.formulario = this.formularioVacio();
    this.idEditando = null;
    this.mostrarFormulario = true;
    this.error = '';
    this.exito = '';
  }

  editar(plan: AdminMembresia): void {
    if (this.guardando || this.operacionIncierta) return;

    this.formulario = {
      nombrePlan: plan.nombrePlan,
      descripcion: plan.descripcion,
      costoMensual: plan.costoMensual,
      costoAnualidad: plan.costoAnualidad
    };

    this.idEditando = plan.idMembresia;
    this.mostrarFormulario = true;
    this.error = '';
    this.exito = '';
  }

  cancelarFormulario(): void {
    if (this.guardando) return;

    this.mostrarFormulario = false;
    this.idEditando = null;
    this.formulario = this.formularioVacio();
    this.error = '';
  }

  private precioValido(valor: number | null): boolean {
    return (
      typeof valor === 'number' &&
      Number.isFinite(valor) &&
      valor > 0 &&
      valor <= 99999999.99 &&
      Math.abs(valor * 100 - Math.round(valor * 100)) < 0.000001
    );
  }

  guardar(): void {
    if (
      this.guardando ||
      this.cargando ||
      this.operacionIncierta
    ) {
      return;
    }

    this.error = '';
    this.exito = '';

    const nombrePlan = this.formulario.nombrePlan.trim();
    const descripcion = this.formulario.descripcion.trim();

    if (nombrePlan.length < 3 || nombrePlan.length > 100) {
      this.error = 'El nombre debe tener entre 3 y 100 caracteres.';
      return;
    }

    if (descripcion.length > 500) {
      this.error = 'La descripción no puede superar 500 caracteres.';
      return;
    }

    if (
      !this.precioValido(this.formulario.costoMensual) ||
      !this.precioValido(this.formulario.costoAnualidad)
    ) {
      this.error =
        'Ingresa precios mayores que cero y con máximo dos decimales.';
      return;
    }

    const datos: GuardarMembresiaRequest = {
      nombrePlan,
      descripcion,
      costoMensual: this.formulario.costoMensual!,
      costoAnualidad: this.formulario.costoAnualidad!
    };

    const id = this.idEditando;

    const confirmado = window.confirm(
      id === null
        ? `¿Crear la membresía "${nombrePlan}"?\n` +
          'Los precios serán oficiales para nuevos pagos.'
        : `¿Guardar los cambios en "${nombrePlan}"?\n` +
          'Los nuevos pagos utilizarán los precios actualizados.'
    );

    if (!confirmado) return;

    this.guardando = true;

    const operacion = id === null
      ? this.servicio.crear(datos)
      : this.servicio.editar(id, datos);

    operacion.subscribe({
      next: () => {
        this.guardando = false;
        this.mostrarFormulario = false;
        this.idEditando = null;
        this.formulario = this.formularioVacio();

        this.exito = id === null
          ? 'Membresía creada correctamente.'
          : 'Membresía actualizada correctamente.';

        this.cargarCatalogo();
      },
      error: (error: HttpErrorResponse) => {
        this.guardando = false;

        this.error = this.obtenerError(error);

        if (error.status === 0 || error.status >= 500) {
          this.operacionIncierta = true;
          this.error +=
            ' El cambio podría haberse guardado. ' +
            'Actualiza el catálogo y verifica antes de repetirlo.';
        }

        this.cd.detectChanges();
      }
    });
  }

  cambiarEstado(plan: AdminMembresia): void {
    if (
      this.guardando ||
      this.cargando ||
      this.operacionIncierta
    ) {
      return;
    }

    const nuevoEstado = !plan.activo;

    const confirmado = window.confirm(
      `¿${nuevoEstado ? 'Activar' : 'Desactivar'} ` +
      `la membresía "${plan.nombrePlan}"?`
    );

    if (!confirmado) return;

    this.guardando = true;
    this.error = '';
    this.exito = '';

    this.servicio.cambiarEstado(
      plan.idMembresia,
      nuevoEstado
    ).subscribe({
      next: () => {
        this.guardando = false;

        this.exito = nuevoEstado
          ? 'Membresía activada correctamente.'
          : 'Membresía desactivada correctamente.';

        this.cargarCatalogo();
      },
      error: (error: HttpErrorResponse) => {
        this.guardando = false;
        this.error = this.obtenerError(error);

        if (error.status === 0 || error.status >= 500) {
          this.operacionIncierta = true;
          this.error +=
            ' Verifica el estado del plan antes de repetir.';
        }

        this.cd.detectChanges();
      }
    });
  }

  consultarHistorial(plan: AdminMembresia): void {
    this.idHistorial = plan.idMembresia;
    this.historial = [];
    this.errorHistorial = '';
    this.cargandoHistorial = true;

    this.servicio.obtenerHistorial(
      plan.idMembresia
    ).subscribe({
      next: (datos) => {
        if (this.idHistorial !== plan.idMembresia) return;

        this.historial = datos ?? [];
        this.cargandoHistorial = false;
        this.cd.detectChanges();
      },
      error: (error: HttpErrorResponse) => {
        if (this.idHistorial !== plan.idMembresia) return;

        this.errorHistorial = this.obtenerError(error);
        this.cargandoHistorial = false;
        this.cd.detectChanges();
      }
    });
  }

  cerrarHistorial(): void {
    this.idHistorial = null;
    this.historial = [];
    this.errorHistorial = '';
  }

  nombrePlanHistorial(): string {
    return this.membresias.find(
      m => m.idMembresia === this.idHistorial
    )?.nombrePlan ?? 'Membresía';
  }

  formatearFecha(fecha: string): string {
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(fecha);

    if (!match) return fecha;

    return `${match[3]}/${match[2]}/${match[1]}`;
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
