
/**
 * GymFlow - Sprint 7
 * Modelos de salarios y nomina.
 *
 * Informacion exclusiva del Administrador.
 */

// HISTORIAL SALARIAL

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

// HISTORIAL DE PAGOS DE NOMINA

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
