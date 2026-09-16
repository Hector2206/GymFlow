import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cliente_resumen.dart';
import 'auth_service.dart';

class ClienteConsultaService {
  final AuthService _authService =
      AuthService();

  Future<List<ClienteResumen>>
      obtenerClientes() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.clienteAltaUrl}/api/clientes',
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
        'No tienes permiso para consultar clientes.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'No fue posible cargar los clientes.',
      );
    }

    try {
      final data =
          jsonDecode(response.body);

      if (data is! List) {
        throw Exception(
          'El servidor devolvió una respuesta no válida.',
        );
      }

      final clientes = data
          .whereType<Map<String, dynamic>>()
          .map(ClienteResumen.fromJson)
          .where(
            (cliente) =>
                cliente.idCliente > 0 &&
                cliente.nombreCompleto.trim().isNotEmpty,
          )
          .toList();

      clientes.sort(
        (a, b) => a.nombreCompleto
            .toLowerCase()
            .compareTo(
              b.nombreCompleto.toLowerCase(),
            ),
      );

      return clientes;
    } on FormatException {
      throw Exception(
        'El servidor devolvió información no válida.',
      );
    }
  }
}