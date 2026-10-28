
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

type VistaMembresias = 'basicflow' | 'catalogo' | 'nuevo';
type TipoPropuesta = 'basicflow' | 'nuevo';

interface PropuestaPlan {
  nombrePlan: string;
  descripcion: string;
  costoMensual: number | null;
  costoAnual: number | null;
  beneficios: string;
  activo: boolean;
}

@Component({
  selector: 'app-admin-membresias',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './admin-membresias.html',
  styleUrl: './admin-membresias.css'
})
export class AdminMembresias {

  vista: VistaMembresias = 'basicflow';

  // BasicFlow aparece en el formulario de Recepción
  // con ID 1. Falta verificarlo en PostgreSQL.
  readonly basicFlowReferencia = {
    idMembresiaEnFormulario: 1,
    nombre: 'BasicFlow'
  };

  // Son propuestas locales, NO precios oficiales.
  propuestaBasicFlow: PropuestaPlan = {
    nombrePlan: 'BasicFlow',
    descripcion: '',
    costoMensual: null,
    costoAnual: null,
    beneficios: '',
    activo: true
  };

  propuestaNueva: PropuestaPlan =
    this.crearPropuestaNueva();

  tipoRevisado: TipoPropuesta | null = null;

  error = '';

  constructor(
    private router: Router
  ) {}

  private crearPropuestaNueva(): PropuestaPlan {

    return {
      nombrePlan: '',
      descripcion: '',
      costoMensual: null,
      costoAnual: null,
      beneficios: '',
      activo: true
    };
  }

  get propuestaActual(): PropuestaPlan {

    return this.vista === 'basicflow'
      ? this.propuestaBasicFlow
      : this.propuestaNueva;
  }

  get beneficiosActuales(): string[] {

    return this.propuestaActual.beneficios
      .split('\n')
      .map(valor => valor.trim())
      .filter(valor => valor.length > 0);
  }

  // NAVEGACIÓN

  cambiarVista(vista: VistaMembresias): void {

    this.vista = vista;
    this.limpiarRevision();
  }

  limpiarRevision(): void {

    this.error = '';
    this.tipoRevisado = null;
  }

  get mostrarRevision(): boolean {

    return (
      (
        this.vista === 'basicflow' &&
        this.tipoRevisado === 'basicflow'
      ) ||
      (
        this.vista === 'nuevo' &&
        this.tipoRevisado === 'nuevo'
      )
    );
  }

  // VALIDACIÓN DE PRECIOS

  private montoValido(
    valor: number | null,
    requerido: boolean
  ): boolean {

    if (valor === null) {
      return !requerido;
    }

    return (
      typeof valor === 'number' &&
      Number.isFinite(valor) &&
      valor > 0 &&
      valor <= 99999999.99 &&
      Math.abs(
        valor * 100 - Math.round(valor * 100)
      ) < 0.000001
    );
  }

  // VALIDAR PROPUESTA SIN GUARDAR

  revisarPropuesta(): void {

    this.limpiarRevision();

    if (this.vista === 'catalogo') {
      return;
    }

    const propuesta = this.propuestaActual;
    const nombre = propuesta.nombrePlan.trim();
    const beneficios = this.beneficiosActuales;

    if (
      this.vista === 'nuevo' &&
      (
        nombre.length < 3 ||
        nombre.length > 80
      )
    ) {

      this.error =
        'El nombre debe tener entre 3 y 80 caracteres.';

      return;
    }

    if (
      propuesta.descripcion.trim().length > 300
    ) {

      this.error =
        'La descripción no debe superar los 300 caracteres.';

      return;
    }

    if (
      !this.montoValido(
        propuesta.costoMensual,
        true
      )
    ) {

      this.error =
        'Ingresa un precio mensual mayor a cero, ' +
        'con máximo dos decimales.';

      return;
    }

    if (
      !this.montoValido(
        propuesta.costoAnual,
        false
      )
    ) {

      this.error =
        'El precio anual debe ser positivo ' +
        'o dejarse sin definir.';

      return;
    }

    if (
      beneficios.length > 12 ||
      beneficios.some(
        valor => valor.length > 100
      )
    ) {

      this.error =
        'Se permiten hasta 12 beneficios ' +
        'de máximo 100 caracteres cada uno.';

      return;
    }

    this.tipoRevisado = this.vista;
  }

  // LIMPIAR BORRADOR LOCAL

  limpiarPropuesta(): void {

    if (this.vista === 'basicflow') {

      this.propuestaBasicFlow = {
        nombrePlan: 'BasicFlow',
        descripcion: '',
        costoMensual: null,
        costoAnual: null,
        beneficios: '',
        activo: true
      };

    } else if (this.vista === 'nuevo') {

      this.propuestaNueva =
        this.crearPropuestaNueva();
    }

    this.limpiarRevision();
  }

  // FORMATO MONETARIO

  mostrarMonto(
    monto: number | null
  ): string {

    if (
      monto === null ||
      !Number.isFinite(monto)
    ) {
      return 'Sin definir';
    }

    return new Intl.NumberFormat('es-MX', {
      style: 'currency',
      currency: 'MXN'
    }).format(monto);
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}
