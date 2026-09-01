import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _usuarioKey = 'usuario';

  Future<bool> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.authLocalUrl}/api/auth/login',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body);

    final token =
        data['token']?.toString();

    if (token == null ||
        token.isEmpty) {
      return false;
    }

    await guardarToken(
      token,
    );

    if (data['usuario'] != null) {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _usuarioKey,
        jsonEncode(
          data['usuario'],
        ),
      );
    }

    return true;
  }

  Future<Map<String, dynamic>> loginGoogle({
    required String googleToken,
  }) async {
    try {
      final response =
          await http.post(
        Uri.parse(
          '${ApiConfig.authGoogleUrl}/api/auth/login-google',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'token':
              googleToken,
        }),
      );

      if (response.statusCode != 200) {
        String mensaje =
            'No se pudo iniciar sesión con Google.';

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
        } catch (_) {}

        return {
          'ok': false,
          'mensaje': mensaje,
          'statusCode':
              response.statusCode,
        };
      }

      final data =
          jsonDecode(
        response.body,
      );

      final token =
          data['token']?.toString();

      if (token == null ||
          token.isEmpty) {
        return {
          'ok': false,
          'mensaje':
              'El servidor no devolvió un token de GymFlow.',
        };
      }

      await guardarToken(
        token,
      );

      if (data['usuario'] != null) {
        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          _usuarioKey,
          jsonEncode(
            data['usuario'],
          ),
        );
      }

      return {
        'ok': true,
        'mensaje':
            'Inicio de sesión con Google correcto.',
      };
    } catch (error) {
      return {
        'ok': false,
        'mensaje':
            'No se pudo conectar con el servidor de Google Login.',
        'error':
            error.toString(),
      };
    }
  }

  Future<void> guardarToken(
    String token,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );
  }

  Future<String?> obtenerToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _tokenKey,
    );
  }

  Future<bool> existeToken() async {
    final token =
        await obtenerToken();

    return token != null &&
        token.trim().isNotEmpty;
  }

  Future<void> guardarUsuario(
    Map<String, dynamic> usuario,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _usuarioKey,
      jsonEncode(
        usuario,
      ),
    );
  }

  Future<Map<String, dynamic>?>
      obtenerUsuarioGuardado() async {
    final prefs =
        await SharedPreferences.getInstance();

    final usuarioJson =
        prefs.getString(
      _usuarioKey,
    );

    if (usuarioJson == null ||
        usuarioJson.isEmpty) {
      return null;
    }

    try {
      final data =
          jsonDecode(
        usuarioJson,
      );

      if (data is Map<String, dynamic>) {
        return data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _tokenKey,
    );

    await prefs.remove(
      _usuarioKey,
    );
  }

  Future<bool> estaAutenticado() async {
    return existeToken();
  }
}