import 'package:flutter/material.dart';

import '../models/ejercicio.dart';
import '../models/rutina.dart';
import '../services/cliente_entrenador_service.dart';
import '../services/ejercicio_service.dart';
import '../services/rutina_service.dart';

class CrearRutinaPage extends StatefulWidget {
  const CrearRutinaPage({
    super.key,
  });

  @override
  State<CrearRutinaPage> createState() =>
      _CrearRutinaPageState();
}

class _CrearRutinaPageState
    extends State<CrearRutinaPage> {
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

  final ClienteEntrenadorService
      _clienteService =
      ClienteEntrenadorService();

  final EjercicioService _ejercicioService =
      EjercicioService();

  final RutinaService _rutinaService =
      RutinaService();

  final TextEditingController
      _nombreController =
      TextEditingController();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  bool _cargandoClientes = true;
  bool _cargandoEjercicios = true;
  bool _guardando = false;

  String _errorClientes = '';
  String _errorEjercicios = '';

  List<dynamic> _clientes = [];
  List<Ejercicio> _ejercicios = [];

  int? _idClienteSeleccionado;

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

  final List<List<_EjercicioConfigurado>>
      _ejerciciosPorDia =
      List.generate(
    7,
    (_) => <_EjercicioConfigurado>[],
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

    for (final dias
        in _ejerciciosPorDia) {
      for (final ejercicio in dias) {
        ejercicio.seriesController.dispose();
        ejercicio.repeticionesController
            .dispose();
      }
    }

    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarClientes(),
      _cargarEjercicios(),
    ]);
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes =
          await _clienteService
              .obtenerMisClientes();

      if (!mounted) {
        return;
      }

      setState(() {
        _clientes = clientes;
        _cargandoClientes = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoClientes = false;

        _errorClientes = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _cargarEjercicios() async {
    try {
      final ejercicios =
          await _ejercicioService
              .obtenerEjercicios();

      if (!mounted) {
        return;
      }

      setState(() {
        _ejercicios = ejercicios
            .where(
              (ejercicio) =>
                  ejercicio.activo,
            )
            .toList();

        _cargandoEjercicios = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoEjercicios = false;

        _errorEjercicios = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
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
          'Nueva Rutina',
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
    if (_cargandoClientes ||
        _cargandoEjercicios) {
      return const Center(
        child: CircularProgressIndicator(
          color: _dorado,
        ),
      );
    }

    if (_errorClientes.isNotEmpty) {
      return _construirError(
        _errorClientes,
        _cargarClientes,
      );
    }

    if (_errorEjercicios.isNotEmpty) {
      return _construirError(
        _errorEjercicios,
        _cargarEjercicios,
      );
    }

    return Form(
      child: ListView(
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
            'Nueva Rutina',
            style: TextStyle(
              color: _texto,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Configura el plan semanal de tu cliente de forma sencilla.',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          _construirInformacionGeneral(),

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
                          : _crearRutina,
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
                          'Crear rutina',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirInformacionGeneral() {
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
                  Icons.person_rounded,
                  color: _doradoOscuro,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información general',
                      style: TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Selecciona el cliente y describe el objetivo de la rutina.',
                      style: TextStyle(
                        color:
                            _textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          const Text(
            'Cliente',
            style: TextStyle(
              color: _texto,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          DropdownButtonFormField<int>(
            initialValue: _idClienteSeleccionado,
            decoration:
                _decoracionCampo(
              'Selecciona un cliente',
            ),
            items: _clientes.map(
              (cliente) {
                final id =
                    int.tryParse(
                      cliente[
                            'idCliente']
                          ?.toString() ??
                          '',
                    ) ??
                    0;

                final nombre =
                    cliente[
                              'nombre']
                          ?.toString() ??
                      'Cliente';

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    nombre,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            onChanged: _guardando
                ? null
                : (value) {
                    setState(() {
                      _idClienteSeleccionado =
                          value;
                    });
                  },
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
              'Ej. Rutina semanal de fuerza',
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
              'Describe brevemente el objetivo de la rutina.',
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Opcional.',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 11,
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
                  Icons.calendar_month_rounded,
                  color: _doradoOscuro,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan semanal',
                      style: TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Selecciona un día para configurar sus ejercicios.',
                      style: TextStyle(
                        color:
                            _textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              _contadorDias(),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          SizedBox(
            height: 78,
            child: ListView.builder(
              scrollDirection:
                  Axis.horizontal,
              itemCount: 7,
              itemBuilder:
                  (context, index) {
                return _construirDiaButton(
                  index,
                );
              },
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Container(
            padding: const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFAF7F0,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              border: Border.all(
                color: const Color(
                  0xFFE8DFD1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'DÍA SELECCIONADO',
                        style: TextStyle(
                          color:
                              _doradoOscuro,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              1.2,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
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

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        ejerciciosDia.isEmpty
                            ? 'Sin ejercicios configurados.'
                            : '${ejerciciosDia.length} ejercicio${ejerciciosDia.length == 1 ? '' : 's'} configurado${ejerciciosDia.length == 1 ? '' : 's'}.',
                        style:
                            const TextStyle(
                          color:
                              _textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
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
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          if (ejerciciosDia.isEmpty)
            _construirDiaDescanso()
          else
            ...ejerciciosDia
                .asMap()
                .entries
                .map(
                  (entry) =>
                      _construirEjercicioConfigurado(
                    entry.key,
                    entry.value,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _contadorDias() {
    final diasConEjercicios =
        _ejerciciosPorDia
            .where(
              (dia) =>
                  dia.isNotEmpty,
            )
            .length;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF3EAD8,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        '$diasConEjercicios días de entrenamiento',
        style: const TextStyle(
          color: _doradoOscuro,
          fontSize: 10,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  Widget _construirDiaButton(
    int index,
  ) {
    final seleccionado =
        _diaSeleccionado == index;

    final cantidad =
        _ejerciciosPorDia[index]
            .length;

    final abreviatura = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ][index];

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
        width: 86,
        margin:
            const EdgeInsets.only(
          right: 8,
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 9,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(
                  0xFFF5EBD7,
                )
              : const Color(
                  0xFFFCFAF5,
                ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: seleccionado
                ? _dorado
                : const Color(
                    0xFFE6DED0,
                  ),
            width:
                seleccionado ? 1.2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              abreviatura,
              style: TextStyle(
                color: _texto,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: cantidad > 0
                    ? _dorado
                    : const Color(
                        0xFFD5D0C7,
                      ),
                shape:
                    BoxShape.circle,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              cantidad == 0
                  ? 'Descanso'
                  : '$cantidad ejercicio${cantidad == 1 ? '' : 's'}',
              style: const TextStyle(
                color:
                    _textoSecundario,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirDiaDescanso() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFAF7F0,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: const Color(
            0xFFE5D8C3,
          ),
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '🌿',
            style: TextStyle(
              fontSize: 30,
            ),
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Día de descanso',
            style: TextStyle(
              color: _texto,
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'Si quieres programar entrenamiento para este día, agrega un ejercicio.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEjercicioConfigurado(
    int indice,
    _EjercicioConfigurado
        configurado,
  ) {
    final ejercicio =
        configurado.ejercicio;

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
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                width: 9,
              ),

              const Text(
                'Orden',
                style: TextStyle(
                  color:
                      _textoSecundario,
                  fontSize: 11,
                ),
              ),

              const Spacer(),

              IconButton(
                onPressed:
                    indice == 0
                        ? null
                        : () {
                            _moverEjercicio(
                              indice,
                              -1,
                            );
                          },
                tooltip:
                    'Subir',
                icon: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                ),
              ),

              IconButton(
                onPressed:
                    indice ==
                            _ejerciciosPorDia[
                                        _diaSeleccionado]
                                    .length -
                                1
                        ? null
                        : () {
                            _moverEjercicio(
                              indice,
                              1,
                            );
                          },
                tooltip:
                    'Bajar',
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
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
                tooltip:
                    'Eliminar',
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
            height: 8,
          ),

          const Text(
            'Ejercicio',
            style: TextStyle(
              color: _texto,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF8F4EC,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
              border: Border.all(
                color: const Color(
                  0xFFE4DBCD,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ejercicio.nombre,
                    style:
                        const TextStyle(
                      color: _texto,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                      _textoSecundario,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 13,
          ),

          Row(
            children: [
              Expanded(
                child: _campoNumero(
                  titulo: 'Series',
                  controller:
                      configurado
                          .seriesController,
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
                      configurado
                          .repeticionesController,
                ),
              ),
            ],
          ),

          if (ejercicio.imagenUrl !=
                  null &&
              ejercicio.imagenUrl!
                  .trim()
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 13,
              ),
              child:
                  _construirImagenEjercicio(
                ejercicio,
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
              _decoracionCampo(
            '',
          ),
        ),
      ],
    );
  }

  Widget _construirImagenEjercicio(
    Ejercicio ejercicio,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFAF7F0,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: const Color(
            0xFFE6DED0,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              8,
            ),
            child: Image.network(
              ejercicio.imagenUrl!,
              width: 65,
              height: 65,
              fit: BoxFit.cover,
              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  width: 65,
                  height: 65,
                  color: const Color(
                    0xFFF0E8DA,
                  ),
                  child: const Icon(
                    Icons
                        .image_not_supported_outlined,
                    color:
                        _textoSecundario,
                  ),
                );
              },
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vista previa',
                  style: TextStyle(
                    color:
                        _textoSecundario,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  ejercicio.nombre,
                  style:
                      const TextStyle(
                    color: _texto,
                    fontSize: 12,
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

  Future<void> _agregarEjercicio() async {
    if (_ejercicios.isEmpty) {
      _mostrarMensaje(
        'No hay ejercicios disponibles. Crea primero un ejercicio.',
      );

      return;
    }

    final ejercicio =
        await _seleccionarEjercicio();

    if (ejercicio == null ||
        !mounted) {
      return;
    }

    final yaExiste =
        _ejerciciosPorDia[
                _diaSeleccionado]
            .any(
      (item) =>
          item.ejercicio.idEjercicio ==
          ejercicio.idEjercicio,
    );

    if (yaExiste) {
      _mostrarMensaje(
        'Este ejercicio ya está agregado a este día.',
      );

      return;
    }

    setState(() {
      _ejerciciosPorDia[
              _diaSeleccionado]
          .add(
        _EjercicioConfigurado(
          ejercicio: ejercicio,
        ),
      );
    });
  }

  Future<Ejercicio?>
      _seleccionarEjercicio() async {
    String busqueda = '';

    List<Ejercicio> filtrados =
        List.from(_ejercicios);

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
            void filtrar(
              String texto,
            ) {
              busqueda =
                  texto.trim();

              setModalState(() {
                if (busqueda.isEmpty) {
                  filtrados =
                      List.from(
                    _ejercicios,
                  );
                } else {
                  filtrados =
                      _ejercicios
                          .where(
                    (ejercicio) =>
                        ejercicio
                            .nombre
                            .toLowerCase()
                            .contains(
                              busqueda
                                  .toLowerCase(),
                            ),
                  ).toList();
                }
              });
            }

            return Container(
              height:
                  MediaQuery.of(
                            context,
                          )
                          .size
                          .height *
                      0.82,
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
                              'Seleccionar ejercicio',
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
                            filtrar,
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
                          filtrados.isEmpty
                              ? const Center(
                                  child:
                                      Text(
                                    'No se encontraron ejercicios.',
                                    style:
                                        TextStyle(
                                      color:
                                          _textoSecundario,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets
                                          .fromLTRB(
                                    20,
                                    8,
                                    20,
                                    25,
                                  ),
                                  itemCount:
                                      filtrados
                                          .length,
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final ejercicio =
                                        filtrados[
                                            index];

                                    return _construirOpcionEjercicio(
                                      ejercicio,
                                      () {
                                        Navigator.pop(
                                          context,
                                          ejercicio,
                                        );
                                      },
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

  Widget _construirOpcionEjercicio(
    Ejercicio ejercicio,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(
            0xFFFFFEFB,
          ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: const Color(
              0xFFE6DED0,
            ),
          ),
        ),
        child: Row(
          children: [
            if (ejercicio.imagenUrl !=
                    null &&
                ejercicio.imagenUrl!
                    .trim()
                    .isNotEmpty)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
                child: Image.network(
                  ejercicio.imagenUrl!,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return _iconoEjercicio();
                  },
                ),
              )
            else
              _iconoEjercicio(),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    ejercicio.nombre,
                    style:
                        const TextStyle(
                      color: _texto,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  if (ejercicio
                              .descripcion !=
                          null &&
                      ejercicio
                          .descripcion!
                          .trim()
                          .isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 3,
                      ),
                      child: Text(
                        ejercicio
                            .descripcion!,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              _textoSecundario,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  _doradoOscuro,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconoEjercicio() {
    return Container(
      width: 55,
      height: 55,
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
    final ejercicios =
        _ejerciciosPorDia[
            _diaSeleccionado];

    final ejercicio =
        ejercicios[indice];

    ejercicio.seriesController
        .dispose();

    ejercicio.repeticionesController
        .dispose();

    setState(() {
      ejercicios.removeAt(
        indice,
      );
    });
  }

  void _moverEjercicio(
    int indice,
    int direccion,
  ) {
    final ejercicios =
        _ejerciciosPorDia[
            _diaSeleccionado];

    final nuevoIndice =
        indice + direccion;

    if (nuevoIndice < 0 ||
        nuevoIndice >=
            ejercicios.length) {
      return;
    }

    setState(() {
      final temporal =
          ejercicios[indice];

      ejercicios[indice] =
          ejercicios[nuevoIndice];

      ejercicios[nuevoIndice] =
          temporal;
    });
  }

  Future<void> _crearRutina() async {
    FocusScope.of(context).unfocus();

    final nombre =
        _nombreController.text
            .trim();

    if (_idClienteSeleccionado ==
        null) {
      _mostrarMensaje(
        'Selecciona un cliente.',
      );

      return;
    }

    if (nombre.isEmpty) {
      _mostrarMensaje(
        'Escribe el nombre de la rutina.',
      );

      return;
    }

    final diasConfigurados =
        <DiaRutina>[];

    for (int i = 0; i < 7; i++) {
      final ejercicios =
          _ejerciciosPorDia[i];

      if (ejercicios.isEmpty) {
        continue;
      }

      final ejerciciosRutina =
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

        ejerciciosRutina.add(
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

      diasConfigurados.add(
        DiaRutina(
          dia: _dias[i],
          ejercicios:
              ejerciciosRutina,
        ),
      );
    }

    if (diasConfigurados.isEmpty) {
      _mostrarMensaje(
        'Agrega al menos un día de entrenamiento con un ejercicio.',
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _rutinaService.crearRutina(
        idCliente:
            _idClienteSeleccionado!,
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
        dias:
            diasConfigurados,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Rutina creada correctamente.',
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

  Widget _construirError(
    String mensaje,
    VoidCallback reintentar,
  ) {
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
              mensaje,
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
              onPressed: reintentar,
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


class _EjercicioConfigurado {
  final Ejercicio ejercicio;

  final TextEditingController
      seriesController;

  final TextEditingController
      repeticionesController;

  _EjercicioConfigurado({
    required this.ejercicio,
  })  : seriesController =
            TextEditingController(
          text: '3',
        ),
        repeticionesController =
            TextEditingController(
          text: '10',
        );
}