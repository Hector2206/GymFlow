
class Progreso {
  final int idProgreso;
  final int idCliente;
  final int idEjercicio;
  final String nombreEjercicio;
  final double pesoUtilizado;
  final DateTime fechaRegistro;

  const Progreso({
    required this.idProgreso,
    required this.idCliente,
    required this.idEjercicio,
    required this.nombreEjercicio,
    required this.pesoUtilizado,
    required this.fechaRegistro,
  });

  factory Progreso.fromJson(Map<String, dynamic> json) {
    return Progreso(
      idProgreso: (json['idProgreso'] as num).toInt(),
      idCliente: (json['idCliente'] as num).toInt(),
      idEjercicio: (json['idEjercicio'] as num).toInt(),
      nombreEjercicio: json['nombreEjercicio'] as String,
      pesoUtilizado: (json['pesoUtilizado'] as num).toDouble(),
      fechaRegistro: DateTime.parse(
        json['fechaRegistro'] as String,
      ),
    );
  }
}
