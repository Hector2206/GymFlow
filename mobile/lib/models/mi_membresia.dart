class MiMembresia {
  final int idCliente;
  final int idMembresia;
  final String nombrePlan;
  final double costoMensual;
  final double costoAnualidad;
  final DateTime? fechaVencimiento;
  final String estado;

  const MiMembresia({
    required this.idCliente,
    required this.idMembresia,
    required this.nombrePlan,
    required this.costoMensual,
    required this.costoAnualidad,
    required this.fechaVencimiento,
    required this.estado,
  });

  factory MiMembresia.fromJson(Map<String, dynamic> json) {
    final idCliente = int.tryParse(json['idCliente']?.toString() ?? '');

    final idMembresia = int.tryParse(json['idMembresia']?.toString() ?? '');

    final nombrePlan = json['nombrePlan'];
    final costoMensual = double.tryParse(
      json['costoMensual']?.toString() ?? '',
    );
    final costoAnualidad = double.tryParse(
      json['costoAnualidad']?.toString() ?? '',
    );

    final estado = json['estado'];
    final fechaTexto = json['fechaVencimiento'];

    DateTime? fechaVencimiento;

    if (fechaTexto != null) {
      if (fechaTexto is! String) {
        throw const FormatException('Fecha de vencimiento inválida.');
      }

      fechaVencimiento = DateTime.tryParse(fechaTexto);

      if (fechaVencimiento == null) {
        throw const FormatException('Fecha de vencimiento inválida.');
      }
    }

    if (idCliente == null ||
        idCliente <= 0 ||
        idMembresia == null ||
        idMembresia <= 0 ||
        nombrePlan is! String ||
        nombrePlan.trim().isEmpty ||
        costoMensual == null ||
        !costoMensual.isFinite ||
        costoMensual <= 0 ||
        costoAnualidad == null ||
        !costoAnualidad.isFinite ||
        costoAnualidad <= 0 ||
        (estado != 'Vigente' && estado != 'Vencida' && estado != 'SinPagos')) {
      throw const FormatException('Los datos de la membresía no son válidos.');
    }

    return MiMembresia(
      idCliente: idCliente,
      idMembresia: idMembresia,
      nombrePlan: nombrePlan.trim(),
      costoMensual: costoMensual,
      costoAnualidad: costoAnualidad,
      fechaVencimiento: fechaVencimiento,
      estado: estado as String,
    );
  }

  String get estadoVisible {
    switch (estado) {
      case 'Vigente':
        return 'Vigente';
      case 'Vencida':
        return 'Vencida';
      case 'SinPagos':
        return 'Sin pagos registrados';
      default:
        return 'Desconocido';
    }
  }

  String get vencimientoVisible {
    final fecha = fechaVencimiento;

    if (fecha == null) {
      return 'Sin fecha de vencimiento';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }
}
