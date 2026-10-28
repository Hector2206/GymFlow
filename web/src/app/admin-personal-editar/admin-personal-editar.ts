
import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  OnInit
} from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';

import {
  ActivatedRoute,
  Router
} from '@angular/router';

import {
  takeUntilDestroyed
} from '@angular/core/rxjs-interop';

import {
  AdminPersonalService
} from '../services/admin-personal.service';

import {
  PersonalAdmin,
  EditarPersonalAdminRequest
} from '../models/admin-personal.model';

@Component({
  selector: 'app-admin-personal-editar',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-personal-editar.html',
  styleUrl: './admin-personal-editar.css'
})
export class AdminPersonalEditar implements OnInit {

  idPersonal = 0;

  empleado: PersonalAdmin | null = null;

  cargando = false;
  errorCarga = '';

  formulario: EditarPersonalAdminRequest = {
    nombreCompleto: '',
    correo: '',
    telefono: '',
    horario: ''
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private personalService: AdminPersonalService,
    private changeDetector: ChangeDetectorRef,
    private destroyRef: DestroyRef
  ) {}

  ngOnInit(): void {

    const id = Number(
      this.route.snapshot.paramMap.get('id')
    );

    if (
      !Number.isInteger(id) ||
      id <= 0
    ) {

      this.errorCarga =
        'El identificador del empleado no es válido.';

      return;
    }

    this.idPersonal = id;

    this.cargarEmpleado();
  }

  // CONSULTAR EL EXPEDIENTE REAL

  cargarEmpleado(): void {

    if (this.cargando || this.idPersonal <= 0) {
      return;
    }

    this.cargando = true;
    this.errorCarga = '';
    this.empleado = null;

    this.personalService
      .obtenerPersonalPorId(this.idPersonal)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({

        next: (respuesta: PersonalAdmin) => {

          this.cargando = false;

          if (
            !respuesta ||
            respuesta.idPersonal !== this.idPersonal
          ) {

            this.errorCarga =
              'El servidor devolvió un expediente inesperado.';

            this.changeDetector.detectChanges();
            return;
          }

          this.empleado = respuesta;

          this.formulario = {
            nombreCompleto: respuesta.nombreCompleto,
            correo: respuesta.correo,
            telefono: respuesta.telefono,
            horario: respuesta.horario || ''
          };

          this.changeDetector.detectChanges();
        },

        error: (error: HttpErrorResponse) => {

          this.cargando = false;

          if (error.status === 401) {

            this.errorCarga =
              'Tu sesión venció. Inicia sesión nuevamente.';

          } else if (error.status === 403) {

            this.errorCarga =
              'No tienes permisos para consultar empleados.';

          } else if (error.status === 404) {

            this.errorCarga =
              'No se encontró el empleado solicitado.';

          } else if (
            error.status === 0 ||
            error.status >= 500
          ) {

            this.errorCarga =
              'No fue posible conectar con el servidor. Intenta nuevamente.';

          } else {

            this.errorCarga =
              error.error?.mensaje ||
              error.error?.detail ||
              'No se pudo consultar el expediente.';
          }

          this.changeDetector.detectChanges();
        }
      });
  }

  // REGRESAR AL DIRECTORIO

  volverDirectorio(): void {

    this.router.navigate([
      '/admin/personal'
    ]);
  }
}
