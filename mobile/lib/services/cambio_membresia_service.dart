import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

/// Cambia la membresia de un cliente desde Administracion o Recepcion.
/// PUT /api/clientes/{idCliente}/membresia (ClienteAltaService).
class CambioMembresiaService {
  final AuthService _auth = AuthService();

  Future<String> cambiarMembresia({
    required int idCliente,
    required int idMembresia,
  }) async {
    if (idCliente <= 0 || idMembresia <= 0) {
      throw Exception('Selecciona un cliente y una membresía válidos.');
    }

    final token = await _auth.obtenerToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.clienteAltaUrl}/api/clientes/$idCliente/membresia',
    );

    late http.Response respuesta;
    try {
      respuesta = await http
          .put(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'idMembresia': idMembresia}),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado. El cambio podría haberse realizado. '
        'Consulta al cliente antes de repetirlo.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo confirmar la respuesta del servidor. '
        'Verifica la membresía antes de repetir el cambio.',
      );
    }

    Map<String, dynamic> datos = {};
    try {
      final json = jsonDecode(respuesta.body);
      if (json is Map<String, dynamic>) datos = json;
    } catch (_) {
      // Se usan mensajes locales si la respuesta no es JSON.
    }

    if (respuesta.statusCode == 200) {
      if (datos['idCliente'] != idCliente ||
          datos['idMembresiaNueva'] != idMembresia) {
        throw Exception(
          'La respuesta del servidor no confirmó los datos solicitados. '
          'Consulta al cliente antes de repetir el cambio.',
        );
      }
      return datos['mensaje']?.toString() ??
          'Membresía actualizada correctamente.';
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente.');
    }
    if (respuesta.statusCode == 403) {
      throw Exception('No tienes permisos para cambiar la membresía.');
    }
    if (respuesta.statusCode == 404) {
      throw Exception(
        'Cliente no encontrado o el endpoint todavía no está desplegado.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw Exception(
        'El servidor respondió HTTP ${respuesta.statusCode}. '
        'El resultado del cambio es incierto. '
        'Consulta al cliente antes de repetir la operación.',
      );
    }

    final mensaje = datos['mensaje']?.toString();
    if (mensaje != null && mensaje.trim().isNotEmpty) {
      throw Exception(mensaje);
    }

    throw Exception(
      'No se pudo actualizar la membresía (HTTP ${respuesta.statusCode}).',
    );
  }
}
