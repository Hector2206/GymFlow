import 'package:flutter/material.dart';

import '../models/admin_pago_nomina.dart';
import '../models/admin_personal.dart';
import '../services/admin_nomina_service.dart';

// GYMFLOW - SPRINT 7
// HISTORIAL DE PAGOS DE NOMINA

class AdminNominaPage extends StatefulWidget {
  final AdminPersonal empleado;

  const AdminNominaPage({super.key, required this.empleado});

  @override
  State<AdminNominaPage> createState() => _AdminNominaPageState();
}

class _AdminNominaPageState extends State<AdminNominaPage> {
  final AdminNominaService _servicio = AdminNominaService();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  List<AdminPagoNomina> _pagos = [];

  bool _cargando = true;
  String? _error;

  int _numeroConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarPagos();
  }

  @override
  void dispose() {
    _numeroConsulta++;
    super.dispose();
  }

  // CONSULTAR PAGOS REALES

  Future<void> _cargarPagos() async {
    final consultaActual = ++_numeroConsulta;

    setState(() {
      _cargando = true;
      _error = null;
      _pagos = [];
    });

    try {
      final resultado = await _servicio.obtenerPagos(
        widget.empleado.idPersonal,
      );

      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _pagos = resultado;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _cargando = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // MOSTRAR FECHAS SIN CAMBIAR EL DIA

  String _mostrarFecha(String? fecha) {
    if (fecha == null || fecha.trim().isEmpty) {
      return 'Sin fecha';
    }

    final valor = fecha.trim();

    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(valor)) {
      return '${valor.substring(8, 10)}/'
          '${valor.substring(5, 7)}/'
          '${valor.substring(0, 4)}';
    }

    return valor;
  }

  // MOSTRAR CANTIDADES EN MXN

  String _mostrarMonto(double monto) {
    final partes = monto.abs().toStringAsFixed(2).split('.');

    final digitos = partes[0];
    final resultado = StringBuffer();

    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) {
        resultado.write(',');
      }

      resultado.write(digitos[i]);
    }

    final signo = monto < 0 ? '-' : '';

    return '$signo\$${resultado.toString()}'
        '.${partes[1]} MXN';
  }

  // VALORES OPCIONALES

  String _mostrarOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Sin registrar';
    }

    return valor;
  }

  // FILAS DE INFORMACION

  Widget _detalle({
    required String etiqueta,
    required String valor,
    IconData? icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, color: _doradoOscuro, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(color: _secundario, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE PAGO

  Widget _tarjetaPago(AdminPagoNomina pago) {
    final cancelado = pago.estaCancelado;

    final colorEstado = cancelado
        ? const Color(0xFFA03930)
        : const Color(0xFF287447);

    final fondoEstado = cancelado
        ? const Color(0xFFFCE9E6)
        : const Color(0xFFE7F3E8);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _doradoOscuro,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mostrarMonto(pago.monto),
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pago #${pago.idPago}',
                      style: const TextStyle(color: _secundario, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ESTADO DEL PAGO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: fondoEstado,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pago.estado,
              style: TextStyle(
                color: colorEstado,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 17),

          const Divider(color: _borde),

          const SizedBox(height: 12),

          _detalle(
            etiqueta: 'Periodo cubierto',
            valor:
                '${_mostrarFecha(pago.periodoInicio)} '
                'al ${_mostrarFecha(pago.periodoFin)}',
            icono: Icons.date_range_outlined,
          ),

          _detalle(
            etiqueta: 'Fecha de pago',
            valor: _mostrarFecha(pago.fechaPago),
            icono: Icons.event_outlined,
          ),

          _detalle(
            etiqueta: 'Método de pago',
            valor: pago.metodo,
            icono: Icons.payments_outlined,
          ),

          _detalle(
            etiqueta: 'Referencia',
            valor: _mostrarOpcional(pago.referencia),
            icono: Icons.tag_outlined,
          ),

          _detalle(
            etiqueta: 'Observaciones',
            valor: _mostrarOpcional(pago.observaciones),
            icono: Icons.notes_outlined,
          ),

          _detalle(
            etiqueta: 'Salario relacionado',
            valor: 'Registro #${pago.idSalario}',
            icono: Icons.history_outlined,
          ),

          _detalle(
            etiqueta: 'Registrado por',
            valor: 'Usuario #${pago.registradoPor}',
            icono: Icons.person_outline,
          ),

          _detalle(
            etiqueta: 'Fecha de registro',
            valor: _mostrarFecha(pago.creadoEn),
            icono: Icons.access_time_outlined,
          ),

          // MOSTRAR DATOS DE CANCELACION
          // SIN OCULTAR EL HISTORIAL
          if (cancelado) ...[
            const Divider(color: _borde),
            const SizedBox(height: 12),

            const Text(
              'CANCELACIÓN DEL PAGO',
              style: TextStyle(
                color: Color(0xFFA03930),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 15),

            _detalle(
              etiqueta: 'Fecha de cancelación',
              valor: _mostrarFecha(pago.fechaCancelacion),
              icono: Icons.event_busy_outlined,
            ),

            _detalle(
              etiqueta: 'Motivo de cancelación',
              valor: _mostrarOpcional(pago.motivoCancelacion),
              icono: Icons.description_outlined,
            ),

            _detalle(
              etiqueta: 'Cancelado por',
              valor: pago.canceladoPor == null
                  ? 'Sin registrar'
                  : 'Usuario #${pago.canceladoPor}',
              icono: Icons.person_off_outlined,
            ),
          ],
        ],
      ),
    );
  }

  // ESTADO DE ERROR

  Widget _vistaError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFA03930), size: 46),
            const SizedBox(height: 14),
            const Text(
              'No fue posible consultar la nómina',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _texto,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Error inesperado.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _secundario, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _cargarPagos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ESTADO SIN PAGOS

  Widget _vistaVacia() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: _doradoOscuro, size: 48),
            SizedBox(height: 14),
            Text(
              'No hay pagos registrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _texto,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los pagos de nómina aparecerán '
              'aquí cuando se registren.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // PANTALLA PRINCIPAL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        title: const Text(
          'Pagos de nómina',
          style: TextStyle(
            color: _texto,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar pagos',
            onPressed: _cargarPagos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _cargarPagos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / NÓMINA',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Historial de pagos',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.empleado.nombreCompleto,
                    style: const TextStyle(
                      color: _texto,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${widget.empleado.puesto} '
                    '· ID ${widget.empleado.idPersonal}',
                    style: const TextStyle(color: _secundario, fontSize: 13),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Consulta el historial de pagos '
                    'registrados y cancelados. '
                    'Esta pantalla es solo de lectura.',
                    style: TextStyle(
                      color: _secundario,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 23),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_error != null)
                    _vistaError()
                  else if (_pagos.isEmpty)
                    _vistaVacia()
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EAD8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pagos.length} '
                        'pagos encontrados',
                        style: const TextStyle(
                          color: _doradoOscuro,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 19),

                    ..._pagos.map(_tarjetaPago),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
