class Rutina {
  final int idRutina;
  final String nombre;
  final String? descripcion;
  final int idCliente;
  final String nombreCliente;
  final List<DiaRutina> dias;

  Rutina({
    required this.idRutina,
    required this.nombre,
    this.descripcion,
    required this.idCliente,
    required this.nombreCliente,
    this.dias = const [],
  });

  factory Rutina.fromJson(
    Map<String, dynamic> json,
  ) {
    return Rutina(
      idRutina:
          json['idRutina'] is int
              ? json['idRutina']
              : int.tryParse(
                    json['idRutina']?.toString() ?? '',
                  ) ??
                  0,
      nombre:
          json['nombre']?.toString() ??
          '',
      descripcion:
          json['descripcion']?.toString(),
      idCliente:
          json['idCliente'] is int
              ? json['idCliente']
              : int.tryParse(
                    json['idCliente']?.toString() ?? '',
                  ) ??
                  0,
      nombreCliente:
          json['nombreCliente']?.toString() ??
          '',
      dias:
          (json['dias'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(
                DiaRutina.fromJson,
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCliente': idCliente,
      'nombre': nombre,
      'descripcion': descripcion,
      'dias': dias
          .map(
            (dia) => dia.toJson(),
          )
          .toList(),
    };
  }
}


class DiaRutina {
  final int? idDia;
  final String dia;
  final List<EjercicioRutina> ejercicios;

  DiaRutina({
    this.idDia,
    required this.dia,
    this.ejercicios = const [],
  });

  factory DiaRutina.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiaRutina(
      idDia:
          json['idDia'] is int
              ? json['idDia']
              : int.tryParse(
                    json['idDia']?.toString() ?? '',
                  ),
      dia:
          json['dia']?.toString() ??
          '',
      ejercicios:
          (json['ejercicios'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(
                EjercicioRutina.fromJson,
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'ejercicios': ejercicios
          .map(
            (ejercicio) =>
                ejercicio.toJson(),
          )
          .toList(),
    };
  }
}


class EjercicioRutina {
  final int? idEjercicioRutina;
  final int idEjercicio;
  final String nombre;
  final String? descripcion;
  final int series;
  final int repeticiones;
  final int orden;
  final String? imagenUrl;

  EjercicioRutina({
    this.idEjercicioRutina,
    required this.idEjercicio,
    required this.nombre,
    this.descripcion,
    required this.series,
    required this.repeticiones,
    required this.orden,
    this.imagenUrl,
  });

  factory EjercicioRutina.fromJson(
    Map<String, dynamic> json,
  ) {
    return EjercicioRutina(
      idEjercicioRutina:
          json['idEjercicioRutina'] is int
              ? json['idEjercicioRutina']
              : int.tryParse(
                    json['idEjercicioRutina']
                            ?.toString() ??
                        '',
                  ),
      idEjercicio:
          json['idEjercicio'] is int
              ? json['idEjercicio']
              : int.tryParse(
                    json['idEjercicio']?.toString() ??
                        '',
                  ) ??
              0,
      nombre:
          json['nombre']?.toString() ??
          '',
      descripcion:
          json['descripcion']?.toString(),
      series:
          json['series'] is int
              ? json['series']
              : int.tryParse(
                    json['series']?.toString() ??
                        '',
                  ) ??
              0,
      repeticiones:
          json['repeticiones'] is int
              ? json['repeticiones']
              : int.tryParse(
                    json['repeticiones']
                            ?.toString() ??
                        '',
                  ) ??
              0,
      orden:
          json['orden'] is int
              ? json['orden']
              : int.tryParse(
                    json['orden']?.toString() ??
                        '',
                  ) ??
              0,
      imagenUrl:
          json['imagenUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idEjercicio': idEjercicio,
      'series': series,
      'repeticiones':
          repeticiones,
      'orden': orden,
    };
  }
}