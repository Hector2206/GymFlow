import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/cliente_service.dart';

class RegistrarClientePage extends StatefulWidget {
  const RegistrarClientePage({
    super.key,
  });

  @override
  State<RegistrarClientePage> createState() =>
      _RegistrarClientePageState();
}

class _RegistrarClientePageState
    extends State<RegistrarClientePage> {
  final _formKey = GlobalKey<FormState>();

  final ClienteService clienteService =
      ClienteService();

  final nombreController =
      TextEditingController();

  final correoController =
      TextEditingController();

  final telefonoController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final costoMensualController =
      TextEditingController();

  final costoAnualController =
      TextEditingController();

  int? idMembresia;

  bool cargando = false;
  bool ocultarPassword = true;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    passwordController.dispose();
    costoMensualController.dispose();
    costoAnualController.dispose();

    super.dispose();
  }

  String? validarNombre(
    String? value,
  ) {
    final nombre =
        value?.trim() ?? '';

    if (nombre.isEmpty) {
      return 'El nombre completo es obligatorio.';
    }

    if (RegExp(r'\d').hasMatch(nombre)) {
      return 'El nombre no puede contener números.';
    }

    if (!RegExp(
      r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]',
    ).hasMatch(nombre)) {
      return 'Ingresa un nombre válido.';
    }

    if (nombre.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }

    if (nombre.length > 100) {
      return 'El nombre es demasiado largo.';
    }

    return null;
  }

  String? validarCorreo(
    String? value,
  ) {
    final correo =
        value?.trim() ?? '';

    if (correo.isEmpty) {
      return 'El correo es obligatorio.';
    }

    if (correo.length > 150) {
      return 'El correo es demasiado largo.';
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(correo)) {
      return 'Ingresa un correo electrónico válido.';
    }

    return null;
  }

  String? validarTelefono(
    String? value,
  ) {
    final telefono =
        value?.trim() ?? '';

    if (telefono.isEmpty) {
      return null;
    }

    if (!RegExp(
      r'^\d+$',
    ).hasMatch(telefono)) {
      return 'El teléfono solo puede contener números.';
    }

    if (telefono.length != 10) {
      return 'El teléfono debe contener 10 dígitos.';
    }

    return null;
  }

  String? validarPassword(
    String? value,
  ) {
    final password =
        value ?? '';

    if (password.trim().isEmpty) {
      return 'La contraseña es obligatoria.';
    }

    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    if (password.length > 72) {
      return 'La contraseña es demasiado larga.';
    }

    return null;
  }

  String? validarCosto(
    String? value,
  ) {
    final texto =
        value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el costo.';
    }

    final numero =
        double.tryParse(texto);

    if (numero == null ||
        !numero.isFinite) {
      return 'Ingresa un número válido.';
    }

    if (numero <= 0) {
      return 'El costo debe ser mayor a \$0.';
    }

    if (numero > 1000000) {
      return 'Verifica el costo ingresado.';
    }

    return null;
  }

  Future<void> registrarCliente() async {
    FocusScope.of(context).unfocus();

    if (cargando) {
      return;
    }

    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    if (idMembresia == null ||
        idMembresia! <= 0) {
      mostrarMensaje(
        'Selecciona una membresía válida.',
        false,
      );

      return;
    }

    final costoMensual =
        double.tryParse(
      costoMensualController.text.trim(),
    );

    final costoAnual =
        double.tryParse(
      costoAnualController.text.trim(),
    );

    if (costoMensual == null ||
        costoAnual == null) {
      mostrarMensaje(
        'Los costos no son válidos.',
        false,
      );

      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final resultado =
          await clienteService.registrarCliente(
        correo:
            correoController.text.trim(),
        password:
            passwordController.text,
        nombreCompleto:
            nombreController.text.trim(),
        telefono:
            telefonoController.text.trim(),
        idMembresia:
            idMembresia!,
        costoMensual:
            costoMensual,
        costoAnual:
            costoAnual,
      );

      if (!mounted) {
        return;
      }

      final ok =
          resultado['ok'] == true;

      mostrarMensaje(
        resultado['mensaje']?.toString() ??
            'Ocurrió un problema.',
        ok,
      );

      if (ok) {
        limpiarFormulario();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      mostrarMensaje(
        'No fue posible completar el registro.',
        false,
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void mostrarMensaje(
    String mensaje,
    bool exito,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito
            ? const Color(0xFF2E7D32)
            : const Color(0xFF990000),
      ),
    );
  }

  void limpiarFormulario() {
    nombreController.clear();
    correoController.clear();
    telefonoController.clear();
    passwordController.clear();
    costoMensualController.clear();
    costoAnualController.clear();

    setState(() {
      idMembresia = null;
    });

    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const dark = Color(0xFF101012);
    const coal = Color(0xFF1A1A1D);
    const silver = Color(0xFFA9A9A9);

    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF29292E),
              coal,
              Color(0xFF0D0D0F),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 650,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode:
                    AutovalidateMode
                        .onUserInteraction,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECEPCIÓN',
                      style: TextStyle(
                        color: gold,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registrar Cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _section(
                      'Datos personales',
                      [
                        _campo(
                          controller:
                              nombreController,
                          label:
                              'Nombre completo *',
                          hint:
                              'Nombre completo',
                          validator:
                              validarNombre,
                          keyboardType:
                              TextInputType.name,
                          maxLength: 100,
                        ),
                        _campo(
                          controller:
                              correoController,
                          label:
                              'Correo electrónico *',
                          hint:
                              'cliente@gymflow.com',
                          validator:
                              validarCorreo,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          maxLength: 150,
                        ),
                        _campo(
                          controller:
                              telefonoController,
                          label: 'Teléfono',
                          hint: '4421234567',
                          validator:
                              validarTelefono,
                          keyboardType:
                              TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _section(
                      'Acceso',
                      [
                        TextFormField(
                          controller:
                              passwordController,
                          enabled: !cargando,
                          obscureText:
                              ocultarPassword,
                          validator:
                              validarPassword,
                          maxLength: 72,
                          style:
                              const TextStyle(
                            color: Colors.white,
                          ),
                          decoration:
                              _decoracion(
                            'Contraseña *',
                            'Mínimo 6 caracteres',
                          ).copyWith(
                            counterText: '',
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  ocultarPassword =
                                      !ocultarPassword;
                                });
                              },
                              icon: Icon(
                                ocultarPassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                                color: silver,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _section(
                      'Membresía y asistencia',
                      [
                        DropdownButtonFormField<int>(
                          initialValue:
                              idMembresia,
                          dropdownColor: coal,
                          style:
                              const TextStyle(
                            color: Colors.white,
                          ),
                          decoration:
                              _decoracion(
                            'Membresía *',
                            'Selecciona una opción',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                'BasicFlow',
                              ),
                            ),
                          ],
                          validator: (value) {
                            if (value == null ||
                                value <= 0) {
                              return 'Selecciona una membresía válida.';
                            }

                            return null;
                          },
                          onChanged: cargando
                              ? null
                              : (value) {
                                  setState(() {
                                    idMembresia =
                                        value;
                                  });
                                },
                        ),
                        _campo(
                          controller:
                              costoMensualController,
                          label:
                              'Costo mensual *',
                          hint: '500.00',
                          validator:
                              validarCosto,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters:
                              _formatoDecimal(),
                        ),
                        _campo(
                          controller:
                              costoAnualController,
                          label:
                              'Costo anual *',
                          hint: '5000.00',
                          validator:
                              validarCosto,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters:
                              _formatoDecimal(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child:
                          FilledButton.icon(
                        onPressed: cargando
                            ? null
                            : registrarCliente,
                        icon: cargando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.person_add,
                              ),
                        label: Text(
                          cargando
                              ? 'Registrando...'
                              : 'Registrar cliente',
                        ),
                        style:
                            FilledButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor:
                              Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TextInputFormatter>
      _formatoDecimal() {
    return [
      TextInputFormatter.withFunction(
        (oldValue, newValue) {
          if (RegExp(
            r'^\d{0,7}(\.\d{0,2})?$',
          ).hasMatch(newValue.text)) {
            return newValue;
          }

          return oldValue;
        },
      ),
    ];
  }

  Widget _section(
    String titulo,
    List<Widget> children,
  ) {
    const gold = Color(0xFFD4AF37);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF171719),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              gold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: gold,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0;
              i < children.length;
              i++) ...[
            children[i],
            if (i < children.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?)
        validator,
    TextInputType keyboardType =
        TextInputType.text,
    List<TextInputFormatter>?
        inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !cargando,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration:
          _decoracion(label, hint).copyWith(
        counterText: '',
      ),
    );
  }

  InputDecoration _decoracion(
    String label,
    String hint,
  ) {
    const gold = Color(0xFFD4AF37);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor:
          const Color(0xFF101012),
      labelStyle: const TextStyle(
        color: Color(0xFFA9A9A9),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF666666),
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide(
          color:
              gold.withValues(alpha: 0.20),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: gold,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }
}