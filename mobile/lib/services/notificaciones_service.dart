import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/notificacion_gymflow.dart';
import 'auth_service.dart';

// GYMFLOW - SPRINT 8
// SERVICIO DE NOTIFICACIONES DEL USUARIO

class NotificacionesService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 50);

  // OBTENER TOKEN DE LA SESION

  Future<String> _obtenerToken() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. '
        'Inicia sesión nuevamente.',
      );
    }

    return token;
  }

  // PETICIONES AUTENTICADAS

  Future<http.Response> _solicitar(Uri uri, {required String metodo}) async {
    final token = await _obtenerToken();

    late http.Response respuesta;

    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      if (metodo == 'GET') {
        respuesta = await http
            .get(uri, headers: headers)
            .timeout(_tiempoEspera);
      } else if (metodo == 'PATCH') {
        respuesta = await http
            .patch(uri, headers: headers)
            .timeout(_tiempoEspera);
      } else {
        throw Exception('Método HTTP no permitido.');
      }
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Actualiza la consulta antes de repetir '
        'la operación.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor. '
        'Comprueba tu conexión.',
      );
    }

    if (respuesta.statusCode != 200) {
      _procesarError(respuesta);
    }

    return respuesta;
  }

  // ======================================
  // GET /api/notificaciones
  // ======================================

  Future<List<NotificacionGymflow>> obtenerNotificaciones() async {
    final uri = Uri.parse(ApiConfig.notificacionesUrl);

    final respuesta = await _solicitar(uri, metodo: 'GET');

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw const FormatException();
      }

      final notificaciones = <NotificacionGymflow>[];

      for (final elemento in datos) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException();
        }

        notificaciones.add(NotificacionGymflow.fromJson(elemento));
      }

      return notificaciones;
    } on FormatException {
      throw Exception(
        'El servidor devolvió notificaciones '
        'con formato no válido.',
      );
    }
  }

  // ======================================
  // GET /api/notificaciones/no-leidas
  // ======================================

  Future<int> obtenerNoLeidas() async {
    final uri = Uri.parse('${ApiConfig.notificacionesUrl}/no-leidas');

    final respuesta = await _solicitar(uri, metodo: 'GET');

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final valor = datos['noLeidas'];

      final total = valor is int
          ? valor
          : int.tryParse(valor?.toString() ?? '');

      if (total == null || total < 0) {
        throw const FormatException();
      }

      return total;
    } on FormatException {
      throw Exception(
        'El contador de notificaciones '
        'no tiene un formato válido.',
      );
    }
  }

  // ======================================
  // PATCH /api/notificaciones/{id}/lectura
  // ======================================

  Future<int> marcarComoLeida(int idNotificacion) async {
    if (idNotificacion <= 0) {
      throw Exception('El ID de notificación no es válido.');
    }

    final uri = Uri.parse(
      '${ApiConfig.notificacionesUrl}'
      '/$idNotificacion/lectura',
    );

    final respuesta = await _solicitar(uri, metodo: 'PATCH');

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final valor = datos['idNotificacion'];

      final idDevuelto = valor is int
          ? valor
          : int.tryParse(valor?.toString() ?? '');

      if (idDevuelto != idNotificacion) {
        throw const FormatException();
      }

      return idDevuelto!;
    } on FormatException {
      throw Exception(
        'No se pudo confirmar la lectura. '
        'Actualiza las notificaciones.',
      );
    }
  }

  // ======================================
  // ERRORES DE LA API
  // ======================================

  Never _procesarError(http.Response respuesta) {
    if (respuesta.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. '
        'Inicia sesión nuevamente.',
      );
    }

    if (respuesta.statusCode == 403) {
      throw Exception(
        'No tienes permisos para '
        'realizar esta operación.',
      );
    }

    if (respuesta.statusCode == 404) {
      throw Exception('La notificación no fue encontrada.');
    }

    String mensaje =
        'No fue posible completar la operación '
        '(código ${respuesta.statusCode}).';

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        final mensajeServidor =
            datos['mensaje']?.toString() ??
            datos['detail']?.toString() ??
            datos['title']?.toString();

        if (mensajeServidor != null && mensajeServidor.trim().isNotEmpty) {
          mensaje = mensajeServidor;
        }
      }
    } catch (_) {
      // Mantener mensaje predeterminado.
    }

    throw Exception(mensaje);
  }
}
