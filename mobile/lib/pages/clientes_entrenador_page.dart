import 'package:flutter/material.dart';

import '../services/cliente_entrenador_service.dart';

class ClientesEntrenadorPage extends StatefulWidget {
  const ClientesEntrenadorPage({
    super.key,
  });

  @override
  State<ClientesEntrenadorPage> createState() =>
      _ClientesEntrenadorPageState();
}

class _ClientesEntrenadorPageState
    extends State<ClientesEntrenadorPage> {
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

  final ClienteEntrenadorService _service =
      ClienteEntrenadorService();

  bool _cargando = true;

  String _error = '';

  List<dynamic> _clientes = [];

  @override
  void initState() {
    super.initState();

    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final clientes =
          await _service.obtenerMisClientes();

      if (!mounted) {
        return;
      }

      setState(() {
        _clientes = clientes;
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
          'Mis Clientes',
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
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: _dorado,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 45,
                color: Colors.red,
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _texto,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              FilledButton(
                onPressed: _cargarClientes,
                style: FilledButton.styleFrom(
                  backgroundColor: _dorado,
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

    return RefreshIndicator(
      color: _dorado,
      onRefresh: _cargarClientes,
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
            'Mis Clientes',
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
            'Consulta los clientes que tienes asignados.',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 14,
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
                        Icons.groups_rounded,
                        color: _doradoOscuro,
                        size: 27,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clientes asignados',
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
                            'Aquí puedes consultar únicamente los clientes asignados a tu cuenta de entrenador.',
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
                  'Clientes asignados: ${_clientes.length}',
                  style: const TextStyle(
                    color: _textoSecundario,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (_clientes.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                    child: Center(
                      child: Text(
                        'No tienes clientes asignados.',
                        style: TextStyle(
                          color:
                              _textoSecundario,
                        ),
                      ),
                    ),
                  ),

                ..._clientes.map(
                  (cliente) =>
                      _construirClienteCard(
                    cliente,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirClienteCard(
    dynamic cliente,
  ) {
    final nombre =
        cliente['nombre']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? cliente['nombre'].toString()
        : 'Cliente';

    final correo =
        cliente['correo']
                ?.toString() ??
            '';

    final telefono =
        cliente['telefono']
                ?.toString() ??
            '';

    final idCliente =
        cliente['idCliente']
                ?.toString() ??
            '';

    final estatus =
        cliente['estatus'] == true;

    final iniciales =
        _obtenerIniciales(
      nombre,
    );

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
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF3EAD8,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      color: _doradoOscuro,
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style:
                          const TextStyle(
                        color: _texto,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: estatus
                            ? const Color(
                                0xFFEAF7EE,
                              )
                            : const Color(
                                0xFFF7EAEA,
                              ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        estatus
                            ? 'ACTIVO'
                            : 'INACTIVO',
                        style: TextStyle(
                          color: estatus
                              ? const Color(
                                  0xFF39804B,
                                )
                              : const Color(
                                  0xFFB34A4A,
                                ),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          const Divider(
            color: Color(
              0xFFE9E1D5,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _datoCliente(
            titulo: 'Correo',
            valor: correo,
          ),

          _datoCliente(
            titulo: 'Teléfono',
            valor: telefono,
          ),

          _datoCliente(
            titulo: 'ID Cliente',
            valor: idCliente,
            ultimo: true,
          ),
        ],
      ),
    );
  }

  Widget _datoCliente({
    required String titulo,
    required String valor,
    bool ultimo = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: ultimo ? 0 : 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              valor.isEmpty
                  ? 'No disponible'
                  : valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _texto,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerIniciales(
    String nombre,
  ) {
    final partes = nombre
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (parte) => parte.isNotEmpty,
        )
        .toList();

    if (partes.isEmpty) {
      return 'CL';
    }

    if (partes.length == 1) {
      return partes.first
          .substring(
            0,
            partes.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return (
      partes.first[0] +
      partes.last[0]
    ).toUpperCase();
  }
}