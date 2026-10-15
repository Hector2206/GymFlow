import 'package:flutter/material.dart';

import '../models/cliente_resumen.dart';
import '../models/entrenador_resumen.dart';
import '../services/asignacion_entrenador_service.dart';
import '../services/cliente_consulta_service.dart';

/// Sprint 6: asignación de entrenadores, disponible desde el Home de Recepción.
/// Conserva los datos del Backend; no modifica clientes ni entrenadores.
class AsignacionEntrenadoresPage extends StatefulWidget {
  const AsignacionEntrenadoresPage({super.key});

  @override
  State<AsignacionEntrenadoresPage> createState() =>
      _AsignacionEntrenadoresPageState();
}

class _AsignacionEntrenadoresPageState
    extends State<AsignacionEntrenadoresPage> {
  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _crema = Color(0xFFF3EAD8);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);
  static const Color _rojo = Color(0xFFB64742);

  final ClienteConsultaService _clienteService = ClienteConsultaService();
  final AsignacionEntrenadorService _asignacionService =
      AsignacionEntrenadorService();

  List<ClienteResumen> _clientes = [];
  List<EntrenadorResumen> _entrenadores = [];
  int? _idCliente;
  int? _idEntrenador;
  bool _cargando = true;
  bool _guardando = false;
  bool _quitando = false;
  String _error = '';
  String _exito = '';

  bool get _ocupado => _cargando || _guardando || _quitando;

  ClienteResumen? get _clienteActual {
    for (final cliente in _clientes) {
      if (cliente.idCliente == _idCliente) return cliente;
    }
    return null;
  }

  EntrenadorResumen? get _entrenadorElegido {
    for (final entrenador in _entrenadores) {
      if (entrenador.idEntrenador == _idEntrenador) return entrenador;
    }
    return null;
  }

  String? get _nombreEntrenadorActual {
    final cliente = _clienteActual;
    final id = cliente?.idEntrenador;
    if (id == null || id <= 0) return null;
    final nombre = cliente?.nombreEntrenador?.trim();
    if (nombre != null && nombre.isNotEmpty) return nombre;
    for (final entrenador in _entrenadores) {
      if (entrenador.idEntrenador == id) return entrenador.nombreCompleto;
    }
    return 'Entrenador #$id';
  }

  String _mensaje(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (_guardando || _quitando) return;
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final resultados = await Future.wait<Object>([
        _clienteService.obtenerClientes(),
        _asignacionService.obtenerEntrenadores(),
      ]);
      if (!mounted) return;

      final clientes = resultados[0] as List<ClienteResumen>;
      final entrenadores = resultados[1] as List<EntrenadorResumen>;
      final clienteSigue =
          clientes.any((item) => item.idCliente == _idCliente);
      final entrenadorSigue =
          entrenadores.any((item) => item.idEntrenador == _idEntrenador);

      setState(() {
        _clientes = clientes;
        _entrenadores = entrenadores;
        if (!clienteSigue) {
          _idCliente = null;
          _idEntrenador = null;
        } else if (!entrenadorSigue) {
          _idEntrenador = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _mensaje(error));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _cambiarCliente(int? id) {
    if (_ocupado) return;
    setState(() {
      _idCliente = id;
      _idEntrenador = null;
      _error = '';
      _exito = '';
    });
  }

  Future<bool> _confirmar({
    required String titulo,
    required String detalle,
    required String accion,
    bool peligro = false,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _superficie,
        title: Text(titulo, style: const TextStyle(color: _texto)),
        content: Text(detalle, style: const TextStyle(color: _secundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: peligro ? _rojo : _doradoOscuro,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  Future<void> _asignar() async {
    if (_ocupado) return;
    final cliente = _clienteActual;
    final entrenador = _entrenadorElegido;
    if (cliente == null || entrenador == null) {
      setState(() => _error = 'Selecciona un cliente y un entrenador.');
      return;
    }
    if (cliente.idEntrenador == entrenador.idEntrenador) {
      setState(() => _error = 'Este cliente ya tiene ese entrenador asignado.');
      return;
    }

    final tieneAsignado = cliente.idEntrenador != null;
    final confirmado = await _confirmar(
      titulo: tieneAsignado ? 'Cambiar entrenador' : 'Asignar entrenador',
      detalle: tieneAsignado
          ? '¿Cambiar el entrenador de ${cliente.nombreCompleto} a '
              '${entrenador.nombreCompleto}?'
          : '¿Asignar a ${entrenador.nombreCompleto} como entrenador de '
              '${cliente.nombreCompleto}?',
      accion: tieneAsignado ? 'Cambiar' : 'Asignar',
    );
    if (!mounted || !confirmado || _ocupado || _idCliente != cliente.idCliente) {
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
      _exito = '';
    });
    try {
      final resultado = await _asignacionService.asignarEntrenador(
        idCliente: cliente.idCliente,
        idEntrenador: entrenador.idEntrenador,
      );
      if (!mounted) return;
      _actualizarClienteLocal(
        cliente.idCliente,
        entrenador.idEntrenador,
        resultado['nombreEntrenador']?.toString() ?? entrenador.nombreCompleto,
      );
      setState(() {
        _idEntrenador = null;
        _exito = resultado['mensaje']?.toString() ??
            'Entrenador asignado correctamente.';
      });
      await _refrescarClientesLuegoDeGuardar();
    } catch (error) {
      if (mounted) setState(() => _error = _mensaje(error));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _quitar() async {
    if (_ocupado) return;
    final cliente = _clienteActual;
    if (cliente == null || cliente.idEntrenador == null) return;

    final confirmado = await _confirmar(
      titulo: 'Quitar entrenador',
      detalle: '¿Quitar a ${_nombreEntrenadorActual ?? 'su entrenador'} '
          'de ${cliente.nombreCompleto}? El cliente quedará sin entrenador '
          'asignado.',
      accion: 'Quitar',
      peligro: true,
    );
    if (!mounted || !confirmado || _ocupado || _idCliente != cliente.idCliente) {
      return;
    }

    setState(() {
      _quitando = true;
      _error = '';
      _exito = '';
    });
    try {
      final resultado =
          await _asignacionService.quitarEntrenador(cliente.idCliente);
      if (!mounted) return;
      _actualizarClienteLocal(cliente.idCliente, null, null);
      setState(() {
        _idEntrenador = null;
        _exito = resultado['mensaje']?.toString() ??
            'Entrenador retirado correctamente.';
      });
      await _refrescarClientesLuegoDeGuardar();
    } catch (error) {
      if (mounted) setState(() => _error = _mensaje(error));
    } finally {
      if (mounted) setState(() => _quitando = false);
    }
  }

  /// Actualización inmediata para que la vista no muestre datos obsoletos.
  void _actualizarClienteLocal(int idCliente, int? idEntrenador, String? nombre) {
    setState(() {
      _clientes = [
        for (final item in _clientes)
          if (item.idCliente == idCliente)
            ClienteResumen(
              idCliente: item.idCliente,
              nombreCompleto: item.nombreCompleto,
              idEntrenador: idEntrenador,
              nombreEntrenador: nombre,
            )
          else
            item,
      ];
    });
  }

  Future<void> _refrescarClientesLuegoDeGuardar() async {
    try {
      final clientes = await _clienteService.obtenerClientes();
      if (mounted) setState(() => _clientes = clientes);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exito += ' Actualiza la pantalla para verificar la asignación.';
      });
    }
  }

  BoxDecoration _decoracionTarjeta() => BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borde),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A362B1F),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      );

  Widget _etiqueta(String texto) => Text(
        texto,
        style: const TextStyle(
          color: _doradoOscuro,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      );

  Widget _mensajeEstado(String mensaje, {required bool error}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFF2F0) : const Color(0xFFEFF8F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: error ? const Color(0xFFF2C9C5) : const Color(0xFFC5DFC6),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline,
              size: 20,
              color: error ? _rojo : const Color(0xFF378248),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: error ? _rojo : const Color(0xFF276D39),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _selectorCliente() => DropdownButtonFormField<int>(
        key: ValueKey('cliente_$_idCliente'),
        initialValue: _idCliente,
        isExpanded: true,
        decoration: _decoracionSelector(
          'Selecciona un cliente',
          Icons.person_outline_rounded,
        ),
        items: [
          for (final cliente in _clientes)
            DropdownMenuItem<int>(
              value: cliente.idCliente,
              child: Text(
                cliente.nombreCompleto,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
        onChanged: _ocupado ? null : _cambiarCliente,
      );

  Widget _selectorEntrenador() => DropdownButtonFormField<int>(
        key: ValueKey('entrenador_${_idCliente}_$_idEntrenador'),
        initialValue: _idEntrenador,
        isExpanded: true,
        decoration: _decoracionSelector(
          'Selecciona un entrenador',
          Icons.fitness_center_rounded,
        ),
        items: [
          for (final entrenador in _entrenadores)
            DropdownMenuItem<int>(
              value: entrenador.idEntrenador,
              child: Text(
                entrenador.nombreCompleto,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
        onChanged: _ocupado || _idCliente == null
            ? null
            : (id) {
                setState(() {
                  _idEntrenador = id;
                  _error = '';
                  _exito = '';
                });
              },
      );

  InputDecoration _decoracionSelector(String pista, IconData icono) =>
      InputDecoration(
        hintText: pista,
        hintStyle: const TextStyle(color: _secundario, fontSize: 14),
        prefixIcon: Icon(icono, color: _doradoOscuro, size: 21),
        filled: true,
        fillColor: _superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _dorado, width: 1.5),
        ),
      );

  Widget _paso(int numero, String titulo, String descripcion) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 33,
            height: 33,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _crema, shape: BoxShape.circle),
            child: Text(
              '$numero',
              style: const TextStyle(
                color: _doradoOscuro,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(color: _secundario, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _asignacionActual() {
    final cliente = _clienteActual;
    if (cliente == null) return const SizedBox.shrink();
    final nombre = _nombreEntrenadorActual;
    final asignado = nombre != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: asignado ? const Color(0xFFF1F6EE) : const Color(0xFFF8F4EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: asignado ? const Color(0xFFDAE8D3) : _borde,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            asignado ? Icons.verified_rounded : Icons.info_outline_rounded,
            size: 22,
            color: asignado ? const Color(0xFF548348) : _doradoOscuro,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asignado ? 'Entrenador asignado actualmente' : 'Sin entrenador asignado',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secundario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  nombre ?? 'Este cliente todavía no tiene entrenador.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: _texto,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cliente.nombreCompleto,
                  style: const TextStyle(fontSize: 12, color: _secundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _dorado));
    }
    if (_clientes.isEmpty || _entrenadores.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_outlined, size: 48, color: _dorado),
              const SizedBox(height: 14),
              Text(
                _error.isNotEmpty
                    ? _error
                    : _clientes.isEmpty
                        ? 'No hay clientes disponibles.'
                        : 'No hay entrenadores activos disponibles.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _texto, fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(backgroundColor: _doradoOscuro),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _dorado,
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          _etiqueta('RECEPCIÓN  /  SPRINT 6'),
          const SizedBox(height: 8),
          const Text(
            'Asignación de Entrenadores',
            style: TextStyle(
              color: _texto,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Asigna un entrenador a cada cliente para dar seguimiento a '
            'sus rutinas y entrenamiento.',
            style: TextStyle(color: _secundario, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (_error.isNotEmpty) ...[
            _mensajeEstado(_error, error: true),
            const SizedBox(height: 12),
          ],
          if (_exito.isNotEmpty) ...[
            _mensajeEstado(_exito, error: false),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _decoracionTarjeta(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _etiqueta('GESTIÓN'),
                          const SizedBox(height: 6),
                          const Text(
                            'Asignar entrenador',
                            style: TextStyle(
                              color: _texto,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _crema,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: _doradoOscuro,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _paso(1, 'Cliente', 'Selecciona al cliente que deseas administrar.'),
                const SizedBox(height: 11),
                _selectorCliente(),
                const SizedBox(height: 15),
                _asignacionActual(),
                if (_clienteActual != null) const SizedBox(height: 17),
                const Divider(color: _borde),
                const SizedBox(height: 17),
                _paso(2, 'Entrenador', 'Selecciona el entrenador que deseas asignar.'),
                const SizedBox(height: 11),
                _selectorEntrenador(),
                const SizedBox(height: 21),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: FilledButton.icon(
                    onPressed: _ocupado || _clienteActual == null ||
                            _entrenadorElegido == null ||
                            _clienteActual!.idEntrenador == _idEntrenador
                        ? null
                        : _asignar,
                    style: FilledButton.styleFrom(
                      backgroundColor: _doradoOscuro,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2DCD1),
                      disabledForegroundColor: _secundario,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: _guardando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      _guardando
                          ? 'Guardando...'
                          : _nombreEntrenadorActual == null
                              ? 'Asignar entrenador'
                              : 'Cambiar entrenador',
                    ),
                  ),
                ),
                if (_nombreEntrenadorActual != null) ...[
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: OutlinedButton.icon(
                      onPressed: _ocupado ? null : _quitar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _rojo,
                        side: const BorderSide(color: Color(0xFFE5C6C1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: _quitando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_remove_alt_1_outlined),
                      label: Text(_quitando ? 'Quitando...' : 'Quitar entrenador'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: _decoracionTarjeta(),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _doradoOscuro),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acerca de las asignaciones',
                        style: TextStyle(color: _texto, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Al asignar un entrenador, este podrá consultar al '
                        'cliente dentro de sus clientes asignados y administrar '
                        'sus rutinas. Desliza hacia abajo para actualizar.',
                        style: TextStyle(
                          color: _secundario,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _fondo,
        appBar: AppBar(
          backgroundColor: _superficie,
          foregroundColor: _texto,
          surfaceTintColor: _superficie,
          elevation: 0,
          centerTitle: true,
          title: Image.asset('assets/Logo_GymFlow.png', height: 33),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _ocupado ? null : _cargarDatos,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(child: _contenido()),
      );
}
