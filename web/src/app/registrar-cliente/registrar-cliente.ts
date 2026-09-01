import {
  ChangeDetectorRef,
  Component
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import {
  HttpClient,
  HttpErrorResponse
} from '@angular/common/http';

import { Router } from '@angular/router';

import {
  environment
} from '../../environments/environment';

@Component({
  selector: 'app-registrar-cliente',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './registrar-cliente.html',
  styleUrl: './registrar-cliente.css'
})
export class RegistrarCliente {

  nombreCompleto = '';
  correo = '';
  password = '';
  telefono = '';
  idAsistencia = '';

  idMembresia: number | null = null;

  costoMensual: number | null = null;
  costoAnual: number | null = null;

  cargando = false;

  error = '';
  exito = '';

  constructor(
    private http: HttpClient,
    private router: Router,
    private changeDetector: ChangeDetectorRef
  ) {}

  volver(): void {
    this.router.navigate(['/home']);
  }

  registrarCliente(): void {

    this.error = '';
    this.exito = '';

    if (!this.nombreCompleto.trim()) {

      this.error =
        'El nombre completo es obligatorio.';

      return;
    }

    if (!this.correo.trim()) {

      this.error =
        'El correo es obligatorio.';

      return;
    }

    if (!this.correoValido(this.correo)) {

      this.error =
        'Ingresa un correo electrónico válido.';

      return;
    }

    if (!this.password.trim()) {

      this.error =
        'La contraseña es obligatoria.';

      return;
    }

    if (this.password.length < 6) {

      this.error =
        'La contraseña debe tener al menos 6 caracteres.';

      return;
    }

    if (!this.idAsistencia.trim()) {

      this.error =
        'El ID de asistencia es obligatorio.';

      return;
    }

    if (
      this.idMembresia === null ||
      this.idMembresia <= 0
    ) {

      this.error =
        'Selecciona una membresía válida.';

      return;
    }

    if (
      this.costoMensual === null ||
      this.costoMensual < 0
    ) {

      this.error =
        'Ingresa un costo mensual válido.';

      return;
    }

    if (
      this.costoAnual === null ||
      this.costoAnual < 0
    ) {

      this.error =
        'Ingresa un costo anual válido.';

      return;
    }

    if (this.cargando) {
      return;
    }

    this.cargando = true;

    const cliente = {

      correo:
        this.correo.trim(),

      password:
        this.password,

      idAsistencia:
        this.idAsistencia.trim(),

      nombreCompleto:
        this.nombreCompleto.trim(),

      telefono:
        this.telefono.trim() || null,

      idMembresia:
        this.idMembresia,

      costoMensual:
        this.costoMensual,

      costoAnual:
        this.costoAnual
    };

    this.http
      .post(
        `${environment.clienteAltaUrl}/api/clientes`,
        cliente
      )
      .subscribe({

        next: (response: any) => {

          this.cargando = false;

          this.exito =
            response?.mensaje ||
            'Cliente registrado correctamente.';

          this.limpiarFormulario();

          this.changeDetector.detectChanges();
        },

        error: (
          error: HttpErrorResponse
        ) => {

          console.error(
            'Error al registrar cliente:',
            error
          );

          this.cargando = false;

          if (error.status === 401) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.error =
              'No tienes permisos para registrar clientes.';

          } else if (error.status === 400) {

            this.error =
              error.error?.mensaje ||
              error.error?.message ||
              'Verifica los datos ingresados.';

          } else if (error.status === 0) {

            this.error =
              'No se pudo conectar con el servicio de registro.';

          } else {

            this.error =
              'Ocurrió un error al registrar el cliente.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  correoValido(
    correo: string
  ): boolean {

    const expresion =
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    return expresion.test(
      correo.trim()
    );
  }

  limpiarFormulario(): void {

    this.nombreCompleto = '';
    this.correo = '';
    this.password = '';
    this.telefono = '';
    this.idAsistencia = '';

    this.idMembresia = null;

    this.costoMensual = null;
    this.costoAnual = null;
  }
}