import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/pago_cliente.dart';
import 'auth_service.dart';

class ResultadoRegistroPago {
  final bool pagoRegistrado;
  final bool esRenovacion;
  final int idCliente;
  final double monto;
  final String tipoPago;
  final String fechaVencimiento;
  final bool membresiaActiva;
  final String mensaje;

  const ResultadoRegistroPago({
    required this.pagoRegistrado,
    required this.esRenovacion,
    required this.idCliente,
    required this.monto,
    required this.tipoPago,
    required this.fechaVencimiento,
    required this.membresiaActiva,
    required this.mensaje,
  });

  factory ResultadoRegistroPago.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResultadoRegistroPago(
      pagoRegistrado:
          json['pagoRegistrado'] == true,
      esRenovacion:
          json['esRenovacion'] == true,
      idCliente:
          int.tryParse(
            json['idCliente']?.toString() ?? '',
          ) ??
          0,
      monto:
          double.tryParse(
            json['monto']?.toString() ?? '',
          ) ??
          0,
      tipoPago:
          json['tipoPago']?.toString() ?? '',
      fechaVencimiento:
          json['fechaVencimiento']?.toString() ?? '',
      membresiaActiva:
          json['membresiaActiva'] == true,
      mensaje:
          json['mensaje']?.toString() ?? '',
    );
  }
}

class PagoService {
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

  String _mensajeError(
    http.Response response,
    String mensajeDefault,
  ) {
    try {
      final data =
          jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data['mensaje']?.toString() ??
            data['message']?.toString() ??
            data['error']?.toString() ??
            mensajeDefault;
      }
    } catch (_) {}

    return mensajeDefault;
  }

  Future<ResultadoRegistroPago>
      registrarPago({
    required int idCliente,
    required double monto,
    required String tipoPago,
  }) async {
    if (idCliente <= 0) {
      throw Exception(
        'Selecciona un cliente válido.',
      );
    }

    if (!monto.isFinite ||
        monto <= 0) {
      throw Exception(
        'El monto debe ser mayor a \$0.',
      );
    }

    if (monto > 100000) {
      throw Exception(
        'Verifica el monto ingresado.',
      );
    }

    if (tipoPago != 'Mensualidad' &&
        tipoPago != 'Anualidad') {
      throw Exception(
        'Selecciona un concepto de pago válido.',
      );
    }

    final token =
        await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(
              ApiConfig.pagosUrl,
            ),
            headers: {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
              'Authorization':
                  'Bearer $token',
            },
            body: jsonEncode({
              'idCliente':
                  idCliente,
              'monto':
                  monto,
              'tipoPago':
                  tipoPago,
            }),
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
    } catch (_) {
      throw Exception(
        'Ocurrió un error al intentar registrar el pago.',
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

        return ResultadoRegistroPago
            .fromJson(data);
      } on FormatException {
        throw Exception(
          'El servidor devolvió una respuesta no válida.',
        );
      }
    }

    if (response.statusCode == 400) {
      throw Exception(
        _mensajeError(
          response,
          'Verifica los datos del pago.',
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
        'No tienes permiso para registrar pagos.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        _mensajeError(
          response,
          'El cliente seleccionado no existe.',
        ),
      );
    }

    if (response.statusCode >= 500) {
      throw Exception(
        'El servidor tuvo un problema al registrar el pago.',
      );
    }

    throw Exception(
      _mensajeError(
        response,
        'No fue posible registrar el pago.',
      ),
    );
  }

  Future<List<PagoCliente>>
      consultarPagosCliente(
    int idCliente,
  ) async {
    if (idCliente <= 0) {
      throw Exception(
        'Selecciona un cliente válido.',
      );
    }

    final token =
        await _obtenerToken();

    late http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(
              '${ApiConfig.pagosUrl}/cliente/$idCliente',
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
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    } catch (_) {
      throw Exception(
        'Ocurrió un error al consultar los pagos.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión no es válida. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar pagos.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        _mensajeError(
          response,
          'El cliente seleccionado no existe.',
        ),
      );
    }

    if (response.statusCode >= 500) {
      throw Exception(
        'El servidor tuvo un problema al consultar los pagos.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        _mensajeError(
          response,
          'No fue posible consultar los pagos.',
        ),
      );
    }

    return _obtenerListaPagos(
      response.body,
    );
  }

  Future<List<PagoCliente>>
      obtenerMisPagos() async {
    final token =
        await _obtenerToken();

    late http.Response response;

    try {
      response = await http
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
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    } catch (_) {
      throw Exception(
        'Ocurrió un error al consultar tus pagos.',
      );
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

    if (response.statusCode >= 500) {
      throw Exception(
        'El servidor tuvo un problema al consultar tus pagos.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        _mensajeError(
          response,
          'No fue posible cargar tus pagos.',
        ),
      );
    }

    return _obtenerListaPagos(
      response.body,
    );
  }

  List<PagoCliente> _obtenerListaPagos(
    String body,
  ) {
    try {
      final data =
          jsonDecode(body);

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
      } else {
        throw const FormatException();
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
    } catch (_) {
      throw Exception(
        'El servidor devolvió información de pagos no válida.',
      );
    }
  }
}