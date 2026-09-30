import {
  Injectable
} from '@angular/core';

import {
  HttpClient
} from '@angular/common/http';

import {
  Observable
} from 'rxjs';

import {
  environment
} from '../../environments/environment';

export interface VersionSistemaResponse {
  version: string;
}

@Injectable({
  providedIn: 'root'
})
export class SistemaService {

  constructor(
    private http: HttpClient
  ) {}


  obtenerVersionSistema():
    Observable<VersionSistemaResponse> {

    return this.http.get<VersionSistemaResponse>(
      `${environment.rutinaServiceUrl}/api/sistema/version`
    );
  }
}