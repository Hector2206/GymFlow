import { Routes } from '@angular/router';

import { Splash } from './splash/splash';

import { Login } from './login/login';

import { Home } from './home/home';

import { Perfil } from './perfil/perfil';

import { ControlAcceso } from './control-acceso/control-acceso';

import {
  HistorialAsistencias
} from './historial-asistencias/historial-asistencias';

import {
  RegistrarCliente
} from './registrar-cliente/registrar-cliente';

import {
  RegistrarPago
} from './registrar-pago/registrar-pago';

import {
  authGuard
} from './auth-guard';

import {
  recepcionistaGuard
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
    canActivate: [
      authGuard
    ]
  },

  {
    path: 'perfil',
    component: Perfil,
    canActivate: [
      authGuard
    ]
  },

  {
    path: 'registrar-cliente',
    component: RegistrarCliente,
    canActivate: [
      authGuard,
      recepcionistaGuard
    ]
  },

  {
    path: 'control-acceso',
    component: ControlAcceso,
    canActivate: [
      authGuard,
      recepcionistaGuard
    ]
  },

  {
    path: 'historial-asistencias',
    component: HistorialAsistencias,
    canActivate: [
      authGuard,
      recepcionistaGuard
    ]
  },

  {
    path: 'registrar-pago',
    component: RegistrarPago,
    canActivate: [
      authGuard,
      recepcionistaGuard
    ]
  },

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