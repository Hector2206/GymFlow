import 'package:flutter/material.dart';

import '../models/admin_personal.dart';
import '../models/admin_salario.dart';
import '../services/admin_salarios_service.dart';
import 'admin_cambiar_salario_page.dart';

// GYMFLOW - SPRINT 7
// HISTORIAL SALARIAL DEL PERSONAL

class AdminSalariosPage extends StatefulWidget {
  final AdminPersonal empleado;

  const AdminSalariosPage({super.key, required this.empleado});

  @override
  State<AdminSalariosPage> createState() => _AdminSalariosPageState();
}

class _AdminSalariosPageState extends State<AdminSalariosPage> {
  final AdminSalariosService _servicio = AdminSalariosService();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  List<AdminSalario> _historial = [];

  bool _cargando = true;
  String? _error;
  int _numeroConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _numeroConsulta++;
    super.dispose();
  }

  // CONSULTAR DATOS REALES

  Future<void> _cargarHistorial() async {
    final consultaActual = ++_numeroConsulta;

    setState(() {
      _cargando = true;
      _error = null;
      _historial = [];
    });

    try {
      final resultado = await _servicio.obtenerHistorial(
        widget.empleado.idPersonal,
      );

      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _historial = resultado;
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

  // FORMATO DE FECHAS

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

  // FORMATO DE MONEDA MXN

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

  // FILA DE INFORMACION

  Widget _detalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),
          const SizedBox(height: 3),
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
    );
  }

  // TARJETA DE REGISTRO SALARIAL

  Widget _tarjetaSalario(AdminSalario salario) {
    final motivo = salario.motivo == null || salario.motivo!.trim().isEmpty
        ? 'Sin motivo registrado'
        : salario.motivo!;

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
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: _doradoOscuro,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _mostrarMonto(salario.monto),
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Registro salarial #${salario.idSalario}',
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),

          const SizedBox(height: 15),

          const Divider(color: _borde),

          const SizedBox(height: 10),

          _detalle('Periodicidad', salario.periodicidad),

          _detalle('Vigente desde', _mostrarFecha(salario.vigenteDesde)),

          _detalle(
            'Vigente hasta',
            salario.vigenteHasta == null
                ? 'Sin fecha de término'
                : _mostrarFecha(salario.vigenteHasta),
          ),

          _detalle('Motivo', motivo),

          _detalle(
            'Registrado por',
            salario.registradoPor == null
                ? 'Sin dato'
                : 'Usuario #${salario.registradoPor}',
          ),

          _detalle('Fecha de registro', _mostrarFecha(salario.creadoEn)),
        ],
      ),
    );
  }

  // ABRIR FORMULARIO DE CAMBIO SALARIAL

  Future<void> _abrirCambioSalario() async {
    final idSalario = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) =>
            AdminCambiarSalarioPage(idPersonal: widget.empleado.idPersonal),
      ),
    );

    if (!mounted) return;

    if (idSalario != null && idSalario > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sueldo actualizado correctamente. '
            'Registro salarial #$idSalario.',
          ),
          backgroundColor: const Color(0xFF287447),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Actualizar incluso si la operación
    // terminó con un resultado incierto.
    await _cargarHistorial();
  }

  Widget _vistaError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFA03930), size: 44),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error inesperado.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _secundario),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: _cargarHistorial,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        title: const Text(
          'Historial de salarios',
          style: TextStyle(
            color: _texto,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            onPressed: _cargarHistorial,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _cargarHistorial,
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
                    'Historial salarial',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 26,
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

                  const SizedBox(height: 8),

                  const Text(
                    'Consulta los sueldos registrados '
                    'y sus periodos de vigencia. '
                    'Esta pantalla es solo de consulta.',
                    style: TextStyle(
                      color: _secundario,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CAMBIAR SUELDO
                  // Solo empleados activos con historial vigente.
                  if (widget.empleado.estaActivo &&
                      !_cargando &&
                      _error == null &&
                      _historial.any(
                        (salario) => salario.vigenteHasta == null,
                      )) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _abrirCambioSalario,
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('Actualizar sueldo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _doradoOscuro,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_error != null)
                    _vistaError()
                  else if (_historial.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: Column(
                          children: [
                            Icon(Icons.history, color: _doradoOscuro, size: 45),
                            SizedBox(height: 12),
                            Text(
                              'No hay registros salariales',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _texto,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      '${_historial.length} '
                      'registros encontrados',
                      style: const TextStyle(
                        color: _doradoOscuro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._historial.map(_tarjetaSalario),
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
