import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ClienteService {
  Future<Map<String, dynamic>> registrarCliente({
    required String correo,
    required String password,
    required String idAsistencia,
    required String nombreCompleto,
    required String telefono,
    required int idMembresia,
    required double costoMensual,
    required double costoAnual,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null ||
        token.isEmpty) {
      return {
        'ok': false,
        'mensaje': 'No hay una sesión válida.',
      };
    }

    final response =
        await http.post(
      Uri.parse(
        '${ApiConfig.clienteAltaUrl}/api/clientes',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode({
        'Correo':
            correo.trim(),
        'Password':
            password,
        'IdAsistencia':
            idAsistencia.trim(),
        'NombreCompleto':
            nombreCompleto.trim(),
        'Telefono':
            telefono.trim(),
        'IdMembresia':
            idMembresia,
        'CostoMensual':
            costoMensual,
        'CostoAnual':
            costoAnual,
      }),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {
          'ok': true,
          'mensaje':
              'Cliente registrado correctamente.',
        };
      }

      try {
        final data =
            jsonDecode(
          response.body,
        );

        return {
          'ok': true,
          'mensaje':
              data['mensaje']?.toString() ??
                  'Cliente registrado correctamente.',
          'data':
              data,
        };
      } catch (_) {
        return {
          'ok': true,
          'mensaje':
              'Cliente registrado correctamente.',
        };
      }
    }

    String mensaje =
        'No se pudo registrar el cliente.';

    try {
      final data =
          jsonDecode(
        response.body,
      );

      mensaje =
          data['mensaje']?.toString() ??
              data['message']?.toString() ??
              data['error']?.toString() ??
              mensaje;
    } catch (_) {
      if (response.body.isNotEmpty) {
        mensaje =
            response.body;
      }
    }

    return {
      'ok': false,
      'mensaje': mensaje,
      'statusCode':
          response.statusCode,
    };
  }
}