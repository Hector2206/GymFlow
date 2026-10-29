import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_personal.dart';
import 'auth_service.dart';

// GYMFLOW - SPRINT 7
// SERVICIO DE ADMINISTRACION DE PERSONAL

class AdminPersonalService {
  final AuthService _authService = AuthService();

  static const Duration _tiempoEspera = Duration(seconds: 50);

  // ==========================================
  // AUTENTICACION JWT
  // ==========================================

  Future<Map<String, String>> _headers() async {
    final token = await _authService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Tu sesión no es válida. '
        'Inicia sesión nuevamente.',
      );
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // VALIDAR ID DEL EMPLEADO
  // ==========================================

  void _validarId(int idPersonal) {
    if (idPersonal <= 0) {
      throw Exception('El ID del empleado no es válido.');
    }
  }

  // ==========================================
  // REALIZAR PETICIONES HTTP
  // ==========================================

  Future<http.Response> _solicitar({
    required String metodo,
    required Uri uri,
    Map<String, dynamic>? cuerpo,
    required Set<int> codigosAceptados,
  }) async {
    final headers = await _headers();

    final cliente = http.Client();

    try {
      final peticion = http.Request(metodo, uri);

      if (cuerpo != null) {
        peticion.body = jsonEncode(cuerpo);
      }

      peticion.headers.addAll(headers);

      final respuesta = await _ejecutarPeticion(
        cliente,
        peticion,
      ).timeout(_tiempoEspera);

      _validarRespuesta(respuesta, codigosAceptados);

      return respuesta;
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Actualiza los datos antes de volver '
        'a intentar una operación.',
      );
    } on http.ClientException {
      throw Exception(
        'No fue posible conectar con el servidor. '
        'Comprueba tu conexión.',
      );
    } finally {
      cliente.close();
    }
  }

  Future<http.Response> _ejecutarPeticion(
    http.Client cliente,
    http.Request peticion,
  ) async {
    final respuesta = await cliente.send(peticion);

    return http.Response.fromStream(respuesta);
  }

  // ==========================================
  // VALIDAR RESPUESTAS DEL SERVIDOR
  // ==========================================

  void _validarRespuesta(http.Response respuesta, Set<int> codigosAceptados) {
    if (codigosAceptados.contains(respuesta.statusCode)) {
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
        'No tienes permisos para administrar '
        'el personal del gimnasio.',
      );
    }

    String mensaje;

    switch (respuesta.statusCode) {
      case 400:
        mensaje = 'Los datos enviados no son válidos.';
        break;

      case 404:
        mensaje = 'El empleado solicitado no existe.';
        break;

      case 409:
        mensaje =
            'Existe un conflicto con los datos. '
            'Consulta la información actual.';
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        mensaje =
            'El servidor no pudo completar '
            'la solicitud. Intenta nuevamente.';
        break;

      default:
        mensaje =
            'No fue posible completar la solicitud '
            '(código ${respuesta.statusCode}).';
    }

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

  // ==========================================
  // CONVERTIR RESPUESTA A OBJETO
  // ==========================================

  Map<String, dynamic> _convertirObjeto(String respuesta) {
    try {
      final datos = jsonDecode(respuesta);

      if (datos is Map<String, dynamic>) {
        return datos;
      }
    } on FormatException {
      // El formato no corresponde a JSON válido.
    }

    throw Exception(
      'El servidor devolvió información '
      'con un formato no válido.',
    );
  }

  // ==========================================
  // 1. CONSULTAR TODOS LOS EMPLEADOS
  //
  // GET /api/admin/personal
  // ==========================================

  Future<List<AdminPersonal>> obtenerPersonal() async {
    final respuesta = await _solicitar(
      metodo: 'GET',
      uri: Uri.parse(ApiConfig.adminPersonalUrl),
      codigosAceptados: {200},
    );

    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw const FormatException();
      }

      final empleados = <AdminPersonal>[];

      for (final elemento in datos) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException();
        }

        final empleado = AdminPersonal.fromJson(elemento);

        if (empleado.idPersonal <= 0 ||
            empleado.nombreCompleto.trim().isEmpty) {
          throw const FormatException();
        }

        empleados.add(empleado);
      }

      // Una lista vacía es válida.
      return empleados;
    } on FormatException {
      throw Exception(
        'El servidor devolvió una lista de '
        'empleados con formato no válido.',
      );
    }
  }

  // ==========================================
  // 2. CONSULTAR EMPLEADO POR ID
  //
  // GET /api/admin/personal/{id}
  // ==========================================

  Future<AdminPersonal> obtenerPersonalPorId(int idPersonal) async {
    _validarId(idPersonal);

    final respuesta = await _solicitar(
      metodo: 'GET',
      uri: Uri.parse('${ApiConfig.adminPersonalUrl}/$idPersonal'),
      codigosAceptados: {200},
    );

    final datos = _convertirObjeto(respuesta.body);

    final empleado = AdminPersonal.fromJson(datos);

    if (empleado.idPersonal <= 0) {
      throw Exception(
        'El servidor devolvió un empleado '
        'con información no válida.',
      );
    }

    return empleado;
  }

  // ==========================================
  // 3. REGISTRAR NUEVO EMPLEADO
  //
  // POST /api/admin/personal
  // ==========================================

  Future<CrearPersonalResponse> crearPersonal(
    CrearPersonalRequest datos,
  ) async {
    if (datos.nombreCompleto.trim().isEmpty ||
        datos.correo.trim().isEmpty ||
        datos.telefono.trim().isEmpty) {
      throw Exception(
        'Completa el nombre, correo '
        'y teléfono del empleado.',
      );
    }

    if (datos.puesto != 'Entrenador' && datos.puesto != 'Recepcionista') {
      throw Exception('Selecciona un puesto válido.');
    }

    if (!datos.sueldo.isFinite || datos.sueldo <= 0) {
      throw Exception('El sueldo debe ser mayor que cero.');
    }

    if (datos.password.length < 8) {
      throw Exception(
        'La contraseña debe contener '
        'al menos 8 caracteres.',
      );
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(datos.fechaContratacion)) {
      throw Exception(
        'La fecha de contratación debe '
        'tener formato YYYY-MM-DD.',
      );
    }

    final respuesta = await _solicitar(
      metodo: 'POST',
      uri: Uri.parse(ApiConfig.adminPersonalUrl),
      cuerpo: datos.toJson(),
      codigosAceptados: {201},
    );

    return CrearPersonalResponse.fromJson(_convertirObjeto(respuesta.body));
  }

  // ==========================================
  // 4. EDITAR INFORMACION DEL EMPLEADO
  //
  // PUT /api/admin/personal/{id}
  // ==========================================

  Future<EditarPersonalResponse> editarPersonal({
    required int idPersonal,
    required EditarPersonalRequest datos,
  }) async {
    _validarId(idPersonal);

    if (datos.nombreCompleto.trim().isEmpty ||
        datos.correo.trim().isEmpty ||
        datos.telefono.trim().isEmpty) {
      throw Exception(
        'Completa el nombre, correo '
        'y teléfono del empleado.',
      );
    }

    final respuesta = await _solicitar(
      metodo: 'PUT',
      uri: Uri.parse('${ApiConfig.adminPersonalUrl}/$idPersonal'),
      cuerpo: datos.toJson(),
      codigosAceptados: {200},
    );

    // La edición no modifica sueldo,
    // puesto ni contraseña.
    return EditarPersonalResponse.fromJson(_convertirObjeto(respuesta.body));
  }

  // ==========================================
  // 5. DAR DE BAJA LOGICA AL EMPLEADO
  //
  // PATCH /api/admin/personal/{id}/baja
  // ==========================================

  Future<BajaPersonalResponse> darDeBajaPersonal({
    required int idPersonal,
    required String motivo,
  }) async {
    _validarId(idPersonal);

    if (motivo.trim().isEmpty) {
      throw Exception('Debes escribir el motivo de la baja.');
    }

    final datos = BajaPersonalRequest(motivo: motivo.trim());

    final respuesta = await _solicitar(
      metodo: 'PATCH',
      uri: Uri.parse(
        '${ApiConfig.adminPersonalUrl}'
        '/$idPersonal/baja',
      ),
      cuerpo: datos.toJson(),
      codigosAceptados: {200},
    );

    // Al dar de baja a un entrenador,
    // el backend puede desasignar clientes.
    return BajaPersonalResponse.fromJson(_convertirObjeto(respuesta.body));
  }
}
