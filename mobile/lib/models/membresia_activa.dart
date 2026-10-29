// GYMFLOW - SPRINT 7
// Precios oficiales leidos del backend; nunca se envian al registrar.
class MembresiaActiva {
  final int idMembresia;
  final String nombrePlan;
  final double costoMensual;
  final double costoAnualidad;
  final String descripcion;
  final bool activo;

  const MembresiaActiva({
    required this.idMembresia,
    required this.nombrePlan,
    required this.costoMensual,
    required this.costoAnualidad,
    required this.descripcion,
    required this.activo,
  });

  factory MembresiaActiva.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['idMembresia']?.toString() ?? '');
    final mensual = double.tryParse(json['costoMensual']?.toString() ?? '');
    final anual = double.tryParse(json['costoAnualidad']?.toString() ?? '');
    final nombre = json['nombrePlan']?.toString().trim() ?? '';
    final activo = json['activo'];

    if (id == null ||
        id <= 0 ||
        mensual == null ||
        !mensual.isFinite ||
        mensual <= 0 ||
        anual == null ||
        !anual.isFinite ||
        anual <= 0 ||
        nombre.isEmpty ||
        activo != true) {
      throw const FormatException('Membresia activa invalida.');
    }

    return MembresiaActiva(
      idMembresia: id,
      nombrePlan: nombre,
      costoMensual: mensual,
      costoAnualidad: anual,
      descripcion: json['descripcion']?.toString() ?? '',
      activo: true,
    );
  }
}
