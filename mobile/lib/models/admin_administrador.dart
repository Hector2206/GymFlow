class AdminAdministrador {
  final int idUsuario;
  final int idPersonal;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String horario;
  final String estatus;
  final String fechaAlta;
  final String? fechaBaja;

  const AdminAdministrador({
    required this.idUsuario,
    required this.idPersonal,
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.horario,
    required this.estatus,
    required this.fechaAlta,
    required this.fechaBaja,
  });

  factory AdminAdministrador.fromJson(Map<String, dynamic> json) {
    int leerId(dynamic valor) {
      if (valor is int) return valor;
      return int.tryParse(valor?.toString() ?? '') ?? 0;
    }

    final idUsuario = leerId(json['idUsuario']);
    final idPersonal = leerId(json['idPersonal']);

    if (idUsuario <= 0 ||
        idPersonal <= 0 ||
        json['nombreCompleto'] is! String ||
        json['correo'] is! String ||
        json['estatus'] is! String) {
      throw const FormatException('El administrador contiene datos inválidos.');
    }

    return AdminAdministrador(
      idUsuario: idUsuario,
      idPersonal: idPersonal,
      nombreCompleto: json['nombreCompleto'],
      correo: json['correo'],
      telefono: json['telefono']?.toString() ?? '',
      horario: json['horario']?.toString() ?? '',
      estatus: json['estatus'],
      fechaAlta: json['fechaAlta']?.toString() ?? '',
      fechaBaja: json['fechaBaja']?.toString(),
    );
  }

  bool get estaActivo => estatus.toLowerCase() == 'activo' && fechaBaja == null;
}

class CrearAdministradorRequest {
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String fechaContratacion;
  final double sueldo;
  final String horario;
  final String password;

  const CrearAdministradorRequest({
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.fechaContratacion,
    required this.sueldo,
    required this.horario,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'nombreCompleto': nombreCompleto.trim(),
    'correo': correo.trim().toLowerCase(),
    'telefono': telefono.trim(),
    'fechaContratacion': fechaContratacion,
    'sueldo': sueldo,
    'horario': horario.trim(),
    'password': password,
  };
}

class EditarAdministradorRequest {
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String horario;

  const EditarAdministradorRequest({
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.horario,
  });

  Map<String, dynamic> toJson() => {
    'nombreCompleto': nombreCompleto.trim(),
    'correo': correo.trim().toLowerCase(),
    'telefono': telefono.trim(),
    'horario': horario.trim(),
  };
}

class BajaAdministradorRequest {
  final String motivoBaja;
  final String fechaBaja;

  const BajaAdministradorRequest({
    required this.motivoBaja,
    required this.fechaBaja,
  });

  Map<String, dynamic> toJson() => {
    'motivoBaja': motivoBaja.trim(),
    'fechaBaja': fechaBaja,
  };
}

class AdministradorOperacionResponse {
  final String mensaje;
  final int idUsuario;

  const AdministradorOperacionResponse({
    required this.mensaje,
    required this.idUsuario,
  });

  factory AdministradorOperacionResponse.fromJson(Map<String, dynamic> json) {
    final valor = json['idUsuario'];

    final id = valor is int
        ? valor
        : int.tryParse(valor?.toString() ?? '') ?? 0;

    if (id <= 0) {
      throw const FormatException(
        'Backend no devolvió un ID de usuario válido.',
      );
    }

    return AdministradorOperacionResponse(
      mensaje: json['mensaje']?.toString() ?? '',
      idUsuario: id,
    );
  }
}
