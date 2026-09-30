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

  final TextEditingController _descripcionController =
      TextEditingController();

  final TextEditingController _imagenController =
      TextEditingController();

  final EjercicioService _service =
      EjercicioService();

  bool _guardando = false;
  String _error = '';

  @override
  void initState() {
    super.initState();

    _nombreController.text =
        widget.ejercicio.nombre;

    _descripcionController.text =
        widget.ejercicio.descripcion ?? '';

    _imagenController.text =
        widget.ejercicio.imagenUrl ?? '';
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

    final request = EjercicioRequest(
      nombre: _nombreController.text,
      descripcion:
          _descripcionController.text,
      imagenUrl:
          _imagenController.text,
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
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _tarjeta,
        foregroundColor: _texto,
        elevation: 0,
        title: const Text(
          'Editar ejercicio',
          style: TextStyle(
            fontWeight: FontWeight.w700,
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
                      Icons
                          .fitness_center,
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
                      Icons
                          .description,
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
              Text(
                _error,
                style:
                    TextStyle(
                  color:
                      Colors.red.shade700,
                ),
              ),
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
                        ? const CircularProgressIndicator(
                            color:
                                Colors.white,
                          )
                        : const Text(
                            'Guardar cambios',
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
    );
  }
}