// GYMFLOW - SPRINT 7
// ADMINISTRACIÓN DE PERSONAL

int _leerEnteroPersonal(dynamic valor) {
  if (valor is num) {
    return valor.toInt();
  }

  return int.tryParse(valor?.toString() ?? '') ?? 0;
}

double _leerDecimalPersonal(dynamic valor) {
  if (valor is num) {
    return valor.toDouble();
  }

  return double.tryParse(valor?.toString() ?? '') ?? 0.0;
}

// DATOS DE UN EMPLEADO

class AdminPersonal {
  final int idPersonal;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String puesto;
  final double salario;
  final String fechaContratacion;
  final String? fechaBaja;
  final String estatus;
  final String horario;

  const AdminPersonal({
    required this.idPersonal,
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.puesto,
    required this.salario,
    required this.fechaContratacion,
    required this.fechaBaja,
    required this.estatus,
    required this.horario,
  });

  factory AdminPersonal.fromJson(Map<String, dynamic> json) {
    return AdminPersonal(
      idPersonal: _leerEnteroPersonal(json['idPersonal']),
      nombreCompleto: json['nombreCompleto']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      puesto: json['puesto']?.toString() ?? '',
      salario: _leerDecimalPersonal(json['salario']),
      fechaContratacion: json['fechaContratacion']?.toString() ?? '',
      fechaBaja: json['fechaBaja']?.toString(),
      estatus: json['estatus']?.toString() ?? '',
      horario: json['horario']?.toString() ?? '',
    );
  }

  bool get estaActivo => estatus.toLowerCase() == 'activo';

  bool get esEntrenador => puesto.toLowerCase() == 'entrenador';

  bool get esRecepcionista => puesto.toLowerCase() == 'recepcionista';
}

// SOLICITUD PARA REGISTRAR PERSONAL

class CrearPersonalRequest {
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String fechaContratacion;
  final String puesto;
  final double sueldo;
  final String password;

  const CrearPersonalRequest({
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.fechaContratacion,
    required this.puesto,
    required this.sueldo,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombreCompleto': nombreCompleto.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'fechaContratacion': fechaContratacion,
      'puesto': puesto,
      'sueldo': sueldo,
      'password': password,
    };
  }
}

// SOLICITUD PARA EDITAR PERSONAL

class EditarPersonalRequest {
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String horario;

  const EditarPersonalRequest({
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.horario,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombreCompleto': nombreCompleto.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'horario': horario.trim(),
    };
  }
}

// SOLICITUD DE BAJA LÓGICA

class BajaPersonalRequest {
  final String motivo;

  const BajaPersonalRequest({required this.motivo});

  Map<String, dynamic> toJson() {
    return {'motivo': motivo.trim()};
  }
}

// RESPUESTA AL CREAR PERSONAL

class CrearPersonalResponse {
  final String mensaje;
  final int idPersonal;

  const CrearPersonalResponse({
    required this.mensaje,
    required this.idPersonal,
  });

  factory CrearPersonalResponse.fromJson(Map<String, dynamic> json) {
    return CrearPersonalResponse(
      mensaje: json['mensaje']?.toString() ?? '',
      idPersonal: _leerEnteroPersonal(json['idPersonal']),
    );
  }
}

// RESPUESTA AL EDITAR PERSONAL

class EditarPersonalResponse {
  final String mensaje;
  final int idPersonal;

  const EditarPersonalResponse({
    required this.mensaje,
    required this.idPersonal,
  });

  factory EditarPersonalResponse.fromJson(Map<String, dynamic> json) {
    return EditarPersonalResponse(
      mensaje: json['mensaje']?.toString() ?? '',
      idPersonal: _leerEnteroPersonal(json['idPersonal']),
    );
  }
}

// RESPUESTA AL DAR DE BAJA

class BajaPersonalResponse {
  final String mensaje;
  final int idPersonal;
  final int clientesDesasignados;

  const BajaPersonalResponse({
    required this.mensaje,
    required this.idPersonal,
    required this.clientesDesasignados,
  });

  factory BajaPersonalResponse.fromJson(Map<String, dynamic> json) {
    return BajaPersonalResponse(
      mensaje: json['mensaje']?.toString() ?? '',
      idPersonal: _leerEnteroPersonal(json['idPersonal']),
      clientesDesasignados: _leerEnteroPersonal(json['clientesDesasignados']),
    );
  }
}
