class EjercicioRequest {
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;

  const EjercicioRequest({
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre.trim(),
      'descripcion': _limpiarTexto(descripcion),
      'imagenUrl': _limpiarTexto(imagenUrl),
    };
  }

  EjercicioRequest copyWith({
    String? nombre,
    String? descripcion,
    String? imagenUrl,
  }) {
    return EjercicioRequest(
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  static String? _limpiarTexto(String? valor) {
    if (valor == null) {
      return null;
    }

    final texto = valor.trim();

    if (texto.isEmpty) {
      return null;
    }

    return texto;
  }
}