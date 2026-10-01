import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/rutina.dart';
import 'auth_service.dart';

class RutinaService {
  final AuthService _authService =
      AuthService();

  Future<Map<String, String>>
      _headers() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    return {
      'Accept':
          'application/json',
      'Content-Type':
          'application/json',
      'Authorization':
          'Bearer $token',
    };
  }

  Future<List<Rutina>>
      obtenerRutinas() async {
    final headers =
        await _headers();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/rutinas',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(
              seconds: 25,
            ),
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
    );

    final data =
        jsonDecode(
          response.body,
        );

    if (data is! List) {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    return data
        .whereType<
            Map<String, dynamic>>()
        .map(
          Rutina.fromJson,
        )
        .toList();
  }

  Future<Rutina>
      obtenerRutina(
    int idRutina,
  ) async {
    final headers =
        await _headers();

    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.rutinaServiceUrl}/api/rutinas/$idRutina',
          ),
          headers: headers,
        )
        .timeout(
          const Duration(
            seconds: 25,
          ),
        );

    _validarRespuesta(
      response,
    );

    final data =
        jsonDecode(
          response.body,
        );

    if (data
        is! Map<String, dynamic>) {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    return Rutina.fromJson(
      data,
    );
  }

  Future<List<Rutina>>
      obtenerRutinasPorCliente(
    int idCliente,
  ) async {
    final headers =
        await _headers();

    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.rutinaServiceUrl}/api/rutinas/cliente/$idCliente',
          ),
          headers: headers,
        )
        .timeout(
          const Duration(
            seconds: 25,
          ),
        );

    _validarRespuesta(
      response,
    );

    final data =
        jsonDecode(
          response.body,
        );

    if (data is! List) {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    return data
        .whereType<
            Map<String, dynamic>>()
        .map(
          Rutina.fromJson,
        )
        .toList();
  }

  // ==========================================================
  // MI RUTINA - CLIENTE
  // ==========================================================

  Future<Rutina>
      obtenerMiRutina() async {
    final headers =
        await _headers();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/rutinas/mi-rutina',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(
              seconds: 25,
            ),
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
    );

    final data =
        jsonDecode(
          response.body,
        );

    if (data
        is! Map<String, dynamic>) {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    return Rutina.fromJson(
      data,
    );
  }

  Future<Rutina>
      crearRutina({
    required int idCliente,
    required String nombre,
    String? descripcion,
    required List<DiaRutina> dias,
  }) async {
    final headers =
        await _headers();

    final body = {
      'idCliente':
          idCliente,
      'nombre':
          nombre.trim(),
      'descripcion':
          descripcion?.trim().isEmpty ==
                  true
              ? null
              : descripcion?.trim(),
      'dias': dias
          .map(
            (dia) =>
                dia.toJson(),
          )
          .toList(),
    };

    final response = await http
        .post(
          Uri.parse(
            '${ApiConfig.rutinaServiceUrl}/api/rutinas',
          ),
          headers: headers,
          body: jsonEncode(
            body,
          ),
        )
        .timeout(
          const Duration(
            seconds: 25,
          ),
        );

    _validarRespuesta(
      response,
      codigosAceptados: {
        200,
        201,
      },
    );

    final data =
        jsonDecode(
          response.body,
        );

    if (data
        is! Map<String, dynamic>) {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    return Rutina.fromJson(
      data,
    );
  }

  Future<Rutina>
      editarRutina({
    required int idRutina,
    required int idCliente,
    required String nombre,
    String? descripcion,
    required List<DiaRutina> dias,
  }) async {
    final headers =
        await _headers();

    final body = {
      'idCliente':
          idCliente,
      'nombre':
          nombre.trim(),
      'descripcion':
          descripcion?.trim().isEmpty ==
                  true
              ? null
              : descripcion?.trim(),
      'dias': dias
          .map(
            (dia) =>
                dia.toJson(),
          )
          .toList(),
    };

    final response = await http
        .put(
          Uri.parse(
            '${ApiConfig.rutinaServiceUrl}/api/rutinas/$idRutina',
          ),
          headers: headers,
          body: jsonEncode(
            body,
          ),
        )
        .timeout(
          const Duration(
            seconds: 25,
          ),
        );

    _validarRespuesta(
      response,
      codigosAceptados: {
        200,
      },
    );

  

    final data =
        jsonDecode(
          response.body,
        );

    if (data
        is! Map<String, dynamic>) {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    return Rutina.fromJson(
      data,
    );
  }

  Future<void> eliminarRutina(
    int idRutina,
  ) async {
    final headers =
        await _headers();

    late http.Response response;

    try {
      response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.rutinaServiceUrl}/api/rutinas/$idRutina',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(
              seconds: 25,
            ),
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
      codigosAceptados: {
        200,
        204,
      },
    );
  }


  void _validarRespuesta(
    http.Response response, {
    Set<int>? codigosAceptados,
  }) {
    final permitidos =
        codigosAceptados ??
            {
              200,
            };

    if (permitidos.contains(
      response.statusCode,
    )) {
      return;
    }

    if (response.statusCode ==
        401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode ==
        403) {
      throw Exception(
        'No tienes permiso para realizar esta acción.',
      );
    }

    if (response.statusCode ==
        404) {
      String mensaje =
          'No se encontró la rutina.';

      try {
        final data =
            jsonDecode(
              response.body,
            );

        if (data
            is Map<String, dynamic>) {
          mensaje =
              data['mensaje']
                      ?.toString() ??
                  mensaje;
        }
      } catch (_) {}

      throw Exception(
        mensaje,
      );
    }

    String mensaje =
        'No fue posible procesar la solicitud.';

    try {
      final data =
          jsonDecode(
            response.body,
          );

      if (data
          is Map<String, dynamic>) {
        mensaje =
            data['mensaje']
                    ?.toString() ??
                data['detail']
                    ?.toString() ??
                data['title']
                    ?.toString() ??
                mensaje;
      }
    } catch (_) {}

    throw Exception(
      mensaje,
    );
  }
}