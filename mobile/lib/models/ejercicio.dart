class Ejercicio {
  final int idEjercicio;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;
  final bool activo;

  const Ejercicio({
    required this.idEjercicio,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    required this.activo,
  });

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    return Ejercicio(
      idEjercicio: _parseInt(
        json['idEjercicio'] ?? json['id_ejercicio'] ?? json['id'],
      ),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: _parseNullableString(
        json['descripcion'],
      ),
      imagenUrl: _parseNullableString(
        json['imagenUrl'] ?? json['imagen_url'],
      ),
      activo: _parseBool(
        json['activo'] ?? json['estado'] ?? true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idEjercicio': idEjercicio,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'activo': activo,
    };
  }

  Ejercicio copyWith({
    int? idEjercicio,
    String? nombre,
    String? descripcion,
    String? imagenUrl,
    bool? activo,
  }) {
    return Ejercicio(
      idEjercicio: idEjercicio ?? this.idEjercicio,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      activo: activo ?? this.activo,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final texto = value.toString().trim();

    if (texto.isEmpty) {
      return null;
    }

    return texto;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value != 0;
    }

    final texto = value?.toString().trim().toLowerCase();

    return texto == 'true' ||
        texto == '1' ||
        texto == 'activo';
  }
}