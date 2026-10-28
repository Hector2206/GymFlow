
/**
 * GymFlow - Sprint 7
 * Modelos de salarios y nómina.
 */

export interface SalarioPersonalAdmin {
  idSalario: number;
  idPersonal: number;
  monto: number;
  periodicidad: string;
  vigenteDesde: string;
  vigenteHasta: string | null;
  motivo: string | null;
  registradoPor: number | null;
  creadoEn: string;
}

export interface PagoNominaAdmin {
  idPago: number;
  idPersonal: number;
  idSalario: number;
  periodoInicio: string;
  periodoFin: string;
  monto: number;
  fechaPago: string;
  metodo: string;
  referencia: string | null;
  observaciones: string | null;
  estado: string;
  registradoPor: number;
  canceladoPor: number | null;
  fechaCancelacion: string | null;
  motivoCancelacion: string | null;
  creadoEn: string;
}

// CAMBIOS SALARIALES

export interface CambiarSalarioAdminRequest {
  monto: number;
  vigenteDesde: string;
  motivo: string;
}

export interface CambiarSalarioAdminResponse {
  mensaje: string;
  idPersonal: number;
  idSalario: number;
}

// REGISTRO MANUAL DE NÓMINA

export type MetodoPagoNominaAdmin =
  'Efectivo' | 'Transferencia';

export interface RegistrarPagoNominaAdminRequest {
  periodoInicio: string;
  periodoFin: string;
  monto: number;
  fechaPago: string;
  metodo: MetodoPagoNominaAdmin;
  referencia: string | null;
  observaciones: string | null;
}

export interface RegistrarPagoNominaAdminResponse {
  mensaje: string;
  idPersonal: number;
  idPago: number;
}
