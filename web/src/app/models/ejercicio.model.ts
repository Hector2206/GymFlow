export interface Ejercicio {
  idEjercicio: number;
  nombre: string;
  descripcion: string | null;
  estado: boolean;

  imagenUrl?: string | null;
}