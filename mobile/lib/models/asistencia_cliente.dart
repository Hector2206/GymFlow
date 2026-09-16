class AsistenciaCliente {
  final int idAsistencia;
  final String fechaHora;
  final String estadoAcceso;
  final String origenRegistro;

  const AsistenciaCliente({
    required this.idAsistencia,
    required this.fechaHora,
    required this.estadoAcceso,
    required this.origenRegistro,
  });

  factory AsistenciaCliente.fromJson(
    Map<String, dynamic> json,
  ) {
    return AsistenciaCliente(
      idAsistencia:
          int.tryParse(
            json['idAsistencia']?.toString() ?? '',
          ) ??
          0,

      fechaHora:
          json['fechaHora']?.toString() ?? '',

      estadoAcceso:
          json['estadoAcceso']?.toString() ?? '',

      origenRegistro:
          json['origenRegistro']?.toString() ?? '',
    );
  }

  DateTime? get fechaHoraDateTime {
    if (fechaHora.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(
        fechaHora,
      ).toLocal();
    } catch (_) {
      return null;
    }
  }
}