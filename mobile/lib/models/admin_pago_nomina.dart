// GYMFLOW - SPRINT 7
// MODELO DE PAGOS DE NOMINA

int _leerEnteroNomina(dynamic valor) {
  if (valor is int) return valor;

  if (valor is num && valor == valor.truncateToDouble()) {
    return valor.toInt();
  }

  return int.parse(valor.toString());
}

double _leerMontoNomina(dynamic valor) {
  if (valor is num) return valor.toDouble();

  return double.parse(valor.toString());
}

class AdminPagoNomina {
  final int idPago;
  final int idPersonal;
  final int idSalario;

  final String periodoInicio;
  final String periodoFin;
  final double monto;
  final String fechaPago;

  final String metodo;
  final String? referencia;
  final String? observaciones;
  final String estado;

  final int registradoPor;
  final int? canceladoPor;
  final String? fechaCancelacion;
  final String? motivoCancelacion;
  final String creadoEn;

  const AdminPagoNomina({
    required this.idPago,
    required this.idPersonal,
    required this.idSalario,
    required this.periodoInicio,
    required this.periodoFin,
    required this.monto,
    required this.fechaPago,
    required this.metodo,
    required this.referencia,
    required this.observaciones,
    required this.estado,
    required this.registradoPor,
    required this.canceladoPor,
    required this.fechaCancelacion,
    required this.motivoCancelacion,
    required this.creadoEn,
  });

  factory AdminPagoNomina.fromJson(Map<String, dynamic> json) {
    final idPago = _leerEnteroNomina(json['idPago']);
    final idPersonal = _leerEnteroNomina(json['idPersonal']);
    final idSalario = _leerEnteroNomina(json['idSalario']);

    final monto = _leerMontoNomina(json['monto']);

    final periodoInicio = json['periodoInicio']?.toString() ?? '';
    final periodoFin = json['periodoFin']?.toString() ?? '';
    final fechaPago = json['fechaPago']?.toString() ?? '';
    final metodo = json['metodo']?.toString() ?? '';
    final estado = json['estado']?.toString() ?? '';

    if (idPago <= 0 ||
        idPersonal <= 0 ||
        idSalario <= 0 ||
        !monto.isFinite ||
        monto <= 0 ||
        periodoInicio.isEmpty ||
        periodoFin.isEmpty ||
        fechaPago.isEmpty ||
        metodo.isEmpty ||
        estado.isEmpty) {
      throw const FormatException('El registro de nómina no es válido.');
    }

    final canceladoPorRaw = json['canceladoPor'];

    return AdminPagoNomina(
      idPago: idPago,
      idPersonal: idPersonal,
      idSalario: idSalario,
      periodoInicio: periodoInicio,
      periodoFin: periodoFin,
      monto: monto,
      fechaPago: fechaPago,
      metodo: metodo,
      referencia: json['referencia']?.toString(),
      observaciones: json['observaciones']?.toString(),
      estado: estado,
      registradoPor: _leerEnteroNomina(json['registradoPor']),
      canceladoPor: canceladoPorRaw == null
          ? null
          : _leerEnteroNomina(canceladoPorRaw),
      fechaCancelacion: json['fechaCancelacion']?.toString(),
      motivoCancelacion: json['motivoCancelacion']?.toString(),
      creadoEn: json['creadoEn']?.toString() ?? '',
    );
  }

  bool get estaCancelado => estado.trim().toLowerCase() == 'cancelado';
}
