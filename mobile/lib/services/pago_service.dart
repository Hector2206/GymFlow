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

  Future<ResultadoRegistroPago>
      registrarPago({
    required int idCliente,
    required double monto,
    required String tipoPago,
  }) async {
    final token =
        await _obtenerToken();

    late http.Response response;

    try {
      response =
          await http
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
                body:
                    jsonEncode(
                  {
                    'idCliente':
                        idCliente,
                    'monto':
                        monto,
                    'tipoPago':
                        tipoPago,
                  },
                ),
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

      return ResultadoRegistroPago.fromJson(
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
    final token =
        await _obtenerToken();

    late http.Response response;

    try {
      response =
          await http
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

      _ordenarPagos(
        pagos,
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

    throw Exception(
      _mensajeError(
        response,
        'No fue posible consultar los pagos.',
      ),
    );
  }

  Future<List<PagoCliente>>
      obtenerMisPagos() async {
    final token =
        await _obtenerToken();

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
    } on http.ClientException {
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

      _ordenarPagos(
        pagos,
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

    throw Exception(
      _mensajeError(
        response,
        'No fue posible cargar tus pagos.',
      ),
    );
  }

  void _ordenarPagos(
    List<PagoCliente> pagos,
  ) {
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
  }
}