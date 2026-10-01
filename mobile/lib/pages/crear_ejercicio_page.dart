import 'package:flutter/material.dart';

import '../models/ejercicio_request.dart';
import '../services/ejercicio_service.dart';

class CrearEjercicioPage extends StatefulWidget {
  const CrearEjercicioPage({
    super.key,
  });

  @override
  State<CrearEjercicioPage> createState() =>
      _CrearEjercicioPageState();
}

class _CrearEjercicioPageState
    extends State<CrearEjercicioPage> {
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

  final TextEditingController
      _nombreController =
      TextEditingController();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  final TextEditingController
      _imagenUrlController =
      TextEditingController();

  final EjercicioService _ejercicioService =
      EjercicioService();

  bool _guardando = false;
  String _error = '';

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _imagenUrlController.dispose();

    super.dispose();
  }

  Future<void> _guardarEjercicio() async {
    FocusScope.of(context).unfocus();

    final formularioValido =
        _formKey.currentState?.validate() ??
            false;

    if (!formularioValido ||
        _guardando) {
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
          _imagenUrlController.text,
    );

    try {
      await _ejercicioService
          .crearEjercicio(
        request,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ejercicio creado correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop(
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _error = _limpiarError(
          error,
        );
      });
    }
  }

  String? _validarNombre(
    String? valor,
  ) {
    final nombre =
        valor?.trim() ?? '';

    if (nombre.isEmpty) {
      return 'Ingresa el nombre del ejercicio.';
    }

    if (nombre.length < 2) {
      return 'El nombre es demasiado corto.';
    }

    return null;
  }

  String? _validarImagenUrl(
    String? valor,
  ) {
    final texto =
        valor?.trim() ?? '';

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
      return 'Ingresa una URL válida.';
    }

    return null;
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
        title: const Text(
          'Nuevo ejercicio',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(
              20,
            ),
            children: [
              _construirEncabezado(),
              const SizedBox(
                height: 20,
              ),
              _construirFormulario(),
              if (_error.isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),
                _construirError(),
              ],
              const SizedBox(
                height: 24,
              ),
              _construirBotonGuardar(),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirEncabezado() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _dorado.withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          alignment:
              Alignment.center,
          child: const Icon(
            Icons
                .fitness_center_rounded,
            color: _doradoOscuro,
            size: 27,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        const Text(
          'Crear ejercicio',
          style: TextStyle(
            color: _texto,
            fontSize: 24,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          'Agrega la información que utilizará el entrenador al crear las rutinas.',
          style: TextStyle(
            color: _texto.withValues(
              alpha: 0.62,
            ),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _construirFormulario() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _dorado.withValues(
            alpha: 0.15,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _texto.withValues(
              alpha: 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del ejercicio',
            style: TextStyle(
              color: _texto,
              fontSize: 17,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          TextFormField(
            controller:
                _nombreController,
            enabled: !_guardando,
            textCapitalization:
                TextCapitalization
                    .sentences,
            textInputAction:
                TextInputAction.next,
            validator:
                _validarNombre,
            decoration:
                _decoracionCampo(
              etiqueta: 'Nombre',
              pista:
                  'Ej. Press de banca',
              icono: Icons
                  .fitness_center_rounded,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          TextFormField(
            controller:
                _descripcionController,
            enabled: !_guardando,
            textCapitalization:
                TextCapitalization
                    .sentences,
            minLines: 3,
            maxLines: 5,
            decoration:
                _decoracionCampo(
              etiqueta:
                  'Descripción',
              pista:
                  'Describe brevemente cómo realizar el ejercicio',
              icono: Icons
                  .description_outlined,
              opcional: true,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          TextFormField(
            controller:
                _imagenUrlController,
            enabled: !_guardando,
            keyboardType:
                TextInputType.url,
            textInputAction:
                TextInputAction.done,
            validator:
                _validarImagenUrl,
            onFieldSubmitted: (_) {
              _guardarEjercicio();
            },
            decoration:
                _decoracionCampo(
              etiqueta:
                  'URL de imagen',
              pista:
                  'https://ejemplo.com/ejercicio.jpg',
              icono: Icons
                  .image_outlined,
              opcional: true,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons
                    .info_outline_rounded,
                size: 17,
                color: _doradoOscuro
                    .withValues(
                  alpha: 0.85,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: Text(
                  'La imagen es opcional. Si no agregas una URL, se mostrará la imagen predeterminada de GymFlow.',
                  style: TextStyle(
                    color: _texto
                        .withValues(
                      alpha: 0.58,
                    ),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracionCampo({
    required String etiqueta,
    required String pista,
    required IconData icono,
    bool opcional = false,
  }) {
    return InputDecoration(
      labelText: opcional
          ? '$etiqueta (opcional)'
          : etiqueta,
      hintText: pista,
      prefixIcon: Icon(
        icono,
        color: _doradoOscuro,
      ),
      filled: true,
      fillColor: _fondo,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
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
        borderSide: BorderSide(
          color: _dorado.withValues(
            alpha: 0.18,
          ),
        ),
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
          width: 1.4,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide: BorderSide(
          color:
              Colors.red.shade700,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide: BorderSide(
          color:
              Colors.red.shade700,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _construirError() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.red
            .withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.red
              .withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons
                .error_outline_rounded,
            color:
                Colors.red.shade700,
            size: 21,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              _error,
              style: TextStyle(
                color: Colors
                    .red.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed:
            _guardando
                ? null
                : _guardarEjercicio,
        style:
            FilledButton.styleFrom(
          backgroundColor:
              _dorado,
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              _dorado.withValues(
            alpha: 0.45,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
        icon: _guardando
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
            : const Icon(
                Icons.add_rounded,
              ),
        label: Text(
          _guardando
              ? 'Guardando...'
              : 'Guardar ejercicio',
          style: const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }
}