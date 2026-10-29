import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/membresia_activa.dart';
import 'auth_service.dart';

// GET en GymManagement.api. Requiere JWT de Recepcion o Administrador.
class MembresiaService {
  final AuthService _authService = AuthService();

  Future<List<MembresiaActiva>> obtenerMembresiasActivas() async {
    final token = await _authService.obtenerToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesion no es valida. Inicia sesion nuevamente.');
    }

    final uri = Uri.parse('${ApiConfig.adminApiUrl}/api/membresias/activas');
    late http.Response respuesta;
    try {
      respuesta = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw Exception('El servidor tardo demasiado en consultar membresias.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesion expiro. Inicia sesion nuevamente.');
    }
    if (respuesta.statusCode == 403) {
      throw Exception(
        'El servidor rechazo el acceso a membresias. '
        'Backend debe validar el rol de Recepcion que contiene el JWT.',
      );
    }
    if (respuesta.statusCode == 404) {
      throw Exception(
        'La consulta de membresias aun no esta desplegada en el servidor.',
      );
    }
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar las membresias '
        '(HTTP ${respuesta.statusCode}).',
      );
    }

    try {
      final datos = jsonDecode(respuesta.body);
      if (datos is! List) throw const FormatException();

      final lista = <MembresiaActiva>[];
      final ids = <int>{};
      for (final dato in datos) {
        if (dato is! Map<String, dynamic>) throw const FormatException();
        final membresia = MembresiaActiva.fromJson(dato);
        if (!ids.add(membresia.idMembresia)) throw const FormatException();
        lista.add(membresia);
      }
      return lista;
    } on FormatException {
      throw Exception(
        'El servidor devolvio un catalogo de membresias invalido.',
      );
    }
  }
}
