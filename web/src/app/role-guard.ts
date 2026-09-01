import { inject } from '@angular/core';

import {
  CanActivateFn,
  Router
} from '@angular/router';

export const recepcionistaGuard: CanActivateFn = () => {

  const router = inject(Router);

  const usuarioGuardado =
    localStorage.getItem('usuario');

  if (!usuarioGuardado) {

    return router.createUrlTree([
      '/login'
    ]);
  }

  try {

    const usuario =
      JSON.parse(usuarioGuardado);

    const role =
      usuario?.role
        ?.toString()
        .toLowerCase();

    if (role === 'recepcionista') {

      return true;
    }

    return router.createUrlTree([
      '/home'
    ]);

  } catch {

    localStorage.removeItem(
      'usuario'
    );

    return router.createUrlTree([
      '/login'
    ]);
  }
};