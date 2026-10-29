
export interface NotificacionGymFlow {
  idNotificacion: number;
  tipo: string;
  titulo: string;
  mensaje: string;
  fechaVencimiento: string;
  leida: boolean;
  fechaLectura: string | null;
  creadoEn: string;
}

export interface ContadorNotificaciones {
  noLeidas: number;
}

export interface LecturaNotificacionResponse {
  mensaje: string;
  idNotificacion: number;
}
