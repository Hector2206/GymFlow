import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_pago_nomina.dart';
import '../models/admin_personal.dart';
import '../models/admin_salario.dart';
import '../services/admin_nomina_service.dart';
import '../services/admin_personal_service.dart';
import '../services/admin_salarios_service.dart';

// GYMFLOW - SPRINT 7
// REGISTRO MANUAL DE PAGOS DE NOMINA

class AdminRegistrarPagoNominaPage extends StatefulWidget {
  final int idPersonal;

  const AdminRegistrarPagoNominaPage({super.key, required this.idPersonal});

  @override
  State<AdminRegistrarPagoNominaPage> createState() =>
      _AdminRegistrarPagoNominaPageState();
}

class _AdminRegistrarPagoNominaPageState
    extends State<AdminRegistrarPagoNominaPage> {
  final _personalService = AdminPersonalService();
  final _salariosService = AdminSalariosService();
  final _nominaService = AdminNominaService();

  final _monto = TextEditingController();
  final _referencia = TextEditingController();
  final _observaciones = TextEditingController();

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

  DateTime? _inicio;
  DateTime? _fin;
  DateTime? _fechaPago;

  String _metodo = 'Efectivo';

  bool _aceptado = false;
  bool _cargando = true;
  bool _guardando = false;
  bool _resultadoIncierto = false;

  String? _errorCarga;
  String? _errorRegistro;

  @override
  void initState() {
    super.initState();
    _cargarExpediente();
  }

  @override
  void dispose() {
    _monto.dispose();
    _referencia.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  // FORMATO DE FECHAS PARA POSTGRESQL

  String _iso(DateTime fecha) {
    return '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  String _mostrarFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  DateTime? _parsearFecha(String? valor) {
    if (valor == null || valor.length < 10) {
      return null;
    }

    final fecha = valor.substring(0, 10);
    final parsed = DateTime.tryParse(fecha);

    if (parsed == null || _iso(parsed) != fecha) {
      return null;
    }

    return DateUtils.dateOnly(parsed);
  }

  // CONSULTAR DATOS REALES ANTES DE REGISTRAR

  Future<void> _cargarExpediente() async {
    if (_guardando || _resultadoIncierto) return;

    setState(() {
      _cargando = true;
      _errorCarga = null;
      _errorRegistro = null;
    });

    try {
      final respuestas = await Future.wait<Object>([
        _personalService.obtenerPersonalPorId(widget.idPersonal),
        _salariosService.obtenerHistorial(widget.idPersonal),
        _nominaService.obtenerPagos(widget.idPersonal),
      ]);

      if (!mounted) return;

      final empleado = respuestas[0] as AdminPersonal;
      final salarios = respuestas[1] as List<AdminSalario>;
      final pagos = respuestas[2] as List<AdminPagoNomina>;

      if (empleado.idPersonal != widget.idPersonal) {
        throw Exception('El servidor devolvió otro empleado.');
      }

      setState(() {
        _empleado = empleado;
        _salarios = salarios;
        _pagos = pagos;
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

  // CALENDARIOS

  Future<void> _seleccionarFecha(String campo) async {
    if (_guardando || _resultadoIncierto || _empleado == null) {
      return;
    }

    final empleado = _empleado!;
    final contratacion = _parsearFecha(empleado.fechaContratacion);

    if (contratacion == null) {
      setState(() {
        _errorRegistro = 'La fecha de contratación no es válida.';
      });
      return;
    }

    final baja = _parsearFecha(empleado.fechaBaja);

    DateTime minimo = campo == 'pago' ? DateTime(1900) : contratacion;

    DateTime maximo = campo == 'pago'
        ? DateUtils.dateOnly(DateTime.now())
        : (baja ?? DateTime(2100));

    if (campo == 'fin' && _inicio != null && _inicio!.isAfter(minimo)) {
      minimo = _inicio!;
    }

    if (minimo.isAfter(maximo)) {
      setState(() {
        _errorRegistro =
            'No hay fechas disponibles '
            'para este periodo.';
      });
      return;
    }

    DateTime? seleccionada;

    if (campo == 'inicio') {
      seleccionada = _inicio;
    } else if (campo == 'fin') {
      seleccionada = _fin;
    } else {
      seleccionada = _fechaPago;
    }

    var inicial = seleccionada ?? DateUtils.dateOnly(DateTime.now());

    if (inicial.isBefore(minimo)) {
      inicial = minimo;
    }

    if (inicial.isAfter(maximo)) {
      inicial = maximo;
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: minimo,
      lastDate: maximo,
      helpText: campo == 'inicio'
          ? 'Inicio del periodo'
          : campo == 'fin'
          ? 'Fin del periodo'
          : 'Fecha de pago',
    );

    if (!mounted || fecha == null) return;

    setState(() {
      _errorRegistro = null;

      if (campo == 'inicio') {
        _inicio = fecha;

        if (_fin != null && _fin!.isBefore(fecha)) {
          _fin = null;
        }
      } else if (campo == 'fin') {
        _fin = fecha;
      } else {
        _fechaPago = fecha;
      }
    });
  }

  // VALIDACIONES EQUIVALENTES A WEB Y BACKEND

  String? _validar() {
    final empleado = _empleado;

    if (empleado == null) {
      return 'No se encontró el empleado.';
    }

    if (_inicio == null || _fin == null || _fechaPago == null) {
      return 'Completa las tres fechas del formulario.';
    }

    final inicio = _iso(_inicio!);
    final fin = _iso(_fin!);
    final pago = _iso(_fechaPago!);

    if (fin.compareTo(inicio) < 0) {
      return 'El fin del periodo no puede ser '
          'anterior al inicio.';
    }

    final contratacion = _parsearFecha(empleado.fechaContratacion);

    if (contratacion == null || _inicio!.isBefore(contratacion)) {
      return 'El periodo no puede comenzar '
          'antes de la contratación.';
    }

    final baja = _parsearFecha(empleado.fechaBaja);

    if (baja != null && _fin!.isAfter(baja)) {
      return 'El periodo no puede terminar '
          'después de la baja laboral.';
    }

    if (!empleado.estaActivo && baja == null) {
      return 'El empleado está inactivo sin '
          'fecha de baja. Revisa su expediente.';
    }

    // Un mismo salario mensual debe cubrir
    // completamente el periodo.

    final salariosValidos = _salarios.where((salario) {
      return salario.periodicidad == 'Mensual' &&
          salario.vigenteDesde.compareTo(inicio) <= 0 &&
          (salario.vigenteHasta == null ||
              salario.vigenteHasta!.compareTo(fin) >= 0);
    }).toList();

    if (salariosValidos.length != 1) {
      return 'El periodo debe estar cubierto '
          'por un solo salario mensual. '
          'Si hubo un cambio salarial, '
          'divide el pago en periodos separados.';
    }

    // Impedir periodos que se superpongan
    // con un pago que siga vigente.

    final duplicado = _pagos.any((registro) {
      return registro.estado.toLowerCase() == 'pagado' &&
          registro.periodoInicio.compareTo(fin) <= 0 &&
          registro.periodoFin.compareTo(inicio) >= 0;
    });

    if (duplicado) {
      return 'Ya existe un pago registrado '
          'que coincide con ese periodo.';
    }

    final montoTexto = _monto.text.trim();

    if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(montoTexto)) {
      return 'Ingresa un monto válido '
          'con máximo dos decimales.';
    }

    final monto = double.tryParse(montoTexto);

    if (monto == null ||
        !monto.isFinite ||
        monto <= 0 ||
        monto > 9999999999.99) {
      return 'El monto debe ser mayor que cero '
          'y no superar 9999999999.99.';
    }

    if (pago.compareTo(_iso(DateUtils.dateOnly(DateTime.now()))) > 0) {
      return 'La fecha de pago no puede ser futura.';
    }

    if (_metodo != 'Efectivo' && _metodo != 'Transferencia') {
      return 'El método de pago no es válido.';
    }

    final referencia = _referencia.text.trim();

    if (referencia.length > 100) {
      return 'La referencia no puede superar '
          '100 caracteres.';
    }

    if (_metodo == 'Transferencia' && referencia.isEmpty) {
      return 'La referencia es obligatoria '
          'para una transferencia.';
    }

    if (!_aceptado) {
      return 'Confirma que el pago ya fue realizado.';
    }

    return null;
  }

  // CONFIRMACION Y REGISTRO

  Future<void> _registrarPago() async {
    if (_guardando || _cargando || _resultadoIncierto) {
      return;
    }

    FocusScope.of(context).unfocus();

    final error = _validar();

    if (error != null) {
      setState(() {
        _errorRegistro = error;
      });
      return;
    }

    final empleado = _empleado!;
    final inicio = _iso(_inicio!);
    final fin = _iso(_fin!);
    final fechaPago = _iso(_fechaPago!);
    final montoTexto = _monto.text.trim();
    final metodo = _metodo;
    final referencia = _referencia.text.trim();
    final observaciones = _observaciones.text.trim();

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar pago de nómina'),
          content: SingleChildScrollView(
            child: Text(
              'Empleado: ${empleado.nombreCompleto}\n\n'
              'Periodo: $inicio al $fin\n'
              'Monto: \$$montoTexto MXN\n'
              'Fecha de pago: $fechaPago\n'
              'Método: $metodo\n'
              'Referencia: '
              '${referencia.isEmpty ? 'Sin referencia' : referencia}\n\n'
              'Confirma únicamente si el pago '
              'ya fue entregado al empleado.\n\n'
              'Esta acción registra el pago, '
              'pero NO realiza una transferencia bancaria.',
            ),
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
              child: const Text('Registrar pago'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    final errorActual = _validar();

    if (errorActual != null) {
      setState(() {
        _errorRegistro = errorActual;
      });
      return;
    }

    setState(() {
      _guardando = true;
      _errorRegistro = null;
    });

    try {
      final idPago = await _nominaService.registrarPago(
        idPersonal: widget.idPersonal,
        periodoInicio: inicio,
        periodoFin: fin,
        montoTexto: montoTexto,
        fechaPago: fechaPago,
        metodo: metodo,
        referencia: referencia,
        observaciones: observaciones,
      );

      if (!mounted) return;

      Navigator.of(context).pop(idPago);
    } on PagoNominaResultadoIncierto catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
        _resultadoIncierto = true;
        _errorRegistro = error.mensaje;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
        _errorRegistro = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ELEMENTOS VISUALES

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
    );
  }

  Widget _campoFecha(String etiqueta, DateTime? fecha, String tipo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              color: _texto,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _guardando || _resultadoIncierto
                  ? null
                  : () => _seleccionarFecha(tipo),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_mostrarFecha(fecha)),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: _doradoOscuro,
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: _borde),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    final empleado = _empleado!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _superficie,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EMPLEADO SELECCIONADO',
                style: TextStyle(
                  color: _doradoOscuro,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                empleado.nombreCompleto,
                style: const TextStyle(
                  color: _texto,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${empleado.puesto} · '
                'ID ${empleado.idPersonal} · '
                '${empleado.estatus}',
                style: const TextStyle(color: _secundario, fontSize: 13),
              ),
              const SizedBox(height: 15),
              Text(
                'Sueldo mensual registrado: '
                '\$${empleado.salario.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  color: _doradoOscuro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        _campoFecha('Inicio del periodo *', _inicio, 'inicio'),

        _campoFecha('Fin del periodo *', _fin, 'fin'),

        TextFormField(
          controller: _monto,
          enabled: !_guardando && !_resultadoIncierto,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: _decoracion(
            'Monto pagado (MXN) *',
            Icons.payments_outlined,
          ),
        ),

        const SizedBox(height: 16),

        _campoFecha('Fecha en que se pagó *', _fechaPago, 'pago'),

        DropdownButtonFormField<String>(
          initialValue: _metodo,
          decoration: _decoracion(
            'Método de pago *',
            Icons.account_balance_wallet_outlined,
          ),
          items: const [
            DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
            DropdownMenuItem(
              value: 'Transferencia',
              child: Text('Transferencia bancaria'),
            ),
          ],
          onChanged: _guardando || _resultadoIncierto
              ? null
              : (valor) {
                  if (valor != null) {
                    setState(() {
                      _metodo = valor;
                    });
                  }
                },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _referencia,
          enabled: !_guardando && !_resultadoIncierto,
          maxLength: 100,
          decoration: _decoracion(
            _metodo == 'Transferencia'
                ? 'Referencia *'
                : 'Referencia (opcional)',
            Icons.numbers_outlined,
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _observaciones,
          enabled: !_guardando && !_resultadoIncierto,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: _decoracion(
            'Observaciones (opcional)',
            Icons.description_outlined,
          ).copyWith(alignLabelWithHint: true),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EAD8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'El pago debe corresponder a un único '
            'salario mensual y no debe coincidir '
            'con otro periodo ya pagado.\n\n'
            'Este formulario registra un pago '
            'realizado; no transfiere dinero.',
            style: TextStyle(color: _texto, fontSize: 12, height: 1.5),
          ),
        ),

        const SizedBox(height: 14),

        CheckboxListTile(
          value: _aceptado,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _doradoOscuro,
          onChanged: _guardando || _resultadoIncierto
              ? null
              : (valor) {
                  setState(() {
                    _aceptado = valor ?? false;
                  });
                },
          title: const Text(
            'Confirmo que el pago ya fue realizado '
            'y que los datos son correctos.',
            style: TextStyle(color: _texto, fontSize: 13),
          ),
        ),

        if (_errorRegistro != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE9E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorRegistro!,
              style: const TextStyle(color: _rojo, fontSize: 13),
            ),
          ),
        ],

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _guardando || _resultadoIncierto ? null : _registrarPago,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.receipt_long_outlined),
            label: Text(
              _guardando ? 'Registrando pago...' : 'Revisar y confirmar pago',
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
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver y verificar historial'),
          ),
        ],
      ],
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
            'Registrar pago de nómina',
            style: TextStyle(
              color: _texto,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / NÓMINA',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registrar pago',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Registra un pago que ya se realizó '
                    'a un empleado del gimnasio.',
                    style: TextStyle(color: _secundario, fontSize: 13),
                  ),
                  const SizedBox(height: 23),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_errorCarga != null) ...[
                    Text(_errorCarga!, style: const TextStyle(color: _rojo)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _cargarExpediente,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ] else if (_empleado != null)
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
