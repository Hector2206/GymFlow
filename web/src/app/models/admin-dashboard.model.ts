
/**
 * GymFlow - Sprint 7
 * Modelos del Dashboard de Administrador
 */

// Total de clientes registrados
export interface TotalClientesResponse {
  totalClientes: number;
}

// Membresías activas
export interface MembresiasActivasResponse {
  membresiasActivas: number;
}

// Asistencias registradas durante el día
export interface AsistenciasDiaResponse {
  asistenciasDia: number;
}

// Total de pagos registrados de clientes
export interface PagosRegistradosResponse {
  pagosRegistrados: number;
}

// Ingresos brutos de clientes por periodo
export interface IngresosPeriodoResponse {
  desde: string;
  hasta: string;
  ingresosPeriodo: number;
}
