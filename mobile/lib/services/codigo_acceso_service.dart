import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/mi_codigo_acceso.dart';
import 'auth_service.dart';

class CodigoAccesoService {
  final AuthService _authService =
      AuthService();

  Future<MiCodigoAcceso> obtenerMiCodigo() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'No hay una sesión válida.',
      );
    }

    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.clienteAltaUrl}/api/clientes/mi-codigo-acceso',
      ),
      headers: {
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(
        response.body,
      );

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'La respuesta del servidor no es válida.',
        );
      }

      return MiCodigoAcceso.fromJson(
        data,
      );
    }

    String mensaje =
        'No se pudo consultar el código de acceso.';

    try {
      final data =
          jsonDecode(
        response.body,
      );

      if (data is Map<String, dynamic>) {
        mensaje =
            data['mensaje']?.toString() ??
                data['message']?.toString() ??
                data['error']?.toString() ??
                mensaje;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        mensaje =
            response.body.trim();
      }
    }

    throw Exception(
      mensaje,
    );
  }
}