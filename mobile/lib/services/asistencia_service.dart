import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../config/api_config.dart';
import '../models/asistencia_cliente.dart';
import 'auth_service.dart';

class ResultadoRegistroAsistencia {
  final bool accesoAprobado;
  final int? idCliente;
  final String nombreCompleto;
  final String codigoAcceso;
  final int? idMembresia;
  final String nombrePlan;
  final String fechaVencimiento;
  final String fechaHoraAsistencia;
  final String motivo;
  final String mensaje;

  const ResultadoRegistroAsistencia({
    required this.accesoAprobado,
    required this.idCliente,
    required this.nombreCompleto,
    required this.codigoAcceso,
    required this.idMembresia,
    required this.nombrePlan,
    required this.fechaVencimiento,
    required this.fechaHoraAsistencia,
    required this.motivo,
    required this.mensaje,
  });

  factory ResultadoRegistroAsistencia
      .fromJson(
    Map<String, dynamic> json,
  ) {
    return ResultadoRegistroAsistencia(
      accesoAprobado:
          json['accesoAprobado'] ==
              true,
      idCliente: int.tryParse(
        json['idCliente']
                ?.toString() ??
            '',
      ),
      nombreCompleto:
          json['nombreCompleto']
                  ?.toString() ??
              '',
      codigoAcceso:
          json['codigoAcceso']
                  ?.toString() ??
              '',
      idMembresia: int.tryParse(
        json['idMembresia']
                ?.toString() ??
            '',
      ),
      nombrePlan:
          json['nombrePlan']
                  ?.toString() ??
              '',
      fechaVencimiento:
          json['fechaVencimiento']
                  ?.toString() ??
              '',
      fechaHoraAsistencia:
          json['fechaHoraAsistencia']
                  ?.toString() ??
              '',
      motivo:
          json['motivo']?.toString() ??
              '',
      mensaje:
          json['mensaje']?.toString() ??
              '',
    );
  }
}

class AsistenciaService {
  final AuthService _authService =
      AuthService();

  Future<String> _token() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    return token;
  }

  String normalizarCodigo(
    String codigo,
  ) {
    return codigo
        .trim()
        .toUpperCase()
        .replaceAll(
          RegExp(r"['’‘`]"),
          '-',
        );
  }

  void validarCodigo(
    String codigo,
  ) {
    if (codigo.isEmpty) {
      throw Exception(
        'Ingresa un código de acceso.',
      );
    }

    if (codigo.length > 80) {
      throw Exception(
        'El código de acceso es demasiado largo.',
      );
    }

    if (!RegExp(
      r'^[A-Z0-9-]+$',
    ).hasMatch(codigo)) {
      throw Exception(
        'El código solo puede contener letras, números y guiones.',
      );
    }
  }

  String _mensaje(
    http.Response response,
    String defaultMessage,
  ) {
    try {
      final data =
          jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data['mensaje']?.toString() ??
            data['message']?.toString() ??
            data['motivo']?.toString() ??
            data['error']?.toString() ??
            defaultMessage;
      }
    } catch (_) {}

    return defaultMessage;
  }

  Future<ResultadoRegistroAsistencia>
      registrarPorCodigo(
    String codigoAcceso,
  ) async {
    final codigo =
        normalizarCodigo(
      codigoAcceso,
    );

    validarCodigo(codigo);

    final token =
        await _token();

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(
              '${ApiConfig.asistenciasUrl}/codigo',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type':
                  'application/json',
              'Authorization':
                  'Bearer $token',
            },
            body: jsonEncode({
              'codigoAcceso': codigo,
            }),
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

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      try {
        final data =
            jsonDecode(response.body);

        if (data
            is! Map<String, dynamic>) {
          throw Exception(
            'El servidor devolvió una respuesta no válida.',
          );
        }

        return ResultadoRegistroAsistencia
            .fromJson(data);
      } on FormatException {
        throw Exception(
          'El servidor devolvió una respuesta no válida.',
        );
      }
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para registrar asistencias.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        _mensaje(
          response,
          'Código de acceso no encontrado.',
        ),
      );
    }

    throw Exception(
      _mensaje(
        response,
        'No fue posible validar el acceso.',
      ),
    );
  }

  Future<List<AsistenciaCliente>>
      consultarPorCliente(
    int idCliente,
  ) async {
    if (idCliente <= 0) {
      throw Exception(
        'Ingresa un ID de cliente válido.',
      );
    }

    final token =
        await _token();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.asistenciasUrl}/cliente/$idCliente',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization':
                  'Bearer $token',
            },
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

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar asistencias.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        _mensaje(
          response,
          'El cliente indicado no existe.',
        ),
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        _mensaje(
          response,
          'No fue posible consultar las asistencias.',
        ),
      );
    }

    return _lista(
      response.body,
    );
  }

  Future<List<AsistenciaCliente>>
      obtenerMisAsistencias() async {
    final token =
        await _token();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.asistenciasUrl}/mis-asistencias',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization':
                  'Bearer $token',
            },
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

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar tus asistencias.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        _mensaje(
          response,
          'No fue posible cargar tus asistencias.',
        ),
      );
    }

    return _lista(
      response.body,
    );
  }

  List<AsistenciaCliente> _lista(
    String body,
  ) {
    try {
      final data =
          jsonDecode(body);

      List<dynamic> jsonLista = [];

      if (data is Map<String, dynamic> &&
          data['asistencias'] is List) {
        jsonLista =
            data['asistencias'] as List;
      } else if (data is List) {
        jsonLista = data;
      }

      final lista = jsonLista
          .whereType<Map<String, dynamic>>()
          .map(
            AsistenciaCliente.fromJson,
          )
          .toList();

      lista.sort(
        (a, b) {
          final fa =
              a.fechaHoraDateTime;
          final fb =
              b.fechaHoraDateTime;

          if (fa == null &&
              fb == null) {
            return 0;
          }

          if (fa == null) {
            return 1;
          }

          if (fb == null) {
            return -1;
          }

          return fb.compareTo(fa);
        },
      );

      return lista;
    } catch (_) {
      throw Exception(
        'El servidor devolvió información de asistencias no válida.',
      );
    }
  }
}