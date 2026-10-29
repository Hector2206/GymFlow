import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/mi_membresia.dart';

void main() {
  Map<String, dynamic> respuesta({
    String estado = 'Vigente',
    String? vencimiento = '2027-09-22T00:00:00',
  }) {
    return {
      'idCliente': 1,
      'idMembresia': 1,
      'nombrePlan': 'BasicFlow',
      'costoMensual': 250.00,
      'costoAnualidad': 500.00,
      'fechaVencimiento': vencimiento,
      'estado': estado,
    };
  }

  test('Membresía vigente muestra datos oficiales', () {
    final membresia = MiMembresia.fromJson(respuesta());

    expect(membresia.nombrePlan, 'BasicFlow');
    expect(membresia.costoMensual, 250);
    expect(membresia.costoAnualidad, 500);
    expect(membresia.estado, 'Vigente');
    expect(membresia.vencimientoVisible, '22/09/2027');
  });

  test('Membresía vencida conserva su estado', () {
    final membresia = MiMembresia.fromJson(respuesta(estado: 'Vencida'));

    expect(membresia.estado, 'Vencida');
  });

  test('Sin pagos permite vencimiento nulo', () {
    final membresia = MiMembresia.fromJson(
      respuesta(estado: 'SinPagos', vencimiento: null),
    );

    expect(membresia.fechaVencimiento, isNull);
    expect(membresia.estadoVisible, 'Sin pagos registrados');
  });
}
