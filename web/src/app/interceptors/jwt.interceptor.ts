import {
  HttpInterceptorFn
} from '@angular/common/http';

export const jwtInterceptor: HttpInterceptorFn = (
  request,
  next
) => {

  const token = localStorage.getItem('token');

  if (token) {

    const requestConToken = request.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });

    return next(requestConToken);
  }

  return next(request);
};