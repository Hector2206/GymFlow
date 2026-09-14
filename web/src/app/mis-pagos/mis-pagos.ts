import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import {
  CommonModule
} from '@angular/common';

import {
  Router
} from '@angular/router';

import {
  PagoCliente,
  PagoService,
  MisPagosResponse
} from '../services/pago.service';

@Component({
  selector: 'app-mis-pagos',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './mis-pagos.html',
  styleUrl: './mis-pagos.css'
})
export class MisPagos implements OnInit {

  pagos: PagoCliente[] = [];

  cargando = true;

  error = '';

  constructor(
    private router: Router,
    private pagoService: PagoService,
    private changeDetector: ChangeDetectorRef
  ) {}

  ngOnInit(): void {

    this.cargarPagos();
  }

  cargarPagos(): void {

    this.cargando = true;
    this.error = '';

    this.pagoService
      .consultarMisPagos()
      .subscribe({

        next: (
          respuesta: MisPagosResponse
        ) => {

          this.pagos =
            respuesta.pagos ?? [];

          this.cargando = false;

          this.changeDetector
            .detectChanges();
        },

        error: (error) => {

          console.error(
            'Error al consultar mis pagos:',
            error
          );

          this.cargando = false;

          if (
            error.status === 401
          ) {

            this.error =
              'Tu sesión no es válida. Inicia sesión nuevamente.';

          } else if (
            error.status === 403
          ) {

            this.error =
              'No tienes permiso para consultar tus pagos.';

          } else if (
            error.status === 0
          ) {

            this.error =
              'No fue posible conectar con el servidor.';

          } else {

            this.error =
              'No fue posible cargar tus pagos.';
          }

          this.changeDetector
            .detectChanges();
        }
      });
  }

  formatearFecha(
    fechaHora: string
  ): string {

    return new Date(
      fechaHora
    ).toLocaleDateString(
      'es-MX',
      {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }
    );
  }

  formatearHora(
    fechaHora: string
  ): string {

    return new Date(
      fechaHora
    ).toLocaleTimeString(
      'es-MX',
      {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }
    );
  }

  formatearMonto(
    monto: number
  ): string {

    return Number(
      monto
    ).toLocaleString(
      'es-MX',
      {
        style: 'currency',
        currency: 'MXN'
      }
    );
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}