import 'package:flutter/material.dart';

import '../models/cliente_resumen.dart';
import '../services/cliente_consulta_service.dart';
import '../services/pago_service.dart';
import 'historial_pagos_page.dart';

// GYMFLOW - RECEPCION / SPRINT 7
// El monto NO se captura ni se envía al servidor.
class RegistrarPagoPage extends StatefulWidget {
  const RegistrarPagoPage({super.key});

  @override
  State<RegistrarPagoPage> createState() => _RegistrarPagoPageState();
}

class _RegistrarPagoPageState extends State<RegistrarPagoPage> {
  final _formKey = GlobalKey<FormState>();
  final _clienteService = ClienteConsultaService();
  final _pagoService = PagoService();

  static const _fondo = Color(0xFFF8F5EF);
  static const _superficie = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _borde = Color(0xFFE5DDCF);
  static const _rojo = Color(0xFFA03930);
  static const _verde = Color(0xFF287447);

  List<ClienteResumen> _clientes = [];
  PagoPendiente? _pendiente;
  ResultadoRegistroPago? _resultado;

  int? _idCliente;
  String? _tipoPago;
  bool _cargandoClientes = true;
  bool _cargandoPendiente = true;
  bool _procesando = false;
  bool _operacionTerminada = false;
  String _errorClientes = '';
  String _errorFormulario = '';
  String _errorPendiente = '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _cargarPendiente();
  }

  String _limpiarError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  Future<void> _cargarClientes() async {
    if (!mounted) return;
    setState(() {
      _cargandoClientes = true;
      _errorClientes = '';
    });
    try {
      final lista = await _clienteService.obtenerClientes();
      if (!mounted) return;
      setState(() {
        _clientes = lista;
        _cargandoClientes = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorClientes = _limpiarError(error);
        _cargandoClientes = false;
      });
    }
  }

  Future<void> _cargarPendiente() async {
    if (!mounted) return;
    setState(() {
      _cargandoPendiente = true;
      _errorPendiente = '';
    });
    try {
      final pendiente = await _pagoService.obtenerPagoPendiente();
      if (!mounted) return;
      setState(() {
        _pendiente = pendiente;
        if (pendiente != null) {
          _idCliente = pendiente.idCliente;
          _tipoPago = pendiente.tipoPago;
        }
        _cargandoPendiente = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorPendiente = _limpiarError(error);
        _cargandoPendiente = false;
      });
    }
  }

  String _nombreCliente(int id) {
    for (final cliente in _clientes) {
      if (cliente.idCliente == id) return cliente.nombreCompleto;
    }
    return 'Cliente #$id';
  }

  Future<void> _abrirHistorial() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const HistorialPagosPage()));
  }

  Future<bool> _confirmar() async {
    final cliente = _nombreCliente(_idCliente!);
    final tipo = _tipoPago!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(
              _pendiente == null ? 'Confirmar pago' : 'Reintentar pago',
            ),
            content: Text(
              'Cliente: $cliente\n'
              'Concepto: $tipo\n\n'
              'El monto se calculará con el precio oficial en PostgreSQL.\n\n'
              '${_pendiente == null ? 'Registra únicamente dinero ya recibido.' : 'Se reutilizará el mismo identificador del intento anterior. No se creará un cobro duplicado.'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _doradoOscuro),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  _pendiente == null
                      ? 'Confirmar registro'
                      : 'Reintentar el mismo pago',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _registrarPago() async {
    if (_procesando ||
        _cargandoPendiente ||
        _operacionTerminada ||
        _errorPendiente.isNotEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_idCliente == null || _tipoPago == null) return;
    if (_pendiente == null &&
        (_cargandoClientes || _errorClientes.isNotEmpty)) {
      return;
    }

    if (!await _confirmar() || !mounted) return;
    final id = _idCliente!;
    final tipo = _tipoPago!;
    setState(() {
      _procesando = true;
      _errorFormulario = '';
      _resultado = null;
    });
    try {
      final resultado = await _pagoService.registrarPago(
        idCliente: id,
        tipoPago: tipo,
      );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _pendiente = null;
        _operacionTerminada = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorFormulario = _limpiarError(error);
      });
      // Aunque haya fallado la conexión, la clave queda guardada.
      await _cargarPendiente();
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  void _nuevaOperacion() {
    if (_procesando || _pendiente != null) return;
    setState(() {
      _operacionTerminada = false;
      _resultado = null;
      _errorFormulario = '';
      _idCliente = null;
      _tipoPago = null;
    });
    _formKey.currentState?.reset();
  }

  InputDecoration _decoracion(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _doradoOscuro),
      filled: true,
      fillColor: const Color(0xFFF8F4EC),
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

  Widget _aviso(String texto, {bool error = false, IconData? icono}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFFEEEE) : const Color(0xFFF3EAD8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: error ? const Color(0xFFE8B7B3) : const Color(0xFFE5D2A5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono ?? (error ? Icons.error_outline : Icons.info_outline),
            color: error ? _rojo : _doradoOscuro,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: error ? _rojo : _texto, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaPagoConfirmado(ResultadoRegistroPago p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F2),
        border: Border.all(color: const Color(0xFFB7D7BC)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: _verde, size: 27),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pago confirmado',
                  style: TextStyle(
                    color: _verde,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.mensaje.isEmpty ? 'El servidor confirmó el pago.' : p.mensaje,
            style: const TextStyle(color: _texto),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${p.monto.toStringAsFixed(2)} MXN · ${p.tipoPago}',
            style: const TextStyle(
              color: _verde,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text('Folio: #${p.idPago}', style: const TextStyle(color: _texto)),
          if (p.fechaVencimiento.isNotEmpty)
            Text(
              'Vencimiento: ${p.fechaVencimiento}',
              style: const TextStyle(color: _secundario),
            ),
          if (p.pagoRepetido) ...[
            const SizedBox(height: 8),
            const Text(
              'El servidor reconoció el UUID original. No generó otro pago.',
              style: TextStyle(color: _verde, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _nuevaOperacion,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Registrar un pago nuevo'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado =
        _procesando ||
        _cargandoPendiente ||
        _operacionTerminada ||
        _errorPendiente.isNotEmpty;
    final hayPendiente = _pendiente != null;

    return PopScope(
      canPop: !_procesando,
      child: Scaffold(
        backgroundColor: _fondo,
        appBar: AppBar(
          backgroundColor: _superficie,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _doradoOscuro),
          title: Image.asset('assets/Logo_GymFlow.png', height: 48),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_fondo, Color(0xFFF2EDE4)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECEPCIÓN / GYMFLOW',
                      style: TextStyle(
                        color: _doradoOscuro,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registrar pago',
                      style: TextStyle(
                        color: _texto,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'El precio oficial se calcula automáticamente en PostgreSQL.',
                      style: TextStyle(color: _secundario, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    if (_cargandoPendiente)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: CircularProgressIndicator(color: _dorado),
                        ),
                      ),
                    if (_errorPendiente.isNotEmpty) ...[
                      _aviso(_errorPendiente, error: true),
                      const SizedBox(height: 14),
                    ],
                    if (hayPendiente) ...[
                      _aviso(
                        'Hay un cobro por confirmar: '
                        '${_nombreCliente(_pendiente!.idCliente)} · ${_pendiente!.tipoPago}. '
                        'El reintento utiliza la misma Idempotency-Key. '
                        'No registres una operación diferente sin resolver esta.',
                        icono: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: _superficie,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _borde),
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos del pago',
                              style: TextStyle(
                                color: _texto,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 17),
                            if (hayPendiente) ...[
                              Text(
                                'Cliente: ${_nombreCliente(_pendiente!.idCliente)}',
                                style: const TextStyle(
                                  color: _texto,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                'Concepto: ${_pendiente!.tipoPago}',
                                style: const TextStyle(
                                  color: _texto,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else ...[
                              if (_cargandoClientes)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: _dorado,
                                  ),
                                )
                              else if (_errorClientes.isNotEmpty) ...[
                                _aviso(_errorClientes, error: true),
                                TextButton.icon(
                                  onPressed: _cargarClientes,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                ),
                              ] else if (_clientes.isEmpty)
                                _aviso(
                                  'No hay clientes disponibles para registrar pagos.',
                                  error: true,
                                )
                              else ...[
                                DropdownButtonFormField<int>(
                                  key: ValueKey('cliente-$_idCliente'),
                                  initialValue: _idCliente,
                                  isExpanded: true,
                                  decoration: _decoracion(
                                    'Cliente *',
                                    Icons.person_outline,
                                  ),
                                  items: _clientes
                                      .map(
                                        (cliente) => DropdownMenuItem<int>(
                                          value: cliente.idCliente,
                                          child: Text(
                                            cliente.nombreCompleto,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  validator: (valor) => valor == null
                                      ? 'Selecciona un cliente.'
                                      : null,
                                  onChanged: bloqueado
                                      ? null
                                      : (valor) {
                                          setState(() {
                                            _idCliente = valor;
                                            _errorFormulario = '';
                                          });
                                        },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  key: ValueKey('tipo-$_tipoPago'),
                                  initialValue: _tipoPago,
                                  decoration: _decoracion(
                                    'Concepto del pago *',
                                    Icons.receipt_long_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Mensualidad',
                                      child: Text('Mensualidad'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Anualidad',
                                      child: Text('Anualidad'),
                                    ),
                                  ],
                                  validator: (valor) => valor == null
                                      ? 'Selecciona el concepto del pago.'
                                      : null,
                                  onChanged: bloqueado
                                      ? null
                                      : (valor) {
                                          setState(() {
                                            _tipoPago = valor;
                                            _errorFormulario = '';
                                          });
                                        },
                                ),
                              ],
                            ],
                            const SizedBox(height: 18),
                            _aviso(
                              'No se captura ni envía ningún monto. '
                              'El servidor registra el precio oficial de la membresía.',
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    bloqueado ||
                                        (!hayPendiente &&
                                            (_cargandoClientes ||
                                                _errorClientes.isNotEmpty ||
                                                _clientes.isEmpty))
                                    ? null
                                    : _registrarPago,
                                icon: _procesando
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.payments_outlined),
                                label: Text(
                                  _procesando
                                      ? 'Confirmando...'
                                      : hayPendiente
                                      ? 'Reintentar el mismo pago'
                                      : 'Revisar y registrar pago',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _doradoOscuro,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_errorFormulario.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      _aviso(_errorFormulario, error: true),
                    ],
                    if (hayPendiente || _operacionTerminada) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _procesando ? null : _abrirHistorial,
                        icon: const Icon(Icons.history),
                        label: const Text('Consultar historial de pagos'),
                      ),
                    ],
                    if (_resultado != null) ...[
                      const SizedBox(height: 17),
                      _tarjetaPagoConfirmado(_resultado!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
