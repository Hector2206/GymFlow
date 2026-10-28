
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

type VistaAdministradores =
  'listado' | 'nuevo' | 'gestion';

interface BorradorAdministrador {
  nombreCompleto: string;
  correo: string;
  telefono: string;
  password: string;
  confirmarPassword: string;
}

@Component({
  selector: 'app-admin-administradores',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-administradores.html',
  styleUrl: './admin-administradores.css'
})
export class AdminAdministradores {

  vista: VistaAdministradores = 'listado';

  readonly rolNuevo = 'Administrador';

  nuevoAdministrador: BorradorAdministrador =
    this.crearBorrador();

  error = '';
  formularioRevisado = false;

  constructor(
    private router: Router
  ) {}

  private crearBorrador(): BorradorAdministrador {

    return {
      nombreCompleto: '',
      correo: '',
      telefono: '',
      password: '',
      confirmarPassword: ''
    };
  }

  cambiarVista(vista: VistaAdministradores): void {

    if (vista !== 'nuevo') {

      // No conservar contraseñas al salir
      // del formulario.
      this.nuevoAdministrador.password = '';
      this.nuevoAdministrador.confirmarPassword = '';
    }

    this.vista = vista;
    this.reiniciarRevision();
  }

  reiniciarRevision(): void {

    this.error = '';
    this.formularioRevisado = false;
  }

  // VALIDACIÓN DE CORREO

  private correoValido(correo: string): boolean {

    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(
      correo
    );
  }

  // VALIDACIÓN DE TELÉFONO

  private telefonoValido(telefono: string): boolean {

    const digitos = telefono.replace(/\D/g, '');

    return (
      digitos.length >= 10 &&
      digitos.length <= 15 &&
      /^[+0-9\s()-]+$/.test(telefono)
    );
  }

  // REVISAR DATOS SIN CREAR CUENTA

  revisarFormulario(): void {

    this.reiniciarRevision();

    const datos = this.nuevoAdministrador;

    const nombre = datos.nombreCompleto.trim();

    const correo = datos.correo.trim().toLowerCase();

    const telefono = datos.telefono.trim();

    if (
      nombre.length < 3 ||
      nombre.length > 150
    ) {

      this.error =
        'El nombre completo debe tener entre 3 y 150 caracteres.';

      return;
    }

    if (
      correo.length > 150 ||
      !this.correoValido(correo)
    ) {

      this.error =
        'Ingresa un correo electrónico válido.';

      return;
    }

    if (!this.telefonoValido(telefono)) {

      this.error =
        'Ingresa un teléfono válido de 10 a 15 dígitos.';

      return;
    }

    if (datos.password.length < 8) {

      this.error =
        'La contraseña inicial debe tener al menos 8 caracteres.';

      return;
    }

    if (datos.password.length > 128) {

      this.error =
        'La contraseña inicial no debe superar 128 caracteres.';

      return;
    }

    if (
      datos.password !==
      datos.confirmarPassword
    ) {

      this.error =
        'Las contraseñas no coinciden.';

      return;
    }

    // Normalizar únicamente los datos
    // que no son contraseñas.
    datos.nombreCompleto = nombre;
    datos.correo = correo;
    datos.telefono = telefono;

    // Solo validación de interfaz.
    // NO se crea cuenta ni se llama al backend.
    this.formularioRevisado = true;
  }

  // DESCARTAR EL BORRADOR

  limpiarFormulario(): void {

    this.nuevoAdministrador =
      this.crearBorrador();

    this.reiniciarRevision();
  }

  volverInicio(): void {

    this.limpiarFormulario();

    this.router.navigate([
      '/home'
    ]);
  }
}
