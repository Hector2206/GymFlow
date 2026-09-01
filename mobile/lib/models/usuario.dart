class Usuario {
  final String idUsuario;
  final String correo;
  final String role;
  final String name;

  const Usuario({
    required this.idUsuario,
    required this.correo,
    required this.role,
    required this.name,
  });

  factory Usuario.fromJson(
    Map<String, dynamic> json,
  ) {
    return Usuario(
      idUsuario:
          json['idUsuario']?.toString() ??
          '',

      correo:
          json['correo']?.toString() ??
          '',

      role:
          json['role']?.toString() ??
          '',

      name:
          json['name']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'correo': correo,
      'role': role,
      'name': name,
    };
  }
}