

export type EstatusClienteAdmin =
  'Activo' | 'Inactivo';

export type VigenciaClienteAdmin =
  'Vigente' | 'Vencida' | 'SinPagos';

// Cliente devuelto por el backend
export interface ClienteAdmin {
  idCliente: number;
  nombreCompleto: string;
  correo: string;
  telefono: string;
  idMembresia: number;
  nombrePlan: string;
  estatus: EstatusClienteAdmin;
  vigencia: VigenciaClienteAdmin;
  fechaVencimiento: string | null;
}

// Filtros disponibles para la busqueda
export interface BuscarClientesAdminFiltros {
  nombre?: string;
  correo?: string;
  estatus?: EstatusClienteAdmin;
  vigencia?: VigenciaClienteAdmin;
  idMembresia?: number;
}
