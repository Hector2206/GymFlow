class PagoCliente {
  final int idPago;
  final double monto;
  final String tipoPago;
  final String fechaTransaccion;

  const PagoCliente({
    required this.idPago,
    required this.monto,
    required this.tipoPago,
    required this.fechaTransaccion,
  });

  factory PagoCliente.fromJson(
    Map<String, dynamic> json,
  ) {
    return PagoCliente(
      idPago:
          int.tryParse(
            json['idPago']?.toString() ?? '',
          ) ??
          0,

      monto:
          double.tryParse(
            json['monto']?.toString() ?? '',
          ) ??
          0,

      tipoPago:
          json['tipoPago']?.toString() ?? '',

      fechaTransaccion:
          json['fechaTransaccion']?.toString() ?? '',
    );
  }

  DateTime? get fechaTransaccionDateTime {
    if (fechaTransaccion.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(
        fechaTransaccion,
      ).toLocal();
    } catch (_) {
      return null;
    }
  }
}