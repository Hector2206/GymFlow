import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/progreso.dart';
import 'auth_service.dart';

class ProgresoService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 25);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión no es válida. Inicia sesión nuevamente.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // POST /api/progreso
  // Backend recibe fechaEntrenamiento como YYYY-MM-DD (opcional).
  Future<void> registrarProgreso({
    required int idEjercicio,
    required double pesoUtilizado,
    DateTime? fechaEntrenamiento,
  }) async {
    if (idEjercicio <= 0) {
      throw Exception('Selecciona un ejercicio válido.');
    }

    if (!pesoUtilizado.isFinite ||
        pesoUtilizado <= 0 ||
        pesoUtilizado > 99999999.99) {
      throw Exception('Ingresa un peso válido mayor a cero.');
    }

    if (fechaEntrenamiento != null) {
      final hoy = DateTime.now();
      final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
      final elegidaSinHora = DateTime(
        fechaEntrenamiento.year,
        fechaEntrenamiento.month,
        fechaEntrenamiento.day,
      );
      if (elegidaSinHora.isAfter(hoySinHora)) {
        throw Exception('No puedes registrar una fecha futura.');
      }
    }

    final headers = await _headers();
    final body = <String, dynamic>{
      'idEjercicio': idEjercicio,
      'pesoUtilizado': pesoUtilizado,
      if (fechaEntrenamiento != null)
        'fechaEntrenamiento':
            '${fechaEntrenamiento.year.toString().padLeft(4, '0')}-'
            '${fechaEntrenamiento.month.toString().padLeft(2, '0')}-'
            '${fechaEntrenamiento.day.toString().padLeft(2, '0')}',
    };

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.rutinaServiceUrl}/api/progreso'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response, codigosAceptados: {201});
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Consulta tu historial antes de volver a guardar.',
      );
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }
  }

  // GET /api/progreso
  Future<List<Progreso>> obtenerMiProgreso() async {
    final headers = await _headers();

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.rutinaServiceUrl}/api/progreso'),
            headers: headers,
          )
          .timeout(_tiempoEspera);

      _validarRespuesta(response);
      return _convertirLista(response.body);
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }
  }

  // GET /api/progreso/ejercicio/{idEjercicio}
  Future<List<Progreso>> obtenerProgresoPorEjercicio(
    int idEjercicio,
  ) async {
    if (idEjercicio <= 0) {
      throw Exception('El ejercicio seleccionado no es válido.');
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
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }
  }

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

  void _validarRespuesta(
    http.Response response, {
    Set<int> codigosAceptados = const {200},
  }) {
    if (codigosAceptados.contains(response.statusCode)) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente.');
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para acceder al progreso.');
    }

    String mensaje =
        'No fue posible procesar la solicitud '
        '(código ${response.statusCode}).';

    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        mensaje = data['mensaje']?.toString() ??
            data['detail']?.toString() ??
            data['title']?.toString() ??
            mensaje;
      }
    } catch (_) {
      // Se conserva el mensaje de respaldo.
    }

    throw Exception(mensaje);
  }
}
