import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/mi_membresia.dart';
import 'auth_service.dart';

class MiMembresiaService {
  final AuthService _authService = AuthService();

  Future<MiMembresia> obtenerMiMembresia() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión no es válida. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.clienteAltaUrl}/api/clientes/mi-membresia',
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
          .timeout(const Duration(seconds: 35));
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Intenta actualizar nuevamente.',
      );
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }

    if (respuesta.statusCode == 200) {
      try {
        final datos = jsonDecode(respuesta.body);

        if (datos is! Map<String, dynamic>) {
          throw const FormatException();
        }

        return MiMembresia.fromJson(datos);
      } catch (_) {
        throw Exception(
          'El servidor devolvió información '
          'de membresía no válida.',
        );
      }
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    if (respuesta.statusCode == 403) {
      throw Exception(
        'Solo los usuarios con rol Cliente '
        'pueden consultar su membresía.',
      );
    }

    if (respuesta.statusCode == 404) {
      String mensaje =
          'No se encontró una membresía asociada '
          'a tu cuenta, o el endpoint todavía no '
          'está disponible en Render.';

      try {
        final datos = jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic>) {
          mensaje = datos['mensaje']?.toString() ?? mensaje;
        }
      } catch (_) {}

      throw Exception(mensaje);
    }

    if (respuesta.statusCode >= 500) {
      throw Exception(
        'El servicio de membresías no está disponible. '
        'Intenta más tarde.',
      );
    }

    throw Exception(
      'No se pudo consultar tu membresía '
      '(HTTP ${respuesta.statusCode}).',
    );
  }
}
