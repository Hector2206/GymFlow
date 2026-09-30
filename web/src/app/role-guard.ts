import {
  inject
} from '@angular/core';

import {
  CanActivateFn,
  Router
} from '@angular/router';


function validarRol(
  rolPermitido: string
): boolean | ReturnType<Router['createUrlTree']> {

  const router =
    inject(Router);

  const usuarioGuardado =
    localStorage.getItem(
      'usuario'
    );

  if (!usuarioGuardado) {

    return router.createUrlTree([
      '/login'
    ]);
  }

  try {

    const usuario =
      JSON.parse(
        usuarioGuardado
      );

    const role =
      usuario?.role
        ?.toString()
        .trim()
        .toLowerCase();

    if (
      role ===
      rolPermitido.toLowerCase()
    ) {

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
}


export const recepcionistaGuard:
  CanActivateFn = () => {

  return validarRol(
    'recepcionista'
  );
};


export const entrenadorGuard:
  CanActivateFn = () => {

  return validarRol(
    'entrenador'
  );
};


export const clienteGuard:
  CanActivateFn = () => {

  return validarRol(
    'cliente'
  );
};
