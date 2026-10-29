import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/pago_cliente.dart';
import 'auth_service.dart';

/// Una operación pendiente mantiene la misma clave en cada reintento.
class PagoPendiente {
  final int idCliente;
  final String tipoPago;
  final String clave;

  const PagoPendiente({
    required this.idCliente,
    required this.tipoPago,
    required this.clave,
  });

  Map<String, dynamic> toJson() => {
    'idCliente': idCliente,
    'tipoPago': tipoPago,
    'clave': clave,
  };

  factory PagoPendiente.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['idCliente']?.toString() ?? '');
    final tipo = json['tipoPago']?.toString() ?? '';
    final clave = json['clave']?.toString() ?? '';
    if (id == null ||
        id <= 0 ||
        (tipo != 'Mensualidad' && tipo != 'Anualidad') ||
        !RegExp(
          r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
        ).hasMatch(clave)) {
      throw const FormatException('El pago pendiente guardado no es válido.');
    }
    return PagoPendiente(idCliente: id, tipoPago: tipo, clave: clave);
  }
}

/// Si no sabemos si el servidor recibió el pago, NO generar otro UUID.
class PagoResultadoInciertoException implements Exception {
  final String mensaje;
  const PagoResultadoInciertoException(this.mensaje);
  @override
  String toString() => mensaje;
}

class ResultadoRegistroPago {
  final bool pagoRegistrado;
  final bool pagoRepetido;
  final int idPago;
  final bool esRenovacion;
  final int idCliente;
  final double monto;
  final String tipoPago;
  final String fechaVencimiento;
  final bool membresiaActiva;
  final String mensaje;

  const ResultadoRegistroPago({
    required this.pagoRegistrado,
    required this.pagoRepetido,
    required this.idPago,
    required this.esRenovacion,
    required this.idCliente,
    required this.monto,
    required this.tipoPago,
    required this.fechaVencimiento,
    required this.membresiaActiva,
    required this.mensaje,
  });

  factory ResultadoRegistroPago.fromJson(Map<String, dynamic> json) {
    final idPago = int.tryParse(json['idPago']?.toString() ?? '');
    final idCliente = int.tryParse(json['idCliente']?.toString() ?? '');
    final monto = double.tryParse(json['monto']?.toString() ?? '');
    final tipo = json['tipoPago']?.toString() ?? '';
    if (json['pagoRegistrado'] != true ||
        idPago == null ||
        idPago <= 0 ||
        idCliente == null ||
        idCliente <= 0 ||
        monto == null ||
        !monto.isFinite ||
        monto <= 0 ||
        (tipo != 'Mensualidad' && tipo != 'Anualidad')) {
      throw const FormatException('La confirmación del pago no es válida.');
    }
    return ResultadoRegistroPago(
      pagoRegistrado: true,
      pagoRepetido: json['pagoRepetido'] == true,
      idPago: idPago,
      esRenovacion: json['esRenovacion'] == true,
      idCliente: idCliente,
      monto: monto,
      tipoPago: tipo,
      fechaVencimiento: json['fechaVencimiento']?.toString() ?? '',
      membresiaActiva: json['membresiaActiva'] == true,
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }
}

class PagoService {
  final AuthService _authService = AuthService();
  static const _timeout = Duration(seconds: 35);
  static const _prefijo = 'gymflow_pago_pendiente_v1_';

  Future<String> _obtenerToken() async {
    final token = await _authService.obtenerToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión no es válida. Inicia sesión nuevamente.');
    }
    return token;
  }

  /// Aislar operaciones por usuario; nunca compartir pendientes entre cuentas.
  String _claveDeAlmacenamiento(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) throw const FormatException();
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );
      if (payload is! Map<String, dynamic>) throw const FormatException();
      final sub = payload['sub']?.toString() ?? '';
      if (!RegExp(r'^\d+$').hasMatch(sub)) throw const FormatException();
      return '$_prefijo$sub';
    } catch (_) {
      throw Exception('No se pudo identificar al usuario de la sesión.');
    }
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<PagoPendiente?> obtenerPagoPendiente() async {
    final token = await _obtenerToken();
    final prefs = await SharedPreferences.getInstance();
    final almacen = prefs.getString(_claveDeAlmacenamiento(token));
    if (almacen == null) return null;
    try {
      final json = jsonDecode(almacen);
      if (json is! Map<String, dynamic>) throw const FormatException();
      return PagoPendiente.fromJson(json);
    } catch (_) {
      // No descartar una clave dañada automáticamente; podría haber pago.
      throw Exception(
        'Hay un pago pendiente que no se puede recuperar. '
        'No registres otro cobro sin revisar el historial.',
      );
    }
  }

  Future<PagoPendiente> _obtenerOCrearOperacion(
    int idCliente,
    String tipoPago,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final llaveLocal = _claveDeAlmacenamiento(token);
    final anterior = prefs.getString(llaveLocal);
    if (anterior != null) {
      final pendiente = await obtenerPagoPendiente();
      if (pendiente == null) throw StateError('Falta la operación pendiente.');
      if (pendiente.idCliente != idCliente || pendiente.tipoPago != tipoPago) {
        throw Exception(
          'Hay otro pago pendiente de confirmación. '
          'Resuélvelo antes de registrar una operación nueva.',
        );
      }
      return pendiente;
    }
    final nuevo = PagoPendiente(
      idCliente: idCliente,
      tipoPago: tipoPago,
      clave: _uuidV4(),
    );
    final guardado = await prefs.setString(
      llaveLocal,
      jsonEncode(nuevo.toJson()),
    );
    if (!guardado) {
      throw Exception('No se pudo guardar el identificador del pago.');
    }
    return nuevo;
  }

  /// Borrar solo después de una confirmación válida del servidor.
  Future<void> _confirmarOperacion(String token, String clave) async {
    final prefs = await SharedPreferences.getInstance();
    final llaveLocal = _claveDeAlmacenamiento(token);
    final raw = prefs.getString(llaveLocal);
    if (raw == null) return;
    final pendiente = PagoPendiente.fromJson(jsonDecode(raw));
    if (pendiente.clave == clave) {
      final eliminado = await prefs.remove(llaveLocal);
      if (!eliminado) {
        throw const PagoResultadoInciertoException(
          'El pago se confirmó, pero no se pudo liberar la operación local. '
          'No generes otro cobro; revisa el historial.',
        );
      }
    }
  }

  String _mensajeError(http.Response respuesta, String alternativa) {
    try {
      final data = jsonDecode(respuesta.body);
      if (data is Map<String, dynamic>) {
        return data['mensaje']?.toString() ??
            data['message']?.toString() ??
            data['detail']?.toString() ??
            alternativa;
      }
    } catch (_) {}
    return alternativa;
  }

  /// POST /api/pagos — body SOLO idCliente y tipoPago.
  /// En timeout/error 5xx se conserva el UUID para un reintento seguro.
  Future<ResultadoRegistroPago> registrarPago({
    required int idCliente,
    required String tipoPago,
  }) async {
    if (idCliente <= 0) throw Exception('Selecciona un cliente válido.');
    if (tipoPago != 'Mensualidad' && tipoPago != 'Anualidad') {
      throw Exception('Selecciona un concepto de pago válido.');
    }
    final token = await _obtenerToken();
    final operacion = await _obtenerOCrearOperacion(idCliente, tipoPago, token);

    late http.Response respuesta;
    try {
      respuesta = await http
          .post(
            Uri.parse(ApiConfig.pagosUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Idempotency-Key': operacion.clave,
            },
            body: jsonEncode({'idCliente': idCliente, 'tipoPago': tipoPago}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const PagoResultadoInciertoException(
        'La solicitud tardó demasiado. El pago pudo registrarse. '
        'Presiona Reintentar el mismo pago para usar el UUID original.',
      );
    } on http.ClientException {
      throw const PagoResultadoInciertoException(
        'Se perdió la conexión y el resultado del pago es incierto. '
        'El reintento conservará el mismo UUID.',
      );
    } catch (e) {
      throw PagoResultadoInciertoException(
        'No se pudo confirmar el cobro: $e. '
        'Se conserva el UUID para reintentar.',
      );
    }

    if (respuesta.statusCode >= 500) {
      throw const PagoResultadoInciertoException(
        'El servidor falló y el resultado es incierto. '
        'Reintenta la operación con la misma clave.',
      );
    }
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      ResultadoRegistroPago resultado;
      try {
        final data = jsonDecode(respuesta.body);
        if (data is! Map<String, dynamic>) throw const FormatException();
        resultado = ResultadoRegistroPago.fromJson(data);
        if (resultado.idCliente != idCliente ||
            resultado.tipoPago != tipoPago) {
          throw const FormatException();
        }
      } catch (_) {
        throw const PagoResultadoInciertoException(
          'El servidor respondió, pero no se pudo validar la confirmación. '
          'Reintenta con el mismo UUID.',
        );
      }
      await _confirmarOperacion(token, operacion.clave);
      return resultado;
    }
    if (respuesta.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente. '
        'El pago pendiente se conserva.',
      );
    }
    if (respuesta.statusCode == 403) {
      throw Exception(
        'No tienes permiso para registrar pagos. '
        'La operación permanece pendiente.',
      );
    }
    if (respuesta.statusCode == 404) {
      throw Exception(
        'El cliente o endpoint no existe. '
        'Verifica el historial antes de continuar.',
      );
    }
    throw Exception(
      _mensajeError(
        respuesta,
        'El servidor rechazó el pago (HTTP ${respuesta.statusCode}). '
        'No generes otra operación sin revisar el historial.',
      ),
    );
  }

  // Consultas existentes que usan otras pantallas: se mantienen intactas.
  Future<List<PagoCliente>> consultarPagosCliente(int idCliente) async {
    if (idCliente <= 0) throw Exception('Selecciona un cliente válido.');
    final token = await _obtenerToken();
    late http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.pagosUrl}/cliente/$idCliente'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en consultar los pagos.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        _mensajeError(response, 'No se pudieron consultar los pagos.'),
      );
    }
    return _obtenerListaPagos(response.body);
  }

  Future<List<PagoCliente>> obtenerMisPagos() async {
    final token = await _obtenerToken();
    late http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.pagosUrl}/mis-pagos'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en consultar tus pagos.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        _mensajeError(response, 'No se pudieron consultar tus pagos.'),
      );
    }
    return _obtenerListaPagos(response.body);
  }

  List<PagoCliente> _obtenerListaPagos(String body) {
    try {
      final data = jsonDecode(body);
      final List<dynamic> lista;
      if (data is Map<String, dynamic> && data['pagos'] is List) {
        lista = data['pagos'] as List;
      } else if (data is List) {
        lista = data;
      } else {
        throw const FormatException();
      }
      final pagos = lista.map((item) {
        if (item is! Map<String, dynamic>) throw const FormatException();
        return PagoCliente.fromJson(item);
      }).toList();
      pagos.sort((a, b) {
        final fa = a.fechaTransaccionDateTime;
        final fb = b.fechaTransaccionDateTime;
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });
      return pagos;
    } catch (_) {
      throw Exception('El servidor devolvió un historial de pagos no válido.');
    }
  }
}
