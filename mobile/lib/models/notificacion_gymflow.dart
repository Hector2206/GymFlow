// GYMFLOW - SPRINT 8
// MODELO DE NOTIFICACIONES

class NotificacionGymflow {
  final int idNotificacion;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String fechaVencimiento;
  final bool leida;
  final String? fechaLectura;
  final String creadoEn;

  const NotificacionGymflow({
    required this.idNotificacion,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.fechaVencimiento,
    required this.leida,
    required this.fechaLectura,
    required this.creadoEn,
  });

  factory NotificacionGymflow.fromJson(Map<String, dynamic> json) {
    final idRaw = json['idNotificacion'];

    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');

    final tipo = json['tipo'];
    final titulo = json['titulo'];
    final mensaje = json['mensaje'];
    final vencimiento = json['fechaVencimiento'];
    final leida = json['leida'];
    final creadoEn = json['creadoEn'];

    if (id == null ||
        id <= 0 ||
        tipo is! String ||
        titulo is! String ||
        mensaje is! String ||
        vencimiento is! String ||
        leida is! bool ||
        creadoEn is! String ||
        titulo.trim().isEmpty ||
        vencimiento.trim().isEmpty ||
        creadoEn.trim().isEmpty) {
      throw const FormatException('Notificación con datos no válidos.');
    }

    final fechaLecturaRaw = json['fechaLectura'];

    if (fechaLecturaRaw != null && fechaLecturaRaw is! String) {
      throw const FormatException('Fecha de lectura no válida.');
    }

    return NotificacionGymflow(
      idNotificacion: id,
      tipo: tipo,
      titulo: titulo,
      mensaje: mensaje,
      fechaVencimiento: vencimiento,
      leida: leida,
      fechaLectura: fechaLecturaRaw,
      creadoEn: creadoEn,
    );
  }

  bool get esNoLeida => !leida;
}
