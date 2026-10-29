
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import {
  UsuarioService
} from '../services/usuario.service';

import {
  AuthService
} from '../services/auth.service';

import {
  Usuario
} from '../models/usuario.model';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home implements OnInit {

  usuario: Usuario | null = null;

  cargando = true;
  error = '';
  mensaje = '';

  constructor(
    private usuarioService: UsuarioService,
    private authService: AuthService,
    private router: Router,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarUsuario();
  }

  cargarUsuario(): void {

    this.cargando = true;
    this.error = '';

    this.usuarioService
      .obtenerUsuarioActual()
      .subscribe({

        next: (usuario) => {

          this.usuario = usuario;

          localStorage.setItem(
            'usuario',
            JSON.stringify(usuario)
          );

          this.cargando = false;

          this.changeDetector.detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al obtener usuario:',
            error
          );

          this.cargando = false;

          if (error.status === 401) {

            this.authService.cerrarSesion();

            this.router.navigate([
              '/login'
            ]);

            return;
          }

          this.error =
            'No se pudieron cargar los datos del usuario.';

          this.changeDetector.detectChanges();
        }
      });
  }

  // ROLES

  esRecepcionista(): boolean {

    return this.usuario?.role
      ?.toLowerCase() === 'recepcionista';
  }

  esCliente(): boolean {

    return this.usuario?.role
      ?.toLowerCase() === 'cliente';
  }

  esAdministrador(): boolean {

    return this.usuario?.role
      ?.toLowerCase() === 'administrador';
  }

  esEntrenador(): boolean {

    return this.usuario?.role
      ?.toLowerCase() === 'entrenador';
  }

  // PERFIL

  irPerfil(): void {
    this.router.navigate(['/perfil']);
  }

  // ADMINISTRADOR

  irDashboardAdministrador(): void {

    if (!this.esAdministrador()) {

      this.mensaje =
        'Esta opción está disponible únicamente para administradores.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/admin/dashboard']);
  }

  irClientesAdministrador(): void {

    if (!this.esAdministrador()) {

      this.mensaje =
        'Esta opción está disponible únicamente para administradores.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/admin/clientes']);
  }

  irPersonalAdministrador(): void {

    if (!this.esAdministrador()) {

      this.mensaje =
        'Esta opción está disponible únicamente para administradores.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/admin/personal']);
  }

  irHorariosAdministrador(): void {

    if (!this.esAdministrador()) {

      this.mensaje =
        'Solo los administradores pueden gestionar horarios y asistencias.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate([
      '/admin/personal/operaciones'
    ]);
  }

  irMembresiasAdministrador(): void {

    if (!this.esAdministrador()) {

      this.mensaje =
        'Solo los administradores pueden gestionar membresías.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/admin/membresias']);
  }

  // NUEVO: ADMINISTRAR ADMINISTRADORES

  irAdministradores(): void {

    if (!this.esAdministrador()) {

      this.mensaje =
        'Solo los administradores pueden gestionar otras cuentas administrativas.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate([
      '/admin/administradores'
    ]);
  }

  // RECEPCIÓN

  irRegistrarCliente(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'No tienes permisos para registrar clientes.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/registrar-cliente']);
  }

  irControlAcceso(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'No tienes permisos para registrar asistencias.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/control-acceso']);
  }

  irHistorialAsistencias(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'No tienes permisos para consultar asistencias.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/historial-asistencias']);
  }

  irRegistrarPago(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'No tienes permisos para registrar pagos.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/registrar-pago']);
  }

  irHistorialPagos(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'No tienes permisos para consultar pagos.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/historial-pagos']);
  }

  irAsignacionEntrenadores(): void {

    if (!this.esRecepcionista()) {

      this.mensaje =
        'Esta opción está disponible únicamente para recepción.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate([
      '/asignacion-entrenadores'
    ]);
  }

  // CLIENTE

  irMiCodigoAcceso(): void {

    if (!this.esCliente()) {

      this.mensaje =
        'Esta opción está disponible únicamente para clientes.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/mi-codigo-acceso']);
  }

  irMisAsistencias(): void {

    if (!this.esCliente()) {

      this.mensaje =
        'Esta opción está disponible únicamente para clientes.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/mis-asistencias']);
  }

  
irMiMembresia(): void {
  if (!this.esCliente()) {
    this.mensaje =
      'Solo los clientes pueden consultar su membresía.';
    this.changeDetector.detectChanges();
    return;
  }

  this.router.navigate(['/mi-membresia']);
}


  irMisPagos(): void {

    if (!this.esCliente()) {

      this.mensaje =
        'Esta opción está disponible únicamente para clientes.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/mis-pagos']);
  }

  irRutinasCliente(): void {

    if (!this.esCliente()) {

      this.mensaje =
        'Esta opción está disponible únicamente para clientes.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/rutinas']);
  }

  irMiProgreso(): void {

    if (!this.esCliente()) {

      this.mensaje =
        'Esta opción está disponible únicamente para clientes.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate(['/mi-progreso']);
  }

  // ENTRENADOR

  irMisClientesEntrenador(): void {

    if (!this.esEntrenador()) {

      this.mensaje =
        'Esta opción está disponible únicamente para entrenadores.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate([
      '/entrenador/mis-clientes'
    ]);
  }

  irEjerciciosEntrenador(): void {

    if (!this.esEntrenador()) {

      this.mensaje =
        'Esta opción está disponible únicamente para entrenadores.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate([
      '/entrenador/ejercicios'
    ]);
  }

  irRutinasEntrenador(): void {

    if (!this.esEntrenador()) {

      this.mensaje =
        'Esta opción está disponible únicamente para entrenadores.';

      this.changeDetector.detectChanges();
      return;
    }

    this.router.navigate([
      '/entrenador/rutinas'
    ]);
  }

  // FUNCIONES PENDIENTES

  proximamente(opcion: string): void {

    this.mensaje =
      `${opcion} estará disponible próximamente.`;

    this.changeDetector.detectChanges();

    setTimeout(() => {

      this.mensaje = '';
      this.changeDetector.detectChanges();

    }, 3000);
  }

  // CERRAR SESIÓN

  cerrarSesion(): void {

    this.authService.cerrarSesion();

    this.router.navigate(['/login']);
  }
}
