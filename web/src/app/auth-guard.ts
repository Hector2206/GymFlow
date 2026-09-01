import { inject } from '@angular/core';

import {
  CanActivateFn,
  Router
} from '@angular/router';

import {
  catchError,
  map,
  of
} from 'rxjs';

import {
  UsuarioService
} from './services/usuario.service';

import {
  AuthService
} from './services/auth.service';

export const authGuard: CanActivateFn = () => {

  const router =
    inject(Router);

  const usuarioService =
    inject(UsuarioService);

  const authService =
    inject(AuthService);

  const token =
    authService.obtenerToken();

  if (!token) {

    authService.cerrarSesion();

    return router.createUrlTree([
      '/login'
    ]);
  }

  return usuarioService
    .obtenerUsuarioActual()
    .pipe(

      map((usuario) => {

        localStorage.setItem(
          'usuario',
          JSON.stringify(usuario)
        );

        return true;
      }),

      catchError((error) => {

        console.error(
          'Sesión inválida:',
          error
        );

        authService.cerrarSesion();

        return of(
          router.createUrlTree([
            '/login'
          ])
        );
      })
    );
};