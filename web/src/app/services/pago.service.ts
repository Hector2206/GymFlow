
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

export type TipoPago = 'Mensualidad' | 'Anualidad';

export interface RegistrarPagoRequest {
  idCliente: number;
  tipoPago: TipoPago;
}

export interface PagoPendiente extends RegistrarPagoRequest {
  clave: string;
  fechaCreacion: string;
}

export interface RegistrarPagoResponse {
  pagoRegistrado: boolean;
  pagoRepetido: boolean;
  idPago: number;
  esRenovacion: boolean | null;
  idCliente: number;
  monto: number;
  tipoPago: TipoPago;
  fechaVencimiento: string | null;
  mensaje: string;
}

export interface PagoCliente {
  idPago: number;
  monto: number;
  tipoPago: string;
  fechaTransaccion: string;
}

export interface HistorialPagosResponse {
  idCliente: number;
  pagos: PagoCliente[];
}

export interface MisPagosResponse {
  pagos: PagoCliente[];
}

@Injectable({
  providedIn: 'root'
})
export class PagoService {
  private readonly apiUrl =
    `${environment.clienteAltaUrl}/api/pagos`;

  private readonly claveLocal =
    'gymflow_pago_pendiente_sprint7';

  constructor(private http: HttpClient) {}

  obtenerPendiente(): PagoPendiente | null {
    let texto: string | null;

    try {
      texto = localStorage.getItem(this.claveLocal);
    } catch {
      throw new Error(
        'No se puede acceder al almacenamiento del navegador.'
      );
    }

    if (!texto) return null;

    try {
      const datos = JSON.parse(texto) as PagoPendiente;

      const uuidValido =
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

      if (
        !datos ||
        !Number.isInteger(datos.idCliente) ||
        datos.idCliente <= 0 ||
        !['Mensualidad', 'Anualidad'].includes(datos.tipoPago) ||
        typeof datos.clave !== 'string' ||
        !uuidValido.test(datos.clave) ||
        typeof datos.fechaCreacion !== 'string'
      ) {
        throw new Error('Datos pendientes inválidos');
      }

      return datos;
    } catch {
      throw new Error(
        'Existe un registro de pago pendiente que no se puede leer. ' +
        'Verifica el historial con Backend antes de continuar.'
      );
    }
  }

  prepararPago(request: RegistrarPagoRequest): PagoPendiente {
    const anterior = this.obtenerPendiente();

    if (anterior) {
      if (
        anterior.idCliente !== request.idCliente ||
        anterior.tipoPago !== request.tipoPago
      ) {
        throw new Error(
          'Ya existe otro pago pendiente de confirmación.'
        );
      }

      return anterior;
    }

    if (
      typeof crypto === 'undefined' ||
      typeof crypto.randomUUID !== 'function'
    ) {
      throw new Error(
        'El navegador no permite generar UUID seguros. ' +
        'Utiliza HTTPS o localhost.'
      );
    }

    const pendiente: PagoPendiente = {
      idCliente: request.idCliente,
      tipoPago: request.tipoPago,
      clave: crypto.randomUUID(),
      fechaCreacion: new Date().toISOString()
    };

    try {
      localStorage.setItem(
        this.claveLocal,
        JSON.stringify(pendiente)
      );
    } catch {
      throw new Error(
        'No fue posible guardar el pago pendiente. ' +
        'No se ha enviado ninguna solicitud.'
      );
    }

    const verificacion = this.obtenerPendiente();

    if (!verificacion ||
        verificacion.clave !== pendiente.clave) {
      throw new Error(
        'No se pudo conservar el UUID del pago.'
      );
    }

    return pendiente;
  }

  registrarPago(
    pendiente: PagoPendiente
  ): Observable<RegistrarPagoResponse> {
    return this.http.post<RegistrarPagoResponse>(
      this.apiUrl,
      {
        idCliente: pendiente.idCliente,
        tipoPago: pendiente.tipoPago
      },
      {
        headers: {
          'Idempotency-Key': pendiente.clave
        }
      }
    );
  }

  confirmarYLimpiar(
    pendiente: PagoPendiente,
    respuesta: RegistrarPagoResponse
  ): void {
    if (
      respuesta.pagoRegistrado !== true ||
      !Number.isInteger(respuesta.idPago) ||
      respuesta.idPago <= 0 ||
      respuesta.idCliente !== pendiente.idCliente ||
      respuesta.tipoPago !== pendiente.tipoPago ||
      !Number.isFinite(respuesta.monto) ||
      respuesta.monto <= 0 ||
      typeof respuesta.pagoRepetido !== 'boolean'
    ) {
      throw new Error(
        'La respuesta del servidor no confirma el pago. ' +
        'Se conservará el UUID para verificarlo.'
      );
    }

    const guardado = this.obtenerPendiente();

    if (!guardado || guardado.clave !== pendiente.clave) {
      throw new Error(
        'La confirmación llegó, pero el UUID guardado cambió. ' +
        'Verifica el historial antes de continuar.'
      );
    }

    try {
      localStorage.removeItem(this.claveLocal);

      if (localStorage.getItem(this.claveLocal) !== null) {
        throw new Error('No se eliminó el registro local');
      }
    } catch {
      throw new Error(
        'El pago fue confirmado, pero no se pudo limpiar ' +
        'el registro pendiente. Consulta el historial.'
      );
    }
  }

  consultarPagosCliente(
    idCliente: number
  ): Observable<HistorialPagosResponse> {
    return this.http.get<HistorialPagosResponse>(
      `${this.apiUrl}/cliente/${idCliente}`
    );
  }

  consultarMisPagos(): Observable<MisPagosResponse> {
    return this.http.get<MisPagosResponse>(
      `${this.apiUrl}/mis-pagos`
    );
  }
}
