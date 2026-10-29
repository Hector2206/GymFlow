import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/asistencia_personal.dart';
import 'auth_service.dart';

class AdminAsistenciaPersonalService {
  final AuthService _auth = AuthService();

  static const _timeout = Duration(seconds: 50);

  static const _url = '${ApiConfig.adminPersonalUrl}/asistencias';

  Future<Map<String, String>> _headers() async {
    final token = await _auth.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _solicitar(
    String metodo,
    Uri uri, {
    Map<String, dynamic>? cuerpo,
  }) async {
    try {
      final headers = await _headers();

      late final http.Response respuesta;

      if (metodo == 'GET') {
        respuesta = await http.get(uri, headers: headers).timeout(_timeout);
      } else if (metodo == 'POST') {
        respuesta = await http
            .post(uri, headers: headers, body: jsonEncode(cuerpo))
            .timeout(_timeout);
      } else if (metodo == 'PATCH') {
        respuesta = await http
            .patch(uri, headers: headers, body: jsonEncode(cuerpo))
            .timeout(_timeout);
      } else {
        throw Exception('Método HTTP no permitido.');
      }

      if (![200, 201].contains(respuesta.statusCode)) {
        _procesarError(respuesta);
      }

      return respuesta;
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado. '
        'Consulta el historial antes de repetir una operación.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con Backend. '
        'Comprueba el historial antes de reintentar.',
      );
    }
  }

  Never _procesarError(http.Response respuesta) {
    String mensaje;

    switch (respuesta.statusCode) {
      case 400:
        mensaje = 'Los datos enviados no son válidos.';
        break;
      case 401:
        mensaje = 'Tu sesión expiró.';
        break;
      case 403:
        mensaje = 'Solo Administrador puede realizar esta operación.';
        break;
      case 409:
        mensaje =
            'La asistencia ya existe, tiene salida o presenta un conflicto.';
        break;
      default:
        mensaje =
            'No se pudo completar la operación '
            '(HTTP ${respuesta.statusCode}).';
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        final detalle =
            datos['mensaje']?.toString() ?? datos['detail']?.toString();

        if (detalle != null && detalle.trim().isNotEmpty) {
          mensaje = detalle;
        }
      }
    } catch (_) {
      // Mantener el mensaje anterior.
    }

    throw Exception(mensaje);
  }

  Map<String, dynamic> _objeto(String contenido) {
    final datos = jsonDecode(contenido);

    if (datos is! Map<String, dynamic>) {
      throw const FormatException('Respuesta inválida de Backend.');
    }

    return datos;
  }

  Future<List<AsistenciaPersonal>> obtenerHistorial({
    int? idPersonal,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final parametros = <String, String>{};

    if (idPersonal != null) {
      parametros['idPersonal'] = '$idPersonal';
    }

    if (fechaInicio != null && fechaInicio.isNotEmpty) {
      parametros['fechaInicio'] = fechaInicio;
    }

    if (fechaFin != null && fechaFin.isNotEmpty) {
      parametros['fechaFin'] = fechaFin;
    }

    final uri = Uri.parse(
      _url,
    ).replace(queryParameters: parametros.isEmpty ? null : parametros);

    final respuesta = await _solicitar('GET', uri);
    final datos = jsonDecode(respuesta.body);

    if (datos is! List) {
      throw const FormatException('Historial con formato inválido.');
    }

    return datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Asistencia inválida.');
      }

      return AsistenciaPersonal.fromJson(item);
    }).toList();
  }

  Future<int> registrarEntrada({
    required int idPersonal,
    required String fecha,
    required String horaEntrada,
  }) async {
    final respuesta = await _solicitar(
      'POST',
      Uri.parse(_url),
      cuerpo: {
        'idPersonal': idPersonal,
        'fecha': fecha,
        'horaEntrada': horaEntrada,
      },
    );

    final id = _objeto(respuesta.body)['idAsistenciaPersonal'];

    if (id is int && id > 0) return id;

    throw const FormatException(
      'No se pudo verificar el folio de entrada. '
      'Consulta el historial.',
    );
  }

  Future<int> registrarSalida({
    required int idAsistencia,
    required String horaSalida,
  }) async {
    if (idAsistencia <= 0) {
      throw Exception('ID de asistencia inválido.');
    }

    final respuesta = await _solicitar(
      'PATCH',
      Uri.parse('$_url/$idAsistencia/salida'),
      cuerpo: {'horaSalida': horaSalida},
    );

    final id = _objeto(respuesta.body)['idAsistenciaPersonal'];

    if (id is int && id == idAsistencia) return id;

    throw const FormatException(
      'No se pudo verificar la salida. Consulta el historial.',
    );
  }
}
