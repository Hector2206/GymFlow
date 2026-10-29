import { ChangeDetectorRef, Component, DestroyRef, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  ClienteConsultaService,
  ClienteResumen
} from '../services/cliente-consulta.service';
import {
  MembresiaService,
  MembresiaActiva
} from '../services/membresia.service';
import { CambioMembresiaService } from '../services/cambio-membresia.service';

// Estos campos opcionales permiten mostrar el plan si el Backend
// los incluye en el futuro. Actualmente GET /api/clientes no los devuelve.
interface ClienteRecepcion extends ClienteResumen {
  idMembresia?: number | null;
  nombrePlan?: string | null;
}

interface MembresiaConfirmada {
  idMembresia: number;
  nombrePlan: string;
}

@Component({
  selector: 'app-recepcion-clientes',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './recepcion-clientes.html',
  styleUrl: './recepcion-clientes.css'
})
export class RecepcionClientes implements OnInit {
  clientes: ClienteRecepcion[] = [];
  busqueda = '';
  cargando = false;
  error = '';
  mensajeExito = '';

  clienteCambio: ClienteRecepcion | null = null;
  membresiasActivas: MembresiaActiva[] = [];
  idNuevaMembresia: number | null = null;
  cargandoMembresias = false;
  guardandoMembresia = false;
  errorMembresia = '';

  // No se guardan planes simulados: solo cambios confirmados por HTTP 200.
  // El Backend actual no devuelve el plan en GET /api/clientes.
  cambiosConfirmados = new Map<number, MembresiaConfirmada>();
  private solicitudCatalogo = 0;

  constructor(
    private readonly clientesService: ClienteConsultaService,
    private readonly membresiaService: MembresiaService,
    private readonly cambioService: CambioMembresiaService,
    private readonly router: Router,
    private readonly cd: ChangeDetectorRef,
    private readonly destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarClientes();
  }

  cargarClientes(): void {
    if (this.cargando) return;
    this.cargando = true;
    this.error = '';

    this.clientesService.obtenerClientes()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (respuesta: ClienteResumen[]) => {
          this.clientes = Array.isArray(respuesta) ? respuesta : [];
          this.cargando = false;
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.cargando = false;
          this.error = this.mensajeError(err, 'consultar clientes');
          this.cd.detectChanges();
        }
      });
  }

  get clientesFiltrados(): ClienteRecepcion[] {
    const texto = this.busqueda.trim().toLowerCase();
    if (!texto) return this.clientes;

    return this.clientes.filter(cliente =>
      cliente.nombreCompleto.toLowerCase().includes(texto) ||
      String(cliente.idCliente).includes(texto) ||
      (cliente.nombreEntrenador ?? '').toLowerCase().includes(texto) ||
      this.nombrePlanVisible(cliente).toLowerCase().includes(texto)
    );
  }

  get cantidadConEntrenador(): number {
    return this.clientes.filter(c => c.idEntrenador != null).length;
  }

  private membresiaConocida(cliente: ClienteRecepcion): number | null {
    return cliente.idMembresia ??
      this.cambiosConfirmados.get(cliente.idCliente)?.idMembresia ?? null;
  }

  nombrePlanVisible(cliente: ClienteRecepcion): string {
    if (cliente.nombrePlan?.trim()) return cliente.nombrePlan;
    if (cliente.idMembresia != null) return `Plan #${cliente.idMembresia}`;
    return this.cambiosConfirmados.get(cliente.idCliente)?.nombrePlan ??
      'No disponible en Recepción';
  }

  origenPlan(cliente: ClienteRecepcion): string {
    if (cliente.nombrePlan || cliente.idMembresia != null) {
      return 'Membresía actual';
    }
    if (this.cambiosConfirmados.has(cliente.idCliente)) {
      return 'Cambio confirmado en esta sesión';
    }
    return 'El listado de Recepción no incluye este dato';
  }

  abrirCambioMembresia(cliente: ClienteRecepcion): void {
    if (this.guardandoMembresia) return;
    this.clienteCambio = cliente;
    this.idNuevaMembresia = this.membresiaConocida(cliente);
    this.membresiasActivas = [];
    this.errorMembresia = '';
    this.mensajeExito = '';
    this.cargandoMembresias = true;
    const solicitud = ++this.solicitudCatalogo;

    this.membresiaService.obtenerActivas()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (planes: MembresiaActiva[]) => {
          if (solicitud !== this.solicitudCatalogo) return;
          this.membresiasActivas = Array.isArray(planes)
            ? planes.filter(plan => plan.activo === true)
            : [];
          this.cargandoMembresias = false;
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          if (solicitud !== this.solicitudCatalogo) return;
          this.cargandoMembresias = false;
          this.errorMembresia = this.mensajeError(err, 'consultar membresías activas');
          this.cd.detectChanges();
        }
      });
  }

  cerrarCambioMembresia(): void {
    if (this.guardandoMembresia) return;
    this.solicitudCatalogo++;
    this.clienteCambio = null;
    this.idNuevaMembresia = null;
    this.errorMembresia = '';
    this.cargandoMembresias = false;
  }

  confirmarCambioMembresia(): void {
    const cliente = this.clienteCambio;
    const idNueva = this.idNuevaMembresia;
    if (!cliente || this.guardandoMembresia || this.cargandoMembresias) return;
    this.errorMembresia = '';

    if (idNueva === null || !Number.isInteger(idNueva) || idNueva <= 0) {
      this.errorMembresia = 'Selecciona una membresía válida.';
      return;
    }
    if (idNueva === this.membresiaConocida(cliente)) {
      this.errorMembresia = 'El cliente ya tiene esa membresía.';
      return;
    }
    const plan = this.membresiasActivas.find(p => p.idMembresia === idNueva);
    if (!plan) {
      this.errorMembresia = 'La membresía elegida no está activa.';
      return;
    }

    this.guardandoMembresia = true;
    this.cambioService.cambiar(cliente.idCliente, idNueva)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: respuesta => {
          this.guardandoMembresia = false;
          this.cambiosConfirmados.set(cliente.idCliente, {
            idMembresia: respuesta.idMembresiaNueva,
            nombrePlan: plan.nombrePlan
          });
          this.mensajeExito = respuesta.mensaje ||
            'Membresía actualizada correctamente.';
          this.cerrarCambioMembresia();
          this.cargarClientes();
          this.cd.detectChanges();
        },
        error: (err: HttpErrorResponse) => {
          this.guardandoMembresia = false;
          this.errorMembresia = this.mensajeError(err, 'cambiar la membresía');
          this.cd.detectChanges();
        }
      });
  }

  private mensajeError(err: HttpErrorResponse, accion: string): string {
    const datos = err.error;
    const mensaje = typeof datos === 'string' ? datos :
      [datos?.mensaje, datos?.detail, datos?.title]
        .find((valor: unknown): valor is string =>
          typeof valor === 'string' && valor.trim().length > 0);

    switch (err.status) {
      case 400: return mensaje || 'La membresía es inválida o está inactiva.';
      case 401: return 'La sesión expiró. Inicia sesión nuevamente.';
      case 403: return 'Acceso denegado. Verifica el rol Recepcionista y que la cuenta esté activa.';
      case 404: return mensaje || 'Cliente o membresía no encontrada. Verifica también el despliegue.';
      case 409: return mensaje || 'El cliente ya tiene la membresía seleccionada.';
      case 0: return 'No se pudo conectar con el servidor.';
      default: return err.status >= 500
        ? 'El servidor no pudo completar la operación.'
        : mensaje || `No fue posible ${accion}.`;
    }
  }

  irAsignacion(): void {
    this.router.navigate(['/asignacion-entrenadores']);
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
