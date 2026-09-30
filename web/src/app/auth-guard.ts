import {
  inject
} from '@angular/core';

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

export const authGuard:
  CanActivateFn = (
    _route,
    state
  ) => {

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

    return router.createUrlTree(
      [
        '/login'
      ],
      {
        queryParams: {
          returnUrl:
            state.url
        }
      }
    );
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
          'No fue posible validar la sesión:',
          error
        );

        if (
          error.status === 401
        ) {

          authService.cerrarSesion();

          return of(
            router.createUrlTree(
              [
                '/login'
              ],
              {
                queryParams: {
                  returnUrl:
                    state.url
                }
              }
            )
          );
        }

        /*
         * Si Render está despertando, hay un problema
         * temporal de red o el servicio responde 5xx,
         * conservamos la sesión. El componente mostrará
         * su estado de error sin destruir el token válido.
         */
        return of(true);
      })
    );
};
