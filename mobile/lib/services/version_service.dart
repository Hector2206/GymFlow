import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class VersionService {
  Future<String?> obtenerVersion() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null ||
        token.trim().isEmpty) {
      return null;
    }

    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.rutinaServiceUrl}/api/sistema/version',
        ),
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(
        response.body,
      );

      if (data
          is! Map<String, dynamic>) {
        return null;
      }

      final version =
          data['version']?.toString().trim();

      if (version == null ||
          version.isEmpty) {
        return null;
      }

      return version;
    } catch (_) {
      return null;
    }
  }
}