// GYMFLOW - SPRINT 7
// MODELOS DEL DASHBOARD ADMINISTRATIVO

int _leerEntero(dynamic valor) {
  if (valor is num) {
    return valor.toInt();
  }

  return int.tryParse(valor?.toString() ?? '') ?? 0;
}

double _leerDecimal(dynamic valor) {
  if (valor is num) {
    return valor.toDouble();
  }

  return double.tryParse(valor?.toString() ?? '') ?? 0.0;
}

// TOTAL DE CLIENTES

class TotalClientesResponse {
  final int totalClientes;

  const TotalClientesResponse({required this.totalClientes});

  factory TotalClientesResponse.fromJson(Map<String, dynamic> json) {
    return TotalClientesResponse(
      totalClientes: _leerEntero(json['totalClientes']),
    );
  }
}

// MEMBRESÍAS ACTIVAS

class MembresiasActivasResponse {
  final int membresiasActivas;

  const MembresiasActivasResponse({required this.membresiasActivas});

  factory MembresiasActivasResponse.fromJson(Map<String, dynamic> json) {
    return MembresiasActivasResponse(
      membresiasActivas: _leerEntero(json['membresiasActivas']),
    );
  }
}

// ASISTENCIAS DEL DÍA

class AsistenciasDiaResponse {
  final int asistenciasDia;

  const AsistenciasDiaResponse({required this.asistenciasDia});

  factory AsistenciasDiaResponse.fromJson(Map<String, dynamic> json) {
    return AsistenciasDiaResponse(
      asistenciasDia: _leerEntero(json['asistenciasDia']),
    );
  }
}

// PAGOS REGISTRADOS

class PagosRegistradosResponse {
  final int pagosRegistrados;

  const PagosRegistradosResponse({required this.pagosRegistrados});

  factory PagosRegistradosResponse.fromJson(Map<String, dynamic> json) {
    return PagosRegistradosResponse(
      pagosRegistrados: _leerEntero(json['pagosRegistrados']),
    );
  }
}

// INGRESOS POR PERIODO

class IngresosPeriodoResponse {
  final String desde;
  final String hasta;
  final double ingresosPeriodo;

  const IngresosPeriodoResponse({
    required this.desde,
    required this.hasta,
    required this.ingresosPeriodo,
  });

  factory IngresosPeriodoResponse.fromJson(Map<String, dynamic> json) {
    return IngresosPeriodoResponse(
      desde: json['desde']?.toString() ?? '',
      hasta: json['hasta']?.toString() ?? '',
      ingresosPeriodo: _leerDecimal(json['ingresosPeriodo']),
    );
  }
}
