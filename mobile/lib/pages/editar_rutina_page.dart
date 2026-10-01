import 'package:flutter/material.dart';

import '../models/ejercicio.dart';
import '../models/rutina.dart';
import '../services/ejercicio_service.dart';
import '../services/rutina_service.dart';

class EditarRutinaPage extends StatefulWidget {
  final int idRutina;

  const EditarRutinaPage({
    super.key,
    required this.idRutina,
  });

  @override
  State<EditarRutinaPage> createState() =>
      _EditarRutinaPageState();
}

class _EditarRutinaPageState
    extends State<EditarRutinaPage> {
  static const Color _fondo =
      Color(0xFFF8F5EF);

  static const Color _tarjeta =
      Color(0xFFFFFDF8);

  static const Color _dorado =
      Color(0xFFB58A2A);

  static const Color _doradoOscuro =
      Color(0xFF8A6814);

  static const Color _texto =
      Color(0xFF2F2A24);

  static const Color _textoSecundario =
      Color(0xFF7B746B);

  final RutinaService _rutinaService =
      RutinaService();

  final EjercicioService _ejercicioService =
      EjercicioService();

  final TextEditingController
      _nombreController =
      TextEditingController();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  bool _cargando = true;
  bool _cargandoEjercicios = true;
  bool _guardando = false;

  String _error = '';

  Rutina? _rutina;

  List<Ejercicio> _ejerciciosDisponibles = [];

  int _diaSeleccionado = 0;

  final List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final List<List<_EjercicioEditado>>
      _ejerciciosPorDia =
      List.generate(
    7,
    (_) => <_EjercicioEditado>[],
  );

  @override
  void initState() {
    super.initState();

    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();

    for (final dia
        in _ejerciciosPorDia) {
      for (final ejercicio in dia) {
        ejercicio.seriesController.dispose();
        ejercicio.repeticionesController
            .dispose();
      }
    }

    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarRutina(),
      _cargarEjercicios(),
    ]);
  }

  Future<void> _cargarRutina() async {
    try {
      final rutina =
          await _rutinaService
              .obtenerRutina(
        widget.idRutina,
      );

      if (!mounted) {
        return;
      }

      _nombreController.text =
          rutina.nombre;

      _descripcionController.text =
          rutina.descripcion ?? '';

      for (int i = 0; i < 7; i++) {
        final nombreDia = _dias[i];

        final dia = rutina.dias
            .where(
              (item) =>
                  item.dia
                      .trim()
                      .toLowerCase() ==
                  nombreDia
                      .trim()
                      .toLowerCase(),
            )
            .firstOrNull;

        if (dia == null) {
          continue;
        }

        for (final ejercicio
            in dia.ejercicios) {
          _ejerciciosPorDia[i].add(
            _EjercicioEditado(
              ejercicio:
                  _crearEjercicioDesdeRutina(
                ejercicio,
              ),
              series:
                  ejercicio.series,
              repeticiones:
                  ejercicio.repeticiones,
            ),
          );
        }
      }

      setState(() {
        _rutina = rutina;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;

        _error = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void>
      _cargarEjercicios() async {
    try {
      final ejercicios =
          await _ejercicioService
              .obtenerEjercicios();

      if (!mounted) {
        return;
      }

      setState(() {
        _ejerciciosDisponibles =
            ejercicios
                .where(
                  (ejercicio) =>
                      ejercicio.activo,
                )
                .toList();

        _cargandoEjercicios = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoEjercicios = false;
      });
    }
  }

 Ejercicio _crearEjercicioDesdeRutina(
  EjercicioRutina ejercicio,
) {
  return Ejercicio(
    idEjercicio:
        ejercicio.idEjercicio,
    nombre:
        ejercicio.nombre,
    descripcion:
        ejercicio.descripcion,
    imagenUrl:
        ejercicio.imagenUrl,
    activo: true,
  );
}

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _tarjeta,
        foregroundColor: _texto,
        elevation: 0,
        title: const Text(
          'Editar Rutina',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _construirContenido(),
      ),
    );
  }

  Widget _construirContenido() {
    if (_cargando ||
        _cargandoEjercicios) {
      return const Center(
        child: CircularProgressIndicator(
          color: _dorado,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return _construirError();
    }

    if (_rutina == null) {
      return const Center(
        child: Text(
          'No fue posible cargar la rutina.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        24,
        18,
        35,
      ),
      children: [
        const Text(
          'ENTRENADOR',
          style: TextStyle(
            color: _doradoOscuro,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'Editar Rutina',
          style: TextStyle(
            color: _texto,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          'Actualiza la rutina de ${_rutina!.nombreCliente}.',
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 14,
            height: 1.4,
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        _construirInformacion(),

        const SizedBox(
          height: 20,
        ),

        _construirPlanSemanal(),

        const SizedBox(
          height: 25,
        ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _guardando
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      _doradoOscuro,
                  side:
                      const BorderSide(
                    color: _dorado,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: ElevatedButton(
                onPressed:
                    _guardando
                        ? null
                        : _guardarCambios,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      _dorado,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar cambios',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirInformacion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFE6DED0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF3EAD8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: _doradoOscuro,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              const Expanded(
                child: Text(
                  'Información general',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'Cliente',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF3EAD8,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color:
                      _doradoOscuro,
                ),

                const SizedBox(
                  width: 9,
                ),

                Expanded(
                  child: Text(
                    _rutina!
                        .nombreCliente,
                    style:
                        const TextStyle(
                      color: _texto,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Nombre de la rutina',
            style: TextStyle(
              color: _texto,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          TextField(
            controller:
                _nombreController,
            enabled: !_guardando,
            textCapitalization:
                TextCapitalization
                    .sentences,
            decoration:
                _decoracionCampo(
              'Nombre de la rutina',
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Descripción',
            style: TextStyle(
              color: _texto,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          TextField(
            controller:
                _descripcionController,
            enabled: !_guardando,
            maxLines: 4,
            textCapitalization:
                TextCapitalization
                    .sentences,
            decoration:
                _decoracionCampo(
              'Descripción de la rutina',
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPlanSemanal() {
    final ejerciciosDia =
        _ejerciciosPorDia[
            _diaSeleccionado];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFE6DED0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: _doradoOscuro,
              ),

              const SizedBox(
                width: 9,
              ),

              const Expanded(
                child: Text(
                  'Plan semanal',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection:
                  Axis.horizontal,
              itemCount: 7,
              itemBuilder:
                  (context, index) {
                return _construirDia(
                  index,
                );
              },
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  _dias[
                      _diaSeleccionado],
                  style:
                      const TextStyle(
                    color: _texto,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed:
                    _guardando
                        ? null
                        : _agregarEjercicio,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Agregar',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      _dorado,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          if (ejerciciosDia.isEmpty)
            _construirDescanso()
          else
            ...ejerciciosDia
                .asMap()
                .entries
                .map(
                  (entry) =>
                      _construirEjercicio(
                    entry.key,
                    entry.value,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _construirDia(int index) {
    final seleccionado =
        _diaSeleccionado == index;

    final cantidad =
        _ejerciciosPorDia[index]
            .length;

    final nombres = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    return GestureDetector(
      onTap: _guardando
          ? null
          : () {
              setState(() {
                _diaSeleccionado =
                    index;
              });
            },
      child: Container(
        width: 82,
        margin:
            const EdgeInsets.only(
          right: 8,
        ),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(
                  0xFFF3EAD8,
                )
              : const Color(
                  0xFFFCFAF5,
                ),
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          border: Border.all(
            color: seleccionado
                ? _dorado
                : const Color(
                    0xFFE6DED0,
                  ),
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              nombres[index],
              style:
                  const TextStyle(
                color: _texto,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              cantidad == 0
                  ? 'Descanso'
                  : '$cantidad ejercicio${cantidad == 1 ? '' : 's'}',
              style:
                  const TextStyle(
                color:
                    _textoSecundario,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEjercicio(
    int indice,
    _EjercicioEditado item,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFFEFB,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(
            0xFFE5DCCE,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFFF3EAD8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${indice + 1}',
                    style:
                        const TextStyle(
                      color:
                          _doradoOscuro,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  item.ejercicio.nombre,
                  style:
                      const TextStyle(
                    color: _texto,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              IconButton(
                onPressed:
                    _guardando
                        ? null
                        : () {
                            _eliminarEjercicio(
                              indice,
                            );
                          },
                color:
                    const Color(
                  0xFFB94A4A,
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child: _campoNumero(
                  titulo: 'Series',
                  controller:
                      item.seriesController,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _campoNumero(
                  titulo:
                      'Repeticiones',
                  controller:
                      item
                          .repeticionesController,
                ),
              ),
            ],
          ),

          if (item.ejercicio
                      .imagenUrl !=
                  null &&
              item.ejercicio
                  .imagenUrl!
                  .trim()
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 12,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child: Image.network(
                  item.ejercicio
                      .imagenUrl!,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const SizedBox
                        .shrink();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _campoNumero({
    required String titulo,
    required TextEditingController
        controller,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: _texto,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        TextField(
          controller:
              controller,
          enabled: !_guardando,
          keyboardType:
              TextInputType.number,
          decoration:
              _decoracionCampo(''),
        ),
      ],
    );
  }

  Widget _construirDescanso() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFAF7F0,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '🌿',
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'Día de descanso',
            style: TextStyle(
              color: _texto,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarEjercicio() async {
    if (_ejerciciosDisponibles
        .isEmpty) {
      _mostrarMensaje(
        'No hay ejercicios disponibles.',
      );

      return;
    }

    final ejercicio =
        await _seleccionarEjercicio();

    if (ejercicio == null ||
        !mounted) {
      return;
    }

    final existe =
        _ejerciciosPorDia[
                _diaSeleccionado]
            .any(
      (item) =>
          item.ejercicio.idEjercicio ==
          ejercicio.idEjercicio,
    );

    if (existe) {
      _mostrarMensaje(
        'Ese ejercicio ya está agregado a este día.',
      );

      return;
    }

    setState(() {
      _ejerciciosPorDia[
              _diaSeleccionado]
          .add(
        _EjercicioEditado(
          ejercicio: ejercicio,
          series: 3,
          repeticiones: 10,
        ),
      );
    });
  }

  Future<Ejercicio?>
      _seleccionarEjercicio() async {
    List<Ejercicio> filtrados =
        List.from(
      _ejerciciosDisponibles,
    );

    return showModalBottomSheet<
        Ejercicio>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (
            context,
            setModalState,
          ) {
            return Container(
              height:
                  MediaQuery.of(
                            context,
                          )
                          .size
                          .height *
                      .82,
              decoration:
                  const BoxDecoration(
                color: _tarjeta,
                borderRadius:
                    BorderRadius.vertical(
                  top:
                      Radius.circular(
                    24,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        20,
                        18,
                        20,
                        10,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Agregar ejercicio',
                              style:
                                  TextStyle(
                                color:
                                    _texto,
                                fontSize:
                                    20,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .close_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        onChanged:
                            (texto) {
                          setModalState(() {
                            if (texto
                                .trim()
                                .isEmpty) {
                              filtrados =
                                  List.from(
                                _ejerciciosDisponibles,
                              );
                            } else {
                              filtrados =
                                  _ejerciciosDisponibles
                                      .where(
                                (ejercicio) =>
                                    ejercicio
                                        .nombre
                                        .toLowerCase()
                                        .contains(
                                          texto
                                              .toLowerCase(),
                                        ),
                              ).toList();
                            }
                          });
                        },
                        decoration:
                            InputDecoration(
                          hintText:
                              'Buscar ejercicio...',
                          prefixIcon:
                              const Icon(
                            Icons
                                .search_rounded,
                            color:
                                _doradoOscuro,
                          ),
                          filled: true,
                          fillColor:
                              const Color(
                            0xFFF8F4EC,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                            borderSide:
                                BorderSide
                                    .none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Expanded(
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          20,
                          8,
                          20,
                          25,
                        ),
                        itemCount:
                            filtrados.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final ejercicio =
                              filtrados[
                                  index];

                          return ListTile(
                            onTap: () {
                              Navigator.pop(
                                context,
                                ejercicio,
                              );
                            },
                            leading:
                                _iconoEjercicio(
                              ejercicio,
                            ),
                            title: Text(
                              ejercicio
                                  .nombre,
                              style:
                                  const TextStyle(
                                color:
                                    _texto,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                            trailing:
                                const Icon(
                              Icons
                                  .chevron_right_rounded,
                              color:
                                  _doradoOscuro,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _iconoEjercicio(
    Ejercicio ejercicio,
  ) {
    if (ejercicio.imagenUrl != null &&
        ejercicio.imagenUrl!
            .trim()
            .isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child: Image.network(
          ejercicio.imagenUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return _iconoDefault();
          },
        ),
      );
    }

    return _iconoDefault();
  }

  Widget _iconoDefault() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(
          0xFFF3EAD8,
        ),
        borderRadius:
            BorderRadius.circular(
          9,
        ),
      ),
      child: const Icon(
        Icons.fitness_center_rounded,
        color: _doradoOscuro,
      ),
    );
  }

  void _eliminarEjercicio(
    int indice,
  ) {
    final lista =
        _ejerciciosPorDia[
            _diaSeleccionado];

    final item =
        lista.removeAt(indice);

    item.seriesController.dispose();
    item.repeticionesController
        .dispose();

    setState(() {});
  }

  Future<void> _guardarCambios() async {
    FocusScope.of(context).unfocus();

    final nombre =
        _nombreController.text.trim();

    if (nombre.isEmpty) {
      _mostrarMensaje(
        'Escribe el nombre de la rutina.',
      );

      return;
    }

    final dias =
        <DiaRutina>[];

    for (int i = 0; i < 7; i++) {
      final ejercicios =
          _ejerciciosPorDia[i];

      if (ejercicios.isEmpty) {
        continue;
      }

      final ejerciciosDia =
          <EjercicioRutina>[];

      for (int j = 0;
          j < ejercicios.length;
          j++) {
        final item =
            ejercicios[j];

        final series =
            int.tryParse(
                  item.seriesController
                      .text
                      .trim(),
                ) ??
                0;

        final repeticiones =
            int.tryParse(
                  item
                      .repeticionesController
                      .text
                      .trim(),
                ) ??
                0;

        if (series <= 0) {
          _mostrarMensaje(
            'Las series deben ser mayores a 0.',
          );

          return;
        }

        if (repeticiones <= 0) {
          _mostrarMensaje(
            'Las repeticiones deben ser mayores a 0.',
          );

          return;
        }

        ejerciciosDia.add(
          EjercicioRutina(
            idEjercicio:
                item.ejercicio
                    .idEjercicio,
            nombre:
                item.ejercicio
                    .nombre,
            series: series,
            repeticiones:
                repeticiones,
            orden: j + 1,
            imagenUrl:
                item.ejercicio
                    .imagenUrl,
          ),
        );
      }

      dias.add(
        DiaRutina(
          dia: _dias[i],
          ejercicios:
              ejerciciosDia,
        ),
      );
    }

    if (dias.isEmpty) {
      _mostrarMensaje(
        'La rutina debe tener al menos un día con ejercicios.',
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _rutinaService.editarRutina(
        idRutina:
            widget.idRutina,
        idCliente:
            _rutina!.idCliente,
        nombre: nombre,
        descripcion:
            _descripcionController
                    .text
                    .trim()
                    .isEmpty
                ? null
                : _descripcionController
                    .text
                    .trim(),
        dias: dias,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Rutina actualizada correctamente.',
          ),
          backgroundColor:
              Color(0xFF39804B),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
      });

      _mostrarMensaje(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  InputDecoration _decoracionCampo(
    String hint,
  ) {
    return InputDecoration(
      hintText:
          hint.isEmpty ? null : hint,
      hintStyle: const TextStyle(
        color: Color(
          0xFF9B9388,
        ),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(
        0xFFF8F4EC,
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color: Color(
            0xFFE4DBCD,
          ),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color: Color(
            0xFFE4DBCD,
          ),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color: _dorado,
          width: 1.3,
        ),
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
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
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton(
              onPressed:
                  _cargarDatos,
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

  void _mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
        ),
      ),
    );
  }
}

class _EjercicioEditado {
  final Ejercicio ejercicio;

  final TextEditingController
      seriesController;

  final TextEditingController
      repeticionesController;

  _EjercicioEditado({
    required this.ejercicio,
    required int series,
    required int repeticiones,
  })  : seriesController =
            TextEditingController(
          text: series.toString(),
        ),
        repeticionesController =
            TextEditingController(
          text: repeticiones.toString(),
        );
}