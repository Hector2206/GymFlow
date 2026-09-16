import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/pago_cliente.dart';
import 'auth_service.dart';

class PagoService {
  final AuthService _authService =
      AuthService();

  Future<List<PagoCliente>>
      obtenerMisPagos() async {
    final token =
        await _authService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    late http.Response response;

    try {
      response =
          await http
              .get(
                Uri.parse(
                  '${ApiConfig.pagosUrl}/mis-pagos',
                ),
                headers: {
                  'Accept':
                      'application/json',
                  'Authorization':
                      'Bearer $token',
                },
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
    } catch (_) {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }

    if (response.statusCode == 200) {
      final data =
          jsonDecode(
        response.body,
      );

      List<dynamic> listaJson = [];

      if (data is Map<String, dynamic>) {
        final pagos =
            data['pagos'];

        if (pagos is List) {
          listaJson =
              pagos;
        }
      } else if (data is List) {
        listaJson =
            data;
      }

      final pagos =
          listaJson
              .whereType<
                  Map<String, dynamic>>()
              .map(
                PagoCliente.fromJson,
              )
              .toList();

      pagos.sort(
        (
          a,
          b,
        ) {
          final fechaA =
              a.fechaTransaccionDateTime;

          final fechaB =
              b.fechaTransaccionDateTime;

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

      return pagos;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar tus pagos.',
      );
    }

    String mensaje =
        'No fue posible cargar tus pagos.';

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
  }
}