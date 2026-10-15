
class ClienteResumen {
  final int idCliente;
  final String nombreCompleto;
  final int? idEntrenador;
  final String? nombreEntrenador;

  const ClienteResumen({
    required this.idCliente,
    required this.nombreCompleto,
    this.idEntrenador,
    this.nombreEntrenador,
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
      idCliente:
          convertirId(json['idCliente']) ?? 0,
      nombreCompleto:
          json['nombreCompleto']?.toString() ?? '',
      idEntrenador:
          convertirId(json['idEntrenador']),
      nombreEntrenador:
          json['nombreEntrenador']?.toString(),
    );
  }
}
