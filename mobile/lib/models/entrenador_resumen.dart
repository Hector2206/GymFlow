
class EntrenadorResumen {
  final int idEntrenador;
  final String nombreCompleto;

  const EntrenadorResumen({
    required this.idEntrenador,
    required this.nombreCompleto,
  });

  factory EntrenadorResumen.fromJson(
    Map<String, dynamic> json,
  ) {
    return EntrenadorResumen(
      idEntrenador: json['idEntrenador'] is int
          ? json['idEntrenador']
          : int.tryParse(
                json['idEntrenador']?.toString() ?? '',
              ) ??
              0,
      nombreCompleto:
          json['nombreCompleto']?.toString() ?? '',
    );
  }
}
