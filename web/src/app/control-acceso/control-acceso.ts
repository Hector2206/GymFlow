import {
  AfterViewInit,
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

  constructor(
    private router: Router,
    private asistenciaService: AsistenciaService
  ) {}

  ngAfterViewInit(): void {

    this.codigoInput
      .nativeElement
      .focus();
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

    if (!this.codigoAcceso) {

      console.log(
        'No se ingresó un código de acceso.'
      );

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

          this.accesoAprobado =
            respuesta.accesoAprobado === true;

          this.clienteIdentificado =
            respuesta.nombreCompleto ?? '';

          this.nombrePlan =
            respuesta.nombrePlan ?? '';

          this.fechaVencimiento =
            respuesta.fechaVencimiento ?? '';
        },

        error: (error) => {

          console.error(
            'Error al registrar asistencia:',
            error
          );

          this.accesoAprobado = false;

          this.clienteIdentificado = '';
          this.nombrePlan = '';
          this.fechaVencimiento = '';
        }
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