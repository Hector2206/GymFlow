// GYMFLOW - SPRINT 7
// MODELO DEL HISTORIAL SALARIAL

class AdminSalario {
  final int idSalario;
  final int idPersonal;
  final double monto;
  final String periodicidad;
  final String vigenteDesde;
  final String? vigenteHasta;
  final String? motivo;
  final int? registradoPor;
  final String creadoEn;

  const AdminSalario({
    required this.idSalario,
    required this.idPersonal,
    required this.monto,
    required this.periodicidad,
    required this.vigenteDesde,
    required this.vigenteHasta,
    required this.motivo,
    required this.registradoPor,
    required this.creadoEn,
  });

  factory AdminSalario.fromJson(Map<String, dynamic> json) {
    int leerEntero(dynamic valor) {
      if (valor is int) return valor;

      return int.parse(valor.toString());
    }

    final montoRaw = json['monto'];

    final monto = montoRaw is num
        ? montoRaw.toDouble()
        : double.parse(montoRaw.toString());

    final idSalario = leerEntero(json['idSalario']);
    final idPersonal = leerEntero(json['idPersonal']);

    final periodicidad = json['periodicidad']?.toString() ?? '';

    final vigenteDesde = json['vigenteDesde']?.toString() ?? '';

    if (idSalario <= 0 ||
        idPersonal <= 0 ||
        !monto.isFinite ||
        monto < 0 ||
        periodicidad.isEmpty ||
        vigenteDesde.isEmpty) {
      throw const FormatException('Registro salarial no válido.');
    }

    final registradoPorRaw = json['registradoPor'];

    return AdminSalario(
      idSalario: idSalario,
      idPersonal: idPersonal,
      monto: monto,
      periodicidad: periodicidad,
      vigenteDesde: vigenteDesde,
      vigenteHasta: json['vigenteHasta']?.toString(),
      motivo: json['motivo']?.toString(),
      registradoPor: registradoPorRaw == null
          ? null
          : leerEntero(registradoPorRaw),
      creadoEn: json['creadoEn']?.toString() ?? '',
    );
  }
}
