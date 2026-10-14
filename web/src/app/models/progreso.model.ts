
export interface RegistrarProgresoRequest {
  idEjercicio: number;
  pesoUtilizado: number;
  fechaEntrenamiento?: string;
}

export interface RegistrarProgresoResponse {
  idProgreso: number;
  idCliente: number;
  idEjercicio: number;
  pesoUtilizado: number;
  fechaRegistro: string;
  fechaEntrenamiento?: string | null;
  mensaje: string;
}

export interface Progreso {
  idProgreso: number;
  idCliente: number;
  idEjercicio: number;
  nombreEjercicio: string;
  pesoUtilizado: number;
  fechaRegistro: string;
  fechaEntrenamiento?: string | null;
}
