
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Subject, Subscription, debounceTime } from 'rxjs';

import { AdminClienteService } from '../services/admin-cliente.service';
import { MembresiaService, MembresiaActiva } from '../services/membresia.service';
import { CambioMembresiaService } from '../services/cambio-membresia.service';
import {
  ClienteAdmin,
  EstatusClienteAdmin,
  VigenciaClienteAdmin
} from '../models/admin-cliente.model';

@Component({
  selector: 'app-admin-clientes',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-clientes.html',
  styleUrl: './admin-clientes.css'
})
export class AdminClientes implements OnInit {
  clientes: ClienteAdmin[] = [];
  cargando = false;
  error = '';
  consultaRealizada = false;

  nombreBusqueda = '';
  correoBusqueda = '';
  estatusBusqueda: EstatusClienteAdmin | '' = '';
  vigenciaBusqueda: VigenciaClienteAdmin | '' = '';
  idMembresiaBusqueda: number | null = null;

  clienteCambio: ClienteAdmin | null = null;
  membresiasActivas: MembresiaActiva[] = [];
  idNuevaMembresia: number | null = null;
  cargandoMembresias = false;
  guardandoMembresia = false;
  errorMembresia = '';
  exitoMembresia = '';

  private cambiosBusqueda = new Subject<void>();
  private consultaClientes?: Subscription;

  constructor(
    private readonly router: Router,
    private readonly adminClienteService: AdminClienteService,
    private readonly membresiaService: MembresiaService,
    private readonly cambioMembresiaService: CambioMembresiaService,
    private readonly changeDetector: ChangeDetectorRef,
    private readonly destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cambiosBusqueda.pipe(
      debounceTime(350),
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(() => this.cargarClientes());
    this.cargarClientes();
  }

  get hayFiltrosActivos(): boolean {
    return this.nombreBusqueda.trim().length > 0
      || this.correoBusqueda.trim().length > 0
      || this.estatusBusqueda !== ''
      || this.vigenciaBusqueda !== ''
      || this.idMembresiaBusqueda !== null;
  }

  limpiarFiltros(): void {
    this.nombreBusqueda = '';
    this.correoBusqueda = '';
    this.estatusBusqueda = '';
    this.vigenciaBusqueda = '';
    this.idMembresiaBusqueda = null;
    this.alCambiarBusqueda();
  }

  alCambiarBusqueda(): void {
    this.consultaClientes?.unsubscribe();
    this.clientes = [];
    this.error = '';
    this.cargando = true;
    this.consultaRealizada = false;
    this.cambiosBusqueda.next();
  }

  cargarClientes(): void {
    this.consultaClientes?.unsubscribe();

    const nombre = this.nombreBusqueda.trim();
    const correo = this.correoBusqueda.trim();
    const estatus = this.estatusBusqueda || undefined;
    const vigencia = this.vigenciaBusqueda || undefined;
    const idMembresia = this.idMembresiaBusqueda;

    this.error = '';
    this.clientes = [];
    this.consultaRealizada = false;

    if (nombre.length > 150 || correo.length > 150) {
      this.cargando = false;
      this.error = 'El nombre y el correo no pueden superar 150 caracteres.';
      this.changeDetector.detectChanges();
      return;
    }

    if (idMembresia !== null &&
      (!Number.isInteger(idMembresia) || idMembresia <= 0)) {
      this.cargando = false;
      this.error = 'El ID de membresía debe ser un entero mayor que cero.';
      this.changeDetector.detectChanges();
      return;
    }

    this.cargando = true;
    this.consultaClientes = this.adminClienteService.buscarClientes({
      nombre: nombre || undefined,
      correo: correo || undefined,
      estatus,
      vigencia,
      idMembresia: idMembresia === null ? undefined : idMembresia
    })
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta: ClienteAdmin[]) => {
          this.cargando = false;
          this.consultaRealizada = true;
          if (!Array.isArray(respuesta)) {
            this.error = 'El servidor devolvió una respuesta inesperada.';
            this.clientes = [];
          } else {
            this.clientes = respuesta;
          }
          this.changeDetector.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.cargando = false;
          this.consultaRealizada = true;
          this.error = this.mensajeError(err, 'consultar los clientes');
          this.changeDetector.detectChanges();
        }
      });
  }

  abrirCambioMembresia(cliente: ClienteAdmin): void {
    if (this.guardandoMembresia) return;
    this.clienteCambio = cliente;
    this.idNuevaMembresia = cliente.idMembresia;
    this.membresiasActivas = [];
    this.errorMembresia = '';
    this.exitoMembresia = '';
    this.cargandoMembresias = true;

    this.membresiaService.obtenerActivas()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (planes: MembresiaActiva[]) => {
          this.cargandoMembresias = false;
          this.membresiasActivas = Array.isArray(planes)
            ? planes.filter(plan => plan.activo)
            : [];
          this.changeDetector.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.cargandoMembresias = false;
          this.errorMembresia = this.mensajeError(err, 'consultar las membresías activas');
          this.changeDetector.detectChanges();
        }
      });
  }

  cerrarCambioMembresia(): void {
    if (this.guardandoMembresia) return;
    this.clienteCambio = null;
    this.idNuevaMembresia = null;
    this.errorMembresia = '';
  }

  confirmarCambioMembresia(): void {
    const cliente = this.clienteCambio;
    if (!cliente || this.guardandoMembresia || this.cargandoMembresias) return;
    const idMembresia = Number(this.idNuevaMembresia);
    this.errorMembresia = '';

    if (!Number.isInteger(idMembresia) || idMembresia <= 0) {
      this.errorMembresia = 'Selecciona una membresía válida.';
      return;
    }
    if (idMembresia === cliente.idMembresia) {
      this.errorMembresia = 'Este cliente ya tiene la membresía seleccionada.';
      return;
    }
    if (!this.membresiasActivas.some(plan => plan.idMembresia === idMembresia)) {
      this.errorMembresia = 'La membresía seleccionada no está activa.';
      return;
    }

    this.guardandoMembresia = true;
    this.cambioMembresiaService.cambiar(cliente.idCliente, idMembresia)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta) => {
          this.guardandoMembresia = false;
          this.clienteCambio = null;
          this.idNuevaMembresia = null;
          this.exitoMembresia = respuesta.mensaje ||
            'Membresía del cliente actualizada correctamente.';
          this.cargarClientes();
          this.changeDetector.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.guardandoMembresia = false;
          this.errorMembresia = this.mensajeError(err, 'cambiar la membresía');
          this.changeDetector.detectChanges();
        }
      });
  }

  private mensajeError(err: HttpErrorResponse, accion: string): string {
    const respuesta = err.error;
    const mensajeServidor = typeof respuesta === 'string' ? respuesta : [
      respuesta?.mensaje,
      respuesta?.detail,
      respuesta?.title
    ].find((valor: unknown): valor is string =>
      typeof valor === 'string' && valor.trim().length > 0);

    switch (err.status) {
      case 400: return mensajeServidor || 'Datos inválidos, membresía inactiva o ya asignada.';
      case 401: return 'Tu sesión venció. Inicia sesión nuevamente.';
      case 403: return 'No tienes permiso para esta operación.';
      case 404: return 'El cliente o la membresía solicitada no existe.';
      case 409: return mensajeServidor || 'No se puede realizar el cambio por el estado actual.';
      case 0: return 'No fue posible conectar con el servidor.';
      default: return err.status >= 500
        ? 'Error del servidor. Intenta nuevamente.'
        : mensajeServidor || `No fue posible ${accion}.`;
    }
  }

  mostrarFecha(fecha: string | null): string {
    if (!fecha) return 'Sin fecha';
    const partes = fecha.split('-');
    if (partes.length !== 3) return fecha;
    return `${partes[2]}/${partes[1]}/${partes[0]}`;
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
