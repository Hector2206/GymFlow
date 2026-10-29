
export type EstadoMembresia =
  'Vigente' | 'Vencida' | 'SinPagos';

export interface MiMembresiaResponse {
  idCliente: number;
  idMembresia: number;
  nombrePlan: string;
  costoMensual: number;
  costoAnualidad: number;
  fechaVencimiento: string | null;
  estado: EstadoMembresia;
}
