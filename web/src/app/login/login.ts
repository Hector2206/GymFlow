import {
  AfterViewInit,
  ChangeDetectorRef,
  Component
} from '@angular/core';

import {
  CommonModule
} from '@angular/common';

import {
  FormsModule
} from '@angular/forms';

import {
  Router
} from '@angular/router';

import {
  HttpClient,
  HttpErrorResponse
} from '@angular/common/http';

import {
  AuthService
} from '../services/auth.service';

import {
  environment
} from '../../environments/environment';

declare const google: any;

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule
  ],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login implements AfterViewInit {

  correo = '';
  password = '';

  cargando = false;
  cargandoGoogle = false;

  error = '';

  private readonly googleClientId =
    environment.googleClientId;

  constructor(
    private authService: AuthService,
    private http: HttpClient,
    private router: Router,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngAfterViewInit(): void {
    this.inicializarGoogle();
  }

  iniciarSesion(): void {

    this.error = '';

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

    if (this.cargando) {
      return;
    }

    this.cargando = true;

    this.authService
      .login(
        this.correo.trim(),
        this.password
      )
      .subscribe({

        next: () => {

          this.cargando = false;

          this.router.navigate([
            '/home'
          ]);
        },

        error: (
          error: HttpErrorResponse
        ) => {

          console.error(
            'Error en login local:',
            error
          );

          this.cargando = false;

          if (error.status === 401) {

            this.error =
              'Correo o contraseña incorrectos.';

          } else if (error.status === 0) {

            this.error =
              'No se pudo conectar con el servicio de autenticación.';

          } else {

            this.error =
              'Ocurrió un error al iniciar sesión.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  inicializarGoogle(): void {

    const intentarInicializar = () => {

      if (typeof google === 'undefined') {

        setTimeout(
          intentarInicializar,
          300
        );

        return;
      }

      google.accounts.id.initialize({

        client_id:
          this.googleClientId,

        callback:
          (response: any) => {

            this.loginGoogle(
              response.credential
            );
          }
      });

      const contenedor =
        document.getElementById(
          'google-login-button'
        );

      if (!contenedor) {
        return;
      }

      google.accounts.id.renderButton(
        contenedor,
        {
          theme:
            'filled_black',

          size:
            'large',

          shape:
            'pill',

          text:
            'signin_with',

          width:
            320
        }
      );
    };

    intentarInicializar();
  }

  loginGoogle(
    credential: string
  ): void {

    if (!credential) {

      this.error =
        'Google no devolvió una credencial válida.';

      this.changeDetector
        .detectChanges();

      return;
    }

    if (this.cargandoGoogle) {
      return;
    }

    this.error = '';
    this.cargandoGoogle = true;

    const body = {
      token: credential
    };

    this.http
      .post<any>(
        `${environment.authGoogleUrl}/api/auth/login-google`,
        body
      )
      .subscribe({

        next: (response) => {

          this.cargandoGoogle = false;

          const token =
            response?.token;

          if (!token) {

            this.error =
              'El servidor no devolvió un token válido.';

            this.changeDetector
              .detectChanges();

            return;
          }

          localStorage.setItem(
            'token',
            token
          );

          if (response?.usuario) {

            localStorage.setItem(
              'usuario',
              JSON.stringify(
                response.usuario
              )
            );
          }

          this.router.navigate([
            '/home'
          ]);
        },

        error: (
          error: HttpErrorResponse
        ) => {

          console.error(
            'Error en login con Google:',
            error
          );

          this.cargandoGoogle = false;

          if (error.status === 400) {

            this.error =
              error.error?.mensaje ||
              'La credencial de Google no es válida.';

          } else if (error.status === 401) {

            this.error =
              error.error?.mensaje ||
              'Esta cuenta de Google no está registrada en GymFlow.';

          } else if (error.status === 403) {

            this.error =
              error.error?.mensaje ||
              'La cuenta de Google no coincide con la registrada.';

          } else if (error.status === 0) {

            this.error =
              'No se pudo conectar con el servicio de Google.';

          } else {

            this.error =
              error.error?.detail ||
              'No fue posible iniciar sesión con Google.';
          }

          this.changeDetector
            .detectChanges();
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
}