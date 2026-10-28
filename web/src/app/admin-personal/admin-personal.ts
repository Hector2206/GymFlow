
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

  tituloOperacion = '';
  mensajeOperacion = '';

  filtroPuesto: PuestoPersonalAdmin | '' = '';
  filtroEstatus: EstatusPersonalAdmin | '' = '';

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

    if (estado && typeof estado === 'object') {

      const datos = estado as {
        empleadoRegistradoId?: unknown;
        empleadoEditadoId?: unknown;
        empleadoBajaId?: unknown;
        clientesDesasignados?: unknown;
      };

      if (
        typeof datos.empleadoRegistradoId === 'number' &&
        Number.isInteger(datos.empleadoRegistradoId) &&
        datos.empleadoRegistradoId > 0
      ) {

        this.tituloOperacion =
          'Empleado registrado';

        this.mensajeOperacion =
          `Empleado registrado correctamente. ` +
          `ID de personal: ${datos.empleadoRegistradoId}.`;

        this.limpiarEstadoNavegacion();

      } else if (
        typeof datos.empleadoEditadoId === 'number' &&
        Number.isInteger(datos.empleadoEditadoId) &&
        datos.empleadoEditadoId > 0
      ) {

        this.tituloOperacion =
          'Empleado actualizado';

        this.mensajeOperacion =
          `Los datos del empleado con ID ` +
          `${datos.empleadoEditadoId} ` +
          `se actualizaron correctamente.`;

        this.limpiarEstadoNavegacion();

      } else if (
        typeof datos.empleadoBajaId === 'number' &&
        Number.isInteger(datos.empleadoBajaId) &&
        datos.empleadoBajaId > 0
      ) {

        this.tituloOperacion =
          'Baja laboral registrada';

        this.mensajeOperacion =
          `El empleado con ID ${datos.empleadoBajaId} ` +
          `fue dado de baja correctamente.`;

        if (
          typeof datos.clientesDesasignados === 'number' &&
          Number.isInteger(datos.clientesDesasignados) &&
          datos.clientesDesasignados >= 0
        ) {

          this.mensajeOperacion +=
            ` Clientes desasignados: ` +
            `${datos.clientesDesasignados}.`;
        }

        this.limpiarEstadoNavegacion();
      }
    }

    this.cargarPersonal();
  }

  private limpiarEstadoNavegacion(): void {

    this.location.replaceState(
      '/admin/personal',
      '',
      {}
    );
  }

  // REGISTRO

  irRegistrarPersonal(): void {

    this.router.navigate([
      '/admin/personal/nuevo'
    ]);
  }

  // BAJAS

  irBajasPersonal(): void {

    this.router.navigate([
      '/admin/personal/bajas'
    ]);
  }

  // SELECCION DE EDICION

  abrirSelectorEdicion(): void {

    this.idPersonalSeleccionado = null;
    this.mostrarSelectorEdicion = true;
  }

  cerrarSelectorEdicion(): void {

    this.mostrarSelectorEdicion = false;
    this.idPersonalSeleccionado = null;
  }

  get empleadosDisponibles(): PersonalAdmin[] {

    return this.empleados.filter(
      empleado => empleado.estatus === 'Activo'
    );
  }

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

  // FILTROS

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
      .pipe(takeUntilDestroyed(this.destroyRef))
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

            const mensajeServidor =
              typeof error.error?.mensaje === 'string'
                ? error.error.mensaje
                : typeof error.error?.detail === 'string'
                  ? error.error.detail
                  : 'No se pudieron consultar los empleados.';

            this.error = mensajeServidor;
          }

          this.changeDetector.detectChanges();
        }
      });
  }

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
