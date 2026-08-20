import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      'https://projectgym-5hpt.onrender.com';

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'correo': correo,
          'password': password,
        }),
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {
            'mensaje': response.body,
          };
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'ok': true,
          'statusCode': response.statusCode,
          'data': data,
        };
      }

      return {
        'ok': false,
        'statusCode': response.statusCode,
        'data': data,
        'mensaje':
          data['mensaje'] ??
        'Error ${response.statusCode}: No se pudo iniciar sesión',
};
    } catch (e) {
      return {
        'ok': false,
        'statusCode': 0,
        'mensaje': 'No se pudo conectar con el servidor',
      };
    }
  }
}