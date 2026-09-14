import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  ElementRef,
  ViewChild
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import {
  AsistenciaService,
  RegistrarAsistenciaResponse
} from '../services/asistencia.service';

@Component({
  selector: 'app-control-acceso',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './control-acceso.html',
  styleUrl: './control-acceso.css'
})
export class ControlAcceso implements AfterViewInit {

  @ViewChild('codigoInput')
  codigoInput!: ElementRef<HTMLInputElement>;

  codigoAcceso = '';

  clienteIdentificado = '';

  nombrePlan = '';
  fechaVencimiento = '';

  accesoAprobado = false;
  accesoRechazado = false;

  mensajeRechazo = '';

  constructor(
    private router: Router,
    private asistenciaService: AsistenciaService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngAfterViewInit(): void {

    this.enfocarCampo();
  }

  capturarCodigo(
    event: Event
  ): void {

    const input =
      event.target as HTMLInputElement;

    this.codigoAcceso =
      input.value;
  }

  detectarEnter(): void {

    this.codigoAcceso =
      this.codigoAcceso.trim();

    this.limpiarResultadoAnterior();

    if (!this.codigoAcceso) {

      this.mostrarRechazo(
        'Ingresa un código de acceso.'
      );

      this.limpiarCampo();

      return;
    }

    const formatoValido =
      /^[A-Za-z0-9-]+$/.test(
        this.codigoAcceso
      );

    if (!formatoValido) {

      this.mostrarRechazo(
        'El código solo puede contener letras, números y guiones.'
      );

      this.limpiarCampo();

      return;
    }

    this.enviarCodigo();
  }

  enviarCodigo(): void {

    console.log(
      'Enviando código al backend:',
      this.codigoAcceso
    );

    this.asistenciaService
      .registrarPorCodigo(
        this.codigoAcceso
      )
      .subscribe({

        next: (
          respuesta: RegistrarAsistenciaResponse
        ) => {

          console.log(
            'Respuesta del backend:',
            respuesta
          );

          if (
            respuesta.accesoAprobado === true
          ) {

            this.accesoAprobado = true;
            this.accesoRechazado = false;

            this.clienteIdentificado =
              respuesta.nombreCompleto ?? '';

            this.nombrePlan =
              respuesta.nombrePlan ?? '';

            this.fechaVencimiento =
              respuesta.fechaVencimiento ?? '';

            this.mensajeRechazo = '';

          } else {

            this.accesoAprobado = false;
            this.accesoRechazado = true;

            this.clienteIdentificado =
              respuesta.nombreCompleto ?? '';

            this.nombrePlan =
              respuesta.nombrePlan ?? '';

            this.fechaVencimiento =
              respuesta.fechaVencimiento ?? '';

            this.mensajeRechazo =
              respuesta.mensaje ??
              'El acceso fue rechazado.';
          }

          this.limpiarCampo();

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al registrar asistencia:',
            error
          );

          this.accesoAprobado = false;
          this.accesoRechazado = true;

          this.clienteIdentificado = '';
          this.nombrePlan = '';
          this.fechaVencimiento = '';

          if (
            error.error &&
            typeof error.error === 'object' &&
            error.error.mensaje
          ) {

            this.mensajeRechazo =
              error.error.mensaje;

          } else if (
            error.status === 404
          ) {

            this.mensajeRechazo =
              'Código de acceso no encontrado.';

          } else if (
            error.status === 401
          ) {

            this.mensajeRechazo =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.mensajeRechazo =
              'No tienes permiso para registrar asistencias.';

          } else if (
            error.status === 0
          ) {

            this.mensajeRechazo =
              'No fue posible conectar con el servidor.';

          } else {

            this.mensajeRechazo =
              'No fue posible validar el acceso. Intenta nuevamente.';
          }

          this.limpiarCampo();

          this.changeDetector
            .detectChanges();
        }
      });
  }

  limpiarResultadoAnterior(): void {

    this.accesoAprobado = false;
    this.accesoRechazado = false;

    this.mensajeRechazo = '';

    this.clienteIdentificado = '';
    this.nombrePlan = '';
    this.fechaVencimiento = '';

    this.changeDetector
      .detectChanges();
  }

  mostrarRechazo(
    mensaje: string
  ): void {

    this.accesoAprobado = false;
    this.accesoRechazado = true;

    this.mensajeRechazo =
      mensaje;

    this.changeDetector
      .detectChanges();
  }

  limpiarCampo(): void {

    this.codigoAcceso = '';

    if (this.codigoInput) {

      this.codigoInput
        .nativeElement
        .value = '';
    }

    this.enfocarCampo();
  }

  enfocarCampo(): void {

    setTimeout(() => {

      this.codigoInput
        ?.nativeElement
        .focus();

    });
  }

  formatearFecha(
    fecha: string
  ): string {

    if (!fecha) {
      return '';
    }

    const fechaConvertida =
      new Date(fecha);

    return fechaConvertida
      .toLocaleDateString('es-MX');
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}