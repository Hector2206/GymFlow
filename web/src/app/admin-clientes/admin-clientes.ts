
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import {
  takeUntilDestroyed
} from '@angular/core/rxjs-interop';

import {
  Subject,
  Subscription,
  debounceTime
} from 'rxjs';

import {
  AdminClienteService
} from '../services/admin-cliente.service';

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

  // BUSQUEDA POR TEXTO

  nombreBusqueda = '';
  correoBusqueda = '';

  // FILTROS ADMINISTRATIVOS

  estatusBusqueda: EstatusClienteAdmin | '' = '';
  vigenciaBusqueda: VigenciaClienteAdmin | '' = '';
  idMembresiaBusqueda: number | null = null;

  private cambiosBusqueda = new Subject<void>();
  private consultaClientes?: Subscription;

  constructor(
    private router: Router,
    private adminClienteService: AdminClienteService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {

    this.cambiosBusqueda
      .pipe(
        debounceTime(350),
        takeUntilDestroyed(this.destroyRef)
      )
      .subscribe(() => {
        this.cargarClientes();
      });

    // Mostrar todos al entrar
    this.cargarClientes();
  }

  // DETECTAR CAMBIO DE CUALQUIER FILTRO

  alCambiarBusqueda(): void {

    // Cancelar consultas anteriores
    this.consultaClientes?.unsubscribe();

    this.clientes = [];
    this.error = '';
    this.cargando = true;
    this.consultaRealizada = false;

    // Solicitar nueva busqueda
    this.cambiosBusqueda.next();
  }

  // CONSULTAR CLIENTES AL BACKEND

  cargarClientes(): void {

    this.consultaClientes?.unsubscribe();

    const nombre = this.nombreBusqueda.trim();
    const correo = this.correoBusqueda.trim();

    const estatus =
      this.estatusBusqueda || undefined;

    const vigencia =
      this.vigenciaBusqueda || undefined;

    const idMembresia =
      this.idMembresiaBusqueda;

    this.error = '';
    this.clientes = [];
    this.consultaRealizada = false;

    // VALIDACION DE TEXTO

    if (
      nombre.length > 150 ||
      correo.length > 150
    ) {

      this.cargando = false;
      this.error =
        'El nombre y el correo no pueden superar 150 caracteres.';

      this.changeDetector.detectChanges();
      return;
    }

    // VALIDACION DE MEMBRESIA

    if (
      idMembresia !== null &&
      (
        !Number.isInteger(idMembresia) ||
        idMembresia <= 0
      )
    ) {

      this.cargando = false;
      this.error =
        'El ID de membresía debe ser un número entero mayor que cero.';

      this.changeDetector.detectChanges();
      return;
    }

    this.cargando = true;

    this.consultaClientes =
      this.adminClienteService
        .buscarClientes({

          nombre: nombre || undefined,

          correo: correo || undefined,

          estatus,

          vigencia,

          idMembresia:
            idMembresia === null
              ? undefined
              : idMembresia

        })
        .pipe(
          takeUntilDestroyed(this.destroyRef)
        )
        .subscribe({

          next: (respuesta) => {

            this.cargando = false;
            this.consultaRealizada = true;

            if (!Array.isArray(respuesta)) {

              this.error =
                'El servidor devolvió una respuesta inesperada.';

              this.changeDetector.detectChanges();
              return;
            }

            this.clientes = respuesta;

            this.changeDetector.detectChanges();
          },

          error: (error: HttpErrorResponse) => {

            this.cargando = false;
            this.consultaRealizada = true;

            if (error.status === 401) {

              this.error =
                'Tu sesión venció. Inicia sesión nuevamente.';

            } else if (error.status === 403) {

              this.error =
                'No tienes permisos para consultar clientes.';

            } else if (
              error.status === 0 ||
              error.status >= 500
            ) {

              this.error =
                'No fue posible conectar con el servidor. Intenta nuevamente.';

            } else {

              const mensajeServidor =
                typeof error.error?.mensaje === 'string'
                  ? error.error.mensaje
                  : typeof error.error?.detail === 'string'
                    ? error.error.detail
                    : typeof error.error?.title === 'string'
                      ? error.error.title
                      : '';

              this.error =
                mensajeServidor ||
                'No se pudieron consultar los clientes.';
            }

            this.changeDetector.detectChanges();
          }
        });
  }

  // FORMATO DE FECHA

  mostrarFecha(
    fecha: string | null
  ): string {

    if (!fecha) {
      return 'Sin fecha';
    }

    const partes = fecha.split('-');

    if (partes.length !== 3) {
      return fecha;
    }

    return `${partes[2]}/${partes[1]}/${partes[0]}`;
  }

  // NAVEGACION

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
