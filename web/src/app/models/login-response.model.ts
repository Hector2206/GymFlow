import { Usuario } from './usuario.model';

export interface LoginResponse {
  token: string;
  usuario: Usuario;
}