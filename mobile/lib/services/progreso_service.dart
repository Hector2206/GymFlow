
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/progreso.dart';
import 'auth_service.dart';

class ProgresoService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera =
      Duration(seconds: 25);

  // ==========================================
  // OBTENER TOKEN JWT
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
  // REGISTRAR PROGRESO
  // POST /api/progreso
  // ==========================================

  Future<void> registrarProgreso({
    required int idEjercicio,
    required double pesoUtilizado,
  }) async {
    if (idEjercicio <= 0) {
      throw Exception(
        'Selecciona un ejercicio válido.',
      );
    }

    if (!pesoUtilizado.isFinite ||
        pesoUtilizado <= 0 ||
        pesoUtilizado > 99999999.99) {
      throw Exception(
        'Ingresa un peso válido mayor a cero.',
      );
    }

    final headers = await _headers();

    final body = {
      'idEjercicio': idEjercicio,
      'pesoUtilizado': pesoUtilizado,
    };

    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/progreso',
            ),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(
        response,
        codigosAceptados: {201},
      );
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Consulta tu historial antes de volver a guardar.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  // ==========================================
  // CONSULTAR MI HISTORIAL
  // GET /api/progreso
  // ==========================================

  Future<List<Progreso>> obtenerMiProgreso() async {
    final headers = await _headers();

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/progreso',
            ),
            headers: headers,
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response);

      return _convertirLista(response.body);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  // ==========================================
  // CONSULTAR PROGRESO POR EJERCICIO
  // GET /api/progreso/ejercicio/{idEjercicio}
  // ==========================================

  Future<List<Progreso>> obtenerProgresoPorEjercicio(
    int idEjercicio,
  ) async {
    if (idEjercicio <= 0) {
      throw Exception(
        'El ejercicio seleccionado no es válido.',
      );
    }

    final headers = await _headers();

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}'
              '/api/progreso/ejercicio/$idEjercicio',
            ),
            headers: headers,
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response);

      return _convertirLista(response.body);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  // ==========================================
  // CONVERTIR JSON A LISTA DE PROGRESOS
  // ==========================================

  List<Progreso> _convertirLista(String respuesta) {
    try {
      final data = jsonDecode(respuesta);

      if (data is! List) {
        throw const FormatException();
      }

      return data.map((registro) {
        if (registro is! Map<String, dynamic>) {
          throw const FormatException();
        }

        return Progreso.fromJson(registro);
      }).toList();
    } catch (_) {
      throw Exception(
        'El servidor devolvió datos de progreso '
        'con un formato no válido.',
      );
    }
  }

  // ==========================================
  // VALIDAR RESPUESTAS DEL SERVIDOR
  // ==========================================

  void _validarRespuesta(
    http.Response response, {
    Set<int> codigosAceptados = const {200},
  }) {
    if (codigosAceptados.contains(response.statusCode)) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para acceder al progreso.',
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
      // Mantener mensaje genérico si no hay JSON.
    }

    throw Exception(mensaje);
  }
}
