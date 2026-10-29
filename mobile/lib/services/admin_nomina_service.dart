import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_pago_nomina.dart';
import 'auth_service.dart';

// GYMFLOW - SPRINT 7
// SERVICIO DE CONSULTA DE NOMINA

class AdminNominaService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 50);

  // GET /api/admin/personal/{id}/nomina

  Future<List<AdminPagoNomina>> obtenerPagos(int idPersonal) async {
    if (idPersonal <= 0) {
      throw Exception('El ID del empleado no es válido.');
    }

    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. '
        'Inicia sesión nuevamente.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.adminPersonalUrl}'
      '/$idPersonal/nomina',
    );

    late http.Response respuesta;

    try {
      respuesta = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_tiempoEspera);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Intenta actualizar la consulta.',
      );
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }

    if (respuesta.statusCode != 200) {
      _procesarError(respuesta);
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw const FormatException();
      }

      final pagos = <AdminPagoNomina>[];

      for (final elemento in datos) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException();
        }

        final pago = AdminPagoNomina.fromJson(elemento);

        if (pago.idPersonal != idPersonal) {
          throw const FormatException();
        }

        pagos.add(pago);
      }

      // Una lista vacía es válida.
      return pagos;
    } on FormatException {
      throw Exception(
        'El servidor devolvió pagos de nómina '
        'con un formato no válido.',
      );
    }
  }

  // VALIDAR RESPUESTAS DE LA API

  Never _procesarError(http.Response respuesta) {
    if (respuesta.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. '
        'Inicia sesión nuevamente.',
      );
    }

    if (respuesta.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar '
        'la nómina del personal.',
      );
    }

    if (respuesta.statusCode == 404) {
      throw Exception('El empleado solicitado no existe.');
    }

    String mensaje =
        'No fue posible consultar los pagos '
        '(código ${respuesta.statusCode}).';

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        final mensajeServidor =
            datos['mensaje']?.toString() ??
            datos['detail']?.toString() ??
            datos['title']?.toString();

        if (mensajeServidor != null && mensajeServidor.trim().isNotEmpty) {
          mensaje = mensajeServidor;
        }
      }
    } catch (_) {
      // Conservar el mensaje predeterminado.
    }

    throw Exception(mensaje);
  }

  // ==========================================
  // REGISTRAR PAGO DE NOMINA
  // POST /api/admin/personal/{id}/nomina
  // ==========================================

  Future<int> registrarPago({
    required int idPersonal,
    required String periodoInicio,
    required String periodoFin,
    required String montoTexto,
    required String fechaPago,
    required String metodo,
    String? referencia,
    String? observaciones,
  }) async {
    if (idPersonal <= 0) {
      throw Exception('El empleado no es válido.');
    }

    final montoLimpio = montoTexto.trim();

    if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(montoLimpio)) {
      throw Exception('Ingresa un monto con máximo dos decimales.');
    }

    final monto = double.tryParse(montoLimpio);

    if (monto == null ||
        !monto.isFinite ||
        monto <= 0 ||
        monto > 9999999999.99) {
      throw Exception(
        'El monto debe ser mayor a cero '
        'y no superar 9999999999.99.',
      );
    }

    bool fechaValida(String fecha) {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) {
        return false;
      }

      final parsed = DateTime.tryParse('${fecha}T00:00:00Z');

      return parsed != null &&
          parsed.toIso8601String().substring(0, 10) == fecha;
    }

    if (!fechaValida(periodoInicio) ||
        !fechaValida(periodoFin) ||
        !fechaValida(fechaPago)) {
      throw Exception('Las fechas del pago no son válidas.');
    }

    if (periodoFin.compareTo(periodoInicio) < 0) {
      throw Exception(
        'El fin del periodo debe ser posterior '
        'o igual al inicio.',
      );
    }

    if (metodo != 'Efectivo' && metodo != 'Transferencia') {
      throw Exception('Selecciona un método de pago válido.');
    }

    final referenciaLimpia = referencia?.trim();
    final observacionesLimpias = observaciones?.trim();

    if ((referenciaLimpia?.length ?? 0) > 100) {
      throw Exception(
        'La referencia no puede superar '
        '100 caracteres.',
      );
    }

    if (metodo == 'Transferencia' &&
        (referenciaLimpia == null || referenciaLimpia.isEmpty)) {
      throw Exception(
        'La referencia es obligatoria '
        'para transferencias.',
      );
    }

    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'La sesión no es válida. '
        'Inicia sesión nuevamente.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.adminPersonalUrl}'
      '/$idPersonal/nomina',
    );

    late http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'periodoInicio': periodoInicio,
              'periodoFin': periodoFin,
              'monto': monto,
              'fechaPago': fechaPago,
              'metodo': metodo,
              'referencia': referenciaLimpia == null || referenciaLimpia.isEmpty
                  ? null
                  : referenciaLimpia,
              'observaciones':
                  observacionesLimpias == null || observacionesLimpias.isEmpty
                  ? null
                  : observacionesLimpias,
            }),
          )
          .timeout(_tiempoEspera);
    } on TimeoutException {
      throw PagoNominaResultadoIncierto(
        'La solicitud tardó demasiado. '
        'Comprueba el historial antes de '
        'registrar otro pago.',
      );
    } on http.ClientException {
      throw PagoNominaResultadoIncierto(
        'La conexión se interrumpió. '
        'Comprueba el historial antes de '
        'registrar otro pago.',
      );
    }

    // Un error del servidor no garantiza que
    // la operación no se haya realizado.
    if (respuesta.statusCode >= 500) {
      throw PagoNominaResultadoIncierto(
        'El servidor no pudo confirmar el resultado. '
        'Consulta los pagos registrados '
        'antes de intentar nuevamente.',
      );
    }

    if (respuesta.statusCode != 201) {
      _procesarError(respuesta);
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final idPersonalRespuesta = datos['idPersonal'];
      final idPagoRespuesta = datos['idPago'];

      final idDevuelto = int.parse(idPersonalRespuesta.toString());

      final idPago = int.parse(idPagoRespuesta.toString());

      if (idDevuelto != idPersonal || idPago <= 0) {
        throw const FormatException();
      }

      return idPago;
    } catch (_) {
      throw PagoNominaResultadoIncierto(
        'La respuesta del servidor fue inesperada. '
        'Verifica el historial antes de repetir '
        'el registro.',
      );
    }
  }

  // ==========================================
  // CANCELAR PAGO DE NOMINA
  //
  // PATCH /api/admin/personal/{id}/nomina/{idPago}/cancelacion
  // ==========================================

  Future<int> cancelarPagoNomina({
    required int idPersonal,
    required int idPago,
    required String motivo,
  }) async {
    if (idPersonal <= 0 || idPago <= 0) {
      throw Exception('El empleado o el pago no es válido.');
    }

    final motivoLimpio = motivo.trim();

    if (motivoLimpio.isEmpty) {
      throw Exception('El motivo de cancelación es obligatorio.');
    }

    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. '
        'Inicia sesión nuevamente.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.adminPersonalUrl}'
      '/$idPersonal/nomina/$idPago/cancelacion',
    );

    late http.Response respuesta;

    try {
      respuesta = await http
          .patch(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'motivo': motivoLimpio}),
          )
          .timeout(_tiempoEspera);
    } on TimeoutException {
      throw const PagoNominaResultadoIncierto(
        'El servidor tardó demasiado en responder. '
        'Revisa el historial antes de intentar '
        'cancelar nuevamente.',
      );
    } on http.ClientException {
      throw const PagoNominaResultadoIncierto(
        'Se perdió la conexión con el servidor. '
        'No es posible confirmar la cancelación. '
        'Revisa el historial.',
      );
    }

    if (respuesta.statusCode >= 500) {
      throw const PagoNominaResultadoIncierto(
        'El servidor no pudo confirmar el resultado. '
        'Actualiza el historial antes de '
        'intentar otra operación.',
      );
    }

    if (respuesta.statusCode != 200) {
      _procesarError(respuesta);
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final personalRespuesta = int.parse(datos['idPersonal'].toString());

      final pagoRespuesta = int.parse(datos['idPago'].toString());

      if (personalRespuesta != idPersonal || pagoRespuesta != idPago) {
        throw const FormatException();
      }

      return pagoRespuesta;
    } catch (_) {
      throw const PagoNominaResultadoIncierto(
        'El servidor respondió de forma inesperada. '
        'Consulta el historial para comprobar '
        'si el pago ya fue cancelado.',
      );
    }
  }
}

class PagoNominaResultadoIncierto implements Exception {
  final String mensaje;

  const PagoNominaResultadoIncierto(this.mensaje);

  @override
  String toString() => mensaje;
}
