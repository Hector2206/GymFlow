class AsistenciaPersonal {
  final int idAsistenciaPersonal;
  final int idPersonal;
  final String nombreCompleto;
  final String fecha;
  final String horaEntrada;
  final String? horaSalida;
  final int registradoPor;
  final int? salidaRegistradaPor;
  final String fechaRegistro;
  final String? fechaRegistroSalida;

  const AsistenciaPersonal({
    required this.idAsistenciaPersonal,
    required this.idPersonal,
    required this.nombreCompleto,
    required this.fecha,
    required this.horaEntrada,
    required this.horaSalida,
    required this.registradoPor,
    required this.salidaRegistradaPor,
    required this.fechaRegistro,
    required this.fechaRegistroSalida,
  });

  factory AsistenciaPersonal.fromJson(Map<String, dynamic> json) {
    int entero(dynamic valor) =>
        valor is int ? valor : int.tryParse('$valor') ?? 0;

    int? enteroOpcional(dynamic valor) => valor == null ? null : entero(valor);

    final id = entero(json['idAsistenciaPersonal']);
    final personal = entero(json['idPersonal']);
    final administrador = entero(json['registradoPor']);

    if (id <= 0 || personal <= 0 || administrador <= 0) {
      throw const FormatException(
        'La asistencia contiene identificadores inválidos.',
      );
    }

    return AsistenciaPersonal(
      idAsistenciaPersonal: id,
      idPersonal: personal,
      nombreCompleto: json['nombreCompleto']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      horaEntrada: json['horaEntrada']?.toString() ?? '',
      horaSalida: json['horaSalida']?.toString(),
      registradoPor: administrador,
      salidaRegistradaPor: enteroOpcional(json['salidaRegistradaPor']),
      fechaRegistro: json['fechaRegistro']?.toString() ?? '',
      fechaRegistroSalida: json['fechaRegistroSalida']?.toString(),
    );
  }

  bool get pendienteSalida => horaSalida == null;

  String get fechaVisible {
    final partes = fecha.split('-');
    if (partes.length != 3) return fecha;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  String get entradaVisible =>
      horaEntrada.length >= 5 ? horaEntrada.substring(0, 5) : horaEntrada;

  String get salidaVisible => horaSalida == null
      ? 'Pendiente'
      : horaSalida!.length >= 5
      ? horaSalida!.substring(0, 5)
      : horaSalida!;
}
