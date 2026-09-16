import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ClienteService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> registrarCliente({
    required String correo,
    required String password,
    required String nombreCompleto,
    required String telefono,
    required int idMembresia,
    required double costoMensual,
    required double costoAnual,
  }) async {
    final nombre = nombreCompleto.trim();
    final email = correo.trim();
    final telefonoLimpio = telefono.trim();

    if (nombre.isEmpty) {
      return {
        'ok': false,
        'mensaje': 'El nombre completo es obligatorio.',
      };
    }

    if (RegExp(r'\d').hasMatch(nombre)) {
      return {
        'ok': false,
        'mensaje': 'El nombre no puede contener números.',
      };
    }

    if (nombre.length < 3) {
      return {
        'ok': false,
        'mensaje': 'El nombre debe tener al menos 3 caracteres.',
      };
    }

    if (email.isEmpty) {
      return {
        'ok': false,
        'mensaje': 'El correo es obligatorio.',
      };
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      return {
        'ok': false,
        'mensaje': 'Ingresa un correo electrónico válido.',
      };
    }

    if (password.trim().isEmpty) {
      return {
        'ok': false,
        'mensaje': 'La contraseña es obligatoria.',
      };
    }

    if (password.length < 6) {
      return {
        'ok': false,
        'mensaje': 'La contraseña debe tener al menos 6 caracteres.',
      };
    }

    if (password.length > 72) {
      return {
        'ok': false,
        'mensaje': 'La contraseña es demasiado larga.',
      };
    }

    if (telefonoLimpio.isNotEmpty) {
      if (!RegExp(r'^\d{10}$').hasMatch(telefonoLimpio)) {
        return {
          'ok': false,
          'mensaje': 'El teléfono debe contener exactamente 10 dígitos.',
        };
      }
    }

    if (idMembresia <= 0) {
      return {
        'ok': false,
        'mensaje': 'Selecciona una membresía válida.',
      };
    }

    if (!costoMensual.isFinite ||
        costoMensual <= 0) {
      return {
        'ok': false,
        'mensaje': 'El costo mensual debe ser mayor a \$0.',
      };
    }

    if (!costoAnual.isFinite ||
        costoAnual <= 0) {
      return {
        'ok': false,
        'mensaje': 'El costo anual debe ser mayor a \$0.',
      };
    }

    if (costoMensual > 100000 ||
        costoAnual > 1000000) {
      return {
        'ok': false,
        'mensaje': 'Verifica los costos ingresados.',
      };
    }

    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      return {
        'ok': false,
        'mensaje':
            'Tu sesión no es válida. Inicia sesión nuevamente.',
      };
    }

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(
              '${ApiConfig.clienteAltaUrl}/api/clientes',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'Correo': email,
              'Password': password,
              'NombreCompleto': nombre,
              'Telefono': telefonoLimpio.isEmpty
                  ? null
                  : telefonoLimpio,
              'IdMembresia': idMembresia,
              'CostoMensual': costoMensual,
              'CostoAnual': costoAnual,
            }),
          )
          .timeout(
            const Duration(seconds: 25),
          );
    } on TimeoutException {
      return {
        'ok': false,
        'mensaje':
            'El servidor tardó demasiado en responder.',
      };
    } on http.ClientException {
      return {
        'ok': false,
        'mensaje':
            'No fue posible conectar con el servidor.',
      };
    } catch (_) {
      return {
        'ok': false,
        'mensaje':
            'Ocurrió un error al intentar registrar el cliente.',
      };
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      String mensaje =
          'Cliente registrado correctamente.';

      try {
        final data =
            jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          mensaje =
              data['mensaje']?.toString() ??
                  mensaje;
        }

        return {
          'ok': true,
          'mensaje': mensaje,
          'data': data,
        };
      } catch (_) {
        return {
          'ok': true,
          'mensaje': mensaje,
        };
      }
    }

    if (response.statusCode == 401) {
      return {
        'ok': false,
        'mensaje':
            'Tu sesión no es válida. Inicia sesión nuevamente.',
        'statusCode': 401,
      };
    }

    if (response.statusCode == 403) {
      return {
        'ok': false,
        'mensaje':
            'No tienes permiso para registrar clientes.',
        'statusCode': 403,
      };
    }

    String mensaje =
        'No se pudo registrar el cliente.';

    try {
      final data =
          jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        mensaje =
            data['mensaje']?.toString() ??
                data['message']?.toString() ??
                data['error']?.toString() ??
                mensaje;
      }
    } catch (_) {}

    return {
      'ok': false,
      'mensaje': mensaje,
      'statusCode': response.statusCode,
    };
  }
}