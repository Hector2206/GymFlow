
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import {
  HttpErrorResponse
} from '@angular/common/http';

import {
  Router
} from '@angular/router';

import {
  takeUntilDestroyed
} from '@angular/core/rxjs-interop';

import {
  Subscription
} from 'rxjs';

import {
  AdminClienteService
} from '../services/admin-cliente.service';

import {
  ClienteAdmin
} from '../models/admin-cliente.model';

@Component({
  selector: 'app-admin-clientes',
  standalone: true,
  imports: [],
  templateUrl: './admin-clientes.html',
  styleUrl: './admin-clientes.css'
})
export class AdminClientes implements OnInit {

  clientes: ClienteAdmin[] = [];

  cargando = false;
  error = '';
  consultaRealizada = false;

  private consultaClientes?: Subscription;

  constructor(
    private router: Router,
    private adminClienteService: AdminClienteService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarClientes();
  }

  // OBTENER CLIENTES REALES

  cargarClientes(): void {

    // Evitar respuestas anteriores fuera de orden
    this.consultaClientes?.unsubscribe();

    this.cargando = true;
    this.error = '';
    this.consultaRealizada = false;
    this.clientes = [];

    this.consultaClientes =
      this.adminClienteService
        .obtenerTodos()
        .pipe(
          takeUntilDestroyed(this.destroyRef)
        )
        .subscribe({

          next: (respuesta) => {

            if (!Array.isArray(respuesta)) {
              this.error =
                'El servidor devolvió una respuesta inesperada.';

              this.cargando = false;
              this.consultaRealizada = true;

              this.changeDetector.detectChanges();
              return;
            }

            this.clientes = respuesta;

            this.cargando = false;
            this.consultaRealizada = true;

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

  // FECHA SIN CAMBIOS DE ZONA HORARIA

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
