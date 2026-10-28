
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  AdminDashboardService
} from '../services/admin-dashboard.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './admin-dashboard.html',
  styleUrl: './admin-dashboard.css'
})
export class AdminDashboard implements OnInit {

  totalClientes: number | null = null;

  cargandoClientes = false;
  errorClientes = '';

  constructor(
    private router: Router,
    private dashboardService: AdminDashboardService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {
    this.cargarTotalClientes();
  }

  cargarTotalClientes(): void {

    this.cargandoClientes = true;
    this.errorClientes = '';
    this.totalClientes = null;

    this.dashboardService
      .obtenerTotalClientes()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta) => {

          this.totalClientes = respuesta.totalClientes;
          this.cargandoClientes = false;

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargandoClientes = false;

          if (error.status === 401) {
            this.errorClientes =
              'Tu sesión venció. Inicia sesión nuevamente.';
          } else if (error.status === 403) {
            this.errorClientes =
              'No tienes permisos para consultar esta información.';
          } else if (error.status === 0 || error.status >= 500) {
            this.errorClientes =
              'No fue posible conectar con el servidor. Intenta nuevamente.';
          } else {
            this.errorClientes =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudo consultar el total de clientes.';
          }

          this.changeDetector.detectChanges();
        }

      });
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
