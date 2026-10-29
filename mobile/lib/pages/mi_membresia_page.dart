import 'package:flutter/material.dart';

import '../models/mi_membresia.dart';
import '../services/mi_membresia_service.dart';
import 'mis_pagos_page.dart';

class MiMembresiaPage extends StatefulWidget {
  const MiMembresiaPage({super.key});

  @override
  State<MiMembresiaPage> createState() => _MiMembresiaPageState();
}

class _MiMembresiaPageState extends State<MiMembresiaPage> {
  final _servicio = MiMembresiaService();

  static const fondo = Color(0xFFF8F5EF);
  static const superficie = Color(0xFFFFFDF8);
  static const dorado = Color(0xFFB58A2A);
  static const doradoOscuro = Color(0xFF8A6814);
  static const texto = Color(0xFF2F2A24);
  static const secundario = Color(0xFF777067);
  static const borde = Color(0xFFE5DDCF);
  static const verde = Color(0xFF287447);
  static const rojo = Color(0xFFA03930);

  MiMembresia? _membresia;
  bool _cargando = true;
  String _error = '';
  int _numeroConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _numeroConsulta++;
    super.dispose();
  }

  Future<void> _cargar() async {
    final consultaActual = ++_numeroConsulta;

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final resultado = await _servicio.obtenerMiMembresia();

      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _membresia = resultado;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _membresia = null;
        _cargando = false;
      });
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Vigente':
        return verde;
      case 'Vencida':
        return rojo;
      default:
        return doradoOscuro;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'Vigente':
        return Icons.check_circle_outline;
      case 'Vencida':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Widget _dato(String etiqueta, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: doradoOscuro, size: 22),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(color: secundario, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  valor,
                  style: const TextStyle(
                    color: texto,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(MiMembresia membresia) {
    final colorEstado = _colorEstado(membresia.estado);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.card_membership_outlined,
                color: doradoOscuro,
                size: 35,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  membresia.nombrePlan,
                  style: const TextStyle(
                    color: texto,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: colorEstado.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorEstado.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconoEstado(membresia.estado),
                  color: colorEstado,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  membresia.estadoVisible,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const Divider(color: borde),
          _dato(
            'Precio mensual oficial',
            '\$${membresia.costoMensual.toStringAsFixed(2)} MXN',
            Icons.payments_outlined,
          ),
          const Divider(color: borde),
          _dato(
            'Precio anual oficial',
            '\$${membresia.costoAnualidad.toStringAsFixed(2)} MXN',
            Icons.account_balance_wallet_outlined,
          ),
          const Divider(color: borde),
          _dato(
            'Fecha de vencimiento',
            membresia.vencimientoVisible,
            Icons.event_outlined,
          ),
          if (membresia.estado == 'SinPagos') ...[
            const SizedBox(height: 10),
            const Text(
              'Aún no se registran pagos para calcular '
              'la fecha de vencimiento de tu membresía.',
              style: TextStyle(color: secundario, fontSize: 12, height: 1.4),
            ),
          ],
          const Divider(color: borde),
          _dato(
            'Identificador del plan',
            '#${membresia.idMembresia}',
            Icons.tag_outlined,
          ),
          const SizedBox(height: 8),
          const Text(
            'Los precios se consultan directamente '
            'desde GymFlow y son únicamente informativos.',
            style: TextStyle(color: secundario, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _errorConsulta() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: rojo, size: 36),
          const SizedBox(height: 12),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: texto),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirPagos() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MisPagosPage()));

    if (mounted) {
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: superficie,
        title: const Text('Mi Membresía'),
        actions: [
          IconButton(
            tooltip: 'Actualizar membresía',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh, color: doradoOscuro),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: dorado,
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GYMFLOW / CLIENTE',
                      style: TextStyle(
                        color: doradoOscuro,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tu membresía',
                      style: TextStyle(
                        color: texto,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Consulta la información y vigencia '
                      'de tu plan de gimnasio.',
                      style: TextStyle(color: secundario, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    if (_cargando)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(color: dorado),
                        ),
                      )
                    else if (_error.isNotEmpty)
                      _errorConsulta()
                    else if (_membresia != null)
                      _tarjeta(_membresia!),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _abrirPagos,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Consultar mis pagos'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
