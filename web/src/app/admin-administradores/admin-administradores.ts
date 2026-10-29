
import { ChangeDetectorRef, Component, DestroyRef, OnInit } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  Administrador,
  CrearAdministradorRequest,
  EditarAdministradorRequest,
  BajaAdministradorRequest
} from '../models/admin-administrador.model';
import { AdminAdministradoresService } from '../services/admin-administradores.service';

type VistaAdministradores = 'listado' | 'nuevo' | 'detalle' | 'editar' | 'baja';

type FormularioAlta = Omit<CrearAdministradorRequest, 'sueldo'> & {
  sueldo: number | null;
  confirmarPassword: string;
};

@Component({
  selector: 'app-admin-administradores',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-administradores.html',
  styleUrl: './admin-administradores.css'
})
export class AdminAdministradores implements OnInit {
  vista: VistaAdministradores = 'listado';
  administradores: Administrador[] = [];
  seleccionado: Administrador | null = null;
  nuevo: FormularioAlta = this.crearAltaVacia();
  edicion: EditarAdministradorRequest = {
    nombreCompleto: '', correo: '', telefono: '', horario: ''
  };
  baja: BajaAdministradorRequest = {
    motivoBaja: '', fechaBaja: this.fechaHoy()
  };

  cargando = false;
  guardando = false;
  error = '';
  exito = '';

  constructor(
    private readonly servicio: AdminAdministradoresService,
    private readonly router: Router,
    private readonly cd: ChangeDetectorRef,
    private readonly destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarAdministradores();
  }

  private crearAltaVacia(): FormularioAlta {
    return {
      nombreCompleto: '',
      correo: '',
      telefono: '',
      fechaContratacion: '',
      sueldo: null,
      horario: '',
      password: '',
      confirmarPassword: ''
    };
  }

  private fechaHoy(): string {
    const ahora = new Date();
    const local = new Date(ahora.getTime() - ahora.getTimezoneOffset() * 60000);
    return local.toISOString().slice(0, 10);
  }

  get miIdUsuario(): number | null {
    try {
      const usuario = JSON.parse(localStorage.getItem('usuario') || 'null');
      const id = Number(usuario?.idUsuario);
      return Number.isInteger(id) && id > 0 ? id : null;
    } catch {
      return null;
    }
  }

  estaActivo(admin: Administrador): boolean {
    return admin.estatus?.trim().toLowerCase() === 'activo';
  }

  puedoDarDeBaja(admin: Administrador): boolean {
    // Si no se puede identificar al usuario actual, ocultamos la baja.
    return this.estaActivo(admin)
      && this.miIdUsuario !== null
      && admin.idUsuario !== this.miIdUsuario;
  }

  cambiarVista(vista: VistaAdministradores): void {
    if (this.guardando) return;
    this.nuevo.password = '';
    this.nuevo.confirmarPassword = '';
    this.error = '';
    this.exito = '';
    this.vista = vista;
    if (vista === 'nuevo') this.nuevo = this.crearAltaVacia();
    if (vista === 'listado') this.seleccionado = null;
  }

  cargarAdministradores(): void {
    this.error = '';
    this.cargando = true;
    this.servicio.listar()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta: Administrador[]) => {
          this.cargando = false;
          if (!Array.isArray(respuesta)) {
            this.error = 'El servidor devolvió un listado inválido.';
            this.administradores = [];
          } else {
            this.administradores = respuesta;
          }
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.cargando = false;
          this.error = this.obtenerError(err, 'consultar los administradores');
          this.cd.detectChanges();
        }
      });
  }

  abrirDetalle(admin: Administrador, accion: 'detalle' | 'editar' | 'baja'): void {
    if (this.cargando || this.guardando) return;
    if (accion !== 'detalle' && !this.estaActivo(admin)) return;
    if (accion === 'baja' && !this.puedoDarDeBaja(admin)) return;

    this.error = '';
    this.exito = '';
    this.cargando = true;
    // Este endpoint utiliza idUsuario, nunca idPersonal.
    this.servicio.obtenerPorId(admin.idUsuario)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (detalle: Administrador) => {
          this.cargando = false;
          if (accion !== 'detalle' && !this.estaActivo(detalle)) {
            this.error = 'No puedes modificar una cuenta inactiva.';
            this.vista = 'listado';
          } else if (accion === 'baja' && !this.puedoDarDeBaja(detalle)) {
            this.error = 'No puedes dar de baja tu propia cuenta.';
            this.vista = 'listado';
          } else {
            this.seleccionado = detalle;
            this.vista = accion;
            if (accion === 'editar') {
              this.edicion = {
                nombreCompleto: detalle.nombreCompleto,
                correo: detalle.correo,
                telefono: detalle.telefono,
                horario: detalle.horario
              };
            }
            if (accion === 'baja') {
              this.baja = { motivoBaja: '', fechaBaja: this.fechaHoy() };
            }
          }
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.cargando = false;
          this.error = this.obtenerError(err, 'consultar el administrador');
          this.cd.detectChanges();
        }
      });
  }

  private validarDatos(datos: EditarAdministradorRequest): string {
    const nombre = datos.nombreCompleto.trim();
    const correo = datos.correo.trim();
    const telefono = datos.telefono.trim();
    const digitos = telefono.replace(/\D/g, '');

    if (nombre.length < 3 || nombre.length > 150)
      return 'El nombre debe tener entre 3 y 150 caracteres.';
    if (correo.length > 150 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo))
      return 'Ingresa un correo electrónico válido.';
    if (!/^[+0-9\s()-]+$/.test(telefono) || digitos.length < 10 || digitos.length > 15)
      return 'El teléfono debe tener entre 10 y 15 dígitos.';
    if (!datos.horario.trim())
      return 'Indica el horario de trabajo.';
    return '';
  }

  guardarNuevo(): void {
    if (this.guardando) return;
    const n = this.nuevo;
    this.error = this.validarDatos(n);
    if (!this.error && !/^\d{4}-\d{2}-\d{2}$/.test(n.fechaContratacion))
      this.error = 'Selecciona una fecha de contratación válida.';
    if (!this.error && (n.sueldo === null || !Number.isFinite(Number(n.sueldo)) || Number(n.sueldo) <= 0))
      this.error = 'Ingresa un sueldo mayor que cero.';
    if (!this.error && (n.password.length < 8 || n.password.length > 128))
      this.error = 'La contraseña debe tener entre 8 y 128 caracteres.';
    if (!this.error && n.password !== n.confirmarPassword)
      this.error = 'Las contraseñas no coinciden.';
    if (this.error) return;

    const datos: CrearAdministradorRequest = {
      nombreCompleto: n.nombreCompleto.trim(),
      correo: n.correo.trim().toLowerCase(),
      telefono: n.telefono.trim(),
      fechaContratacion: n.fechaContratacion,
      sueldo: Number(n.sueldo),
      horario: n.horario.trim(),
      password: n.password
    };

    this.guardando = true;
    this.servicio.crear(datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta) => {
          this.guardando = false;
          datos.password = '';
          this.nuevo = this.crearAltaVacia();
          this.vista = 'listado';
          this.exito = respuesta.mensaje || 'Administrador registrado correctamente.';
          this.cargarAdministradores();
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.guardando = false;
          datos.password = '';
          this.nuevo.password = '';
          this.nuevo.confirmarPassword = '';
          this.error = this.obtenerError(err, 'registrar el administrador');
          this.cd.detectChanges();
        }
      });
  }

  guardarEdicion(): void {
    const admin = this.seleccionado;
    if (!admin || this.guardando || !this.estaActivo(admin)) return;

    const datos: EditarAdministradorRequest = {
      nombreCompleto: this.edicion.nombreCompleto.trim(),
      correo: this.edicion.correo.trim().toLowerCase(),
      telefono: this.edicion.telefono.trim(),
      horario: this.edicion.horario.trim()
    };
    this.error = this.validarDatos(datos);
    if (this.error) return;

    this.guardando = true;
    this.servicio.editar(admin.idUsuario, datos)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta) => {
          this.guardando = false;
          this.seleccionado = null;
          this.vista = 'listado';
          this.exito = respuesta.mensaje || 'Administrador actualizado correctamente.';
          this.cargarAdministradores();
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.guardando = false;
          this.error = this.obtenerError(err, 'editar el administrador');
          this.cd.detectChanges();
        }
      });
  }

  confirmarBaja(): void {
    const admin = this.seleccionado;
    if (!admin || !this.puedoDarDeBaja(admin) || this.guardando) return;

    const motivoBaja = this.baja.motivoBaja.trim();
    this.error = '';
    if (motivoBaja.length < 5) this.error = 'Indica un motivo de al menos 5 caracteres.';
    if (!this.error && !/^\d{4}-\d{2}-\d{2}$/.test(this.baja.fechaBaja))
      this.error = 'Selecciona una fecha de baja válida.';
    if (this.error) return;

    this.guardando = true;
    this.servicio.darDeBaja(admin.idUsuario, {
      motivoBaja,
      fechaBaja: this.baja.fechaBaja
    })
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta) => {
          this.guardando = false;
          this.seleccionado = null;
          this.vista = 'listado';
          this.exito = respuesta.mensaje || 'Administrador dado de baja correctamente.';
          this.cargarAdministradores();
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.guardando = false;
          this.error = this.obtenerError(err, 'dar de baja el administrador');
          this.cd.detectChanges();
        }
      });
  }

  private obtenerError(err: HttpErrorResponse, accion: string): string {
    const respuesta = err.error;
    const texto = typeof respuesta === 'string' ? respuesta : [
      respuesta?.mensaje, respuesta?.detail, respuesta?.title
    ].find((valor: unknown): valor is string =>
      typeof valor === 'string' && valor.trim().length > 0);

    switch (err.status) {
      case 400: return texto || 'Datos inválidos o correo ya registrado.';
      case 401: return 'Tu sesión expiró. Inicia sesión nuevamente.';
      case 403: return 'No tienes permiso para esta operación.';
      case 404: return 'No se encontró el administrador solicitado.';
      case 409: return texto || 'Conflicto con las reglas de protección de administradores.';
      case 0: return 'No se pudo conectar con el servidor.';
      default: return err.status >= 500
        ? 'El servidor no está disponible. Intenta nuevamente.'
        : texto || `No fue posible ${accion}.`;
    }
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
