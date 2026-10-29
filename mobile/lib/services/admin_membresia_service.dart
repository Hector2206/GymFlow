import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_membresia.dart';
import 'auth_service.dart';

class HistorialPrecioMembresia {
  final int idHistorial;
  final int idMembresia;
  final double costoMensual;
  final double costoAnualidad;
  final String registradoEn;
  final int? idUsuarioApp;
  final String origen;

  const HistorialPrecioMembresia({
    required this.idHistorial,
    required this.idMembresia,
    required this.costoMensual,
    required this.costoAnualidad,
    required this.registradoEn,
    required this.idUsuarioApp,
    required this.origen,
  });

  factory HistorialPrecioMembresia.fromJson(Map<String, dynamic> json) {
    return HistorialPrecioMembresia(
      idHistorial: (json['idHistorial'] as num).toInt(),
      idMembresia: (json['idMembresia'] as num).toInt(),
      costoMensual: (json['costoMensual'] as num).toDouble(),
      costoAnualidad: (json['costoAnualidad'] as num).toDouble(),
      registradoEn: json['registradoEn']?.toString() ?? '',
      idUsuarioApp: (json['idUsuarioApp'] as num?)?.toInt(),
      origen: json['origen']?.toString() ?? '',
    );
  }
}

class AdminMembresiaService {
  final AuthService _auth = AuthService();

  static const String _base = '${ApiConfig.adminApiUrl}/api/admin/membresias';

  Future<http.Response> _solicitar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? datos,
  }) async {
    final token = await _auth.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse('$_base$ruta');

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late http.Response respuesta;

    try {
      switch (metodo) {
        case 'GET':
          respuesta = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 40));
        case 'POST':
          respuesta = await http
              .post(uri, headers: headers, body: jsonEncode(datos))
              .timeout(const Duration(seconds: 40));
        case 'PUT':
          respuesta = await http
              .put(uri, headers: headers, body: jsonEncode(datos))
              .timeout(const Duration(seconds: 40));
        case 'PATCH':
          respuesta = await http
              .patch(uri, headers: headers, body: jsonEncode(datos))
              .timeout(const Duration(seconds: 40));
        default:
          throw Exception('Método HTTP no permitido.');
      }
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado. Si modificaste datos, '
        'actualiza el catálogo antes de repetir la operación.',
      );
    } on http.ClientException {
      throw Exception(
        'Se perdió la conexión. Verifica el catálogo '
        'antes de volver a guardar.',
      );
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return respuesta;
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    if (respuesta.statusCode == 403) {
      throw Exception('No tienes autorización para administrar membresías.');
    }

    if (respuesta.statusCode == 404) {
      throw Exception('La membresía o el endpoint solicitado no existe.');
    }

    String mensaje = 'La operación falló (HTTP ${respuesta.statusCode}).';

    try {
      final json = jsonDecode(respuesta.body);

      if (json is Map<String, dynamic>) {
        mensaje =
            json['mensaje']?.toString() ??
            json['detail']?.toString() ??
            json['title']?.toString() ??
            mensaje;
      }
    } catch (_) {
      // Mantener mensaje original.
    }

    throw Exception(mensaje);
  }

  Future<List<AdminMembresia>> obtenerCatalogo() async {
    final respuesta = await _solicitar('GET', '');

    try {
      final json = jsonDecode(respuesta.body);

      if (json is! List) {
        throw const FormatException();
      }

      return json.map((elemento) {
        return AdminMembresia.fromJson(
          Map<String, dynamic>.from(elemento as Map),
        );
      }).toList();
    } catch (_) {
      throw Exception('El servidor devolvió un catálogo no válido.');
    }
  }

  Map<String, dynamic> _datosPlan({
    required String nombrePlan,
    required String descripcion,
    required double costoMensual,
    required double costoAnualidad,
  }) {
    return {
      'nombrePlan': nombrePlan.trim(),
      'descripcion': descripcion.trim(),
      'costoMensual': costoMensual,
      'costoAnualidad': costoAnualidad,
    };
  }

  Future<void> crearMembresia({
    required String nombrePlan,
    required String descripcion,
    required double costoMensual,
    required double costoAnualidad,
  }) async {
    await _solicitar(
      'POST',
      '',
      datos: _datosPlan(
        nombrePlan: nombrePlan,
        descripcion: descripcion,
        costoMensual: costoMensual,
        costoAnualidad: costoAnualidad,
      ),
    );
  }

  Future<void> editarMembresia({
    required int idMembresia,
    required String nombrePlan,
    required String descripcion,
    required double costoMensual,
    required double costoAnualidad,
  }) async {
    await _solicitar(
      'PUT',
      '/$idMembresia',
      datos: _datosPlan(
        nombrePlan: nombrePlan,
        descripcion: descripcion,
        costoMensual: costoMensual,
        costoAnualidad: costoAnualidad,
      ),
    );
  }

  Future<void> cambiarEstado({
    required int idMembresia,
    required bool activo,
  }) async {
    await _solicitar(
      'PATCH',
      '/$idMembresia/estado',
      datos: {'activo': activo},
    );
  }

  Future<List<HistorialPrecioMembresia>> obtenerHistorial(
    int idMembresia,
  ) async {
    final respuesta = await _solicitar(
      'GET',
      '/$idMembresia/historial-precios',
    );

    try {
      final json = jsonDecode(respuesta.body);

      if (json is! List) {
        throw const FormatException();
      }

      return json.map((elemento) {
        return HistorialPrecioMembresia.fromJson(
          Map<String, dynamic>.from(elemento as Map),
        );
      }).toList();
    } catch (_) {
      throw Exception('No fue posible interpretar el historial de precios.');
    }
  }
}
