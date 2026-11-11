
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { ActivatedRoute, Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Observable } from 'rxjs';

import {
  AdminDetallesService,
  AsistenciaAdmin,
  PagoAdmin
} from '../services/admin-detalles.service';

import {
  AlertaPersonal
} from '../admin-personal-ui/alerta-personal';

type TipoDetalleAdmin = 'asistencias' | 'pagos';

@Component({
  selector: 'app-admin-detalles',
  standalone: true,
  imports: [
    CommonModule,
    AlertaPersonal
  ],
  templateUrl: './admin-detalles.html',
  styleUrl: './admin-detalles.css'
})
export class AdminDetalles implements OnInit {

  tipo: TipoDetalleAdmin = 'asistencias';

  asistencias: AsistenciaAdmin[] = [];
  pagos: PagoAdmin[] = [];

  pagina = 1;
  readonly limite = 25;

  cargando = false;
  error = '';
  haySiguiente = false;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly servicio: AdminDetallesService,
    private readonly cd: ChangeDetectorRef,
    private readonly destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {

    this.tipo =
      this.route.snapshot.data['tipo'] === 'pagos'
        ? 'pagos'
        : 'asistencias';

    this.cargar();
  }

  get titulo(): string {
    return this.tipo === 'asistencias'
      ? 'Asistencias del día'
      : 'Historial de pagos';
  }

  get descripcion(): string {
    return this.tipo === 'asistencias'
      ? 'Consulta los accesos aprobados de clientes durante el día.'
      : 'Consulta los pagos registrados de los clientes.';
  }

  get cantidadRegistros(): number {
    return this.tipo === 'asistencias'
      ? this.asistencias.length
      : this.pagos.length;
  }

  cargar(): void {

    if (this.cargando) {
      return;
    }

    this.cargando = true;
    this.error = '';
    this.haySiguiente = false;

    this.asistencias = [];
    this.pagos = [];

    const peticion:
      Observable<AsistenciaAdmin[] | PagoAdmin[]> =
      this.tipo === 'asistencias'
        ? this.servicio.obtenerAsistencias(
            this.pagina,
            this.limite
          )
        : this.servicio.obtenerPagos(
            this.pagina,
            this.limite
          );

    peticion
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.cargando = false;

          if (!Array.isArray(respuesta)) {
            this.error =
              'El servidor devolvió una respuesta inesperada.';

            this.cd.detectChanges();
            return;
          }

          if (this.tipo === 'asistencias') {
            this.asistencias =
              respuesta as AsistenciaAdmin[];
          } else {
            this.pagos =
              respuesta as PagoAdmin[];
          }

          // El endpoint no devuelve total de páginas.
          this.haySiguiente =
            respuesta.length === this.limite;

          this.cd.detectChanges();
        },

        error: (err: HttpErrorResponse) => {

          this.cargando = false;

          if (err.status === 401) {
            this.error =
              'Tu sesión venció. Inicia sesión nuevamente.';
          } else if (err.status === 403) {
            this.error =
              'No tienes permisos para consultar esta información.';
          } else if (err.status === 0) {
            this.error =
              'No fue posible conectar con el servidor.';
          } else if (err.status >= 500) {
            this.error =
              'El servidor no está disponible. Intenta nuevamente.';
          } else {
            this.error =
              'No fue posible consultar los registros.';
          }

          this.cd.detectChanges();
        }

      });
  }

  paginaAnterior(): void {

    if (this.cargando || this.pagina <= 1) {
      return;
    }

    this.pagina--;
    this.cargar();
  }

  paginaSiguiente(): void {

    if (this.cargando || !this.haySiguiente) {
      return;
    }

    this.pagina++;
    this.cargar();
  }

  volverDashboard(): void {
    this.router.navigate(['/admin/dashboard']);
  }
}
