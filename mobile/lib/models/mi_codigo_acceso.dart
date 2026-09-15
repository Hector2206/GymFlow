class MiCodigoAcceso {
  final int idCliente;
  final String codigoAcceso;
  final String nombreCompleto;

  const MiCodigoAcceso({
    required this.idCliente,
    required this.codigoAcceso,
    required this.nombreCompleto,
  });

  factory MiCodigoAcceso.fromJson(
    Map<String, dynamic> json,
  ) {
    return MiCodigoAcceso(
      idCliente:
          int.tryParse(
            json['idCliente']?.toString() ?? '',
          ) ??
          0,

      codigoAcceso:
          json['codigoAcceso']?.toString() ?? '',

      nombreCompleto:
          json['nombreCompleto']?.toString() ?? '',
    );
  }
}