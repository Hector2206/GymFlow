import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

// GYMFLOW - REGISTRO DE CLIENTES CON PRECIOS OFICIALES
// Contrato: POST /api/clientes no recibe costos. Solo recibe IdMembresia.
class ClienteService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> registrarCliente({
    required String correo,
    required String password,
    required String nombreCompleto,
    required String telefono,
    required int idMembresia,
  }) async {
    final nombre = nombreCompleto.trim();
    final email = correo.trim().toLowerCase();
    final telefonoLimpio = telefono.trim();

    if (nombre.length < 3 ||
        nombre.length > 100 ||
        RegExp(r'\d').hasMatch(nombre)) {
      return {'ok': false, 'mensaje': 'Ingresa un nombre completo valido.'};
    }
    if (email.length > 150 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return {'ok': false, 'mensaje': 'Ingresa un correo electronico valido.'};
    }
    if (password.trim().isEmpty ||
        password.length < 6 ||
        password.length > 72) {
      return {
        'ok': false,
        'mensaje': 'La contrasena debe tener entre 6 y 72 caracteres.',
      };
    }
    if (telefonoLimpio.isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(telefonoLimpio)) {
      return {'ok': false, 'mensaje': 'El telefono debe tener 10 digitos.'};
    }
    if (idMembresia <= 0) {
      return {'ok': false, 'mensaje': 'Selecciona una membresia activa.'};
    }

    final token = await _authService.obtenerToken();
    if (token == null || token.trim().isEmpty) {
      return {
        'ok': false,
        'mensaje': 'Tu sesion no es valida. Inicia sesion nuevamente.',
      };
    }

    late http.Response respuesta;
    try {
      respuesta = await http
          .post(
            Uri.parse('${ApiConfig.clienteAltaUrl}/api/clientes'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'Correo': email,
              'Password': password,
              'NombreCompleto': nombre,
              'Telefono': telefonoLimpio.isEmpty ? null : telefonoLimpio,
              'IdMembresia': idMembresia,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      return {
        'ok': false,
        'mensaje':
            'No se confirmo el registro. Verifica el directorio antes de reintentar.',
        'resultadoIncierto': true,
      };
    } on http.ClientException {
      return {
        'ok': false,
        'mensaje':
            'Se interrumpio la conexion. Verifica si el cliente fue registrado antes de reintentar.',
        'resultadoIncierto': true,
      };
    } catch (_) {
      return {
        'ok': false,
        'mensaje':
            'No fue posible confirmar el registro. Revisa el directorio.',
        'resultadoIncierto': true,
      };
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      try {
        final data = jsonDecode(respuesta.body);
        return {
          'ok': true,
          'mensaje': data is Map<String, dynamic>
              ? data['mensaje']?.toString() ??
                    'Cliente registrado correctamente.'
              : 'Cliente registrado correctamente.',
        };
      } catch (_) {
        return {'ok': true, 'mensaje': 'Cliente registrado correctamente.'};
      }
    }

    if (respuesta.statusCode == 401) {
      return {
        'ok': false,
        'mensaje': 'Tu sesion no es valida. Inicia sesion nuevamente.',
      };
    }
    if (respuesta.statusCode == 403) {
      return {
        'ok': false,
        'mensaje': 'No tienes permiso para registrar clientes.',
      };
    }
    if (respuesta.statusCode >= 500) {
      return {
        'ok': false,
        'mensaje':
            'El servidor no confirmo el resultado. Revisa si el cliente ya existe antes de repetir el registro.',
        'resultadoIncierto': true,
      };
    }

    String mensaje = 'No fue posible registrar el cliente.';
    try {
      final datos = jsonDecode(respuesta.body);
      if (datos is Map<String, dynamic>) {
        mensaje =
            datos['mensaje']?.toString() ??
            datos['message']?.toString() ??
            datos['error']?.toString() ??
            mensaje;
      }
    } catch (_) {
      // Se conserva mensaje predeterminado.
    }
    return {
      'ok': false,
      'mensaje': mensaje,
      'statusCode': respuesta.statusCode,
    };
  }
}
