import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ejercicio.dart';
import '../models/progreso.dart';
import '../services/ejercicio_service.dart';
import '../services/progreso_service.dart';

/// Mi Progreso — Mobile Sprint 6.
/// Diseño adaptado de la pantalla Angular de GymFlow.
/// Todos los registros se obtienen del Backend con JWT.
class MiProgresoPage extends StatefulWidget {
  const MiProgresoPage({super.key});

  @override
  State<MiProgresoPage> createState() => _MiProgresoPageState();
}

class _MiProgresoPageState extends State<MiProgresoPage> {
  static const _fondo = Color(0xFFF8F5EF);
  static const _superficie = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _crema = Color(0xFFF3EAD8);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _borde = Color(0xFFE5DDCF);

  final _ejercicioService = EjercicioService();
  final _progresoService = ProgresoService();
  final _pesoController = TextEditingController();

  DateTime _fechaEntrenamiento = DateUtils.dateOnly(DateTime.now());

  List<Ejercicio> _ejercicios = [];
  List<Progreso> _historial = [];
  List<Progreso> _progresoEjercicio = [];

  int? _idFormulario;
  int? _idGrafica;
  int _solicitudGrafica = 0;
  int _solicitudDatos = 0;
  int? _puntoSeleccionado;

  bool _cargando = true;
  bool _cargandoGrafica = false;
  bool _guardando = false;
  String _errorEjercicios = '';
  String _errorHistorial = '';
  String _errorGrafica = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  String _mensajeError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  String _peso(double valor) =>
      valor.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  String _fecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  String _fechaYHora(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${_fecha(fecha)} · ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  // La fecha del entrenamiento puede diferir del día del registro.
  String _fechaDelProgreso(Progreso progreso) {
    final fechaEntrenamiento = progreso.fechaEntrenamiento;
    if (fechaEntrenamiento == null) {
      return _fechaYHora(progreso.fechaRegistro);
    }
    final fechaElegida = _fecha(fechaEntrenamiento);
    if (fechaElegida != _fecha(progreso.fechaRegistro)) {
      return '$fechaElegida · registrado ${_fecha(progreso.fechaRegistro)}';
    }
    return fechaElegida;
  }

  Future<void> _seleccionarFecha() async {
    if (_guardando) return;
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaEntrenamiento.isAfter(hoy) ? hoy : _fechaEntrenamiento,
      firstDate: DateTime(2000),
      lastDate: hoy,
      helpText: 'Fecha del entrenamiento',
      cancelText: 'Cancelar',
      confirmText: 'Elegir fecha',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _dorado,
            onPrimary: Colors.white,
            surface: _superficie,
            onSurface: _texto,
          ),
        ),
        child: child!,
      ),
    );
    if (elegida != null && mounted) {
      setState(() => _fechaEntrenamiento = DateUtils.dateOnly(elegida));
    }
  }

  Widget _campoFecha() => InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: _guardando ? null : _seleccionarFecha,
        child: InputDecorator(
          isEmpty: false,
          decoration: _entrada('Fecha del entrenamiento').copyWith(
            suffixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: _doradoOscuro,
            ),
          ),
          child: Text(
            _fecha(_fechaEntrenamiento),
            style: const TextStyle(
              color: _texto,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );

  void _mensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: error ? const Color(0xFF8F2030) : _doradoOscuro,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Se conservan los ejercicios activos para registrar y los que ya tengan
  /// historial para consultarlos, aunque se hayan desactivado.
  List<Ejercicio> _combinarEjercicios(
    List<Ejercicio> catalogo,
    List<Progreso> historial,
  ) {
    final mapa = <int, Ejercicio>{};
    for (final ejercicio in catalogo) {
      if (ejercicio.idEjercicio > 0 && ejercicio.activo) {
        mapa[ejercicio.idEjercicio] = ejercicio;
      }
    }
    for (final registro in historial) {
      mapa.putIfAbsent(
        registro.idEjercicio,
        () => Ejercicio(
          idEjercicio: registro.idEjercicio,
          nombre: registro.nombreEjercicio,
          activo: false,
        ),
      );
    }
    return mapa.values.toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(
            b.nombre.toLowerCase(),
          ));
  }

  /// Los GET /api/progreso y /api/ejercicios se mantienen independientes:
  /// si uno falla, mostramos el otro en lugar de perder toda la pantalla.
  Future<void> _cargarDatos() async {
    final solicitud = ++_solicitudDatos;
    ++_solicitudGrafica; // Invalida cualquier gráfica en vuelo.
    setState(() {
      _cargando = true;
      _cargandoGrafica = false;
      _errorEjercicios = '';
      _errorHistorial = '';
      _errorGrafica = '';
      _progresoEjercicio = [];
    });

    List<Ejercicio> catalogo = [];
    List<Progreso> historial = [];
    String errorEjercicios = '';
    String errorHistorial = '';

    try {
      catalogo = await _ejercicioService.obtenerEjercicios();
    } catch (error) {
      errorEjercicios = _mensajeError(error);
    }
    try {
      historial = await _progresoService.obtenerMiProgreso();
    } catch (error) {
      errorHistorial = _mensajeError(error);
    }
    if (!mounted || solicitud != _solicitudDatos) return;

    final ejercicios = _combinarEjercicios(catalogo, historial);
    final ids = ejercicios.map((e) => e.idEjercicio).toSet();

    var idFormulario = _idFormulario;
    if (idFormulario == null || !ids.contains(idFormulario)) {
      idFormulario = historial.isNotEmpty
          ? historial.first.idEjercicio
          : (ejercicios.isEmpty ? null : ejercicios.first.idEjercicio);
    }

    // La gráfica sigue al ejercicio elegido en el formulario, evitando
    // que se muestre por accidente la gráfica del ejercicio anterior.
    setState(() {
      _ejercicios = ejercicios;
      _historial = historial;
      _idFormulario = idFormulario;
      _idGrafica = idFormulario;
      _errorEjercicios = errorEjercicios;
      _errorHistorial = errorHistorial;
      _cargando = false;
    });
    if (idFormulario != null) {
      await _cargarGrafica(idFormulario);
    }
  }

  /// Reinicia la gráfica ANTES del await, y descarta respuestas antiguas.
  /// Así, al cambiar de Sentadilla a Remo, nunca se conserva Sentadilla.
  Future<void> _cargarGrafica(int idEjercicio) async {
    final solicitud = ++_solicitudGrafica;
    setState(() {
      _idGrafica = idEjercicio;
      _progresoEjercicio = [];
      _errorGrafica = '';
      _cargandoGrafica = true;
      _puntoSeleccionado = null;
    });

    try {
      final registros = await _progresoService
          .obtenerProgresoPorEjercicio(idEjercicio);
      if (!mounted ||
          solicitud != _solicitudGrafica ||
          _idGrafica != idEjercicio) {
        return;
      }
      final ordenados = [...registros]
        ..sort((a, b) {
          final fechas = a.fechaVisible.compareTo(b.fechaVisible);
          if (fechas != 0) return fechas;
          final registro = a.fechaRegistro.compareTo(b.fechaRegistro);
          return registro != 0
              ? registro
              : a.idProgreso.compareTo(b.idProgreso);
        });
      setState(() {
        _progresoEjercicio = ordenados;
        _puntoSeleccionado = ordenados.isEmpty ? null : ordenados.length - 1;
        _cargandoGrafica = false;
      });
    } catch (error) {
      if (!mounted ||
          solicitud != _solicitudGrafica ||
          _idGrafica != idEjercicio) {
        return;
      }
      setState(() {
        _errorGrafica = _mensajeError(error);
        _cargandoGrafica = false;
      });
    }
  }

  void _seleccionarEjercicio(int idEjercicio) {
    if (_guardando) return;
    setState(() => _idFormulario = idEjercicio);
    _cargarGrafica(idEjercicio);
  }

  Ejercicio? get _ejercicioFormulario {
    for (final ejercicio in _ejercicios) {
      if (ejercicio.idEjercicio == _idFormulario) return ejercicio;
    }
    return null;
  }

  String get _nombreGrafica {
    for (final ejercicio in _ejercicios) {
      if (ejercicio.idEjercicio == _idGrafica) return ejercicio.nombre;
    }
    for (final progreso in _historial) {
      if (progreso.idEjercicio == _idGrafica) {
        return progreso.nombreEjercicio;
      }
    }
    return 'Ejercicio';
  }

  List<_EjercicioResumen> get _resumenEjercicios {
    final mapa = <int, _EjercicioResumen>{};
    for (final progreso in _historial) {
      if (mapa.containsKey(progreso.idEjercicio)) {
        mapa[progreso.idEjercicio]!.cantidad++;
      } else {
        mapa[progreso.idEjercicio] = _EjercicioResumen(
          idEjercicio: progreso.idEjercicio,
          nombre: progreso.nombreEjercicio,
          cantidad: 1,
        );
      }
    }
    return mapa.values.toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(
            b.nombre.toLowerCase(),
          ));
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final ejercicio = _ejercicioFormulario;
    if (ejercicio == null) {
      _mensaje('Selecciona un ejercicio.', error: true);
      return;
    }
    if (!ejercicio.activo) {
      _mensaje(
        'Este ejercicio está inactivo. Solo puedes consultar su historial.',
        error: true,
      );
      return;
    }
    final peso = double.tryParse(
      _pesoController.text.trim().replaceAll(',', '.'),
    );
    if (peso == null ||
        !peso.isFinite ||
        peso <= 0 ||
        peso > 99999999.99) {
      _mensaje('Ingresa un peso válido mayor a cero.', error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      await _progresoService.registrarProgreso(
        idEjercicio: ejercicio.idEjercicio,
        pesoUtilizado: peso,
        fechaEntrenamiento: _fechaEntrenamiento,
      );
      if (!mounted) return;
      _pesoController.clear();
      setState(() => _fechaEntrenamiento = DateUtils.dateOnly(DateTime.now()));
      FocusScope.of(context).unfocus();
      _mensaje('Progreso registrado correctamente.');
      await _cargarDatos();
    } catch (error) {
      if (mounted) _mensaje(_mensajeError(error), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _entrada(String etiqueta, {String? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(color: _secundario, fontSize: 13),
      suffixText: sufijo,
      suffixStyle: const TextStyle(
        color: _doradoOscuro,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: _fondo,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFD8C8A5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _dorado, width: 1.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
      ),
    );
  }

  Widget _etiqueta(String texto) => Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: _doradoOscuro,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      );

  Widget _textoAyuda(String texto) => Text(
        texto,
        style: const TextStyle(color: _secundario, fontSize: 13, height: 1.5),
      );

  Widget _panel(Widget contenido) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borde),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C4C3E24),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: contenido,
      );

  Widget _encabezadoPanel({
    required String etiqueta,
    required String titulo,
    required String descripcion,
    required IconData icono,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _etiqueta(etiqueta),
              const SizedBox(height: 6),
              Text(
                titulo,
                style: const TextStyle(
                  color: _texto,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              _textoAyuda(descripcion),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 49,
          width: 49,
          decoration: BoxDecoration(
            color: _crema,
            border: Border.all(color: const Color(0xFFE4D2AA)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icono, color: _doradoOscuro, size: 25),
        ),
      ],
    );
  }

  Widget _botonGuardar() => SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _guardando || _ejercicioFormulario?.activo != true
              ? null
              : _guardar,
          icon: _guardando
              ? const SizedBox(
                  height: 17,
                  width: 17,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.add_circle_outline_rounded, size: 19),
          label: Text(
            _guardando ? 'Guardando...' : 'Registrar progreso',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _dorado,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD8C89F),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      );

  Widget _formulario() {
    final actual = _ejercicioFormulario;
    final habilitado = actual?.activo == true;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoPanel(
            etiqueta: 'Nuevo registro',
            titulo: 'Registrar progreso',
            descripcion:
                'Selecciona un ejercicio e indica el peso utilizado durante tu entrenamiento.',
            icono: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 22),
          if (_errorEjercicios.isNotEmpty) ...[
            _aviso('No se pudo cargar el catálogo: $_errorEjercicios'),
            const SizedBox(height: 12),
          ],
          if (_ejercicios.isEmpty)
            _aviso('No hay ejercicios disponibles para registrar.')
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final ancho = constraints.maxWidth;
                final campos = <Widget>[
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      // Fuerza recreación del campo al seleccionar otro
                      // ejercicio, evitando que aparezca el nombre anterior.
                      key: ValueKey('ejercicio-$_idFormulario'),
                      initialValue: _idFormulario,
                      isExpanded: true,
                      dropdownColor: _superficie,
                      decoration: _entrada('Ejercicio'),
                      items: _ejercicios.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.idEjercicio,
                          child: Text(
                            e.activo ? e.nombre : '${e.nombre} (historial)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _guardando
                          ? null
                          : (id) {
                              if (id != null) _seleccionarEjercicio(id);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _pesoController,
                      enabled: !_guardando && habilitado,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _entrada('Peso utilizado', sufijo: 'kg'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _campoFecha()),
                  const SizedBox(width: 12),
                  _botonGuardar(),
                ];
                if (ancho >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: campos,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey('ejercicio-$_idFormulario'),
                      initialValue: _idFormulario,
                      isExpanded: true,
                      dropdownColor: _superficie,
                      decoration: _entrada('Ejercicio'),
                      items: _ejercicios.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.idEjercicio,
                          child: Text(
                            e.activo ? e.nombre : '${e.nombre} (historial)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _guardando
                          ? null
                          : (id) {
                              if (id != null) _seleccionarEjercicio(id);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pesoController,
                      enabled: !_guardando && habilitado,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _entrada('Peso utilizado', sufijo: 'kg'),
                    ),
                    const SizedBox(height: 12),
                    _campoFecha(),
                    const SizedBox(height: 14),
                    _botonGuardar(),
                  ],
                );
              },
            ),
            if (!habilitado) ...[
              const SizedBox(height: 10),
              _textoAyuda(
                'Este ejercicio está inactivo: puedes ver sus registros, pero no registrar un peso nuevo.',
              ),
            ],
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.today_outlined, size: 17, color: _doradoOscuro),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Puedes seleccionar hoy o una fecha anterior si olvidaste registrar tu entrenamiento.',
                  style: const TextStyle(color: _secundario, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aviso(String texto) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _fondo,
          border: Border.all(color: _borde),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _textoAyuda(texto),
      );

  Widget _chipEjercicio(_EjercicioResumen resumen) {
    final seleccionado = _idGrafica == resumen.idEjercicio;
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: _guardando ? null : () => _seleccionarEjercicio(resumen.idEjercicio),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: seleccionado ? _crema : _fondo,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: seleccionado ? _dorado : _borde,
            width: seleccionado ? 1.5 : 1,
          ),
          boxShadow: seleccionado
              ? const [
                  BoxShadow(
                    color: Color(0x1AB58A2A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: seleccionado ? _dorado : _crema,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 17,
                color: seleccionado ? Colors.white : _doradoOscuro,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resumen.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _texto,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${resumen.cantidad} ${resumen.cantidad == 1 ? 'registro' : 'registros'}',
                    style: const TextStyle(color: _secundario, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metrica(
    String titulo,
    String valor, {
    bool actual = false,
    Color? color,
    IconData? icono,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: actual ? const Color(0xFFF8F2E5) : _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: actual ? const Color(0xFFD8C392) : _borde,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icono != null) ...[
                Icon(icono, size: 15, color: actual ? _doradoOscuro : _secundario),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secundario, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              maxLines: 1,
              style: TextStyle(
                color: color ?? (actual ? _doradoOscuro : _texto),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleGrafica() {
    // Cargar y datos siempre se refieren a _idGrafica (no al anterior).
    final registros = _progresoEjercicio;
    final inicial = registros.isEmpty ? 0.0 : registros.first.pesoUtilizado;
    final actual = registros.isEmpty ? 0.0 : registros.last.pesoUtilizado;
    final cambio = actual - inicial;
    final cambioColor = cambio > 0
        ? const Color(0xFF477C4C)
        : cambio < 0
            ? const Color(0xFFA8444F)
            : _secundario;

    if (_cargandoGrafica) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: _dorado)),
      );
    }
    if (_errorGrafica.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aviso('No se pudo cargar la evolución: $_errorGrafica'),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _idGrafica == null
                ? null
                : () => _cargarGrafica(_idGrafica!),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (_idGrafica == null) {
      return _aviso('Selecciona un ejercicio para consultar su progreso.');
    }
    if (registros.isEmpty) {
      return _aviso(
        'Todavía no hay registros de $_nombreGrafica. '
        'Selecciona un ejercicio con historial o realiza tu primer registro.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _fondo,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: const BoxDecoration(
              color: _superficie,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  height: 47,
                  width: 47,
                  decoration: BoxDecoration(
                    color: _crema,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: _doradoOscuro,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _etiqueta('Tu progreso en'),
                      const SizedBox(height: 4),
                      Text(
                        _nombreGrafica,
                        style: const TextStyle(
                          color: _texto,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: _crema,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${registros.length}',
                    style: const TextStyle(
                      color: _doradoOscuro,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borde),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 16, 13, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tarjetas = <Widget>[
                  _metrica(
                    'Peso inicial',
                    '${_peso(inicial)} kg',
                    icono: Icons.flag_outlined,
                  ),
                  _metrica(
                    'Peso actual',
                    '${_peso(actual)} kg',
                    actual: true,
                    icono: Icons.fitness_center_outlined,
                  ),
                  _metrica(
                    'Cambio',
                    registros.length < 2
                        ? '—'
                        : '${cambio > 0 ? '+' : ''}${_peso(cambio)} kg',
                    color: cambioColor,
                    icono: Icons.trending_up,
                  ),
                ];
                // En móvil conservamos las tres métricas juntas, como Web,
                // y en pantallas muy estrechas usamos dos columnas.
                if (constraints.maxWidth < 300) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tarjeta in tarjetas)
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: tarjeta,
                        ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < tarjetas.length; i++) ...[
                      Expanded(child: tarjetas[i]),
                      if (i < tarjetas.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                );
              },
            ),
          ),
          if (registros.length < 2)
            Padding(
              padding: const EdgeInsets.all(17),
              child: _aviso(
                'Tu evolución comienza aquí. Registra este ejercicio otra vez '
                'para ver cómo cambia tu peso.',
              ),
            )
          else
            _graficaLinea(registros),
          _historialEjercicio(registros),
        ],
      ),
    );
  }

  Widget _graficaLinea(List<Progreso> registros) {
    final indice = math.min(
      registros.length - 1,
      math.max(0, _puntoSeleccionado ?? (registros.length - 1)),
    );
    final punto = registros[indice];

    void seleccionar(double x, double width) {
      // Los márgenes deben coincidir con _PintorEvolucion.
      const izquierdo = 51.0;
      const derecho = 17.0;
      final ancho = math.max(1.0, width - izquierdo - derecho);
      final valor = math.min(
        registros.length - 1,
        math.max(
          0,
          ((x - izquierdo) / ancho * (registros.length - 1)).round(),
        ),
      );
      if (_puntoSeleccionado != valor) {
        setState(() => _puntoSeleccionado = valor);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(13, 16, 13, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _superficie,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _etiqueta('Evolución'),
                    const SizedBox(height: 4),
                    const Text(
                      'Peso utilizado',
                      style: TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _crema,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'kg',
                  style: TextStyle(
                    color: _doradoOscuro,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Toca un punto de la gráfica para ver su peso y fecha.',
            style: TextStyle(color: _secundario, fontSize: 11),
          ),
          const SizedBox(height: 13),
          Container(
            height: 242,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFAF7F1), _superficie],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => seleccionar(
                  details.localPosition.dx,
                  box.maxWidth,
                ),
                onHorizontalDragUpdate: (details) => seleccionar(
                  details.localPosition.dx,
                  box.maxWidth,
                ),
                child: CustomPaint(
                  painter: _PintorEvolucion(
                    registros,
                    indiceSeleccionado: indice,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  _fecha(registros.first.fechaVisible),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secundario, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fecha(registros.last.fechaVisible),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secundario, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: _crema,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4D2AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: _doradoOscuro),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ENTRENAMIENTO SELECCIONADO',
                        style: TextStyle(
                          color: _doradoOscuro,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fechaDelProgreso(punto),
                        style: const TextStyle(
                          color: _texto,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_peso(punto.pesoUtilizado)} kg',
                  style: const TextStyle(
                    color: _doradoOscuro,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// El historial se agrupa por fecha de entrenamiento (no por fecha de
  /// registro). Las fechas más recientes quedan arriba, sin alterar el orden
  /// ascendente que utiliza la gráfica para las métricas.
  Widget _historialEjercicio(List<Progreso> registros) {
    final recientes = [...registros]
      ..sort((a, b) {
        final fecha = b.fechaVisible.compareTo(a.fechaVisible);
        if (fecha != 0) return fecha;
        final registro = b.fechaRegistro.compareTo(a.fechaRegistro);
        return registro != 0
            ? registro
            : b.idProgreso.compareTo(a.idProgreso);
      });

    final grupos = <String, List<Progreso>>{};
    for (final progreso in recientes) {
      final dia = _fecha(progreso.fechaVisible);
      grupos.putIfAbsent(dia, () => []).add(progreso);
    }

    return Container(
      margin: const EdgeInsets.all(13),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _superficie,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiqueta('Registros'),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historial del ejercicio',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _crema,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${registros.length} registros',
                  style: const TextStyle(
                    color: _doradoOscuro,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Agrupados por fecha de entrenamiento · recientes primero',
            style: TextStyle(color: _secundario, fontSize: 11),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < grupos.length; i++) ...[
            _grupoHistorial(
              grupos.entries.elementAt(i).key,
              grupos.entries.elementAt(i).value,
              abierto: i == 0,
            ),
            if (i < grupos.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }

  Widget _grupoHistorial(
    String fecha,
    List<Progreso> registros, {
    required bool abierto,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _borde),
        color: _fondo,
      ),
      child: ExpansionTile(
        key: PageStorageKey('$_idGrafica-$fecha'),
        initiallyExpanded: abierto,
        tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
        childrenPadding: const EdgeInsets.only(bottom: 5),
        iconColor: _doradoOscuro,
        collapsedIconColor: _doradoOscuro,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          fecha,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _texto,
          ),
        ),
        subtitle: Text(
          '${registros.length} ${registros.length == 1 ? 'registro' : 'registros'}',
          style: const TextStyle(color: _secundario, fontSize: 11),
        ),
        leading: const Icon(Icons.calendar_month_outlined,
            color: _doradoOscuro, size: 21),
        children: [
          for (var i = 0; i < registros.length; i++) ...[
            if (i == 0) const Divider(height: 1, color: _borde),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _dorado,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrenamiento registrado',
                          style: TextStyle(
                            color: _texto,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Capturado el ${_fechaYHora(registros[i].fechaRegistro)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _secundario,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_peso(registros[i].pesoUtilizado)} kg',
                    style: const TextStyle(
                      color: _doradoOscuro,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (i < registros.length - 1)
              const Divider(indent: 30, endIndent: 12, height: 1, color: _borde),
          ],
        ],
      ),
    );
  }

  Widget _seccionEvolucion() {
    final resumen = _resumenEjercicios;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoPanel(
            etiqueta: 'Evolución',
            titulo: 'Progreso por ejercicio',
            descripcion:
                'Elige un ejercicio para revisar tus pesos, métricas y registros.',
            icono: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 19),
          if (_errorHistorial.isNotEmpty) ...[
            _aviso('No se pudo cargar el historial: $_errorHistorial'),
            const SizedBox(height: 12),
          ],
          if (resumen.isEmpty) ...[
            _aviso(
              'Aún no tienes registros. Guarda tu primer peso para comenzar '
              'a visualizar tu evolución.',
            ),
          ] else ...[
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: resumen.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) =>
                    _chipEjercicio(resumen[index]),
              ),
            ),
            const SizedBox(height: 17),
          ],
          _detalleGrafica(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: _superficie,
        foregroundColor: _doradoOscuro,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _borde),
        ),
        title: Image.asset(
          'assets/Logo_GymFlow.png',
          width: 120,
          height: 45,
          fit: BoxFit.contain,
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _dorado))
          : RefreshIndicator(
              color: _dorado,
              onRefresh: _cargarDatos,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_fondo, Color(0xFFF2EDE4)],
                  ),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1020),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiqueta('Cliente'),
                              const SizedBox(height: 7),
                              const Text(
                                'Mi Progreso',
                                style: TextStyle(
                                  color: _texto,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _textoAyuda(
                                'Registra el peso utilizado en tus ejercicios '
                                'y observa cómo evoluciona tu entrenamiento.',
                              ),
                              const SizedBox(height: 24),
                              _formulario(),
                              const SizedBox(height: 22),
                              _seccionEvolucion(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EjercicioResumen {
  final int idEjercicio;
  final String nombre;
  int cantidad;

  _EjercicioResumen({
    required this.idEjercicio,
    required this.nombre,
    required this.cantidad,
  });
}

/// Eje vertical en kg, líneas guía y puntos seleccionables. La posición de
/// cada punto conserva el orden cronológico recibido (incluye varios registros
/// en un mismo día, cada uno con su lugar en la secuencia).
class _PintorEvolucion extends CustomPainter {
  final List<Progreso> registros;
  final int? indiceSeleccionado;

  const _PintorEvolucion(
    this.registros, {
    this.indiceSeleccionado,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (registros.length < 2 || size.width < 90 || size.height < 90) {
      return;
    }

    const izquierda = 51.0;
    const derecha = 17.0;
    const arriba = 26.0;
    const abajo = 25.0;
    final ancho = math.max(1.0, size.width - izquierda - derecha);
    final alto = math.max(1.0, size.height - arriba - abajo);
    final valores = registros.map((r) => r.pesoUtilizado).toList();
    final menor = valores.reduce(math.min);
    final mayor = valores.reduce(math.max);
    final paddingVertical = math.max(2.0, (mayor - menor) * 0.12);
    final minY = math.max(0.0, menor - paddingVertical);
    final maxY = mayor + paddingVertical;
    final rango = math.max(1.0, maxY - minY);

    String etiqueta(double valor) {
      return valor.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    }

    final guia = Paint()
      ..color = const Color(0xFFE6DCCD)
      ..strokeWidth = 1;
    final textoEstilo = const TextStyle(
      color: Color(0xFF8B8173),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Cuatro marcas en el eje Y, siempre con su peso en kg.
    for (var i = 0; i < 4; i++) {
      final fraccion = i / 3;
      final y = arriba + alto * fraccion;
      canvas.drawLine(
        Offset(izquierda, y),
        Offset(izquierda + ancho, y),
        guia,
      );
      final peso = maxY - rango * fraccion;
      final textPainter = TextPainter(
        text: TextSpan(text: etiqueta(peso), style: textoEstilo),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: izquierda - 8);
      textPainter.paint(
        canvas,
        Offset(izquierda - 9 - textPainter.width, y - textPainter.height / 2),
      );
    }

    Offset posicion(int indice) {
      final x = izquierda + ancho * indice / (valores.length - 1);
      final y = arriba + alto * (1 - (valores[indice] - minY) / rango);
      return Offset(x, y);
    }

    final camino = Path();
    for (var i = 0; i < valores.length; i++) {
      final pt = posicion(i);
      if (i == 0) {
        camino.moveTo(pt.dx, pt.dy);
      } else {
        camino.lineTo(pt.dx, pt.dy);
      }
    }

    // Fondo dorado suave bajo la línea.
    final area = Path.from(camino)
      ..lineTo(izquierda + ancho, arriba + alto)
      ..lineTo(izquierda, arriba + alto)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x39B58A2A), Color(0x00B58A2A)],
        ).createShader(Rect.fromLTWH(izquierda, arriba, ancho, alto)),
    );

    final linea = Paint()
      ..color = const Color(0xFFB58A2A)
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(camino, linea);

    if (indiceSeleccionado != null &&
        indiceSeleccionado! >= 0 &&
        indiceSeleccionado! < valores.length) {
      final seleccionado = posicion(indiceSeleccionado!);
      final vertical = Paint()
        ..color = const Color(0x99B58A2A)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(seleccionado.dx, arriba),
        Offset(seleccionado.dx, arriba + alto),
        vertical,
      );
    }

    for (var i = 0; i < valores.length; i++) {
      final pos = posicion(i);
      final elegido = i == indiceSeleccionado;
      if (elegido) {
        canvas.drawCircle(pos, 9, Paint()..color = const Color(0x55B58A2A));
      }
      canvas.drawCircle(pos, elegido ? 5.5 : 4.0,
          Paint()..color = const Color(0xFFFFFDF8));
      canvas.drawCircle(pos, elegido ? 4.3 : 3.0,
          Paint()..color = const Color(0xFF8A6814));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorEvolucion anterior) =>
      anterior.registros != registros ||
      anterior.indiceSeleccionado != indiceSeleccionado;
}
