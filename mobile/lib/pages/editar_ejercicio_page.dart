import 'package:flutter/material.dart';

import '../models/ejercicio.dart';
import '../models/ejercicio_request.dart';
import '../services/ejercicio_service.dart';

class EditarEjercicioPage extends StatefulWidget {
  final Ejercicio ejercicio;

  const EditarEjercicioPage({
    super.key,
    required this.ejercicio,
  });

  @override
  State<EditarEjercicioPage> createState() =>
      _EditarEjercicioPageState();
}

class _EditarEjercicioPageState
    extends State<EditarEjercicioPage> {
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

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nombreController =
      TextEditingController();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  final TextEditingController _imagenController =
      TextEditingController();

  final EjercicioService _service =
      EjercicioService();

  bool _guardando = false;
  String _error = '';

  late bool _estado;

  @override
  void initState() {
    super.initState();

    _nombreController.text =
        widget.ejercicio.nombre;

    _descripcionController.text =
        widget.ejercicio.descripcion ?? '';

    _imagenController.text =
        widget.ejercicio.imagenUrl ?? '';

    _estado =
        widget.ejercicio.activo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _imagenController.dispose();

    super.dispose();
  }

  Future<void> _actualizarEjercicio() async {
    FocusScope.of(context).unfocus();

    final valido =
        _formKey.currentState?.validate() ??
            false;

    if (!valido || _guardando) {
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    final request =
        EjercicioRequest(
      nombre:
          _nombreController.text,
      descripcion:
          _descripcionController.text,
      imagenUrl:
          _imagenController.text,
      estado:
          _estado,
    );

    try {
      await _service.actualizarEjercicio(
        widget.ejercicio.idEjercicio,
        request,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ejercicio actualizado correctamente.',
          ),
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
        _error = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  String? _validarNombre(
    String? value,
  ) {
    final texto =
        value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El nombre es obligatorio.';
    }

    return null;
  }

  String? _validarImagen(
    String? value,
  ) {
    final texto =
        value?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final uri =
        Uri.tryParse(texto);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      return 'La URL no es válida.';
    }

    return null;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          _fondo,
      appBar: AppBar(
        backgroundColor:
            _tarjeta,
        foregroundColor:
            _texto,
        elevation: 0,
        title: const Text(
          'Editar ejercicio',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(
            20,
          ),
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              decoration:
                  BoxDecoration(
                color: _tarjeta,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller:
                        _nombreController,
                    validator:
                        _validarNombre,
                    enabled:
                        !_guardando,
                    decoration:
                        _campo(
                      'Nombre',
                      Icons.fitness_center,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextFormField(
                    controller:
                        _descripcionController,
                    enabled:
                        !_guardando,
                    maxLines:
                        4,
                    decoration:
                        _campo(
                      'Descripción',
                      Icons.description,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  DropdownButtonFormField<bool>(
                    initialValue:
                        _estado,
                    decoration:
                        _campo(
                      'Estado del ejercicio',
                      Icons.toggle_on_outlined,
                    ),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text(
                          'Activo',
                        ),
                      ),
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text(
                          'Inactivo',
                        ),
                      ),
                    ],
                    onChanged:
                        _guardando
                            ? null
                            : (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setState(() {
                                  _estado =
                                      value;
                                });
                              },
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          _estado
                              ? const Color(
                                  0xFFF0F8F0,
                                )
                              : const Color(
                                  0xFFFFF1F1,
                                ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border:
                          Border.all(
                        color:
                            _estado
                                ? const Color(
                                    0xFFC8E6C9,
                                  )
                                : const Color(
                                    0xFFF0CACA,
                                  ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _estado
                              ? Icons.check_circle_outline
                              : Icons
                                  .pause_circle_outline,
                          color:
                              _estado
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _estado
                                    ? 'Ejercicio activo'
                                    : 'Ejercicio inactivo',
                                style:
                                    TextStyle(
                                  color:
                                      _estado
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                _estado
                                    ? 'Puede utilizarse en nuevas rutinas.'
                                    : 'No debe utilizarse en nuevas rutinas.',
                                style:
                                    TextStyle(
                                  color:
                                      _estado
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextFormField(
                    controller:
                        _imagenController,
                    validator:
                        _validarImagen,
                    enabled:
                        !_guardando,
                    keyboardType:
                        TextInputType.url,
                    decoration:
                        _campo(
                      'URL imagen',
                      Icons.image,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            if (_error.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFEEEE,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  _error,
                  style:
                      TextStyle(
                    color:
                        Colors.red.shade700,
                  ),
                ),
              ),

            if (_error.isNotEmpty)
              const SizedBox(
                height: 20,
              ),

            SizedBox(
              height: 52,
              child:
                  FilledButton(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      _dorado,
                ),
                onPressed:
                    _guardando
                        ? null
                        : _actualizarEjercicio,
                child:
                    _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2.5,
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
      ),
    );
  }

  InputDecoration _campo(
    String texto,
    IconData icono,
  ) {
    return InputDecoration(
      labelText:
          texto,
      prefixIcon:
          Icon(
        icono,
        color:
            _doradoOscuro,
      ),
      filled:
          true,
      fillColor:
          _fondo,
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            const BorderSide(
          color: _dorado,
        ),
      ),
    );
  }
}