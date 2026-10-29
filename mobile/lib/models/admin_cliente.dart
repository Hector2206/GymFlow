// GYMFLOW - SPRINT 7
// MODELO DE CLIENTES PARA ADMINISTRADOR

int _leerIdCliente(dynamic valor) {
  if (valor is num) {
    return valor.toInt();
  }

  return int.tryParse(valor?.toString() ?? '') ?? 0;
}

// CLIENTE DEVUELTO POR EL BACKEND

class AdminCliente {
  final int idCliente;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final int idMembresia;
  final String nombrePlan;
  final String estatus;
  final String vigencia;
  final String? fechaVencimiento;

  const AdminCliente({
    required this.idCliente,
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.idMembresia,
    required this.nombrePlan,
    required this.estatus,
    required this.vigencia,
    required this.fechaVencimiento,
  });

  factory AdminCliente.fromJson(Map<String, dynamic> json) {
    return AdminCliente(
      idCliente: _leerIdCliente(json['idCliente']),
      nombreCompleto: json['nombreCompleto']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      idMembresia: _leerIdCliente(json['idMembresia']),
      nombrePlan: json['nombrePlan']?.toString() ?? '',
      estatus: json['estatus']?.toString() ?? '',
      vigencia: json['vigencia']?.toString() ?? '',
      fechaVencimiento: json['fechaVencimiento']?.toString(),
    );
  }

  bool get estaActivo {
    return estatus.toLowerCase() == 'activo';
  }

  bool get membresiaVigente {
    return vigencia.toLowerCase() == 'vigente';
  }
}

// FILTROS DE CONSULTA

class AdminClienteFiltros {
  final String? nombre;
  final String? correo;
  final String? estatus;
  final String? vigencia;
  final int? idMembresia;

  const AdminClienteFiltros({
    this.nombre,
    this.correo,
    this.estatus,
    this.vigencia,
    this.idMembresia,
  });

  Map<String, String> get queryParameters {
    final parametros = <String, String>{};

    final nombreBuscado = nombre?.trim();
    final correoBuscado = correo?.trim();

    if (nombreBuscado != null && nombreBuscado.isNotEmpty) {
      parametros['nombre'] = nombreBuscado;
    }

    if (correoBuscado != null && correoBuscado.isNotEmpty) {
      parametros['correo'] = correoBuscado;
    }

    if (estatus != null && estatus!.isNotEmpty) {
      parametros['estatus'] = estatus!;
    }

    if (vigencia != null && vigencia!.isNotEmpty) {
      parametros['vigencia'] = vigencia!;
    }

    if (idMembresia != null) {
      parametros['idMembresia'] = idMembresia.toString();
    }

    return parametros;
  }
}
