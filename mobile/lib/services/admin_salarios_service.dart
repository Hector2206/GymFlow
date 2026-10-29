import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_salario.dart';
import 'auth_service.dart';

// GYMFLOW - SPRINT 7
// CONSULTA DEL HISTORIAL SALARIAL

class AdminSalariosService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 50);

  // GET /api/admin/personal/{id}/salarios

  Future<List<AdminSalario>> obtenerHistorial(int idPersonal) async {
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
      '/$idPersonal/salarios',
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
      throw Exception('El servidor tardó demasiado en responder.');
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

      final historial = <AdminSalario>[];

      for (final elemento in datos) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException();
        }

        final salario = AdminSalario.fromJson(elemento);

        if (salario.idPersonal != idPersonal) {
          throw const FormatException();
        }

        historial.add(salario);
      }

      return historial;
    } on FormatException {
      throw Exception(
        'El servidor devolvió un historial '
        'salarial con formato no válido.',
      );
    }
  }

  // ERRORES DE LA API

  Never _procesarError(http.Response respuesta) {
    if (respuesta.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. '
        'Inicia sesión nuevamente.',
      );
    }

    if (respuesta.statusCode == 403) {
      throw Exception('No tienes permisos para consultar salarios.');
    }

    if (respuesta.statusCode == 404) {
      throw Exception('El empleado no fue encontrado.');
    }

    String mensaje =
        'No fue posible consultar el historial '
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
      // Mantener el mensaje predeterminado.
    }

    throw Exception(mensaje);
  }

  // ==========================================
  // ACTUALIZAR SUELDO DEL EMPLEADO
  //
  // POST /api/admin/personal/{id}/salarios
  // ==========================================

  Future<int> cambiarSalario({
    required int idPersonal,
    required String montoTexto,
    required String vigenteDesde,
    required String motivo,
  }) async {
    if (idPersonal <= 0) {
      throw Exception('El ID del empleado no es válido.');
    }

    final montoLimpio = montoTexto.trim();
    final motivoLimpio = motivo.trim();

    if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(montoLimpio)) {
      throw Exception(
        'El monto debe estar entre 0 y '
        '99999999.99, con máximo dos decimales.',
      );
    }

    if (motivoLimpio.isEmpty) {
      throw Exception('Escribe el motivo del cambio salarial.');
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(vigenteDesde)) {
      throw Exception('La fecha de vigencia no es válida.');
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
      '/$idPersonal/salarios',
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
              'monto': double.parse(montoLimpio),
              'vigenteDesde': vigenteDesde,
              'motivo': motivoLimpio,
            }),
          )
          .timeout(_tiempoEspera);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Verifica el historial antes de reintentar.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible confirmar la conexión. '
        'Verifica el historial antes de reintentar.',
      );
    }

    if (respuesta.statusCode != 201) {
      String mensaje =
          'No fue posible actualizar el sueldo '
          '(código ${respuesta.statusCode}).';

      if (respuesta.statusCode == 401) {
        mensaje = 'Tu sesión ha expirado.';
      } else if (respuesta.statusCode == 403) {
        mensaje = 'No tienes permisos para cambiar sueldos.';
      }

      try {
        final datos = jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic>) {
          mensaje =
              datos['mensaje']?.toString() ??
              datos['detail']?.toString() ??
              datos['title']?.toString() ??
              mensaje;
        }
      } catch (_) {
        // Conservar mensaje predeterminado.
      }

      throw Exception(mensaje);
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final idRespuesta = datos['idPersonal'];
      final idSalarioRespuesta = datos['idSalario'];

      final idDevuelto = idRespuesta is num
          ? idRespuesta.toInt()
          : int.parse(idRespuesta.toString());

      final idSalario = idSalarioRespuesta is num
          ? idSalarioRespuesta.toInt()
          : int.parse(idSalarioRespuesta.toString());

      if (idDevuelto != idPersonal || idSalario <= 0) {
        throw const FormatException();
      }

      return idSalario;
    } on FormatException {
      throw Exception(
        'El servidor respondió de forma inesperada. '
        'Consulta el historial antes de reintentar.',
      );
    }
  }
}
