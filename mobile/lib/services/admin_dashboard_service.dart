import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_dashboard.dart';
import 'auth_service.dart';

// GYMFLOW - SPRINT 7
// SERVICIO DEL DASHBOARD ADMINISTRATIVO

class AdminDashboardService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 50);

  // OBTENER TOKEN DE LA SESIÓN ACTUAL

  Future<Map<String, String>> _headers() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión no es válida. Inicia sesión nuevamente.');
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // REALIZAR CONSULTA GET

  Future<Map<String, dynamic>> _consultar(
    String endpoint, {
    Map<String, String>? parametros,
  }) async {
    final headers = await _headers();

    final uri = Uri.parse(
      '${ApiConfig.adminDashboardUrl}/$endpoint',
    ).replace(queryParameters: parametros);

    late http.Response respuesta;

    try {
      respuesta = await http.get(uri, headers: headers).timeout(_tiempoEspera);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Intenta actualizar el Dashboard.',
      );
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }

    _validarRespuesta(respuesta);

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return datos;
    } on FormatException {
      throw Exception('El servidor devolvió información no válida.');
    }
  }

  // VALIDAR RESPUESTA DEL BACKEND

  void _validarRespuesta(http.Response respuesta) {
    if (respuesta.statusCode == 200) {
      return;
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente.');
    }

    if (respuesta.statusCode == 403) {
      throw Exception(
        'No tienes permisos para consultar '
        'el Dashboard Administrativo.',
      );
    }

    String mensaje =
        'No fue posible consultar el Dashboard '
        '(código ${respuesta.statusCode}).';

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        mensaje =
            datos['mensaje']?.toString() ??
            datos['detail']?.toString() ??
            datos['title']?.toString() ??
            mensaje;
      }
    } catch (_) {
      // Conservar el mensaje predeterminado.
    }

    throw Exception(mensaje);
  }

  // VALIDAR QUE EXISTA UN NÚMERO
  // No convertir respuestas inválidas en estadísticas falsas.

  void _validarNumero(Map<String, dynamic> datos, String campo) {
    final valor = datos[campo];

    final numero = valor is num ? valor : num.tryParse(valor?.toString() ?? '');

    if (numero == null || !numero.isFinite) {
      throw Exception(
        'El servidor no devolvió correctamente '
        'el campo $campo.',
      );
    }
  }

  // 1. TOTAL DE CLIENTES
  // GET /api/admin/dashboard/total-clientes

  Future<TotalClientesResponse> obtenerTotalClientes() async {
    final datos = await _consultar('total-clientes');

    _validarNumero(datos, 'totalClientes');

    return TotalClientesResponse.fromJson(datos);
  }

  // 2. MEMBRESÍAS ACTIVAS
  // GET /api/admin/dashboard/membresias-activas

  Future<MembresiasActivasResponse> obtenerMembresiasActivas() async {
    final datos = await _consultar('membresias-activas');

    _validarNumero(datos, 'membresiasActivas');

    return MembresiasActivasResponse.fromJson(datos);
  }

  // 3. ASISTENCIAS DEL DÍA
  // GET /api/admin/dashboard/asistencias-dia

  Future<AsistenciasDiaResponse> obtenerAsistenciasDia() async {
    final datos = await _consultar('asistencias-dia');

    _validarNumero(datos, 'asistenciasDia');

    return AsistenciasDiaResponse.fromJson(datos);
  }

  // 4. PAGOS REGISTRADOS
  // GET /api/admin/dashboard/pagos-registrados

  Future<PagosRegistradosResponse> obtenerPagosRegistrados() async {
    final datos = await _consultar('pagos-registrados');

    _validarNumero(datos, 'pagosRegistrados');

    return PagosRegistradosResponse.fromJson(datos);
  }

  // 5. INGRESOS POR PERIODO
  // GET /api/admin/dashboard/ingresos-periodo

  Future<IngresosPeriodoResponse> obtenerIngresosPeriodo({
    required String desde,
    required String hasta,
  }) async {
    final formatoFecha = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!formatoFecha.hasMatch(desde) || !formatoFecha.hasMatch(hasta)) {
      throw Exception('Las fechas deben tener formato YYYY-MM-DD.');
    }

    final fechaInicial = DateTime.tryParse(desde);
    final fechaFinal = DateTime.tryParse(hasta);

    if (fechaInicial == null ||
        fechaFinal == null ||
        fechaInicial.year.toString().padLeft(4, '0') != desde.substring(0, 4) ||
        fechaFinal.year.toString().padLeft(4, '0') != hasta.substring(0, 4) ||
        fechaInicial.month.toString().padLeft(2, '0') !=
            desde.substring(5, 7) ||
        fechaFinal.month.toString().padLeft(2, '0') != hasta.substring(5, 7) ||
        fechaInicial.day.toString().padLeft(2, '0') != desde.substring(8, 10) ||
        fechaFinal.day.toString().padLeft(2, '0') != hasta.substring(8, 10) ||
        fechaFinal.isBefore(fechaInicial)) {
      throw Exception('Selecciona un periodo de fechas válido.');
    }

    final datos = await _consultar(
      'ingresos-periodo',
      parametros: {'desde': desde, 'hasta': hasta},
    );

    _validarNumero(datos, 'ingresosPeriodo');

    return IngresosPeriodoResponse.fromJson(datos);
  }
}
