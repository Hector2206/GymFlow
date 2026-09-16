import 'dart:convert';

import 'package:http/http.dart' as http;

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

  factory ResultadoRegistroAsistencia.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResultadoRegistroAsistencia(
      accesoAprobado:
          json['accesoAprobado'] == true,

      idCliente:
          int.tryParse(
        json['idCliente']?.toString() ?? '',
      ),

      nombreCompleto:
          json['nombreCompleto']?.toString() ?? '',

      codigoAcceso:
          json['codigoAcceso']?.toString() ?? '',

      idMembresia:
          int.tryParse(
        json['idMembresia']?.toString() ?? '',
      ),

      nombrePlan:
          json['nombrePlan']?.toString() ?? '',

      fechaVencimiento:
          json['fechaVencimiento']?.toString() ?? '',

      fechaHoraAsistencia:
          json['fechaHoraAsistencia']?.toString() ?? '',

      motivo:
          json['motivo']?.toString() ?? '',

      mensaje:
          json['mensaje']?.toString() ?? '',
    );
  }
}

class AsistenciaService {
  final AuthService _authService =
      AuthService();

  Future<String> _obtenerToken() async {
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

  String _obtenerMensajeError(
    http.Response response,
    String mensajeDefault,
  ) {
    try {
      final data =
          jsonDecode(
        response.body,
      );

      if (data is Map<String, dynamic>) {
        return data['mensaje']?.toString() ??
            data['message']?.toString() ??
            data['error']?.toString() ??
            mensajeDefault;
      }
    } catch (_) {}

    return mensajeDefault;
  }

  Future<ResultadoRegistroAsistencia>
      registrarPorCodigo(
    String codigoAcceso,
  ) async {
    final token =
        await _obtenerToken();

    final codigoNormalizado =
        normalizarCodigo(
      codigoAcceso,
    );

    try {
      final response =
          await http.post(
        Uri.parse(
          '${ApiConfig.asistenciasUrl}/codigo',
        ),
        headers: {
          'Accept':
              'application/json',
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body:
            jsonEncode(
          {
            'codigoAcceso':
                codigoNormalizado,
          },
        ),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final data =
            jsonDecode(
          response.body,
        );

        if (data is! Map<String, dynamic>) {
          throw Exception(
            'El servidor devolvió una respuesta no válida.',
          );
        }

        return ResultadoRegistroAsistencia.fromJson(
          data,
        );
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
          _obtenerMensajeError(
            response,
            'Código de acceso no encontrado.',
          ),
        );
      }

      throw Exception(
        _obtenerMensajeError(
          response,
          'No fue posible validar el acceso.',
        ),
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  Future<List<AsistenciaCliente>>
      consultarPorCliente(
    int idCliente,
  ) async {
    final token =
        await _obtenerToken();

    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.asistenciasUrl}/cliente/$idCliente',
        ),
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(
          response.body,
        );

        List<dynamic> listaJson = [];

        if (data is Map<String, dynamic>) {
          final asistencias =
              data['asistencias'];

          if (asistencias is List) {
            listaJson =
                asistencias;
          }
        } else if (data is List) {
          listaJson =
              data;
        }

        final asistencias =
            listaJson
                .whereType<
                    Map<String, dynamic>>()
                .map(
                  AsistenciaCliente.fromJson,
                )
                .toList();

        asistencias.sort(
          (
            a,
            b,
          ) {
            final fechaA =
                a.fechaHoraDateTime;

            final fechaB =
                b.fechaHoraDateTime;

            if (fechaA == null &&
                fechaB == null) {
              return 0;
            }

            if (fechaA == null) {
              return 1;
            }

            if (fechaB == null) {
              return -1;
            }

            return fechaB.compareTo(
              fechaA,
            );
          },
        );

        return asistencias;
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
        return [];
      }

      throw Exception(
        _obtenerMensajeError(
          response,
          'No fue posible consultar las asistencias.',
        ),
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }

  Future<List<AsistenciaCliente>>
      obtenerMisAsistencias() async {
    final token =
        await _obtenerToken();

    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.asistenciasUrl}/mis-asistencias',
        ),
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(
          response.body,
        );

        List<dynamic> listaJson = [];

        if (data is Map<String, dynamic>) {
          final asistencias =
              data['asistencias'];

          if (asistencias is List) {
            listaJson =
                asistencias;
          }
        } else if (data is List) {
          listaJson =
              data;
        }

        final asistencias =
            listaJson
                .whereType<
                    Map<String, dynamic>>()
                .map(
                  AsistenciaCliente.fromJson,
                )
                .toList();

        asistencias.sort(
          (
            a,
            b,
          ) {
            final fechaA =
                a.fechaHoraDateTime;

            final fechaB =
                b.fechaHoraDateTime;

            if (fechaA == null &&
                fechaB == null) {
              return 0;
            }

            if (fechaA == null) {
              return 1;
            }

            if (fechaB == null) {
              return -1;
            }

            return fechaB.compareTo(
              fechaA,
            );
          },
        );

        return asistencias;
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

      throw Exception(
        _obtenerMensajeError(
          response,
          'No fue posible cargar tus asistencias.',
        ),
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }
}