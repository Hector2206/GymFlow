import { Routes } from '@angular/router';

import { Home } from './home/home';
import { Login } from './login/login';
import { Perfil } from './perfil/perfil';
import { authGuard } from './auth-guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
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
    path: '**',
    redirectTo: 'login'
  }
];