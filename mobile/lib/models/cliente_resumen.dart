class ClienteResumen {
  final int idCliente;
  final String nombreCompleto;

  const ClienteResumen({
    required this.idCliente,
    required this.nombreCompleto,
  });

  factory ClienteResumen.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClienteResumen(
      idCliente:
          int.tryParse(
            json['idCliente']?.toString() ?? '',
          ) ??
          0,
      nombreCompleto:
          json['nombreCompleto']?.toString() ?? '',
    );
  }
}