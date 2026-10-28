
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

  // EMPLEADOS REGISTRADOS

  empleados: PersonalAdmin[] = [];

  cargando = false;
  error = '';
  consultaRealizada = false;

  // FILTROS

  filtroPuesto: PuestoPersonalAdmin | '' = '';
  filtroEstatus: EstatusPersonalAdmin | '' = '';

  // FORMULARIO DE ALTA

  mostrarFormularioAlta = false;

  nuevoEmpleado = this.crearFormularioVacio();

  constructor(
    private router: Router,
    private personalService: AdminPersonalService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarPersonal();
  }

  // ABRIR FORMULARIO

  abrirFormularioAlta(): void {

    this.nuevoEmpleado = this.crearFormularioVacio();

    this.mostrarFormularioAlta = true;
  }

  // CERRAR FORMULARIO

  cerrarFormularioAlta(): void {

    this.mostrarFormularioAlta = false;

    // Limpiar todos los campos, incluida la contrasena
    this.nuevoEmpleado = this.crearFormularioVacio();
  }

  // DATOS INICIALES DEL FORMULARIO

  private crearFormularioVacio() {

    return {
      nombreCompleto: '',
      correo: '',
      telefono: '',
      fechaContratacion: '',
      puesto: '' as PuestoPersonalAdmin | '',
      sueldo: null as number | null,
      password: ''
    };
  }

  // FILTRAR EMPLEADOS

  get empleadosFiltrados(): PersonalAdmin[] {

    return this.empleados.filter(empleado => {

      const coincidePuesto =
        !this.filtroPuesto ||
        empleado.puesto === this.filtroPuesto;

      const coincideEstatus =
        !this.filtroEstatus ||
        empleado.estatus === this.filtroEstatus;

      return coincidePuesto && coincideEstatus;
    });
  }

  get hayFiltrosActivos(): boolean {

    return (
      this.filtroPuesto !== '' ||
      this.filtroEstatus !== ''
    );
  }

  // LIMPIAR FILTROS

  limpiarFiltros(): void {

    this.filtroPuesto = '';
    this.filtroEstatus = '';
  }

  // CONSULTAR EMPLEADOS

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

        next: (respuesta) => {

          this.cargando = false;
          this.consultaRealizada = true;

          if (!Array.isArray(respuesta)) {

            this.error =
              'El servidor devolvió una respuesta inesperada.';

            this.changeDetector.detectChanges();
            return;
          }

          this.empleados = respuesta;

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
                  : typeof error.error?.title === 'string'
                    ? error.error.title
                    : '';

            this.error =
              mensajeServidor ||
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
      currency: 'MXN',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(monto);
  }

  // FORMATO DE FECHAS

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
