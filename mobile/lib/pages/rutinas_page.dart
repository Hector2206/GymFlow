import 'package:flutter/material.dart';

import '../models/rutina.dart';
import '../services/rutina_service.dart';
import 'crear_rutina_page.dart';
import 'editar_rutina_page.dart';

class RutinasPage extends StatefulWidget {
  const RutinasPage({
    super.key,
  });

  @override
  State<RutinasPage> createState() =>
      _RutinasPageState();
}

class _RutinasPageState
    extends State<RutinasPage> {
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

  bool _cargando = true;

  String _error = '';

  List<Rutina> _rutinas = [];

  @override
  void initState() {
    super.initState();

    _cargarRutinas();
  }

  Future<void> _cargarRutinas() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final rutinas =
          await _rutinaService
              .obtenerRutinas();

      if (!mounted) {
        return;
      }

      setState(() {
        _rutinas = rutinas;
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
          'Administrar Rutinas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargarRutinas,
            tooltip: 'Actualizar',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _construirContenido(),
      ),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: _dorado,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return _construirError();
    }

    return RefreshIndicator(
      color: _dorado,
      onRefresh: _cargarRutinas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          24,
          18,
          30,
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
            'Administrar Rutinas',
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
            'Consulta y administra las rutinas de entrenamiento de tus clientes.',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final creada = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrearRutinaPage(),
                  ),
                );

                if (creada == true) {
                  _cargarRutinas();
                }
              },
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Nueva Rutina',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dorado,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Container(
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
                      width: 50,
                      height: 50,
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
                        Icons.fitness_center_rounded,
                        color:
                            _doradoOscuro,
                        size: 26,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Rutinas de entrenamiento',
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
                            'Edita la información de una rutina o administra las rutinas de tus clientes.',
                            style: TextStyle(
                              color:
                                  _textoSecundario,
                              fontSize: 12,
                              height: 1.4,
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

                Text(
                  'Rutinas registradas: ${_rutinas.length}',
                  style: const TextStyle(
                    color: _textoSecundario,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                if (_rutinas.isEmpty)
                  _construirSinRutinas(),

                ..._rutinas.asMap().entries.map(
                  (entry) {
                    final indice =
                        entry.key;

                    final rutina =
                        entry.value;

                    return _construirRutinaCard(
                      rutina,
                      indice + 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRutinaCard(
    Rutina rutina,
    int numero,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFFEFB,
        ),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(
            0xFFE7DED0,
          ),
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
                width: 50,
                height: 50,
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
                  Icons.fitness_center_rounded,
                  color:
                      _doradoOscuro,
                  size: 24,
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
                    Text(
                      'Rutina #$numero',
                      style:
                          const TextStyle(
                        color:
                            _doradoOscuro,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      rutina.nombre.isEmpty
                          ? 'Rutina sin nombre'
                          : rutina.nombre,
                      style:
                          const TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          const Divider(
            color: Color(
              0xFFE9E1D5,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          if (rutina.descripcion !=
                  null &&
              rutina.descripcion!
                  .trim()
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 15,
              ),
              child: Text(
                rutina.descripcion!,
                style: const TextStyle(
                  color:
                      _textoSecundario,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Cliente',
                style: TextStyle(
                  color:
                      _textoSecundario,
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  rutina.nombreCliente
                          .trim()
                          .isEmpty
                      ? 'Sin cliente'
                      : rutina.nombreCliente,
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    color: _texto,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final actualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditarRutinaPage(
                      idRutina: rutina.idRutina,
                    ),
                  ),
                );

                if (actualizado == true) {
                  _cargarRutinas();
                }
              },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    _doradoOscuro,
                side: const BorderSide(
                  color: _dorado,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: const Text(
                'Editar rutina',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSinRutinas() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFFEFB,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(
            0xFFE7DED0,
          ),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 42,
            color: _dorado,
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'No hay rutinas registradas',
            style: TextStyle(
              color: _texto,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Crea una rutina para comenzar a organizar el entrenamiento de tus clientes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              style: const TextStyle(
                color: _texto,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton(
              onPressed:
                  _cargarRutinas,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _dorado,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}