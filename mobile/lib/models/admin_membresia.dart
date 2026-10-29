class AdminMembresia {
  final int idMembresia;
  final String nombrePlan;
  final double costoMensual;
  final double costoAnualidad;
  final String descripcion;
  final bool activo;

  const AdminMembresia({
    required this.idMembresia,
    required this.nombrePlan,
    required this.costoMensual,
    required this.costoAnualidad,
    required this.descripcion,
    required this.activo,
  });

  factory AdminMembresia.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['idMembresia']?.toString() ?? '');

    final mensual = double.tryParse(json['costoMensual']?.toString() ?? '');

    final anual = double.tryParse(json['costoAnualidad']?.toString() ?? '');

    final nombre = json['nombrePlan'];
    final descripcion = json['descripcion'];
    final activo = json['activo'];

    if (id == null ||
        id <= 0 ||
        mensual == null ||
        !mensual.isFinite ||
        mensual <= 0 ||
        anual == null ||
        !anual.isFinite ||
        anual <= 0 ||
        nombre is! String ||
        nombre.trim().isEmpty ||
        descripcion is! String ||
        activo is! bool) {
      throw const FormatException('La membresía contiene datos no válidos.');
    }

    return AdminMembresia(
      idMembresia: id,
      nombrePlan: nombre.trim(),
      costoMensual: mensual,
      costoAnualidad: anual,
      descripcion: descripcion,
      activo: activo,
    );
  }
}
