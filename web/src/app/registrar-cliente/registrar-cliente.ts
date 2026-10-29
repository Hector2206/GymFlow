
import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  HttpClient,
  HttpErrorResponse
} from '@angular/common/http';
import { Router } from '@angular/router';

import { environment } from '../../environments/environment';
import {
  MembresiaService,
  MembresiaActiva
} from '../services/membresia.service';

@Component({
  selector: 'app-registrar-cliente',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './registrar-cliente.html',
  styleUrl: './registrar-cliente.css'
})
export class RegistrarCliente implements OnInit {
  nombreCompleto = '';
  correo = '';
  password = '';
  telefono = '';

  idMembresia: number | null = null;
  membresias: MembresiaActiva[] = [];

  cargandoMembresias = true;
  cargando = false;
  registroIncierto = false;

  errorMembresias = '';
  error = '';
  exito = '';

  constructor(
    private http: HttpClient,
    private router: Router,
    private membresiaService: MembresiaService,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarMembresias();
  }

  get membresiaSeleccionada(): MembresiaActiva | null {
    return this.membresias.find(
      m => m.idMembresia === this.idMembresia
    ) ?? null;
  }

  cargarMembresias(): void {
    this.cargandoMembresias = true;
    this.errorMembresias = '';
    this.membresias = [];
    this.idMembresia = null;

    this.membresiaService.obtenerActivas().subscribe({
      next: (planes) => {
        this.membresias = (planes ?? []).filter(
          m =>
            m.activo === true &&
            m.idMembresia > 0 &&
            m.costoMensual > 0 &&
            m.costoAnualidad > 0
        );
        this.cargandoMembresias = false;
        this.cd.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        this.cargandoMembresias = false;
        this.errorMembresias =
          err.status === 403
            ? 'No tienes permiso para consultar membresías.'
            : err.status === 401
              ? 'Tu sesión expiró. Vuelve a iniciar sesión.'
              : err.status === 404
                ? 'El endpoint de membresías no está disponible.'
                : 'No fue posible cargar las membresías.';
        this.cd.detectChanges();
      }
    });
  }

  volver(): void {
    this.router.navigate(['/home']);
  }

  registrarCliente(): void {
    if (
      this.cargando ||
      this.cargandoMembresias ||
      this.registroIncierto
    ) {
      return;
    }

    this.error = '';
    this.exito = '';

    const nombre = this.nombreCompleto.trim();
    const email = this.correo.trim().toLowerCase();
    const telefono = this.telefono.trim();
    const plan = this.membresiaSeleccionada;

    if (
      nombre.length < 3 ||
      nombre.length > 100 ||
      /\d/.test(nombre)
    ) {
      this.error = 'Ingresa un nombre completo válido.';
      return;
    }

    if (
      email.length > 150 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    ) {
      this.error = 'Ingresa un correo electrónico válido.';
      return;
    }

    if (
      this.password.trim().length < 6 ||
      this.password.length > 72
    ) {
      this.error =
        'La contraseña debe tener entre 6 y 72 caracteres.';
      return;
    }

    if (telefono && !/^\d{10}$/.test(telefono)) {
      this.error = 'El teléfono debe tener 10 dígitos.';
      return;
    }

    if (!plan) {
      this.error = 'Selecciona una membresía activa.';
      return;
    }

    this.cargando = true;

    // No enviamos precios: Backend los calcula desde PostgreSQL.
    const cliente = {
      correo: email,
      password: this.password,
      nombreCompleto: nombre,
      telefono: telefono || null,
      idMembresia: plan.idMembresia
    };

    this.http.post<{ mensaje?: string }>(
      `${environment.clienteAltaUrl}/api/clientes`,
      cliente
    ).subscribe({
      next: (respuesta) => {
        this.cargando = false;
        this.exito =
          respuesta?.mensaje ??
          'Cliente registrado correctamente.';

        this.limpiarFormulario();
        this.cd.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        this.cargando = false;

        if (err.status === 0 || err.status >= 500) {
          this.registroIncierto = true;
          this.error =
            'No se pudo confirmar el resultado. ' +
            'El cliente podría haberse registrado. ' +
            'Consulta el directorio antes de intentar otra alta.';
        } else if (err.status === 401) {
          this.error = 'Tu sesión expiró.';
        } else if (err.status === 403) {
          this.error = 'No tienes permiso para registrar clientes.';
        } else {
          this.error =
            err.error?.mensaje ??
            err.error?.message ??
            'No se pudo registrar el cliente.';
        }

        this.cd.detectChanges();
      }
    });
  }

  limpiarFormulario(): void {
    this.nombreCompleto = '';
    this.correo = '';
    this.password = '';
    this.telefono = '';
    this.idMembresia = null;
  }
}
