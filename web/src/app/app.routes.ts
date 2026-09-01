import { Routes } from '@angular/router';

import { Splash } from './splash/splash';
import { Login } from './login/login';
import { Home } from './home/home';
import { Perfil } from './perfil/perfil';

import {
  RegistrarCliente
} from './registrar-cliente/registrar-cliente';

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
    path: '',
    redirectTo: 'splash',
    pathMatch: 'full'
  },

  {
    path: '**',
    redirectTo: 'splash'
  }

];