
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';

import {
  NotificacionesService
} from '../services/notificaciones.service';

import {
  NotificacionGymFlow
} from '../models/notificacion.model';

@Component({
  selector: 'app-notificaciones',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notificaciones.html',
  styleUrl: './notificaciones.css'
})
export class Notificaciones implements OnInit {
  notificaciones: NotificacionGymFlow[] = [];

  cargando = false;
  soloNoLeidas = false;
  procesandoId: number | null = null;

  error = '';
  errorAccion = '';
  mensajeExito = '';

  constructor(
    private servicio: NotificacionesService,
    private router: Router,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarNotificaciones();
  }

  cargarNotificaciones(): void {
    if (this.cargando || this.procesandoId !== null) {
      return;
    }

    this.cargando = true;
    this.error = '';
    this.errorAccion = '';

    this.servicio.obtenerNotificaciones().subscribe({
      next: respuesta => {
        if (!Array.isArray(respuesta)) {
          this.notificaciones = [];
          this.error = 'El servidor devolvió datos no válidos.';
        } else {
          this.notificaciones = respuesta;
        }

        this.cargando = false;
        this.cd.detectChanges();
      },

      error: (err: HttpErrorResponse) => {
        this.cargando = false;
        this.notificaciones = [];
        this.error = this.mensajeError(err);
        this.cd.detectChanges();
      }
    });
  }

  get totalNoLeidas(): number {
    return this.notificaciones.filter(
      notificacion => !notificacion.leida
    ).length;
  }

  get notificacionesVisibles(): NotificacionGymFlow[] {
    if (!this.soloNoLeidas) {
      return this.notificaciones;
    }

    return this.notificaciones.filter(
      notificacion => !notificacion.leida
    );
  }

  mostrarTodas(): void {
    this.soloNoLeidas = false;
  }

  mostrarNoLeidas(): void {
    this.soloNoLeidas = true;
  }

  marcarComoLeida(
    notificacion: NotificacionGymFlow
  ): void {
    if (
      notificacion.leida ||
      this.procesandoId !== null ||
      this.cargando
    ) {
      return;
    }

    this.procesandoId = notificacion.idNotificacion;
    this.errorAccion = '';
    this.mensajeExito = '';

    this.servicio.marcarComoLeida(
      notificacion.idNotificacion
    ).subscribe({
      next: respuesta => {
        this.procesandoId = null;

        if (
          respuesta.idNotificacion !==
          notificacion.idNotificacion
        ) {
          this.errorAccion =
            'No se pudo verificar la confirmación. ' +
            'Actualiza la lista.';
        } else {
          this.mensajeExito =
            'Notificación marcada como leída.';
        }

        this.cd.detectChanges();
        this.cargarNotificaciones();
      },

      error: (err: HttpErrorResponse) => {
        this.procesandoId = null;

        this.errorAccion =
          this.mensajeError(err) +
          ' Actualiza la lista para verificar si ' +
          'la notificación ya quedó marcada.';

        this.cd.detectChanges();
      }
    });
  }

  private mensajeError(error: HttpErrorResponse): string {
    if (error.status === 401) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }

    if (error.status === 403) {
      return 'No tienes permiso para consultar estos avisos.';
    }

    if (error.status === 404) {
      return 'No se encontró la notificación.';
    }

    if (error.status === 0) {
      return 'No fue posible conectar con Backend.';
    }

    return 'No fue posible completar la operación.';
  }

  formatearFecha(fecha: string | null): string {
    if (!fecha) {
      return 'No disponible';
    }

    const partes =
      /^(\d{4})-(\d{2})-(\d{2})/.exec(fecha);

    if (!partes) {
      return fecha;
    }

    return `${partes[3]}/${partes[2]}/${partes[1]}`;
  }

  trackNotificacion(
    _indice: number,
    notificacion: NotificacionGymFlow
  ): number {
    return notificacion.idNotificacion;
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
