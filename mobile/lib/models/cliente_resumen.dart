
class ClienteResumen {
  final int idCliente;
  final String nombreCompleto;

  final int? idEntrenador;
  final String? nombreEntrenador;

  final int? idMembresia;
  final String? nombrePlan;

  const ClienteResumen({
    required this.idCliente,
    required this.nombreCompleto,
    this.idEntrenador,
    this.nombreEntrenador,
    this.idMembresia,
    this.nombrePlan,
  });

  factory ClienteResumen.fromJson(
    Map<String, dynamic> json,
  ) {
    int? convertirId(dynamic valor) {
      if (valor == null) return null;
      if (valor is int) return valor;
      return int.tryParse(valor.toString());
    }

    return ClienteResumen(
      idCliente: convertirId(json['idCliente']) ?? 0,
      nombreCompleto:
          json['nombreCompleto']?.toString() ?? '',
      idEntrenador: convertirId(json['idEntrenador']),
      nombreEntrenador: json['nombreEntrenador']?.toString(),
      idMembresia: convertirId(json['idMembresia']),
      nombrePlan: json['nombrePlan']?.toString(),
    );
  }
}
