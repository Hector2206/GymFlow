import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_personal.dart';
import '../models/admin_salario.dart';
import '../services/admin_personal_service.dart';
import '../services/admin_salarios_service.dart';

// GYMFLOW - SPRINT 7
// ACTUALIZACION DEL SUELDO MENSUAL

class AdminCambiarSalarioPage extends StatefulWidget {
  final int idPersonal;

  const AdminCambiarSalarioPage({super.key, required this.idPersonal});

  @override
  State<AdminCambiarSalarioPage> createState() =>
      _AdminCambiarSalarioPageState();
}

class _AdminCambiarSalarioPageState extends State<AdminCambiarSalarioPage> {
  final _formKey = GlobalKey<FormState>();

  final _personalService = AdminPersonalService();
  final _salariosService = AdminSalariosService();

  final _montoController = TextEditingController();
  final _motivoController = TextEditingController();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  AdminPersonal? _empleado;
  AdminSalario? _salarioVigente;

  bool _cargando = true;
  bool _guardando = false;
  bool _resultadoIncierto = false;

  String? _errorCarga;
  String? _errorGuardado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  // FECHA UTC: LOS SERVIDORES CLOUD
  // NORMALMENTE UTILIZAN UTC.

  String _fechaOperacion() {
    final fecha = DateTime.now().toUtc();

    return '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  // CONSULTAR EMPLEADO E HISTORIAL ACTUALES

  Future<void> _cargarDatos() async {
    if (_guardando || _resultadoIncierto) return;

    setState(() {
      _cargando = true;
      _errorCarga = null;
      _empleado = null;
      _salarioVigente = null;
    });

    try {
      final empleado = await _personalService.obtenerPersonalPorId(
        widget.idPersonal,
      );

      final historial = await _salariosService.obtenerHistorial(
        widget.idPersonal,
      );

      if (!mounted) return;

      if (!empleado.estaActivo) {
        throw Exception(
          'Solo puedes actualizar el sueldo '
          'de empleados activos.',
        );
      }

      final vigentes = historial
          .where((salario) => salario.vigenteHasta == null)
          .toList();

      if (vigentes.length != 1) {
        throw Exception(
          'No existe exactamente un sueldo vigente. '
          'Revisa el historial antes de continuar.',
        );
      }

      final vigente = vigentes.single;

      if (empleado.salario.toStringAsFixed(2) !=
          vigente.monto.toStringAsFixed(2)) {
        throw Exception(
          'El sueldo del expediente no coincide '
          'con el historial salarial.',
        );
      }

      setState(() {
        _empleado = empleado;
        _salarioVigente = vigente;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // UN CAMBIO DEBE SER POSTERIOR
  // AL INICIO DEL SUELDO ACTUAL.

  bool get _fechaPermitida {
    final salario = _salarioVigente;

    if (salario == null) return false;

    return _fechaOperacion().compareTo(salario.vigenteDesde.substring(0, 10)) >
        0;
  }

  // GUARDAR EN EL BACKEND

  Future<void> _guardar() async {
    if (_guardando ||
        _resultadoIncierto ||
        _empleado == null ||
        _salarioVigente == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_fechaPermitida) {
      setState(() {
        _errorGuardado =
            'La nueva vigencia debe ser posterior '
            'al inicio del sueldo actual.';
      });
      return;
    }

    final montoTexto = _montoController.text.trim();
    final monto = double.parse(montoTexto);
    final salarioActual = _salarioVigente!.monto;

    if (monto.toStringAsFixed(2) == salarioActual.toStringAsFixed(2)) {
      setState(() {
        _errorGuardado =
            'El nuevo sueldo debe ser diferente '
            'al sueldo actual.';
      });
      return;
    }

    final motivo = _motivoController.text.trim();
    final fechaVigencia = _fechaOperacion();

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar cambio salarial'),
          content: Text(
            'Empleado: ${_empleado!.nombreCompleto}\n\n'
            'Sueldo actual: '
            '\$${salarioActual.toStringAsFixed(2)} MXN\n'
            'Nuevo sueldo: '
            '\$${monto.toStringAsFixed(2)} MXN\n'
            'Vigencia: $fechaVigencia\n\n'
            'Motivo: $motivo\n\n'
            'El sueldo anterior quedará '
            'conservado en el historial.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    // Si el día cambió durante la confirmación,
    // exigir una nueva revisión.
    if (_fechaOperacion() != fechaVigencia) {
      setState(() {
        _errorGuardado =
            'La fecha cambió. Revisa los datos '
            'y confirma nuevamente.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _errorGuardado = null;
    });

    try {
      final idSalario = await _salariosService.cambiarSalario(
        idPersonal: widget.idPersonal,
        montoTexto: montoTexto,
        vigenteDesde: fechaVigencia,
        motivo: motivo,
      );

      if (!mounted) return;

      Navigator.of(context).pop(idSalario);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;

        // No reenviar la operación hasta
        // comprobar el historial real.
        _resultadoIncierto = true;

        _errorGuardado =
            '${error.toString().replaceFirst('Exception: ', '')}'
            '\n\nRegresa al historial, actualiza '
            'los datos y comprueba si el cambio '
            'ya fue registrado antes de intentar '
            'otra actualización.';
      });
    }
  }

  // ESTILO DE LOS CAMPOS

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: _doradoOscuro),
      filled: true,
      fillColor: _superficie,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dorado, width: 1.5),
      ),
    );
  }

  Widget _formulario() {
    final empleado = _empleado!;
    final salario = _salarioVigente!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _superficie,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empleado.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _texto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${empleado.puesto} · '
                    'Personal #${empleado.idPersonal}',
                    style: const TextStyle(color: _secundario),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'SUELDO MENSUAL ACTUAL',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${salario.monto.toStringAsFixed(2)} MXN',
                    style: const TextStyle(
                      color: _texto,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vigente desde: '
                    '${salario.vigenteDesde}',
                    style: const TextStyle(color: _secundario, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // NUEVO SUELDO
          TextFormField(
            controller: _montoController,
            enabled: !_guardando && !_resultadoIncierto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: _decoracion(
              'Nuevo sueldo mensual (MXN)',
              Icons.payments_outlined,
            ),
            validator: (valor) {
              final texto = valor?.trim() ?? '';

              if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(texto)) {
                return 'Monto válido: 0 a 99999999.99, '
                    'máximo dos decimales.';
              }

              return null;
            },
          ),

          const SizedBox(height: 17),

          // MOTIVO DEL CAMBIO
          TextFormField(
            controller: _motivoController,
            enabled: !_guardando && !_resultadoIncierto,
            maxLength: 200,
            minLines: 3,
            maxLines: 5,
            decoration: _decoracion(
              'Motivo del cambio',
              Icons.description_outlined,
            ).copyWith(alignLabelWithHint: true),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'El motivo es obligatorio.';
              }
              return null;
            },
          ),

          const SizedBox(height: 7),

          // VIGENCIA AUTOMÁTICA
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined, color: _doradoOscuro),
            title: const Text('Fecha de vigencia'),
            subtitle: Text(
              '${_fechaOperacion()} '
              '(fecha UTC de referencia)',
            ),
          ),

          if (!_fechaPermitida) ...[
            const SizedBox(height: 10),
            const Text(
              'El sueldo vigente comenzó hoy '
              'o en una fecha posterior. '
              'No se puede realizar este cambio.',
              style: TextStyle(color: Color(0xFFA03930)),
            ),
          ],

          if (_errorGuardado != null) ...[
            const SizedBox(height: 15),
            Text(
              _errorGuardado!,
              style: const TextStyle(color: Color(0xFFA03930)),
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _guardando || _resultadoIncierto || !_fechaPermitida
                  ? null
                  : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _guardando ? 'Guardando cambio...' : 'Actualizar sueldo',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _doradoOscuro,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          if (_resultadoIncierto) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver y revisar historial'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        backgroundColor: _fondo,
        appBar: AppBar(
          backgroundColor: _superficie,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _doradoOscuro),
          title: const Text(
            'Actualizar sueldo',
            style: TextStyle(
              color: _texto,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / ADMINISTRACIÓN',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Cambio salarial',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Los cambios conservarán '
                    'el historial de sueldos.',
                    style: TextStyle(color: _secundario),
                  ),
                  const SizedBox(height: 22),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_errorCarga != null) ...[
                    Text(
                      _errorCarga!,
                      style: const TextStyle(color: Color(0xFFA03930)),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: _cargarDatos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ] else if (_empleado != null && _salarioVigente != null)
                    _formulario(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
