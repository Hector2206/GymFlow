import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_administrador.dart';
import 'auth_service.dart';

class AdminAdministradoresService {
  final AuthService _auth = AuthService();

  static const Duration _timeout = Duration(seconds: 50);

  static const String _url =
      '${ApiConfig.adminApiUrl}/api/admin/administradores';

  Future<Map<String, String>> _headers() async {
    final token = await _auth.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _solicitar({
    required String metodo,
    required Uri uri,
    Map<String, dynamic>? cuerpo,
    required int codigoEsperado,
  }) async {
    final cliente = http.Client();

    try {
      final headers = await _headers();
      final peticion = http.Request(metodo, uri);

      peticion.headers.addAll(headers);

      if (cuerpo != null) {
        peticion.body = jsonEncode(cuerpo);
      }

      final respuestaStream = await cliente.send(peticion).timeout(_timeout);

      final respuesta = await http.Response.fromStream(
        respuestaStream,
      ).timeout(_timeout);

      if (respuesta.statusCode != codigoEsperado) {
        _procesarError(respuesta);
      }

      return respuesta;
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado. '
        'Consulta los administradores antes '
        'de repetir la operación.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con Backend. '
        'Comprueba el estado de la operación.',
      );
    } finally {
      cliente.close();
    }
  }

  Never _procesarError(http.Response respuesta) {
    String mensaje;

    switch (respuesta.statusCode) {
      case 400:
        mensaje = 'Los datos enviados no son válidos.';
        break;
      case 401:
        mensaje = 'Tu sesión expiró.';
        break;
      case 403:
        mensaje = 'No tienes permisos para gestionar administradores.';
        break;
      case 404:
        mensaje = 'El administrador solicitado no existe.';
        break;
      case 409:
        mensaje =
            'No es posible completar la operación. '
            'Comprueba si se trata del último '
            'administrador activo.';
        break;
      default:
        mensaje =
            'Ocurrió un error HTTP '
            '${respuesta.statusCode}.';
    }

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        final servidor =
            datos['mensaje']?.toString() ??
            datos['detail']?.toString() ??
            datos['title']?.toString();

        if (servidor != null && servidor.trim().isNotEmpty) {
          mensaje = servidor;
        }
      }
    } catch (_) {
      // Se conserva el mensaje predeterminado.
    }

    throw Exception(mensaje);
  }

  Map<String, dynamic> _leerObjeto(String contenido) {
    final datos = jsonDecode(contenido);

    if (datos is! Map<String, dynamic>) {
      throw const FormatException('Backend devolvió una respuesta inválida.');
    }

    return datos;
  }

  Future<List<AdminAdministrador>> obtenerAdministradores() async {
    final respuesta = await _solicitar(
      metodo: 'GET',
      uri: Uri.parse(_url),
      codigoEsperado: 200,
    );

    final datos = jsonDecode(respuesta.body);

    if (datos is! List) {
      throw const FormatException(
        'El listado de administradores no es válido.',
      );
    }

    return datos.map((elemento) {
      if (elemento is! Map<String, dynamic>) {
        throw const FormatException(
          'Un administrador contiene información inválida.',
        );
      }

      return AdminAdministrador.fromJson(elemento);
    }).toList();
  }

  Future<AdminAdministrador> obtenerPorId(int idUsuario) async {
    if (idUsuario <= 0) {
      throw Exception('ID de administrador inválido.');
    }

    final respuesta = await _solicitar(
      metodo: 'GET',
      uri: Uri.parse('$_url/$idUsuario'),
      codigoEsperado: 200,
    );

    final administrador = AdminAdministrador.fromJson(
      _leerObjeto(respuesta.body),
    );

    if (administrador.idUsuario != idUsuario) {
      throw const FormatException('El servidor devolvió otro administrador.');
    }

    return administrador;
  }

  Future<AdministradorOperacionResponse> crear(
    CrearAdministradorRequest datos,
  ) async {
    if (datos.password.length < 8) {
      throw Exception('La contraseña debe tener al menos 8 caracteres.');
    }

    if (datos.nombreCompleto.trim().isEmpty ||
        datos.correo.trim().isEmpty ||
        datos.telefono.trim().isEmpty ||
        datos.horario.trim().isEmpty ||
        datos.fechaContratacion.isEmpty ||
        !datos.sueldo.isFinite ||
        datos.sueldo <= 0) {
      throw Exception('Completa los datos obligatorios del administrador.');
    }

    final respuesta = await _solicitar(
      metodo: 'POST',
      uri: Uri.parse(_url),
      cuerpo: datos.toJson(),
      codigoEsperado: 201,
    );

    return AdministradorOperacionResponse.fromJson(_leerObjeto(respuesta.body));
  }

  Future<AdministradorOperacionResponse> editar({
    required int idUsuario,
    required EditarAdministradorRequest datos,
  }) async {
    if (idUsuario <= 0) {
      throw Exception('ID de administrador inválido.');
    }

    final respuesta = await _solicitar(
      metodo: 'PUT',
      uri: Uri.parse('$_url/$idUsuario'),
      cuerpo: datos.toJson(),
      codigoEsperado: 200,
    );

    return AdministradorOperacionResponse.fromJson(_leerObjeto(respuesta.body));
  }

  Future<AdministradorOperacionResponse> darDeBaja({
    required int idUsuario,
    required BajaAdministradorRequest datos,
  }) async {
    if (idUsuario <= 0 ||
        datos.motivoBaja.trim().isEmpty ||
        datos.fechaBaja.isEmpty) {
      throw Exception('Completa el motivo y la fecha de baja.');
    }

    final respuesta = await _solicitar(
      metodo: 'PATCH',
      uri: Uri.parse('$_url/$idUsuario/baja'),
      cuerpo: datos.toJson(),
      codigoEsperado: 200,
    );

    return AdministradorOperacionResponse.fromJson(_leerObjeto(respuesta.body));
  }
}
