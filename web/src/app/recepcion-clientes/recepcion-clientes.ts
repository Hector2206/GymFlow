
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';

import {
  ClienteConsultaService,
  ClienteResumen
} from '../services/cliente-consulta.service';

@Component({
  selector: 'app-recepcion-clientes',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './recepcion-clientes.html',
  styleUrl: './recepcion-clientes.css'
})
export class RecepcionClientes implements OnInit {
  clientes: ClienteResumen[] = [];
  busqueda = '';

  cargando = true;
  error = '';

  constructor(
    private clientesService: ClienteConsultaService,
    private router: Router,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarClientes();
  }

  cargarClientes(): void {
    if (this.cargando && this.clientes.length > 0) {
      return;
    }

    this.cargando = true;
    this.error = '';

    this.clientesService.obtenerClientes().subscribe({
      next: (respuesta) => {
        this.clientes = respuesta ?? [];
        this.cargando = false;
        this.cd.detectChanges();
      },

      error: (err: HttpErrorResponse) => {
        this.cargando = false;

        switch (err.status) {
          case 401:
            this.error = 'Tu sesión expiró.';
            break;
          case 403:
            this.error =
              'No tienes permiso para consultar clientes.';
            break;
          case 0:
            this.error =
              'No se pudo conectar con el servidor.';
            break;
          default:
            this.error =
              'No fue posible cargar el directorio de clientes.';
        }

        this.cd.detectChanges();
      }
    });
  }

  get clientesFiltrados(): ClienteResumen[] {
    const texto = this.busqueda.trim().toLowerCase();

    if (!texto) {
      return this.clientes;
    }

    return this.clientes.filter(cliente => {
      const nombre = cliente.nombreCompleto.toLowerCase();
      const id = cliente.idCliente.toString();
      const entrenador =
        (cliente.nombreEntrenador ?? '').toLowerCase();

      return (
        nombre.includes(texto) ||
        id.includes(texto) ||
        entrenador.includes(texto)
      );
    });
  }

  get cantidadConEntrenador(): number {
    return this.clientes.filter(
      cliente => cliente.idEntrenador != null
    ).length;
  }

  irAsignacion(): void {
    this.router.navigate(['/asignacion-entrenadores']);
  }

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
