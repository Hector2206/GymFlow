import 'package:flutter/material.dart';

import '../models/membresia_activa.dart';
import '../services/cambio_membresia_service.dart';
import '../services/membresia_service.dart';

/// Boton reutilizable en los directorios de Administracion y Recepcion.
class CambiarMembresiaButton extends StatelessWidget {
  const CambiarMembresiaButton({
    super.key,
    required this.idCliente,
    required this.nombreCliente,
    required this.alActualizar,
    this.idMembresiaActual,
    this.nombreMembresiaActual,
  });

  final int idCliente;
  final String nombreCliente;
  final int? idMembresiaActual;
  final String? nombreMembresiaActual;
  final Future<void> Function() alActualizar;

  static const _dorado = Color(0xFFB58A2A);

  Future<void> _abrir(BuildContext context) async {
    final actualizado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CambiarMembresiaDialog(
        idCliente: idCliente,
        nombreCliente: nombreCliente,
        idMembresiaActual: idMembresiaActual,
        nombreMembresiaActual: nombreMembresiaActual,
      ),
    );

    if (!context.mounted || actualizado != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membresía actualizada correctamente.'),
        backgroundColor: Color(0xFF287447),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await alActualizar();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: idCliente > 0 ? () => _abrir(context) : null,
        icon: const Icon(Icons.card_membership_outlined),
        label: const Text('Cambiar membresía'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _dorado,
          side: const BorderSide(color: _dorado),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }
}

class _CambiarMembresiaDialog extends StatefulWidget {
  const _CambiarMembresiaDialog({
    required this.idCliente,
    required this.nombreCliente,
    this.idMembresiaActual,
    this.nombreMembresiaActual,
  });

  final int idCliente;
  final String nombreCliente;
  final int? idMembresiaActual;
  final String? nombreMembresiaActual;

  @override
  State<_CambiarMembresiaDialog> createState() =>
      _CambiarMembresiaDialogState();
}

class _CambiarMembresiaDialogState extends State<_CambiarMembresiaDialog> {
  static const _dorado = Color(0xFFB58A2A);
  static const _gris = Color(0xFF777067);
  static const _rojo = Color(0xFFA03930);
  static const _fondo = Color(0xFFFFFDF8);

  final _membresias = MembresiaService();
  final _cambios = CambioMembresiaService();

  List<MembresiaActiva> _planes = [];
  int? _idSeleccionado;
  bool _cargando = true;
  bool _guardando = false;
  bool _resultadoIncierto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _consultarPlanes();
  }

  Future<void> _consultarPlanes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final respuesta = await _membresias.obtenerMembresiasActivas();
      if (!mounted) return;
      setState(() {
        _planes = respuesta.where((plan) => plan.activo).toList();
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _guardar() async {
    final idPlan = _idSeleccionado;
    if (_guardando || _resultadoIncierto || idPlan == null) return;

    if (widget.idMembresiaActual == idPlan) {
      setState(() => _error = 'Selecciona una membresía diferente.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _cambios.cambiarMembresia(
        idCliente: widget.idCliente,
        idMembresia: idPlan,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final mensaje = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _guardando = false;
        _error = mensaje;
        _resultadoIncierto =
            mensaje.contains('podría haberse realizado') ||
            mensaje.contains('Verifica la membresía') ||
            mensaje.contains('no confirmó los datos') ||
            mensaje.contains('resultado del cambio es incierto');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombrePlan = widget.nombreMembresiaActual?.trim();
    final textoActual = nombrePlan != null && nombrePlan.isNotEmpty
        ? nombrePlan
        : widget.idMembresiaActual != null
            ? 'Plan #${widget.idMembresiaActual}'
            : 'No disponible en Recepción';

    return AlertDialog(
      backgroundColor: _fondo,
      title: const Text('Cambiar membresía'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.nombreCliente,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              Text('Membresía actual: $textoActual',
                  style: const TextStyle(color: _gris)),
              const SizedBox(height: 20),
              if (_cargando)
                const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Cargando membresías activas...')),
                  ],
                )
              else if (_planes.isEmpty)
                const Text('No hay membresías activas disponibles.')
              else
                DropdownButtonFormField<int>(
                  initialValue: _idSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva membresía',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Selecciona una membresía'),
                  items: _planes.map((plan) {
                    return DropdownMenuItem<int>(
                      value: plan.idMembresia,
                      enabled:
                          plan.idMembresia != widget.idMembresiaActual,
                      child: Text(plan.nombrePlan,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _guardando || _resultadoIncierto
                      ? null
                      : (id) => setState(() {
                          _idSeleccionado = id;
                          _error = null;
                        }),
                ),
              const SizedBox(height: 14),
              const Text(
                'El cambio se aplica inmediatamente. No registra '
                'un pago ni modifica las fechas o el historial de pagos.',
                style: TextStyle(color: _gris, fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: _rojo)),
              ],
              if (_resultadoIncierto) ...[
                const SizedBox(height: 8),
                const Text(
                  'Cierra esta ventana y vuelve a consultar al cliente '
                  'antes de intentar otro cambio.',
                  style: TextStyle(color: _rojo, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _dorado),
          onPressed: _guardando ||
                  _resultadoIncierto ||
                  _cargando ||
                  _idSeleccionado == null
              ? null
              : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Confirmar cambio'),
        ),
      ],
    );
  }
}
