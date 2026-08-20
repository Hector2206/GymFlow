import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login {

  correo = '';
  password = '';

  errorCorreo = '';
  errorPassword = '';
  errorLogin = '';

  cargando = false;

  constructor(private router: Router) {}

  async validarFormulario() {

    this.errorCorreo = '';
    this.errorPassword = '';
    this.errorLogin = '';

    let formularioValido = true;

    // VALIDAR CORREO
    if (!this.correo.trim()) {

      this.errorCorreo = 'El correo es obligatorio';
      formularioValido = false;

    } else if (!this.correoValido(this.correo)) {

      this.errorCorreo = 'Ingresa un correo electrónico válido';
      formularioValido = false;
    }

    // VALIDAR CONTRASEÑA
    if (!this.password.trim()) {

      this.errorPassword = 'La contraseña es obligatoria';
      formularioValido = false;

    } else if (this.password.length < 6) {

      this.errorPassword =
        'La contraseña debe tener al menos 6 caracteres';

      formularioValido = false;
    }

    if (!formularioValido) {
      return;
    }

    await this.iniciarSesion();
  }

  async iniciarSesion() {

    this.cargando = true;
    this.errorLogin = '';

    try {

      const response = await fetch(
        'https://projectgym-5hpt.onrender.com/api/auth/login',
        {
          method: 'POST',

          headers: {
            'Content-Type': 'application/json'
          },

          body: JSON.stringify({
            correo: this.correo.trim(),
            password: this.password
          })
        }
      );

      let data: any = null;

      try {
        data = await response.json();
      } catch {
        data = null;
      }

      if (!response.ok) {

        this.errorLogin =
          data?.mensaje ||
          data?.message ||
          'Correo o contraseña incorrectos';

        return;
      }

      console.log('Respuesta del backend:', data);

      // Guardar token si el backend lo devuelve
      if (data?.token) {
        localStorage.setItem('token', data.token);
      }

      // Guardar usuario si el backend lo devuelve
      if (data?.usuario) {
        localStorage.setItem(
          'usuario',
          JSON.stringify(data.usuario)
        );
      }

      // Ir al menú principal
      this.router.navigate(['/home']);

    } catch (error) {

      console.error('Error al conectar con el backend:', error);

      this.errorLogin =
        'No se pudo conectar con el servidor';

    } finally {

      this.cargando = false;
    }
  }

  correoValido(correo: string): boolean {

    const expresion =
      /^[^\s@]+@[a-zA-Z]+\.com$/;

    return expresion.test(correo.trim());
  }
}