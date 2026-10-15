export interface EntrenadorResumen {
  idEntrenador: number;
  nombreCompleto: string;
}

export interface AsignarEntrenadorRequest {
  idEntrenador: number;
}

export interface AsignarEntrenadorResponse {
  idEntrenador: number;
  nombreEntrenador: string;
  mensaje: string;
}

export interface QuitarEntrenadorResponse {
  idEntrenador: number | null;
  mensaje: string;
}