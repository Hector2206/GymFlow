export interface RutinaResumen {
  idRutina: number;
  nombre: string;
  descripcion: string | null;
  idCliente: number;
  nombreCliente: string;
}

export interface EjercicioRutinaDetalle {
  idEjercicioRutina: number;
  idEjercicio: number;
  nombre: string;
  descripcion: string | null;

  imagenUrl?: string | null;

  series: number;
  repeticiones: number;
  orden: number;
}

export interface DiaRutinaDetalle {
  idDia: number;
  dia: string;
  ejercicios: EjercicioRutinaDetalle[];
}

export interface RutinaDetalle {
  idRutina: number;
  idCliente: number;
  nombreCliente: string;
  nombre: string;
  descripcion: string | null;
  dias: DiaRutinaDetalle[];
}

export interface EjercicioRutinaRequest {
  idEjercicio: number;
  series: number;
  repeticiones: number;
  orden: number;
}

export interface DiaRutinaRequest {
  dia: string;
  ejercicios: EjercicioRutinaRequest[];
}

export interface CrearRutinaRequest {
  idCliente: number;
  nombre: string;
  descripcion: string | null;
  dias: DiaRutinaRequest[];
}

export interface RutinaGuardadaResponse {
  idRutina: number;
  idCliente: number;
  idEntrenador: number;
  nombre: string;
  descripcion: string | null;
}