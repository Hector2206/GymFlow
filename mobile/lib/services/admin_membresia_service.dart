import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_membresia.dart';
import 'auth_service.dart';

class AdminMembresiaService {
  final AuthService _auth = AuthService();

  Future<List<AdminMembresia>> obtenerCatalogo() async {
    final token = await _auth.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión no es válida. Inicia sesión nuevamente.');
    }

    late http.Response respuesta;

    try {
      respuesta = await http
          .get(
            Uri.parse('${ApiConfig.adminApiUrl}/api/admin/membresias'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con el servidor.');
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    if (respuesta.statusCode == 403) {
      throw Exception('Solo Administración puede consultar membresías.');
    }

    if (respuesta.statusCode == 404) {
      throw Exception(
        'El endpoint de membresías todavía '
        'no está publicado en este servidor.',
      );
    }

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No fue posible consultar las membresías '
        '(HTTP ${respuesta.statusCode}).',
      );
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw const FormatException();
      }

      final membresias = <AdminMembresia>[];

      for (final elemento in datos) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException();
        }

        membresias.add(AdminMembresia.fromJson(elemento));
      }

      return membresias;
    } on FormatException {
      throw Exception('El servidor devolvió información no válida.');
    }
  }
}
