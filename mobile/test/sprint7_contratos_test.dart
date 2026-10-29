import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/models/membresia_activa.dart';
import 'package:mobile/services/pago_service.dart';

void main() {
  test('Membresía activa interpreta precios oficiales', () {
    final membresia = MembresiaActiva.fromJson({
      'idMembresia': 1,
      'nombrePlan': 'BasicFlow',
      'costoMensual': 250.00,
      'costoAnualidad': 500.00,
      'descripcion': '',
      'activo': true,
    });

    expect(membresia.idMembresia, 1);
    expect(membresia.nombrePlan, 'BasicFlow');
    expect(membresia.costoMensual, 250.00);
    expect(membresia.costoAnualidad, 500.00);
    expect(membresia.activo, true);
  });

  test('Pago repetido interpreta respuesta oficial', () {
    final respuesta = ResultadoRegistroPago.fromJson({
      'pagoRegistrado': true,
      'pagoRepetido': true,
      'idPago': 27,
      'esRenovacion': null,
      'idCliente': 22,
      'monto': 250.00,
      'tipoPago': 'Mensualidad',
      'fechaVencimiento': '2026-11-29T00:00:00',
      'mensaje': 'Este pago ya había sido procesado.',
    });

    expect(respuesta.pagoRegistrado, true);
    expect(respuesta.pagoRepetido, true);
    expect(respuesta.idPago, 27);
    expect(respuesta.esRenovacion, isNull);
    expect(respuesta.monto, 250.00);
  });

  test('Operación pendiente conserva el UUID', () {
    const uuid = '550e8400-e29b-41d4-a716-446655440000';

    const operacion = PagoPendiente(
      idCliente: 22,
      tipoPago: 'Mensualidad',
      clave: uuid,
    );

    final recuperada = PagoPendiente.fromJson(
      jsonDecode(jsonEncode(operacion.toJson())) as Map<String, dynamic>,
    );

    expect(recuperada.idCliente, 22);
    expect(recuperada.tipoPago, 'Mensualidad');
    expect(recuperada.clave, uuid);
  });
}
