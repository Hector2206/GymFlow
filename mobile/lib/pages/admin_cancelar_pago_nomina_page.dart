import 'package:flutter/material.dart';

import '../models/admin_pago_nomina.dart';
import '../models/admin_personal.dart';
import '../services/admin_nomina_service.dart';

// GYMFLOW - SPRINT 7
// CANCELACION ADMINISTRATIVA DE PAGOS DE NOMINA

class AdminCancelarPagoNominaPage extends StatefulWidget {
  final AdminPersonal empleado;
  final AdminPagoNomina pago;

  const AdminCancelarPagoNominaPage({
    super.key,
    required this.empleado,
    required this.pago,
  });

  @override
  State<AdminCancelarPagoNominaPage> createState() =>
      _AdminCancelarPagoNominaPageState();
}

class _AdminCancelarPagoNominaPageState
    extends State<AdminCancelarPagoNominaPage> {
  final AdminNominaService _servicio = AdminNominaService();

  final _motivo = TextEditingController();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);
  static const Color _rojo = Color(0xFFA03930);

  bool _aceptado = false;
  bool _enviando = false;
  bool _resultadoIncierto = false;

  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  String _fecha(String valor) {
    if (valor.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(valor)) {
      return '${valor.substring(8, 10)}/'
          '${valor.substring(5, 7)}/'
          '${valor.substring(0, 4)}';
    }

    return valor;
  }

  String _monto(double cantidad) {
    return '\$${cantidad.toStringAsFixed(2)} MXN';
  }

  // CANCELACION CON DOBLE CONFIRMACION

  Future<void> _cancelar() async {
    if (_enviando || _resultadoIncierto) return;

    final motivo = _motivo.text.trim();

    if (motivo.isEmpty) {
      setState(() {
        _error = 'Escribe el motivo de la cancelación.';
      });
      return;
    }

    if (!_aceptado) {
      setState(() {
        _error = 'Debes confirmar que revisaste el pago.';
      });
      return;
    }

    if (widget.pago.idPersonal != widget.empleado.idPersonal ||
        widget.pago.estado != 'Pagado') {
      setState(() {
        _error = 'El pago no es válido para cancelación.';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar cancelación'),
          content: SingleChildScrollView(
            child: Text(
              'Empleado: '
              '${widget.empleado.nombreCompleto}\n\n'
              'Pago #${widget.pago.idPago}\n'
              'Monto: ${_monto(widget.pago.monto)}\n'
              'Periodo: '
              '${_fecha(widget.pago.periodoInicio)} '
              'al ${_fecha(widget.pago.periodoFin)}\n\n'
              'Motivo: $motivo\n\n'
              'El registro quedará como Cancelado '
              'y se conservará para auditoría.\n\n'
              'Esta operación NO devuelve '
              'dinero automáticamente.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No, regresar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _rojo),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sí, cancelar pago'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      // Verificar nuevamente el pago antes
      // de enviar una operación que modifica BD.
      final pagosActuales = await _servicio.obtenerPagos(
        widget.empleado.idPersonal,
      );

      AdminPagoNomina? pagoActual;

      for (final pago in pagosActuales) {
        if (pago.idPago == widget.pago.idPago) {
          pagoActual = pago;
          break;
        }
      }

      if (pagoActual == null) {
        throw Exception(
          'El pago no aparece en el historial. '
          'Actualiza la consulta.',
        );
      }

      if (pagoActual.estado != 'Pagado') {
        throw Exception(
          'Este pago ya no está en estado Pagado. '
          'Actualiza el historial.',
        );
      }

      final idCancelado = await _servicio.cancelarPagoNomina(
        idPersonal: widget.empleado.idPersonal,
        idPago: widget.pago.idPago,
        motivo: motivo,
      );

      if (!mounted) return;

      Navigator.of(context).pop(idCancelado);
    } on PagoNominaResultadoIncierto catch (error) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
        _resultadoIncierto = true;
        _error = error.mensaje;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        backgroundColor: _fondo,
        appBar: AppBar(
          backgroundColor: _superficie,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _doradoOscuro),
          title: const Text(
            'Cancelar pago',
            style: TextStyle(color: _texto, fontWeight: FontWeight.w700),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Text(
                    'Cancelación de pago',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Revisa el registro antes '
                    'de confirmar la cancelación.',
                    style: TextStyle(color: _secundario, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _superficie,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borde),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATOS DEL PAGO',
                          style: TextStyle(
                            color: _doradoOscuro,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _dato('Empleado', widget.empleado.nombreCompleto),

                        _dato('Folio', '#${widget.pago.idPago}'),

                        _dato('Monto', _monto(widget.pago.monto)),

                        _dato(
                          'Periodo',
                          '${_fecha(widget.pago.periodoInicio)} '
                              'al ${_fecha(widget.pago.periodoFin)}',
                        ),

                        _dato('Fecha de pago', _fecha(widget.pago.fechaPago)),

                        _dato('Método', widget.pago.metodo),

                        _dato('Estado actual', widget.pago.estado),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE9E6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: _rojo),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Se marcará el pago como '
                            'Cancelado y se registrarán '
                            'el motivo, fecha y '
                            'Administrador responsable. '
                            'No se borra su historial.',
                            style: TextStyle(color: _texto, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _motivo,
                    enabled: !_enviando && !_resultadoIncierto,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Motivo de cancelación *',
                      hintText:
                          'Describe por qué se cancela '
                          'este registro',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: _superficie,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  CheckboxListTile(
                    value: _aceptado,
                    onChanged: _enviando || _resultadoIncierto
                        ? null
                        : (valor) {
                            setState(() {
                              _aceptado = valor ?? false;
                            });
                          },
                    activeColor: _doradoOscuro,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Confirmo que revisé el pago '
                      'y comprendo las consecuencias '
                      'de cancelarlo.',
                      style: TextStyle(color: _texto, fontSize: 13),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE9E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _rojo),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _enviando || _resultadoIncierto
                          ? null
                          : _cancelar,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(
                        _enviando
                            ? 'Procesando cancelación...'
                            : 'Revisar y cancelar pago',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _rojo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  if (_resultadoIncierto) ...[
                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver y verificar historial'),
                    ),
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
