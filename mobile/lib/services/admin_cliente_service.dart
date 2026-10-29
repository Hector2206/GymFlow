import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_cliente.dart';
import 'auth_service.dart';

// GYMFLOW - SPRINT 7
// SERVICIO ADMINISTRATIVO DE CLIENTES

class AdminClienteService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 50);

  // ==========================================
  // OBTENER TOKEN DE AUTENTICACIÓN
  // ==========================================

  Future<Map<String, String>> _headers() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. '
        'Inicia sesión nuevamente.',
      );
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ==========================================
  // VALIDAR FILTROS DE CONSULTA
  // ==========================================

  void _validarFiltros(AdminClienteFiltros filtros) {
    final nombre = filtros.nombre?.trim() ?? '';
    final correo = filtros.correo?.trim() ?? '';

    if (nombre.length > 150) {
      throw Exception('El nombre no puede superar 150 caracteres.');
    }

    if (correo.length > 150) {
      throw Exception('El correo no puede superar 150 caracteres.');
    }

    if (filtros.estatus != null &&
        filtros.estatus!.isNotEmpty &&
        !['Activo', 'Inactivo'].contains(filtros.estatus)) {
      throw Exception('Selecciona un estatus válido.');
    }

    if (filtros.vigencia != null &&
        filtros.vigencia!.isNotEmpty &&
        !['Vigente', 'Vencida', 'SinPagos'].contains(filtros.vigencia)) {
      throw Exception('Selecciona una vigencia válida.');
    }

    if (filtros.idMembresia != null && filtros.idMembresia! <= 0) {
      throw Exception('Selecciona una membresía válida.');
    }
  }

  // ==========================================
  // CONSULTAR TODOS LOS CLIENTES
  // GET /api/admin/clientes
  // ==========================================

  Future<List<AdminCliente>> obtenerTodos() async {
    return buscarClientes();
  }

  // ==========================================
  // BUSCAR CLIENTES CON FILTROS
  // GET /api/admin/clientes?nombre=...
  // ==========================================

  Future<List<AdminCliente>> buscarClientes({
    AdminClienteFiltros filtros = const AdminClienteFiltros(),
  }) async {
    _validarFiltros(filtros);

    final headers = await _headers();

    // Uri codifica los parámetros correctamente.
    final parametros = filtros.queryParameters;

    final uri = Uri.parse(
      ApiConfig.adminClientesUrl,
    ).replace(queryParameters: parametros.isEmpty ? null : parametros);

    late http.Response respuesta;

    try {
      respuesta = await http.get(uri, headers: headers).timeout(_tiempoEspera);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Intenta actualizar la lista.',
      );
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }

    _validarRespuesta(respuesta);

    // El backend devuelve directamente una lista:
    // [{...}, {...}]
    // No devuelve { "clientes": [...] }.

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw const FormatException();
      }

      final clientes = <AdminCliente>[];

      for (final item in datos) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException();
        }

        final cliente = AdminCliente.fromJson(item);

        if (cliente.idCliente <= 0 || cliente.nombreCompleto.trim().isEmpty) {
          throw const FormatException();
        }

        clientes.add(cliente);
      }

      // Una lista vacía [] es una respuesta válida.
      return clientes;
    } on FormatException {
      throw Exception(
        'El servidor devolvió datos de clientes '
        'con un formato no válido.',
      );
    }
  }

  // ==========================================
  // VALIDAR RESPUESTA DEL BACKEND
  // ==========================================

  void _validarRespuesta(http.Response respuesta) {
    if (respuesta.statusCode == 200) {
      return;
    }

    if (respuesta.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. '
        'Inicia sesión nuevamente.',
      );
    }

    if (respuesta.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar '
        'los clientes del Administrador.',
      );
    }

    String mensaje =
        'No fue posible consultar los clientes '
        '(código ${respuesta.statusCode}).';

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        final mensajeServidor =
            datos['mensaje']?.toString() ??
            datos['detail']?.toString() ??
            datos['title']?.toString();

        if (mensajeServidor != null && mensajeServidor.trim().isNotEmpty) {
          mensaje = mensajeServidor;
        }
      }
    } catch (_) {
      // Conservar el mensaje predeterminado.
    }

    throw Exception(mensaje);
  }
}
