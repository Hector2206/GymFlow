export interface Administrador {
  idUsuario: number;
  idPersonal: number;
  nombreCompleto: string;
  correo: string;
  telefono: string;
  horario: string;
  estatus: string;
  fechaAlta: string | null;
  fechaBaja: string | null;
}

export interface CrearAdministradorRequest {
  nombreCompleto: string;
  correo: string;
  telefono: string;
  fechaContratacion: string;
  sueldo: number;
  horario: string;
  password: string;
}

export interface EditarAdministradorRequest {
  nombreCompleto: string;
  correo: string;
  telefono: string;
  horario: string;
}

export interface BajaAdministradorRequest {
  motivoBaja: string;
  fechaBaja: string;
}

export interface OperacionAdministradorResponse {
  mensaje: string;
  idUsuario: number;
}
