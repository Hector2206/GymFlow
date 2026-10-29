
import { Routes } from '@angular/router';

import { Splash } from './splash/splash';
import { Login } from './login/login';
import { Home } from './home/home';
import { Perfil } from './perfil/perfil';

import {
  ControlAcceso
} from './control-acceso/control-acceso';

import {
  HistorialAsistencias
} from './historial-asistencias/historial-asistencias';

import {
  HistorialPagos
} from './historial-pagos/historial-pagos';

import {
  MiCodigoAcceso
} from './mi-codigo-acceso/mi-codigo-acceso';

import {
  MisAsistencias
} from './mis-asistencias/mis-asistencias';

import {
  MisPagos
} from './mis-pagos/mis-pagos';

import {
  RegistrarCliente
} from './registrar-cliente/registrar-cliente';

import {
  RegistrarPago
} from './registrar-pago/registrar-pago';

import {
  MisClientesEntrenador
} from './mis-clientes-entrenador/mis-clientes-entrenador';

import {
  AdministrarEjercicios
} from './administrar-ejercicios/administrar-ejercicios';

import {
  FormularioEjercicio
} from './formulario-ejercicio/formulario-ejercicio';

import {
  AdministrarRutinas
} from './administrar-rutinas/administrar-rutinas';

import {
  FormularioRutina
} from './formulario-rutina/formulario-rutina';

import {
  MiRutina
} from './mi-rutina/mi-rutina';

import {
  MiProgreso
} from './mi-progreso/mi-progreso';

import {
  AdminDashboard
} from './admin-dashboard/admin-dashboard';

import {
  AdminClientes
} from './admin-clientes/admin-clientes';

import {
  AdminMembresias
} from './admin-membresias/admin-membresias';

import {
  AdminAdministradores
} from './admin-administradores/admin-administradores';

import {
  AdminPersonal
} from './admin-personal/admin-personal';

import {
  AdminPersonalAlta
} from './admin-personal-alta/admin-personal-alta';

import {
  AdminPersonalEditar
} from './admin-personal-editar/admin-personal-editar';

import {
  AdminPersonalBajas
} from './admin-personal-bajas/admin-personal-bajas';

import {
  AdminNomina
} from './admin-nomina/admin-nomina';

import {
  AdminNominaPago
} from './admin-nomina-pago/admin-nomina-pago';

import {
  AdminPersonalOperaciones
} from './admin-personal-operaciones/admin-personal-operaciones';

import {
  AsignacionEntrenadores
} from './asignacion-entrenadores/asignacion-entrenadores';

import { authGuard } from './auth-guard';

import { MiMembresia } from './mi-membresia/mi-membresia';


import { RecepcionClientes } from './recepcion-clientes/recepcion-clientes';

import { Notificaciones } from './notificaciones/notificaciones';


import {
  recepcionistaGuard,
  entrenadorGuard,
  clienteGuard,
  administradorGuard
} from './role-guard';

export const routes: Routes = [

  {
    path: 'splash',
    component: Splash
  },

  {
    path: 'login',
    component: Login
  },

  {
    path: 'home',
    component: Home,
    canActivate: [authGuard]
  },

  {
    path: 'perfil',
    component: Perfil,
    canActivate: [authGuard]
  },

  
{
  path: 'notificaciones',
  component: Notificaciones,
  canActivate: [authGuard]
},


  // ADMINISTRADOR

  {
    path: 'admin/dashboard',
    component: AdminDashboard,
    canActivate: [authGuard, administradorGuard]
  },

  {
    path: 'admin/clientes',
    component: AdminClientes,
    canActivate: [authGuard, administradorGuard]
  },

  {
    path: 'admin/membresias',
    component: AdminMembresias,
    canActivate: [authGuard, administradorGuard]
  },

  // NUEVO: ADMINISTRAR ADMINISTRADORES

  {
    path: 'admin/administradores',
    component: AdminAdministradores,
    canActivate: [authGuard, administradorGuard]
  },

  // PERSONAL

  {
    path: 'admin/personal/nuevo',
    component: AdminPersonalAlta,
    canActivate: [authGuard, administradorGuard]
  },

  {
    path: 'admin/personal/editar/:id',
    component: AdminPersonalEditar,
    canActivate: [authGuard, administradorGuard]
  },

  {
    path: 'admin/personal/bajas',
    component: AdminPersonalBajas,
    canActivate: [authGuard, administradorGuard]
  },

  // NÓMINA

  {
    path: 'admin/personal/nomina/pago/:id',
    component: AdminNominaPago,
    canActivate: [authGuard, administradorGuard]
  },

  {
    path: 'admin/personal/nomina',
    component: AdminNomina,
    canActivate: [authGuard, administradorGuard]
  },

  // HORARIOS Y ASISTENCIAS

  {
    path: 'admin/personal/operaciones',
    component: AdminPersonalOperaciones,
    canActivate: [authGuard, administradorGuard]
  },

  {
    path: 'admin/personal',
    component: AdminPersonal,
    canActivate: [authGuard, administradorGuard]
  },

  // RECEPCIÓN

  {
    path: 'registrar-cliente',
    component: RegistrarCliente,
    canActivate: [authGuard, recepcionistaGuard]
  },

  {
    path: 'control-acceso',
    component: ControlAcceso,
    canActivate: [authGuard, recepcionistaGuard]
  },

  
{
  path: 'recepcion/clientes',
  component: RecepcionClientes,
  canActivate: [authGuard, recepcionistaGuard]
},


  {
    path: 'historial-asistencias',
    component: HistorialAsistencias,
    canActivate: [authGuard, recepcionistaGuard]
  },

  {
    path: 'registrar-pago',
    component: RegistrarPago,
    canActivate: [authGuard, recepcionistaGuard]
  },

  {
    path: 'historial-pagos',
    component: HistorialPagos,
    canActivate: [authGuard, recepcionistaGuard]
  },

  {
    path: 'asignacion-entrenadores',
    component: AsignacionEntrenadores,
    canActivate: [authGuard, recepcionistaGuard]
  },

  // CLIENTE

  {
    path: 'mi-codigo-acceso',
    component: MiCodigoAcceso,
    canActivate: [authGuard, clienteGuard]
  },

  {
    path: 'mis-asistencias',
    component: MisAsistencias,
    canActivate: [authGuard, clienteGuard]
  },

  
{
  path: 'mi-membresia',
  component: MiMembresia,
  canActivate: [authGuard, clienteGuard]
},


  {
    path: 'mis-pagos',
    component: MisPagos,
    canActivate: [authGuard, clienteGuard]
  },

  {
    path: 'rutinas',
    component: MiRutina,
    canActivate: [authGuard, clienteGuard]
  },

  {
    path: 'mi-progreso',
    component: MiProgreso,
    canActivate: [authGuard, clienteGuard]
  },

  // ENTRENADOR

  {
    path: 'entrenador/mis-clientes',
    component: MisClientesEntrenador,
    canActivate: [authGuard, entrenadorGuard]
  },

  {
    path: 'entrenador/ejercicios/nuevo',
    component: FormularioEjercicio,
    canActivate: [authGuard, entrenadorGuard]
  },

  {
    path: 'entrenador/ejercicios/editar/:id',
    component: FormularioEjercicio,
    canActivate: [authGuard, entrenadorGuard]
  },

  {
    path: 'entrenador/ejercicios',
    component: AdministrarEjercicios,
    canActivate: [authGuard, entrenadorGuard]
  },

  {
    path: 'entrenador/rutinas/nueva',
    component: FormularioRutina,
    canActivate: [authGuard, entrenadorGuard]
  },

  {
    path: 'entrenador/rutinas/editar/:id',
    component: FormularioRutina,
    canActivate: [authGuard, entrenadorGuard]
  },

  {
    path: 'entrenador/rutinas',
    component: AdministrarRutinas,
    canActivate: [authGuard, entrenadorGuard]
  },

  // INICIO

  {
    path: '',
    redirectTo: 'splash',
    pathMatch: 'full'
  },

  {
    path: '**',
    redirectTo: 'splash'
  }

];
