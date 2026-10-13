export interface RegistrarProgresoRequest {
  idEjercicio: number;
  pesoUtilizado: number;
}

export interface RegistrarProgresoResponse {
  idProgreso: number;
  idCliente: number;
  idEjercicio: number;
  pesoUtilizado: number;
  fechaRegistro: string;
  mensaje: string;
}

export interface Progreso {
  idProgreso: number;
  idCliente: number;
  idEjercicio: number;
  nombreEjercicio: string;
  pesoUtilizado: number;
  fechaRegistro: string;
}