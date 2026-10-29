import 'package:flutter/material.dart';

import '../services/notificaciones_service.dart';
import 'notificaciones_page.dart';

// GYMFLOW - SPRINT 8
// CAMPANITA CON CONTADOR DE NOTIFICACIONES

class CampanaNotificaciones extends StatefulWidget {
  const CampanaNotificaciones({super.key});

  @override
  State<CampanaNotificaciones> createState() => _CampanaNotificacionesState();
}

class _CampanaNotificacionesState extends State<CampanaNotificaciones> {
  final NotificacionesService _servicio = NotificacionesService();

  static const Color _doradoOscuro = Color(0xFF8A6814);

  static const Color _rojo = Color(0xFFA03930);

  int? _noLeidas;
  int _versionConsulta = 0;

  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    _actualizarContador();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  // CONSULTAR CONTADOR REAL DEL BACKEND

  Future<void> _actualizarContador() async {
    final consultaActual = ++_versionConsulta;

    try {
      final cantidad = await _servicio.obtenerNoLeidas();

      if (!mounted || consultaActual != _versionConsulta) {
        return;
      }

      setState(() {
        _noLeidas = cantidad;
      });
    } catch (_) {
      if (!mounted || consultaActual != _versionConsulta) {
        return;
      }

      // Si falla la consulta, no mostrar
      // un número desactualizado.
      setState(() {
        _noLeidas = null;
      });
    }
  }

  // ABRIR NOTIFICACIONES Y ACTUALIZAR AL REGRESAR

  Future<void> _abrirNotificaciones() async {
    if (_abriendo) return;

    setState(() {
      _abriendo = true;
    });

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const NotificacionesPage()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _abriendo = false;
        });

        await _actualizarContador();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _noLeidas ?? 0;

    final textoContador = pendientes > 99 ? '99+' : '$pendientes';

    return IconButton(
      tooltip: pendientes > 0
          ? '$pendientes notificaciones sin leer'
          : 'Mis notificaciones',
      onPressed: _abriendo ? null : _abrirNotificaciones,
      icon: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_outlined,
                color: _doradoOscuro,
                size: 27,
              ),
            ),

            // MOSTRAR CONTADOR SOLO SI EXISTEN
            // NOTIFICACIONES PENDIENTES.
            if (pendientes > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _rojo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      textoContador,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
