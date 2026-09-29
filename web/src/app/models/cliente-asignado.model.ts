export interface ClienteAsignado {
  idCliente: number;
  idUsuario: number;
  nombre: string;
  correo: string;
  telefono: string;
  estatus: boolean;
}

export interface ClientesEntrenadorResponse {
  idEntrenador: number;
  clientes: ClienteAsignado[];
}