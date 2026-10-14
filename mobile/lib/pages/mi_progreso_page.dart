
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/progreso.dart';
import '../models/rutina.dart';
import '../services/progreso_service.dart';
import '../services/rutina_service.dart';

class MiProgresoPage extends StatefulWidget {
  const MiProgresoPage({super.key});

  @override
  State<MiProgresoPage> createState() => _MiProgresoPageState();
}

class _MiProgresoPageState extends State<MiProgresoPage> {
  static const Color _fondo = Color(0xFFF7F3EC);
  static const Color _blanco = Color(0xFFFFFCF7);
  static const Color _dorado = Color(0xFFC39528);
  static const Color _doradoOscuro = Color(0xFF96701A);
  static const Color _texto = Color(0xFF29251F);
  static const Color _gris = Color(0xFF7C756B);
  static const Color _borde = Color(0xFFE8DFD0);

  final RutinaService _rutinaService = RutinaService();
  final ProgresoService _progresoService = ProgresoService();
  final TextEditingController _pesoController =
      TextEditingController();

  List<EjercicioRutina> _ejercicios = [];
  List<Progreso> _historial = [];
  List<Progreso> _evolucion = [];

  int? _idSeleccionado;

  bool _cargando = true;
  bool _guardando = false;
  bool _cargandoEvolucion = false;

  String _errorRutina = '';
  String _errorHistorial = '';
  String _errorEvolucion = '';

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

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _fecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}'
        '  ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  String _peso(double valor) {
    final texto = valor.toStringAsFixed(2);
    return texto.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _errorRutina = '';
      _errorHistorial = '';
    });

    List<EjercicioRutina> ejercicios = [];
    List<Progreso> historial = [];
    String errorRutina = '';
    String errorHistorial = '';

    try {
      final rutina = await _rutinaService.obtenerMiRutina();
      final mapa = <int, EjercicioRutina>{};

      for (final dia in rutina.dias) {
        for (final ejercicio in dia.ejercicios) {
          if (ejercicio.idEjercicio > 0) {
            mapa[ejercicio.idEjercicio] = ejercicio;
          }
        }
      }

      ejercicios = mapa.values.toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
    } catch (error) {
      errorRutina = _mensajeError(error);
    }

    try {
      historial = await _progresoService.obtenerMiProgreso();
    } catch (error) {
      errorHistorial = _mensajeError(error);
    }

    if (!mounted) return;

    int? seleccionado = _idSeleccionado;

    if (!ejercicios.any(
      (ejercicio) => ejercicio.idEjercicio == seleccionado,
    )) {
      seleccionado = ejercicios.isEmpty
          ? null
          : ejercicios.first.idEjercicio;
    }

    setState(() {
      _ejercicios = ejercicios;
      _historial = historial;
      _idSeleccionado = seleccionado;
      _errorRutina = errorRutina;
      _errorHistorial = errorHistorial;
      _errorEvolucion = '';
      _evolucion = [];
      _cargando = false;
    });

    if (seleccionado != null) {
      await _cargarEvolucion(seleccionado);
    }
  }

  Future<void> _cargarEvolucion(int idEjercicio) async {
    setState(() {
      _cargandoEvolucion = true;
      _errorEvolucion = '';
      _evolucion = [];
    });

    try {
      final registros = await _progresoService
          .obtenerProgresoPorEjercicio(idEjercicio);

      if (!mounted || _idSeleccionado != idEjercicio) {
        return;
      }

      setState(() {
        _evolucion = registros;
        _cargandoEvolucion = false;
      });
    } catch (error) {
      if (!mounted || _idSeleccionado != idEjercicio) {
        return;
      }

      setState(() {
        _errorEvolucion = _mensajeError(error);
        _cargandoEvolucion = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    final idEjercicio = _idSeleccionado;
    final texto = _pesoController.text.trim().replaceAll(',', '.');
    final peso = double.tryParse(texto);

    if (idEjercicio == null) {
      _mostrarMensaje('Selecciona un ejercicio.');
      return;
    }

    if (peso == null ||
        !peso.isFinite ||
        peso <= 0 ||
        peso > 99999999.99) {
      _mostrarMensaje('Ingresa un peso válido mayor a cero.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _progresoService.registrarProgreso(
        idEjercicio: idEjercicio,
        pesoUtilizado: peso,
      );

      if (!mounted) return;

      _pesoController.clear();
      FocusScope.of(context).unfocus();

      _mostrarMensaje('Progreso registrado correctamente.');

      await _cargarDatos();
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(_mensajeError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _tarjeta(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borde),
      ),
      child: child,
    );
  }

  Widget _tituloSeccion(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: _doradoOscuro, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: _texto,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mensaje(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          color: _gris,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _formulario() {
    return _tarjeta(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            'Registrar entrenamiento',
            Icons.fitness_center_outlined,
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona un ejercicio de tu rutina y registra '
            'el peso que utilizaste.',
            style: TextStyle(color: _gris, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_errorRutina.isNotEmpty)
            _mensaje(_errorRutina),
          if (_ejercicios.isEmpty)
            _mensaje(
              'No hay ejercicios disponibles en tu rutina.',
            )
          else ...[
            DropdownButtonFormField<int>(
              initialValue: _idSeleccionado,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Ejercicio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _ejercicios.map((ejercicio) {
                return DropdownMenuItem<int>(
                  value: ejercicio.idEjercicio,
                  child: Text(
                    ejercicio.nombre,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _guardando
                  ? null
                  : (valor) {
                      if (valor == null) return;

                      setState(() {
                        _idSeleccionado = valor;
                      });

                      _cargarEvolucion(valor);
                    },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _pesoController,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Peso utilizado',
                hintText: 'Ejemplo: 35.5',
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : 'Guardar progreso',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _doradoOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grafica() {
    return _tarjeta(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            'Evolución del ejercicio',
            Icons.show_chart,
          ),
          const SizedBox(height: 16),
          if (_cargandoEvolucion)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: _dorado,
                ),
              ),
            )
          else if (_errorEvolucion.isNotEmpty)
            _mensaje(_errorEvolucion)
          else if (_idSeleccionado == null)
            _mensaje('Selecciona un ejercicio.')
          else if (_evolucion.isEmpty)
            _mensaje(
              'Todavía no tienes registros para este ejercicio.',
            )
          else if (_evolucion.length == 1)
            _mensaje(
              'Primer registro: '
              '${_peso(_evolucion.first.pesoUtilizado)} kg. '
              'Registra otro entrenamiento para ver la gráfica.',
            )
          else ...[
            Text(
              '${_evolucion.length} registros',
              style: const TextStyle(
                color: _gris,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 190,
              child: CustomPaint(
                painter: _PintorGrafica(_evolucion),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fecha(_evolucion.first.fechaRegistro)
                      .split('  ')
                      .first,
                  style: const TextStyle(
                    color: _gris,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _fecha(_evolucion.last.fechaRegistro)
                      .split('  ')
                      .first,
                  style: const TextStyle(
                    color: _gris,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Último peso: '
              '${_peso(_evolucion.last.pesoUtilizado)} kg',
              style: const TextStyle(
                color: _doradoOscuro,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historialWidget() {
    return _tarjeta(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            'Historial de progreso',
            Icons.history,
          ),
          const SizedBox(height: 14),
          if (_errorHistorial.isNotEmpty)
            _mensaje(_errorHistorial)
          else if (_historial.isEmpty)
            _mensaje(
              'Aún no tienes registros de entrenamiento.',
            )
          else
            ..._historial.map((registro) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _fondo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borde),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: _doradoOscuro,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              registro.nombreEjercicio,
                              style: const TextStyle(
                                color: _texto,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _fecha(registro.fechaRegistro),
                              style: const TextStyle(
                                color: _gris,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_peso(registro.pesoUtilizado)} kg',
                        style: const TextStyle(
                          color: _doradoOscuro,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _blanco,
        foregroundColor: _doradoOscuro,
        title: const Text(
          'Mi Progreso',
          style: TextStyle(
            color: _texto,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: _dorado,
              ),
            )
          : RefreshIndicator(
              color: _dorado,
              onRefresh: _cargarDatos,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16, 20, 16, 32,
                ),
                children: [
                  const Text(
                    'MI ENTRENAMIENTO',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mi Progreso',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registra tus pesos y consulta '
                    'cómo avanzas en cada ejercicio.',
                    style: TextStyle(
                      color: _gris,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _formulario(),
                  const SizedBox(height: 18),
                  _grafica(),
                  const SizedBox(height: 18),
                  _historialWidget(),
                ],
              ),
            ),
    );
  }
}

class _PintorGrafica extends CustomPainter {
  final List<Progreso> registros;

  _PintorGrafica(this.registros);

  @override
  void paint(Canvas canvas, Size size) {
    if (registros.length < 2) return;

    const double margen = 18;

    final valores = registros
        .map((e) => e.pesoUtilizado)
        .toList();

    final minimo = valores.reduce(math.min);
    final maximo = valores.reduce(math.max);
    final rango = math.max(1.0, maximo - minimo);

    final ancho = math.max(1.0, size.width - margen * 2);
    final alto = math.max(1.0, size.height - margen * 2);

    final guia = Paint()
      ..color = const Color(0xFFE8DFD0)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = margen + (alto * i / 3);
      canvas.drawLine(
        Offset(margen, y),
        Offset(margen + ancho, y),
        guia,
      );
    }

    final linea = Paint()
      ..color = const Color(0xFFC39528)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final punto = Paint()
      ..color = const Color(0xFF96701A);

    final trayectoria = Path();

    for (int i = 0; i < valores.length; i++) {
      final x = margen +
          ancho * i / (valores.length - 1);
      final y = margen +
          alto * (1 - (valores[i] - minimo) / rango);

      if (i == 0) {
        trayectoria.moveTo(x, y);
      } else {
        trayectoria.lineTo(x, y);
      }
    }

    canvas.drawPath(trayectoria, linea);

    for (int i = 0; i < valores.length; i++) {
      final x = margen +
          ancho * i / (valores.length - 1);
      final y = margen +
          alto * (1 - (valores[i] - minimo) / rango);

      canvas.drawCircle(
        Offset(x, y),
        4,
        punto,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorGrafica oldDelegate) {
    return oldDelegate.registros != registros;
  }
}
