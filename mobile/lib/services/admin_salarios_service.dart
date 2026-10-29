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
}
