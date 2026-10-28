
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { Location } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  PersonalAdmin,
  PuestoPersonalAdmin,
  EstatusPersonalAdmin
} from '../models/admin-personal.model';

@Component({
  selector: 'app-admin-personal',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal.html',
  styleUrl: './admin-personal.css'
})
export class AdminPersonal implements OnInit {

  empleados: PersonalAdmin[] = [];

  cargando = false;
  error = '';
  consultaRealizada = false;

  mensajeRegistro = '';

  filtroPuesto: PuestoPersonalAdmin | '' = '';
  filtroEstatus: EstatusPersonalAdmin | '' = '';

  // SELECTOR DE EMPLEADOS

  mostrarSelectorEdicion = false;
  idPersonalSeleccionado: number | null = null;

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef,
    private location: Location
  ) {}

  ngOnInit(): void {

    const estado = this.location.getState();

    if (
      estado &&
      typeof estado === 'object' &&
      'empleadoRegistradoId' in estado
    ) {

      const id = (
        estado as { empleadoRegistradoId?: unknown }
      ).empleadoRegistradoId;

      if (
        typeof id === 'number' &&
        Number.isInteger(id) &&
        id > 0
      ) {

        this.mensajeRegistro =
          `Empleado registrado correctamente. ID: ${id}.`;

        this.location.replaceState(
          '/admin/personal',
          '',
          {}
        );
      }
    }

    this.cargarPersonal();
  }

  // REGISTRAR EMPLEADO

  irRegistrarPersonal(): void {

    this.router.navigate([
      '/admin/personal/nuevo'
    ]);
  }

  // ABRIR SELECTOR DE EDICION

  abrirSelectorEdicion(): void {

    this.idPersonalSeleccionado = null;
    this.mostrarSelectorEdicion = true;
  }

  // CERRAR SELECTOR

  cerrarSelectorEdicion(): void {

    this.mostrarSelectorEdicion = false;
    this.idPersonalSeleccionado = null;
  }

  // MOSTRAR SOLO EMPLEADOS ACTIVOS

  get empleadosDisponibles(): PersonalAdmin[] {

    return this.empleados.filter(
      empleado => empleado.estatus === 'Activo'
    );
  }

  // IR A LA PANTALLA DE EDICION

  continuarEdicion(): void {

    const id = this.idPersonalSeleccionado;

    if (id === null) {
      return;
    }

    const existe = this.empleadosDisponibles.some(
      empleado => empleado.idPersonal === id
    );

    if (!existe) {
      return;
    }

    this.cerrarSelectorEdicion();

    this.router.navigate([
      '/admin/personal/editar',
      id
    ]);
  }

  // FILTROS DEL DIRECTORIO

  get empleadosFiltrados(): PersonalAdmin[] {

    return this.empleados.filter(empleado => {

      const puestoValido =
        !this.filtroPuesto ||
        empleado.puesto === this.filtroPuesto;

      const estatusValido =
        !this.filtroEstatus ||
        empleado.estatus === this.filtroEstatus;

      return puestoValido && estatusValido;
    });
  }

  get hayFiltrosActivos(): boolean {

    return (
      this.filtroPuesto !== '' ||
      this.filtroEstatus !== ''
    );
  }

  limpiarFiltros(): void {

    this.filtroPuesto = '';
    this.filtroEstatus = '';
  }

  // CONSULTAR PERSONAL

  cargarPersonal(): void {

    if (this.cargando) {
      return;
    }

    this.cargando = true;
    this.error = '';
    this.consultaRealizada = false;
    this.empleados = [];

    this.personalService
      .obtenerPersonal()
      .pipe(
        takeUntilDestroyed(this.destroyRef)
      )
      .subscribe({

        next: (respuesta: PersonalAdmin[]) => {

          this.cargando = false;
          this.consultaRealizada = true;

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
          this.consultaRealizada = true;

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
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudieron consultar los empleados.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // FORMATO DE SALARIO

  mostrarSalario(monto: number): string {

    if (
      monto === null ||
      monto === undefined ||
      !Number.isFinite(Number(monto))
    ) {
      return 'No disponible';
    }

    return new Intl.NumberFormat('es-MX', {
      style: 'currency',
      currency: 'MXN'
    }).format(monto);
  }

  // FORMATO DE FECHA

  mostrarFecha(fecha: string | null): string {

    if (!fecha) {
      return '—';
    }

    const partes = fecha.split('-');

    if (partes.length !== 3) {
      return fecha;
    }

    return `${partes[2]}/${partes[1]}/${partes[0]}`;
  }

  volverInicio(): void {

    this.router.navigate(['/home']);
  }
}
