import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/ejercicio.dart';
import '../models/ejercicio_request.dart';
import 'auth_service.dart';

class EjercicioService {
  final AuthService _authService = AuthService();

  Future<String> _obtenerToken() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Ejercicio>> obtenerEjercicios() async {
    final token = await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/ejercicios',
            ),
            headers: _headers(token),
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

    _validarRespuesta(
      response,
      mensajeGeneral:
          'No fue posible cargar los ejercicios.',
    );

    return _convertirLista(response.body);
  }

  Future<List<Ejercicio>> buscarEjercicios(
    String nombre,
  ) async {
    final texto = nombre.trim();

    if (texto.isEmpty) {
      return obtenerEjercicios();
    }

    final token = await _obtenerToken();

    final uri = Uri.parse(
      '${ApiConfig.rutinaServiceUrl}/api/ejercicios/buscar',
    ).replace(
      queryParameters: {
        'nombre': texto,
      },
    );

    late http.Response response;

    try {
      response = await http
          .get(
            uri,
            headers: _headers(token),
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

    _validarRespuesta(
      response,
      mensajeGeneral:
          'No fue posible buscar los ejercicios.',
    );

    return _convertirLista(response.body);
  }

  Future<Ejercicio> obtenerEjercicio(
    int idEjercicio,
  ) async {
    final token = await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/ejercicios/$idEjercicio',
            ),
            headers: _headers(token),
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

    _validarRespuesta(
      response,
      mensajeGeneral:
          'No fue posible cargar el ejercicio.',
    );

    try {
      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'El servidor devolvió una respuesta no válida.',
        );
      }

      return Ejercicio.fromJson(data);
    } on FormatException {
      throw Exception(
        'El servidor devolvió información no válida.',
      );
    }
  }

  Future<void> crearEjercicio(
    EjercicioRequest request,
  ) async {
    final token = await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/ejercicios',
            ),
            headers: _headers(token),
            body: jsonEncode(
              request.toJson(),
            ),
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

    _validarRespuesta(
      response,
      mensajeGeneral:
          'No fue posible crear el ejercicio.',
      codigosCorrectos: {
        200,
        201,
      },
    );
  }

  Future<void> actualizarEjercicio(
    int idEjercicio,
    EjercicioRequest request,
  ) async {
    final token = await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .put(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/ejercicios/$idEjercicio',
            ),
            headers: _headers(token),
            body: jsonEncode(
              request.toJson(),
            ),
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

    _validarRespuesta(
      response,
      mensajeGeneral:
          'No fue posible actualizar el ejercicio.',
      codigosCorrectos: {
        200,
        204,
      },
    );
  }

  Future<void> eliminarEjercicio(
    int idEjercicio,
  ) async {
    final token = await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/ejercicios/$idEjercicio',
            ),
            headers: _headers(token),
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

    _validarRespuesta(
      response,
      mensajeGeneral:
          'No fue posible desactivar el ejercicio.',
      codigosCorrectos: {
        200,
        204,
      },
    );
  }

  List<Ejercicio> _convertirLista(
    String body,
  ) {
    try {
      final data = jsonDecode(body);

      if (data is! List) {
        throw Exception(
          'El servidor devolvió una respuesta no válida.',
        );
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Ejercicio.fromJson)
          .where(
            (ejercicio) =>
                ejercicio.idEjercicio > 0 &&
                ejercicio.nombre.trim().isNotEmpty,
          )
          .toList();
    } on FormatException {
      throw Exception(
        'El servidor devolvió información no válida.',
      );
    }
  }

  void _validarRespuesta(
    http.Response response, {
    required String mensajeGeneral,
    Set<int> codigosCorrectos = const {
      200,
    },
  }) {
    if (codigosCorrectos.contains(
      response.statusCode,
    )) {
      return;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _obtenerMensajeServidor(
          response.body,
          'Los datos enviados no son válidos.',
        ),
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para realizar esta acción.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        _obtenerMensajeServidor(
          response.body,
          'El ejercicio solicitado no fue encontrado.',
        ),
      );
    }

    if (response.statusCode >= 500) {
      throw Exception(
        'El servidor presentó un problema. Intenta nuevamente.',
      );
    }

    throw Exception(
      _obtenerMensajeServidor(
        response.body,
        mensajeGeneral,
      ),
    );
  }

  String _obtenerMensajeServidor(
    String body,
    String mensajePredeterminado,
  ) {
    if (body.trim().isEmpty) {
      return mensajePredeterminado;
    }

    try {
      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        final mensaje =
            data['mensaje'] ??
            data['message'] ??
            data['error'];

        if (mensaje != null &&
            mensaje.toString().trim().isNotEmpty) {
          return mensaje.toString();
        }
      }
    } catch (_) {}

    return mensajePredeterminado;
  }
}