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

    if (cargando) {
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

    const dark =
        Color(0xFF101012);

    return Scaffold(
      backgroundColor:
          dark,

      appBar: AppBar(
        backgroundColor:
            dark,

        elevation: 0,

        leadingWidth: 70,

        leading: Padding(
          padding:
              const EdgeInsets.only(
            left: 14,
            top: 6,
            bottom: 6,
          ),

          child: Container(
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),

              border:
                  Border.all(
                color:
                    gold.withValues(
                  alpha: 0.45,
                ),
              ),
            ),

            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },

              icon:
                  const Icon(
                Icons.arrow_back,
                color: gold,
              ),
            ),
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),

        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(
            1,
          ),

          child: Container(
            height: 1,

            color:
                gold.withValues(
              alpha: 0.30,
            ),
          ),
        ),
      ),

      body: Container(
        width:
            double.infinity,

        decoration:
            const BoxDecoration(
          gradient:
              RadialGradient(
            center:
                Alignment.topCenter,

            radius:
                1.5,

            colors: [
              Color(0xFF29292E),
              coal,
              Color(0xFF0D0D0F),
            ],

            stops: [
              0.0,
              0.35,
              1.0,
            ],
          ),
        ),

        child: SafeArea(
          top: false,

          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              36,
              20,
              50,
            ),

            child: Center(
              child:
                  ConstrainedBox(
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
                        'RECEPCIÓN',

                        style:
                            TextStyle(
                          color: gold,

                          fontSize: 13,

                          fontWeight:
                              FontWeight.bold,

                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Registrar Cliente',

                        style:
                            TextStyle(
                          color:
                              Colors.white,

                          fontSize: 32,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Ingresa los datos del nuevo cliente',

                        style:
                            TextStyle(
                          color: silver,

                          fontSize: 15,

                          height: 1.4,
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      _section(
                        titulo:
                            'Datos personales',

                        child:
                            Column(
                          children: [
                            _input(
                              controller:
                                  nombreController,

                              label:
                                  'Nombre completo *',

                              hint:
                                  'Nombre completo del cliente',

                              keyboardType:
                                  TextInputType.name,

                              validator:
                                  (value) {
                                if (value ==
                                        null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'El nombre completo es obligatorio.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _input(
                              controller:
                                  correoController,

                              label:
                                  'Correo electrónico *',

                              hint:
                                  'cliente@gymflow.com',

                              keyboardType:
                                  TextInputType
                                      .emailAddress,

                              validator:
                                  (value) {
                                final correo =
                                    value?.trim() ??
                                        '';

                                if (correo.isEmpty) {
                                  return 'El correo es obligatorio.';
                                }

                                final valido =
                                    RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(
                                  correo,
                                );

                                if (!valido) {
                                  return 'Ingresa un correo electrónico válido.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _input(
                              controller:
                                  telefonoController,

                              label:
                                  'Teléfono',

                              hint:
                                  '4421234567',

                              keyboardType:
                                  TextInputType.phone,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      _section(
                        titulo:
                            'Acceso',

                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
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

                                hint:
                                    'Mínimo 6 caracteres',

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

                                    color:
                                        silver,
                                  ),
                                ),
                              ),

                              validator:
                                  (value) {
                                if (value ==
                                        null ||
                                    value.isEmpty) {
                                  return 'La contraseña es obligatoria.';
                                }

                                if (value.length <
                                    6) {
                                  return 'La contraseña debe tener al menos 6 caracteres.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 9,
                            ),

                            const Text(
                              'La contraseña será cifrada por el backend.',

                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFF777777,
                                ),

                                fontSize:
                                    12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      _section(
                        titulo:
                            'Membresía y asistencia',

                        child:
                            Column(
                          children: [
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

                                hint:
                                    'Selecciona una opción',
                              ),

                              items:
                                  const [
                                DropdownMenuItem(
                                  value: 1,

                                  child:
                                      Text(
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
                                  return 'Selecciona una membresía válida.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _input(
                              controller:
                                  costoMensualController,

                              label:
                                  'Costo mensual *',

                              hint:
                                  '0.00',

                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),

                              validator:
                                  validarCosto,
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _input(
                              controller:
                                  costoAnualController,

                              label:
                                  'Costo anual *',

                              hint:
                                  '0.00',

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

                        height: 56,

                        child:
                            ElevatedButton(
                          onPressed:
                              cargando
                                  ? null
                                  : registrarCliente,

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
                              fontSize: 16,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          child:
                              cargando
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,

                                      children: [
                                        SizedBox(
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
                                        ),

                                        SizedBox(
                                          width:
                                              12,
                                        ),

                                        Text(
                                          'Registrando...',
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Registrar cliente',
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

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        24,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            Color(0xFF1D1D20),
            Color(0xFF151517),
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              gold.withValues(
            alpha: 0.16,
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

              fontSize: 19,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          child,
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,

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

        hint:
            hint,
      ),

      validator:
          validator,
    );
  }

  InputDecoration _decoracion({
    required String label,
    required String hint,
    Widget? suffix,
  }) {
    const gold =
        Color(0xFFD4AF37);

    const silver =
        Color(0xFFA9A9A9);

    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      labelStyle:
          const TextStyle(
        color: silver,
      ),

      hintStyle:
          const TextStyle(
        color:
            Color(0xFF777777),
      ),

      suffixIcon:
          suffix,

      filled:
          true,

      fillColor:
          const Color(
        0xFF101012,
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
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

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(0xFF990000),

          width: 1.5,
        ),
      ),
    );
  }
}