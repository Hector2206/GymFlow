
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/entrenador_resumen.dart';
import 'auth_service.dart';

class AsignacionEntrenadorService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera =
      Duration(seconds: 25);

  // ==========================================
  // AUTENTICACIÓN JWT
  // ==========================================

  Future<Map<String, String>> _headers() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // LISTAR ENTRENADORES ACTIVOS
  // GET /api/entrenadores
  // ==========================================

  Future<List<EntrenadorResumen>>
      obtenerEntrenadores() async {
    final headers = await _headers();

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.clienteAltaUrl}/api/entrenadores',
            ),
            headers: headers,
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response);

      final data = jsonDecode(response.body);

      if (data is! List) {
        throw const FormatException();
      }

      final entrenadores = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException();
        }

        return EntrenadorResumen.fromJson(item);
      }).where((entrenador) {
        return entrenador.idEntrenador > 0 &&
            entrenador.nombreCompleto.trim().isNotEmpty;
      }).toList();

      entrenadores.sort(
        (a, b) => a.nombreCompleto
            .toLowerCase()
            .compareTo(b.nombreCompleto.toLowerCase()),
      );

      return entrenadores;
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    } on FormatException {
      throw Exception(
        'El servidor devolvió una lista de entrenadores '
        'con formato no válido.',
      );
    }
  }

  // ==========================================
  // ASIGNAR O CAMBIAR ENTRENADOR
  // PUT /api/clientes/{idCliente}/entrenador
  // ==========================================

  Future<Map<String, dynamic>> asignarEntrenador({
    required int idCliente,
    required int idEntrenador,
  }) async {
    if (idCliente <= 0) {
      throw Exception('Selecciona un cliente válido.');
    }

    if (idEntrenador <= 0) {
      throw Exception('Selecciona un entrenador válido.');
    }

    final headers = await _headers();

    try {
      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.clienteAltaUrl}'
              '/api/clientes/$idCliente/entrenador',
            ),
            headers: headers,
            body: jsonEncode({
              'idEntrenador': idEntrenador,
            }),
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response);

      return _convertirObjeto(response.body);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Actualiza la lista de clientes antes de reintentar.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  // ==========================================
  // QUITAR ENTRENADOR ASIGNADO
  // DELETE /api/clientes/{idCliente}/entrenador
  // ==========================================

  Future<Map<String, dynamic>> quitarEntrenador(
    int idCliente,
  ) async {
    if (idCliente <= 0) {
      throw Exception('Selecciona un cliente válido.');
    }

    final headers = await _headers();

    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.clienteAltaUrl}'
              '/api/clientes/$idCliente/entrenador',
            ),
            headers: headers,
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response);

      return _convertirObjeto(response.body);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Actualiza la lista de clientes antes de reintentar.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  // ==========================================
  // CONVERTIR RESPUESTA JSON
  // ==========================================

  Map<String, dynamic> _convertirObjeto(String body) {
    try {
      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      // Respuesta inválida.
    }

    throw Exception(
      'El servidor devolvió una respuesta no válida.',
    );
  }

  // ==========================================
  // VALIDAR RESPUESTA DE BACKEND
  // ==========================================

  void _validarRespuesta(http.Response response) {
    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Esta operación está disponible '
        'únicamente para Recepción.',
      );
    }

    String mensaje =
        'No fue posible procesar la solicitud '
        '(código ${response.statusCode}).';

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        mensaje =
            data['mensaje']?.toString() ??
            data['detail']?.toString() ??
            data['title']?.toString() ??
            mensaje;
      }
    } catch (_) {
      // Conservar el mensaje predeterminado.
    }

    throw Exception(mensaje);
  }
}
