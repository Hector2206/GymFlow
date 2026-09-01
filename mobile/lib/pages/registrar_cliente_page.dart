import 'package:flutter/material.dart';

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

  final TextEditingController nombreController =
      TextEditingController();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController telefonoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController idAsistenciaController =
      TextEditingController();

  final TextEditingController costoMensualController =
      TextEditingController();

  final TextEditingController costoAnualController =
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
    idAsistenciaController.dispose();
    costoMensualController.dispose();
    costoAnualController.dispose();

    super.dispose();
  }

  Future<void> registrarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (idMembresia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una membresía.',
          ),
          backgroundColor:
              Color(0xFF990000),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los costos deben ser números válidos.',
          ),
          backgroundColor:
              Color(0xFF990000),
        ),
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

        idAsistencia:
            idAsistenciaController.text.trim(),

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

      final mensaje =
          resultado['mensaje']?.toString() ??
              'Ocurrió un problema.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
          ),
          backgroundColor:
              ok
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF990000),
        ),
      );

      if (ok) {
        limpiarFormulario();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo conectar con el servidor.\n$error',
          ),
          backgroundColor:
              const Color(0xFF990000),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void limpiarFormulario() {
    nombreController.clear();
    correoController.clear();
    telefonoController.clear();
    passwordController.clear();
    idAsistenciaController.clear();
    costoMensualController.clear();
    costoAnualController.clear();

    setState(() {
      idMembresia = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const gold =
        Color(0xFFD4AF37);

    const coal =
        Color(0xFF1A1A1D);

    const silver =
        Color(0xFFA9A9A9);

    return Scaffold(
      backgroundColor:
          const Color(0xFF101012),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF101012),

        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },

          icon: const Icon(
            Icons.arrow_back,
            color: gold,
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 650,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Registrar Cliente',

                      style:
                          TextStyle(
                        color:
                            Colors.white,

                        fontSize: 30,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Da de alta un nuevo cliente en GymFlow.',

                      style:
                          TextStyle(
                        color: silver,

                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _section(
                      titulo:
                          'Información personal',

                      child:
                          Column(
                        children: [
                          _input(
                            controller:
                                nombreController,

                            label:
                                'Nombre completo *',

                            icon:
                                Icons.person_outline,

                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Ingresa el nombre completo';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          _input(
                            controller:
                                correoController,

                            label:
                                'Correo *',

                            icon:
                                Icons.email_outlined,

                            keyboardType:
                                TextInputType
                                    .emailAddress,

                            validator:
                                (value) {
                              final correo =
                                  value?.trim() ??
                                      '';

                              if (correo.isEmpty) {
                                return 'Ingresa el correo';
                              }

                              final valido =
                                  RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(
                                correo,
                              );

                              if (!valido) {
                                return 'Ingresa un correo válido';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          _input(
                            controller:
                                telefonoController,

                            label:
                                'Teléfono *',

                            icon:
                                Icons.phone_outlined,

                            keyboardType:
                                TextInputType.phone,

                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Ingresa el teléfono';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _section(
                      titulo:
                          'Acceso',

                      child:
                          TextFormField(
                        controller:
                            passwordController,

                        obscureText:
                            ocultarPassword,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                        ),

                        decoration:
                            _decoracion(
                          label:
                              'Contraseña *',

                          icon:
                              Icons.lock_outline,

                          suffix:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                ocultarPassword =
                                    !ocultarPassword;
                              });
                            },

                            icon:
                                Icon(
                              ocultarPassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,

                              color: silver,
                            ),
                          ),
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value.isEmpty) {
                            return 'Ingresa una contraseña';
                          }

                          if (value.length <
                              6) {
                            return 'Mínimo 6 caracteres';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _section(
                      titulo:
                          'Membresía y asistencia',

                      child:
                          Column(
                        children: [
                          _input(
                            controller:
                                idAsistenciaController,

                            label:
                                'ID de asistencia *',

                            icon:
                                Icons
                                    .check_circle_outline,

                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Ingresa el ID de asistencia';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          DropdownButtonFormField<int>(
                            initialValue:
                                idMembresia,

                            dropdownColor:
                                coal,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),

                            decoration:
                                _decoracion(
                              label:
                                  'Membresía *',

                              icon:
                                  Icons
                                      .card_membership_outlined,
                            ),

                            items:
                                const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  'BasicFlow',
                                ),
                              ),
                            ],

                            onChanged:
                                cargando
                                    ? null
                                    : (value) {
                                        setState(() {
                                          idMembresia =
                                              value;
                                        });
                                      },

                            validator:
                                (value) {
                              if (value ==
                                  null) {
                                return 'Selecciona una membresía';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          _input(
                            controller:
                                costoMensualController,

                            label:
                                'Costo mensual *',

                            icon:
                                Icons.attach_money,

                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),

                            validator:
                                validarCosto,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          _input(
                            controller:
                                costoAnualController,

                            label:
                                'Costo anual *',

                            icon:
                                Icons.payments_outlined,

                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),

                            validator:
                                validarCosto,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    SizedBox(
                      width:
                          double.infinity,

                      height: 54,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            cargando
                                ? null
                                : registrarCliente,

                        icon:
                            cargando
                                ? const SizedBox(
                                    width:
                                        20,

                                    height:
                                        20,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,

                                      color:
                                          coal,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .person_add_alt_1,
                                  ),

                        label:
                            Text(
                          cargando
                              ? 'Registrando...'
                              : 'Registrar Cliente',
                        ),

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              gold,

                          foregroundColor:
                              coal,

                          disabledBackgroundColor:
                              gold.withValues(
                            alpha: 0.50,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),

                          textStyle:
                              const TextStyle(
                            fontSize:
                                16,

                            fontWeight:
                                FontWeight.bold,
                          ),
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

  String? validarCosto(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingresa el costo';
    }

    final numero =
        double.tryParse(
      value.trim(),
    );

    if (numero == null) {
      return 'Ingresa un número válido';
    }

    if (numero < 0) {
      return 'El costo no puede ser negativo';
    }

    return null;
  }

  Widget _section({
    required String titulo,
    required Widget child,
  }) {
    const gold =
        Color(0xFFD4AF37);

    const coal =
        Color(0xFF1A1A1D);

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color: coal,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              gold.withValues(
            alpha: 0.20,
          ),
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
              color: gold,

              fontSize: 18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          child,
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,

    TextInputType keyboardType =
        TextInputType.text,

    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:
          controller,

      keyboardType:
          keyboardType,

      style:
          const TextStyle(
        color:
            Colors.white,
      ),

      decoration:
          _decoracion(
        label:
            label,

        icon:
            icon,
      ),

      validator:
          validator,
    );
  }

  InputDecoration _decoracion({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    const gold =
        Color(0xFFD4AF37);

    const silver =
        Color(0xFFA9A9A9);

    return InputDecoration(
      labelText:
          label,

      labelStyle:
          const TextStyle(
        color: silver,
      ),

      prefixIcon:
          Icon(
        icon,
        color: gold,
      ),

      suffixIcon:
          suffix,

      filled:
          true,

      fillColor:
          const Color(
        0xFF111113,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              gold.withValues(
            alpha: 0.15,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color: gold,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(0xFF990000),
        ),
      ),
    );
  }
}