import 'package:flutter/material.dart';

import '../models/admin_pago_nomina.dart';
import '../models/admin_personal.dart';
import '../models/admin_salario.dart';
import '../services/admin_nomina_service.dart';
import '../services/admin_personal_service.dart';
import '../services/admin_salarios_service.dart';
import 'admin_cambiar_salario_page.dart';
import 'admin_nomina_page.dart';
import 'admin_salarios_page.dart';

// GYMFLOW - SPRINT 7
// VISTA CENTRAL DE SALARIOS Y NOMINA, COMO EN WEB

class AdminNominaGestionPage extends StatefulWidget {
  final int idPersonal;

  const AdminNominaGestionPage({super.key, required this.idPersonal});

  @override
  State<AdminNominaGestionPage> createState() => _AdminNominaGestionPageState();
}

class _AdminNominaGestionPageState extends State<AdminNominaGestionPage> {
  final AdminPersonalService _personal = AdminPersonalService();
  final AdminSalariosService _salariosService = AdminSalariosService();
  final AdminNominaService _nominaService = AdminNominaService();

  static const _fondo = Color(0xFFF8F5EF);
  static const _superficie = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _borde = Color(0xFFE5DDCF);
  static const _rojo = Color(0xFFA03930);

  AdminPersonal? _empleado;
  List<AdminSalario> _salarios = [];
  List<AdminPagoNomina> _pagos = [];
  bool _cargando = true;
  String? _error;
  int _versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    _actualizar();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  Future<void> _actualizar() async {
    final version = ++_versionConsulta;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Consultar en paralelo con el mismo ID de empleado.
      final respuestas = await Future.wait<Object>([
        _personal.obtenerPersonalPorId(widget.idPersonal),
        _salariosService.obtenerHistorial(widget.idPersonal),
        _nominaService.obtenerPagos(widget.idPersonal),
      ]);
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _empleado = respuestas[0] as AdminPersonal;
        _salarios = respuestas[1] as List<AdminSalario>;
        _pagos = respuestas[2] as List<AdminPagoNomina>;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  AdminSalario? get _vigente {
    for (final s in _salarios) {
      if (s.vigenteHasta == null) return s;
    }
    return null;
  }

  String _fecha(String? dato) {
    if (dato == null || dato.trim().isEmpty) return '—';
    final valor = dato.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(valor)) {
      return '${valor.substring(8, 10)}/${valor.substring(5, 7)}/${valor.substring(0, 4)}';
    }
    return valor;
  }

  String _monto(double valor) {
    if (!valor.isFinite) return 'No disponible';
    final n = valor.abs().toStringAsFixed(2).split('.');
    final entero = n[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '${valor < 0 ? '-' : ''}\$$entero.${n[1]} MXN';
  }

  Widget _panel({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Widget contenido,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: _superficie,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: _doradoOscuro),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(color: _secundario, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          contenido,
        ],
      ),
    );
  }

  Widget _boton(
    String titulo,
    IconData icono,
    VoidCallback funcion, {
    bool principal = false,
  }) {
    final boton = principal
        ? FilledButton.icon(
            onPressed: funcion,
            icon: Icon(icono),
            label: Text(titulo),
            style: FilledButton.styleFrom(
              backgroundColor: _doradoOscuro,
              padding: const EdgeInsets.all(14),
            ),
          )
        : OutlinedButton.icon(
            onPressed: funcion,
            icon: Icon(icono),
            label: Text(titulo),
            style: OutlinedButton.styleFrom(
              foregroundColor: _doradoOscuro,
              padding: const EdgeInsets.all(14),
              side: const BorderSide(color: _borde),
            ),
          );
    return SizedBox(width: double.infinity, child: boton);
  }

  Future<void> _cambiarSueldo() async {
    final idSalario = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => AdminCambiarSalarioPage(idPersonal: widget.idPersonal),
      ),
    );
    if (!mounted) return;
    if (idSalario != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sueldo actualizado. Registro #$idSalario.'),
          backgroundColor: const Color(0xFF287447),
        ),
      );
    }
    await _actualizar();
  }

  Future<void> _abrirHistorialSalarios() async {
    final empleado = _empleado;
    if (empleado == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AdminSalariosPage(empleado: empleado)),
    );
    if (!mounted) return;
    await _actualizar();
  }

  Future<void> _abrirPagos() async {
    final empleado = _empleado;
    if (empleado == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AdminNominaPage(empleado: empleado)),
    );
    if (!mounted) return;
    await _actualizar();
  }

  Widget _resumenEmpleado() {
    final empleado = _empleado!;
    final salarioActual = _vigente;
    return _panel(
      icono: Icons.badge_outlined,
      titulo: empleado.nombreCompleto,
      descripcion:
          '${empleado.puesto} · Personal #${empleado.idPersonal} · ${empleado.estatus}',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUELDO MENSUAL VIGENTE',
            style: TextStyle(
              color: _doradoOscuro,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            salarioActual == null
                ? 'Sin salario vigente'
                : _monto(salarioActual.monto),
            style: const TextStyle(
              color: _texto,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            salarioActual == null
                ? 'Consulta el historial del empleado.'
                : 'Desde ${_fecha(salarioActual.vigenteDesde)} · ${salarioActual.periodicidad}',
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _historialSalarial() {
    final empleado = _empleado!;
    final vigente = _vigente;
    final puedeCambiar =
        empleado.estaActivo &&
        vigente != null &&
        vigente.periodicidad == 'Mensual' &&
        empleado.salario.toStringAsFixed(2) == vigente.monto.toStringAsFixed(2);

    return _panel(
      icono: Icons.history_outlined,
      titulo: 'Historial salarial',
      descripcion: 'Sueldos anteriores y fechas de vigencia',
      contenido: Column(
        children: [
          if (_salarios.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No hay registros salariales.',
                style: TextStyle(color: _secundario),
              ),
            )
          else
            ..._salarios
                .take(3)
                .map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _monto(s.monto),
                      style: const TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${_fecha(s.vigenteDesde)} — ${_fecha(s.vigenteHasta)}\n'
                      '${s.motivo?.isNotEmpty == true ? s.motivo : 'Sin motivo'}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      s.vigenteHasta == null ? 'Vigente' : 'Histórico',
                      style: const TextStyle(
                        color: _doradoOscuro,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          _boton(
            'Ver historial salarial completo',
            Icons.history,
            _abrirHistorialSalarios,
          ),
          if (puedeCambiar) ...[
            const SizedBox(height: 9),
            _boton(
              'Cambiar sueldo mensual',
              Icons.edit_note_outlined,
              _cambiarSueldo,
              principal: true,
            ),
          ],
          if (!empleado.estaActivo)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'El empleado está inactivo: solo consulta.',
                style: TextStyle(color: _secundario, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _historialPagos() {
    return _panel(
      icono: Icons.receipt_long_outlined,
      titulo: 'Pagos de nómina',
      descripcion: 'Periodos pagados, métodos y cancelaciones',
      contenido: Column(
        children: [
          if (_pagos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Todavía no hay pagos registrados.',
                style: TextStyle(color: _secundario),
              ),
            )
          else
            ..._pagos
                .take(3)
                .map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.receipt_outlined,
                      color: p.estaCancelado ? _rojo : _doradoOscuro,
                    ),
                    title: Text(
                      _monto(p.monto),
                      style: const TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${_fecha(p.periodoInicio)} al ${_fecha(p.periodoFin)}\n'
                      '${p.metodo} · ${_fecha(p.fechaPago)}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      p.estado,
                      style: TextStyle(
                        color: p.estaCancelado
                            ? _rojo
                            : const Color(0xFF287447),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          _boton(
            'Ver todos los pagos',
            Icons.receipt_long_outlined,
            _abrirPagos,
          ),
          const SizedBox(height: 10),
          const Text(
            'El registro y la cancelación de pagos se integrarán '
            'en los siguientes cambios. Esta vista no modifica pagos.',
            style: TextStyle(color: _secundario, fontSize: 11),
            textAlign: TextAlign.center,
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
          'Salarios y nómina',
          style: TextStyle(color: _texto, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar sueldos y pagos',
            onPressed: _cargando ? null : _actualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _actualizar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / NÓMINA',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Gestión de salarios y nómina',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Resumen laboral, sueldos y pagos registrados.',
                    style: TextStyle(color: _secundario, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: _rojo)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _actualizar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ] else if (_empleado != null) ...[
                    _resumenEmpleado(),
                    _historialSalarial(),
                    _historialPagos(),
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
