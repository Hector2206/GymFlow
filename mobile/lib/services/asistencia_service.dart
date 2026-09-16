import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/asistencia_cliente.dart';
import 'auth_service.dart';

class AsistenciaService {
  final AuthService _authService =
      AuthService();

  Future<List<AsistenciaCliente>>
      obtenerMisAsistencias() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

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

      String mensaje =
          'No fue posible cargar tus asistencias.';

      try {
        final data =
            jsonDecode(
          response.body,
        );

        if (data is Map<String, dynamic>) {
          mensaje =
              data['mensaje']?.toString() ??
                  data['message']?.toString() ??
                  data['error']?.toString() ??
                  mensaje;
        }
      } catch (_) {}

      throw Exception(
        mensaje,
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }
  }
}