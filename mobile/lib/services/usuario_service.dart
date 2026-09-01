import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/usuario.dart';

class UsuarioService {
  Future<Usuario?> obtenerUsuarioActual() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null ||
        token.isEmpty) {
      return null;
    }

    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.usuarioConsultaUrl}/api/usuarios/me',
      ),

      headers: {
        'Authorization':
            'Bearer $token',

        'Content-Type':
            'application/json',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data =
        jsonDecode(
      response.body,
    );

    final usuario =
        Usuario.fromJson(
      data,
    );

    await prefs.setString(
      'usuario',
      jsonEncode(
        usuario.toJson(),
      ),
    );

    return usuario;
  }
}