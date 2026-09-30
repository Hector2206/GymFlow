import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ejercicio.dart';
import '../services/ejercicio_service.dart';
import 'crear_ejercicio_page.dart';
import 'editar_ejercicio_page.dart';


class EjerciciosPage extends StatefulWidget {
  const EjerciciosPage({
    super.key,
  });

  @override
  State<EjerciciosPage> createState() =>
      _EjerciciosPageState();
}

class _EjerciciosPageState
    extends State<EjerciciosPage> {
  static const Color _fondo =
      Color(0xFFF8F5EF);

  static const Color _tarjeta =
      Color(0xFFFFFDF8);

  static const Color _dorado =
      Color(0xFFB58A2A);

  static const Color _doradoOscuro =
      Color(0xFF8A6814);

  static const Color _texto =
      Color(0xFF2B2925);

  final EjercicioService _ejercicioService =
      EjercicioService();

  final TextEditingController
      _busquedaController =
      TextEditingController();

  Timer? _temporizadorBusqueda;

  List<Ejercicio> _ejercicios = [];

  bool _cargando = true;

  String _error = '';

  @override
  void initState() {
    super.initState();

    _cargarEjercicios();
  }

  @override
  void dispose() {
    _temporizadorBusqueda?.cancel();
    _busquedaController.dispose();

    super.dispose();
  }

  Future<void> _cargarEjercicios() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final ejercicios =
          await _ejercicioService
              .obtenerEjercicios();

      if (!mounted) {
        return;
      }

      setState(() {
        _ejercicios = ejercicios;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _ejercicios = [];
        _cargando = false;
        _error = _limpiarError(
          error,
        );
      });
    }
  }

  void _alCambiarBusqueda(
    String valor,
  ) {
    _temporizadorBusqueda?.cancel();

    _temporizadorBusqueda = Timer(
      const Duration(
        milliseconds: 450,
      ),
      () {
        _buscarEjercicios(
          valor,
        );
      },
    );
  }

  Future<void> _buscarEjercicios(
    String nombre,
  ) async {
    final texto = nombre.trim();

    if (texto.isEmpty) {
      await _cargarEjercicios();
      return;
    }

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final ejercicios =
          await _ejercicioService
              .buscarEjercicios(
        texto,
      );

      if (!mounted) {
        return;
      }

      if (_busquedaController.text
              .trim() !=
          texto) {
        return;
      }

      setState(() {
        _ejercicios = ejercicios;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (_busquedaController.text
              .trim() !=
          texto) {
        return;
      }

      setState(() {
        _ejercicios = [];
        _cargando = false;
        _error = _limpiarError(
          error,
        );
      });
    }
  }

  Future<void> _actualizar() async {
    final texto =
        _busquedaController.text.trim();

    if (texto.isEmpty) {
      await _cargarEjercicios();
      return;
    }

    await _buscarEjercicios(
      texto,
    );
  }

  void _limpiarBusqueda() {
    _temporizadorBusqueda?.cancel();

    _busquedaController.clear();

    _cargarEjercicios();
  }

  String _limpiarError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
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
        centerTitle: false,
        title: const Text(
          'Ejercicios',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _cargando
                    ? null
                    : _actualizar,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
           body: SafeArea(
        child: Column(
          children: [
            _construirEncabezado(),
            Expanded(
              child:
                  _construirContenido(),
            ),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: _dorado,
        foregroundColor: Colors.white,
        onPressed:
            _abrirCrearEjercicio,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Nuevo ejercicio',
        ),
      ),
    );
  }

  Widget _construirEncabezado() {
    return Container(
      width: double.infinity,
      color: _tarjeta,
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Catálogo de ejercicios',
            style: TextStyle(
              color: _texto,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            'Consulta los ejercicios disponibles para las rutinas.',
            style: TextStyle(
              color: _texto.withValues(
                alpha: 0.65,
              ),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          TextField(
            controller:
                _busquedaController,
            onChanged:
                _alCambiarBusqueda,
            textInputAction:
                TextInputAction.search,
            decoration: InputDecoration(
              hintText:
                  'Buscar ejercicio',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon:
                  _busquedaController
                          .text
                          .isEmpty
                      ? null
                      : IconButton(
                          tooltip:
                              'Limpiar búsqueda',
                          onPressed:
                              _limpiarBusqueda,
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                        ),
              filled: true,
              fillColor: _fondo,
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide.none,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide(
                  color: _dorado
                      .withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    const BorderSide(
                  color: _dorado,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
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

    if (_ejercicios.isEmpty) {
      return _construirVacio();
    }

    return RefreshIndicator(
      color: _dorado,
      onRefresh: _actualizar,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          20,
        ),
        itemCount:
            _ejercicios.length,
        separatorBuilder:
            (
              context,
              index,
            ) =>
                const SizedBox(
          height: 12,
        ),
        itemBuilder:
            (
              context,
              index,
            ) {
          return _construirTarjeta(
            _ejercicios[index],
          );
        },
      ),
    );
  }

  Widget _construirTarjeta(
    Ejercicio ejercicio,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _dorado.withValues(
            alpha: 0.14,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _texto.withValues(
              alpha: 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            _construirImagen(
              ejercicio,
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    ejercicio.nombre,
                    style:
                        const TextStyle(
                      color: _texto,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  if (ejercicio
                          .descripcion !=
                      null) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      ejercicio
                          .descripcion!,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        color: _texto
                            .withValues(
                          alpha: 0.62,
                        ),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 9,
                  ),
                  _construirEstado(
                    ejercicio,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                 Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    tooltip: 'Acciones',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                    ),
                    color: _tarjeta,
                    onSelected: (accion) {
                      switch (accion) {
                        case 'editar':
                          _editarEjercicio(
                            ejercicio,
                          );
                          break;

                        case 'eliminar':
                          _confirmarEliminarEjercicio(
                            ejercicio,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 20,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Editar',
                              ),
                            ],
                          ),
                        ),

                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Desactivar',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirImagen(
    Ejercicio ejercicio,
  ) {
    final imagenUrl =
        ejercicio.imagenUrl?.trim();

    if (imagenUrl == null ||
        imagenUrl.isEmpty) {
      return _imagenFallback();
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: Image.network(
        imagenUrl,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder:
            (
              context,
              error,
              stackTrace,
            ) {
          return _imagenFallback();
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

          return Container(
            width: 76,
            height: 76,
            color: _fondo,
            alignment:
                Alignment.center,
            child:
                const SizedBox(
              width: 22,
              height: 22,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: _dorado,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagenFallback() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: _dorado.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fitness_center_rounded,
        color: _doradoOscuro,
        size: 30,
      ),
    );
  }

  Widget _construirEstado(
    Ejercicio ejercicio,
  ) {
    final activo =
        ejercicio.activo;

    final color =
        activo
            ? _doradoOscuro
            : Colors.red.shade700;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        activo
            ? 'Activo'
            : 'Inactivo',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _construirVacio() {
    final buscando =
        _busquedaController.text
            .trim()
            .isNotEmpty;

    return RefreshIndicator(
      color: _dorado,
      onRefresh: _actualizar,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          32,
        ),
        children: [
          const SizedBox(
            height: 90,
          ),
          Icon(
            buscando
                ? Icons
                    .search_off_rounded
                : Icons
                    .fitness_center_rounded,
            size: 58,
            color: _dorado,
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            buscando
                ? 'No encontramos ejercicios'
                : 'No hay ejercicios disponibles',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: _texto,
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            buscando
                ? 'Prueba con otro nombre o limpia la búsqueda.'
                : 'Los ejercicios aparecerán aquí cuando estén disponibles.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: _texto.withValues(
                alpha: 0.60,
              ),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirError() {
    return RefreshIndicator(
      color: _dorado,
      onRefresh: _actualizar,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          32,
        ),
        children: [
          const SizedBox(
            height: 80,
          ),
          Icon(
            Icons
                .error_outline_rounded,
            size: 58,
            color:
                Colors.red.shade700,
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'No pudimos cargar los ejercicios',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: _texto,
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            _error,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: _texto.withValues(
                alpha: 0.65,
              ),
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 22,
          ),
          Center(
            child:
                FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _dorado,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
              ),
              onPressed:
                  _actualizar,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Intentar de nuevo',
              ),
            ),
          ),
        ],
      ),
    );
  }
    Future<void> _abrirCrearEjercicio() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CrearEjercicioPage(),
      ),
    );

    if (creado == true) {
      await _cargarEjercicios();
    }
  }

  Future<void> _editarEjercicio(
  Ejercicio ejercicio,
) async {
  final actualizado =
      await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          EditarEjercicioPage(
        ejercicio: ejercicio,
      ),
    ),
  );

  if (actualizado == true) {
    await _cargarEjercicios();
  }
}
Future<void> _confirmarEliminarEjercicio(
  Ejercicio ejercicio,
) async {
  final confirmar =
      await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Desactivar ejercicio',
        ),
        content: Text(
          '¿Deseas desactivar "${ejercicio.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text(
              'Cancelar',
            ),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text(
              'Desactivar',
            ),
          ),
        ],
      );
    },
  );

  if (confirmar != true) {
    return;
  }

  try {
    await _ejercicioService
        .eliminarEjercicio(
      ejercicio.idEjercicio,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Ejercicio desactivado correctamente.',
        ),
      ),
    );

    await _cargarEjercicios();
  } catch (error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          error
              .toString()
              .replaceFirst(
                'Exception: ',
                '',
              ),
        ),
      ),
    );
  }
}

}