import 'package:flutter/material.dart';

import '../models/rutina.dart';
import '../services/rutina_service.dart';

class MiRutinaPage extends StatefulWidget {
  const MiRutinaPage({super.key});

  @override
  State<MiRutinaPage> createState() =>
      _MiRutinaPageState();
}

class _MiRutinaPageState
    extends State<MiRutinaPage> {
  final RutinaService _rutinaService =
      RutinaService();

  static const Color _fondo =
      Color(0xFFF7F3EC);

  static const Color _blanco =
      Color(0xFFFFFCF7);

  static const Color _dorado =
      Color(0xFFC39528);

  static const Color _doradoOscuro =
      Color(0xFF96701A);

  static const Color _texto =
      Color(0xFF29251F);

  static const Color _gris =
      Color(0xFF7C756B);

  static const Color _borde =
      Color(0xFFE8DFD0);

  Rutina? _rutina;

  bool _cargando = true;

  String _error = '';

  int _diaSeleccionado = 0;

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _cargarRutina();
  }

  Future<void> _cargarRutina() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final rutina =
          await _rutinaService.obtenerMiRutina();

      if (!mounted) return;

      setState(() {
        _rutina = rutina;
        _diaSeleccionado =
            _primerDiaConEntrenamiento(rutina);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = _mensajeError(e);
      });
    }
  }

  int _primerDiaConEntrenamiento(
    Rutina rutina,
  ) {
    for (int i = 0;
        i < _diasSemana.length;
        i++) {
      final dia =
          _obtenerDia(rutina, i);

      if (dia != null &&
          dia.ejercicios.isNotEmpty) {
        return i;
      }
    }

    return 0;
  }

  DiaRutina? _obtenerDia(
    Rutina rutina,
    int indice,
  ) {
    final nombre =
        _diasSemana[indice];

    for (final dia in rutina.dias) {
      if (_normalizarDia(dia.dia) ==
          _normalizarDia(nombre)) {
        return dia;
      }
    }

    return null;
  }

  String _normalizarDia(
    String valor,
  ) {
    return valor
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  String _mensajeError(Object error) {
    final mensaje =
        error.toString();

    if (mensaje.startsWith(
      'Exception: ',
    )) {
      return mensaje.substring(11);
    }

    return mensaje;
  }

  int get _diasConEntrenamiento {
    if (_rutina == null) {
      return 0;
    }

    return _rutina!.dias
        .where(
          (dia) =>
              dia.ejercicios.isNotEmpty,
        )
        .length;
  }

  DiaRutina? get _diaActual {
    if (_rutina == null) {
      return null;
    }

    return _obtenerDia(
      _rutina!,
      _diaSeleccionado,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _blanco,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _doradoOscuro,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Mi Rutina',
          style: TextStyle(
            color: _texto,
            fontSize: 21,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: _dorado,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return _construirError();
    }

    if (_rutina == null) {
      return _construirSinRutina();
    }

    return RefreshIndicator(
      color: _dorado,
      onRefresh: _cargarRutina,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          32,
        ),
        children: [
          _construirEncabezado(),
          const SizedBox(height: 18),
          _construirRutinaAsignada(),
          const SizedBox(height: 18),
          _construirSemana(),
          const SizedBox(height: 18),
          _construirDiaSeleccionado(),
        ],
      ),
    );
  }

  Widget _construirEncabezado() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'CLIENTE',
          style: TextStyle(
            color: _doradoOscuro,
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Mi Rutina',
          style: TextStyle(
            color: _texto,
            fontSize: 30,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Selecciona un día y consulta los ejercicios de tu entrenamiento.',
          style: TextStyle(
            color: _gris,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _construirRutinaAsignada() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: _blanco,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _borde,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFFF4EAD5,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '🏋️',
                    style: TextStyle(
                      fontSize: 27,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RUTINA ASIGNADA',
                      style: TextStyle(
                        color:
                            _doradoOscuro,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing:
                            1.5,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      _rutina!.nombre,
                      style:
                          const TextStyle(
                        color: _texto,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    if (_rutina!
                            .descripcion
                            ?.isNotEmpty ==
                        true) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _rutina!
                            .descripcion!,
                        style:
                            const TextStyle(
                          color: _gris,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color: const Color(
                0xFFF7F3EC,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: _borde,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    color: _gris,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rutina!
                      .nombreCliente,
                  style:
                      const TextStyle(
                    color: _texto,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Widget _construirSemana() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _blanco,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: _borde,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEMANA',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tu entrenamiento',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_diasConEntrenamiento ${_diasConEntrenamiento == 1 ? 'día' : 'días'}',
                style: const TextStyle(
                  color: _doradoOscuro,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 72,
          child: Row(
            children: List.generate(
              _diasSemana.length,
              (index) {
                return Expanded(
                  child: _construirDia(index),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _construirDia(
  int index,
) {
  final dia = _obtenerDia(
    _rutina!,
    index,
  );

  final tieneRutina =
      dia != null &&
      dia.ejercicios.isNotEmpty;

  final seleccionado =
      _diaSeleccionado == index;

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 2,
    ),
    child: InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _diaSeleccionado = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        margin:
            const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFFF4EAD5)
              : const Color(0xFFFBF8F2),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? _dorado
                : _borde,
            width:
                seleccionado ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              _abreviarDia(
                _diasSemana[index],
              ),
              style: TextStyle(
                color: seleccionado
                    ? _doradoOscuro
                    : _texto,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                color: tieneRutina
                    ? _dorado
                    : const Color(
                        0xFFD7D1C7,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
String _abreviarDia(
  String dia,
) {
  switch (dia) {
    case 'Lunes':
      return 'Lun';
    case 'Martes':
      return 'Mar';
    case 'Miércoles':
      return 'Mié';
    case 'Jueves':
      return 'Jue';
    case 'Viernes':
      return 'Vie';
    case 'Sábado':
      return 'Sáb';
    case 'Domingo':
      return 'Dom';
    default:
      return dia;
  }
}

  Widget _construirDiaSeleccionado() {
    final dia =
        _diaActual;

    final ejercicios =
        dia?.ejercicios ??
            [];

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: _blanco,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _borde,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'DÍA SELECCIONADO',
            style: TextStyle(
              color: _doradoOscuro,
              fontSize: 11,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _diasSemana[
                _diaSeleccionado],
            style:
                const TextStyle(
              color: _texto,
              fontSize: 22,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ejercicios.isEmpty
                ? 'Día de descanso'
                : '${ejercicios.length} ${ejercicios.length == 1 ? 'ejercicio' : 'ejercicios'} configurados',
            style:
                const TextStyle(
              color: _gris,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(
            color: _borde,
            height: 1,
          ),
          const SizedBox(height: 18),
          if (ejercicios.isEmpty)
            _construirDescanso()
          else
            ...List.generate(
              ejercicios.length,
              (index) {
                return Padding(
                  padding:
                      EdgeInsets.only(
                    bottom:
                        index ==
                                ejercicios.length -
                                    1
                            ? 0
                            : 16,
                  ),
                  child:
                      _construirEjercicio(
                    ejercicios[index],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _construirDescanso() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 16,
      ),
      decoration:
          BoxDecoration(
        color: const Color(
          0xFFFBF8F2,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: _borde,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🌿',
            style: TextStyle(
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Día de descanso',
            style:
                TextStyle(
              color: _texto,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'No tienes ejercicios programados para este día.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: _gris,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEjercicio(
    EjercicioRutina ejercicio,
  ) {
    return Container(
      clipBehavior:
          Clip.antiAlias,
      decoration:
          BoxDecoration(
        color: _blanco,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: _borde,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (ejercicio.imagenUrl !=
                  null &&
              ejercicio.imagenUrl!
                  .trim()
                  .isNotEmpty)
            _construirImagen(
              ejercicio.imagenUrl!,
            ),
          Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF4EAD5,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${ejercicio.orden}',
                          style:
                              const TextStyle(
                            color:
                                _doradoOscuro,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 11,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'EJERCICIO',
                            style:
                                TextStyle(
                              color:
                                  _doradoOscuro,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing:
                                  1.5,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            ejercicio
                                .nombre,
                            style:
                                const TextStyle(
                              color:
                                  _texto,
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ejercicio
                        .descripcion
                        ?.isNotEmpty ==
                    true) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    ejercicio
                        .descripcion!,
                    style:
                        const TextStyle(
                      color: _gris,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          _construirDato(
                        'Series',
                        ejercicio
                            .series
                            .toString(),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          _construirDato(
                        'Repeticiones',
                        ejercicio
                            .repeticiones
                            .toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirImagen(
    String url,
  ) {
    return Container(
      width: double.infinity,
      height: 210,
      color: Colors.white,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return const Center(
            child: Icon(
              Icons
                  .fitness_center_outlined,
              size: 50,
              color: _dorado,
            ),
          );
        },
        loadingBuilder:
            (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress ==
              null) {
            return child;
          }

          return const Center(
            child:
                CircularProgressIndicator(
              color: _dorado,
            ),
          );
        },
      ),
    );
  }

  Widget _construirDato(
    String titulo,
    String valor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color: const Color(
          0xFFF7F3EC,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: _borde,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style:
                const TextStyle(
              color: _gris,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style:
                const TextStyle(
              color: _texto,
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              _error,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: _texto,
                fontSize: 15,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            ElevatedButton(
              onPressed:
                  _cargarRutina,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _dorado,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSinRutina() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Text(
              '🏋️',
              style: TextStyle(
                fontSize: 48,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'Aún no tienes una rutina asignada.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: _texto,
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Cuando tu entrenador te asigne una rutina aparecerá aquí.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: _gris,
                fontSize: 14,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            ElevatedButton(
              onPressed:
                  _cargarRutina,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _dorado,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Actualizar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}