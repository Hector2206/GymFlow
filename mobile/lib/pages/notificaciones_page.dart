import 'package:flutter/material.dart';

import '../models/notificacion_gymflow.dart';
import '../services/notificaciones_service.dart';

// GYMFLOW - SPRINT 8
// PANTALLA DE NOTIFICACIONES DEL USUARIO

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final NotificacionesService _servicio = NotificacionesService();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);
  static const Color _rojo = Color(0xFFA03930);
  static const Color _verde = Color(0xFF287447);

  List<NotificacionGymflow> _notificaciones = [];

  bool _cargando = true;
  bool _soloNoLeidas = false;

  String? _error;
  int? _marcandoId;
  int _versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  // ====================================
  // CONSULTAR NOTIFICACIONES REALES
  // ====================================

  Future<void> _cargarNotificaciones() async {
    final versionActual = ++_versionConsulta;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _servicio.obtenerNotificaciones();

      if (!mounted || versionActual != _versionConsulta) {
        return;
      }

      setState(() {
        _notificaciones = resultado;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || versionActual != _versionConsulta) {
        return;
      }

      setState(() {
        _cargando = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ====================================
  // MARCAR COMO LEIDA
  // ====================================

  Future<void> _marcarComoLeida(NotificacionGymflow notificacion) async {
    if (notificacion.leida || _marcandoId != null || _cargando) {
      return;
    }

    setState(() {
      _marcandoId = notificacion.idNotificacion;
    });

    try {
      await _servicio.marcarComoLeida(notificacion.idNotificacion);

      if (!mounted) return;

      await _cargarNotificaciones();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación marcada como leída.'),
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${error.toString().replaceFirst('Exception: ', '')} '
            'Actualiza la lista para comprobar '
            'el estado de la notificación.',
          ),
          backgroundColor: _rojo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _marcandoId = null;
        });
      }
    }
  }

  // ====================================
  // FILTROS Y FORMATOS
  // ====================================

  int get _totalNoLeidas => _notificaciones.where((n) => !n.leida).length;

  List<NotificacionGymflow> get _notificacionesVisibles {
    if (!_soloNoLeidas) {
      return _notificaciones;
    }

    return _notificaciones.where((n) => !n.leida).toList();
  }

  String _mostrarFecha(String fecha) {
    if (fecha.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(fecha)) {
      return '${fecha.substring(8, 10)}/'
          '${fecha.substring(5, 7)}/'
          '${fecha.substring(0, 4)}';
    }

    return fecha;
  }

  // ====================================
  // TARJETA DE NOTIFICACION
  // ====================================

  Widget _tarjetaNotificacion(NotificacionGymflow notificacion) {
    final pendiente = !notificacion.leida;

    final procesando = _marcandoId == notificacion.idNotificacion;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: pendiente ? const Color(0xFFD7BB78) : _borde,
          width: pendiente ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pendiente
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  color: _doradoOscuro,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.titulo,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      notificacion.tipo,
                      style: const TextStyle(color: _secundario, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: pendiente
                  ? const Color(0xFFF3EAD8)
                  : const Color(0xFFE7F3E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pendiente ? 'No leída' : 'Leída',
              style: TextStyle(
                color: pendiente ? _doradoOscuro : _verde,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            notificacion.mensaje,
            style: const TextStyle(color: _texto, fontSize: 14, height: 1.5),
          ),

          const SizedBox(height: 16),

          const Divider(color: _borde),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.event_outlined, color: _doradoOscuro, size: 18),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Vencimiento: '
                  '${_mostrarFecha(notificacion.fechaVencimiento)}',
                  style: const TextStyle(color: _secundario, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Recibida: '
            '${_mostrarFecha(notificacion.creadoEn)}',
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),

          if (notificacion.leida && notificacion.fechaLectura != null) ...[
            const SizedBox(height: 7),

            Text(
              'Leída: '
              '${_mostrarFecha(notificacion.fechaLectura!)}',
              style: const TextStyle(color: _secundario, fontSize: 12),
            ),
          ],

          if (pendiente) ...[
            const SizedBox(height: 17),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _marcandoId != null || _cargando
                    ? null
                    : () => _marcarComoLeida(notificacion),
                icon: procesando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.done_all_outlined),
                label: Text(
                  procesando ? 'Actualizando...' : 'Marcar como leída',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _doradoOscuro,
                  padding: const EdgeInsets.all(13),
                  side: const BorderSide(color: Color(0xFFD8C8A5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 35),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: _rojo, size: 44),

            const SizedBox(height: 12),

            Text(
              _error ??
                  'No fue posible obtener '
                      'las notificaciones.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _secundario),
            ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: _cargarNotificaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // PANTALLA PRINCIPAL
  // ====================================

  @override
  Widget build(BuildContext context) {
    final visibles = _notificacionesVisibles;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: _texto, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar notificaciones',
            onPressed: _cargando || _marcandoId != null
                ? null
                : _cargarNotificaciones,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _cargarNotificaciones,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
          children: [
            const Text(
              'GYMFLOW / AVISOS',
              style: TextStyle(
                color: _doradoOscuro,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Centro de notificaciones',
              style: TextStyle(
                color: _texto,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Consulta tus avisos y revisa '
              'los que tienes pendientes.',
              style: TextStyle(color: _secundario, fontSize: 13, height: 1.4),
            ),

            const SizedBox(height: 22),

            if (!_cargando && _error == null) ...[
              Row(
                children: [
                  Expanded(child: _resumen('Total', _notificaciones.length)),

                  const SizedBox(width: 12),

                  Expanded(child: _resumen('Sin leer', _totalNoLeidas)),
                ],
              ),

              const SizedBox(height: 22),

              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: !_soloNoLeidas,
                    selectedColor: const Color(0xFFF3EAD8),
                    onSelected: (_) {
                      setState(() {
                        _soloNoLeidas = false;
                      });
                    },
                  ),

                  ChoiceChip(
                    label: const Text('No leídas'),
                    selected: _soloNoLeidas,
                    selectedColor: const Color(0xFFF3EAD8),
                    onSelected: (_) {
                      setState(() {
                        _soloNoLeidas = true;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
            else if (visibles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 35),
                child: Column(
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: _doradoOscuro,
                      size: 48,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _soloNoLeidas
                          ? 'No tienes avisos pendientes'
                          : 'No tienes notificaciones',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...visibles.map(_tarjetaNotificacion),
          ],
        ),
      ),
    );
  }

  Widget _resumen(String titulo, int cantidad) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),

          const SizedBox(height: 8),

          Text(
            '$cantidad',
            style: const TextStyle(
              color: _doradoOscuro,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
