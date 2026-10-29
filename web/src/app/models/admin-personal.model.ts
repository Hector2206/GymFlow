
/**
 * GymFlow - Sprint 7
 * Modelos de administracion de personal.
 *
 * Incluye entrenadores y recepcionistas.
 */

export type PuestoPersonalAdmin =
  'Entrenador' | 'Recepcionista';

export type EstatusPersonalAdmin =
  'Activo' | 'Inactivo';

// EMPLEADO DEVUELTO POR EL BACKEND

export interface PersonalAdmin {
  idPersonal: number;
  nombreCompleto: string;
  correo: string;
  telefono: string;
  puesto: PuestoPersonalAdmin;
  salario: number;
  fechaContratacion: string;
  fechaBaja: string | null;
  estatus: EstatusPersonalAdmin;
  horario: string;
}

// DATOS PARA REGISTRAR UN EMPLEADO

export interface CrearPersonalAdminRequest {
  nombreCompleto: string;
  correo: string;
  telefono: string;
  fechaContratacion: string;
  puesto: PuestoPersonalAdmin;
  sueldo: number;
  password: string;
}

// RESPUESTA AL REGISTRAR EMPLEADO

export interface CrearPersonalAdminResponse {
  mensaje: string;
  idPersonal: number;
}

// DATOS PARA EDITAR UN EMPLEADO

export interface EditarPersonalAdminRequest {
  nombreCompleto: string;
  correo: string;
  telefono: string;
  horario: string;
}

// RESPUESTA AL EDITAR EMPLEADO

export interface EditarPersonalAdminResponse {
  mensaje: string;
  idPersonal: number;
}

// DATOS PARA DAR DE BAJA UN EMPLEADO

export interface BajaPersonalAdminRequest {
  motivo: string;
}

// RESPUESTA AL DAR DE BAJA

export interface BajaPersonalAdminResponse {
  mensaje: string;
  idPersonal: number;
  clientesDesasignados: number;
}
