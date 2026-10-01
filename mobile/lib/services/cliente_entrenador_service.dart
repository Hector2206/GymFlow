import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ClienteEntrenadorService {
  final AuthService _authService =
      AuthService();

  Future<List<dynamic>> obtenerMisClientes() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Sesión no válida. Inicia sesión nuevamente.',
      );
    }

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/entrenador/mis-clientes',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 25),
          );
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar tus clientes.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'No fue posible cargar tus clientes. Código: ${response.statusCode}',
      );
    }

    try {
      final data =
          jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'El servidor devolvió una respuesta no válida.',
        );
      }

      final clientes =
          data['clientes'];

      if (clientes is! List) {
        throw Exception(
          'El servidor no devolvió la lista de clientes.',
        );
      }

      return clientes;
    } on FormatException {
      throw Exception(
        'El servidor devolvió información no válida.',
      );
    }
  }
}