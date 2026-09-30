export interface Ejercicio {
  idEjercicio: number;
  nombre: string;
  descripcion: string | null;
  estado: boolean;
  imagenUrl?: string | null;
}

export interface CrearEjercicioRequest {
  nombre: string;
  descripcion: string | null;
  imagenUrl?: string | null;
}