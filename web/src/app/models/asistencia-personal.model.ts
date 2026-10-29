
export interface AsistenciaPersonal {
  idAsistenciaPersonal: number;
  idPersonal: number;
  nombreCompleto: string;
  fecha: string;
  horaEntrada: string;
  horaSalida: string | null;
  registradoPor: number;
  salidaRegistradaPor: number | null;
  fechaRegistro: string;
  fechaRegistroSalida: string | null;
}

export interface RegistrarEntradaPersonalRequest {
  idPersonal: number;
  fecha: string;
  horaEntrada: string;
}

export interface RegistrarEntradaPersonalResponse {
  mensaje: string;
  idAsistenciaPersonal: number;
  idPersonal: number;
  fecha: string;
  horaEntrada: string;
}

export interface RegistrarSalidaPersonalResponse {
  mensaje: string;
  idAsistenciaPersonal: number;
  horaSalida: string;
}

export interface FiltrosAsistenciaPersonal {
  idPersonal?: number;
  fechaInicio?: string;
  fechaFin?: string;
}
