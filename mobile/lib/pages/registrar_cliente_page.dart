import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/cliente_service.dart';

class RegistrarClientePage
    extends StatefulWidget {
  const RegistrarClientePage({
    super.key,
  });

  @override
  State<RegistrarClientePage>
      createState() =>
          _RegistrarClientePageState();
}

class _RegistrarClientePageState
    extends State<RegistrarClientePage> {
  final _formKey =
      GlobalKey<FormState>();

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

    if (RegExp(r'\d')
        .hasMatch(nombre)) {
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

    if (!(_formKey.currentState
            ?.validate() ??
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
          await clienteService
              .registrarCliente(
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
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        margin:
            const EdgeInsets.all(
          18,
        ),

        elevation:
            3,

        backgroundColor:
            exito
                ? const Color(
                    0xFFF1F8F2,
                  )
                : const Color(
                    0xFFFFF6F6,
                  ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          side:
              BorderSide(
            color:
                exito
                    ? const Color(
                        0xFFBBD8BF,
                      )
                    : const Color(
                        0xFFEDB9BF,
                      ),
          ),
        ),

        content: Row(
          children: [
            Container(
              width:
                  30,
              height:
                  30,

              decoration:
                  BoxDecoration(
                color:
                    exito
                        ? const Color(
                            0xFF2E7D32,
                          )
                        : const Color(
                            0xFFC21B2E,
                          ),

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                exito
                    ? Icons
                        .check_rounded
                    : Icons
                        .priority_high_rounded,

                color:
                    Colors.white,

                size:
                    18,
              ),
            ),

            const SizedBox(
              width:
                  12,
            ),

            Expanded(
              child: Text(
                mensaje,

                style:
                    TextStyle(
                  color:
                      exito
                          ? const Color(
                              0xFF285E2D,
                            )
                          : const Color(
                              0xFF8F2030,
                            ),

                  fontSize:
                      13,

                  fontWeight:
                      FontWeight.w600,

                  height:
                      1.4,
                ),
              ),
            ),
          ],
        ),
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
  Widget build(
    BuildContext context,
  ) {
    const background =
        Color(
      0xFFF8F5EF,
    );

    const surface =
        Color(
      0xFFFFFDF8,
    );

    const gold =
        Color(
      0xFFB58A2A,
    );

    const goldDark =
        Color(
      0xFF8A6814,
    );

    const textPrimary =
        Color(
      0xFF2F2A24,
    );

    const textSecondary =
        Color(
      0xFF777067,
    );

    return Scaffold(
      backgroundColor:
          background,

      appBar: AppBar(
        backgroundColor:
            surface,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        leading: Padding(
          padding:
              const EdgeInsets.all(
            8,
          ),

          child: Container(
            decoration:
                BoxDecoration(
              color:
                  surface,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),

              border:
                  Border.all(
                color:
                    const Color(
                  0xFFD8C8A5,
                ),
              ),
            ),

            child: IconButton(
              padding:
                  EdgeInsets.zero,

              tooltip:
                  'Regresar',

              onPressed: () {
                Navigator.of(
                  context,
                ).pop();
              },

              icon:
                  const Icon(
                Icons
                    .arrow_back_rounded,

                color:
                    goldDark,

                size:
                    21,
              ),
            ),
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',

          height:
              48,

          fit:
              BoxFit.contain,
        ),

        bottom:
            const PreferredSize(
          preferredSize:
              Size.fromHeight(
            1,
          ),

          child: Divider(
            height:
                1,

            color:
                Color(
              0xFFE7DFD2,
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
              LinearGradient(
            begin:
                Alignment.topCenter,

            end:
                Alignment.bottomCenter,

            colors: [
              Color(
                0xFFF8F5EF,
              ),

              Color(
                0xFFF2EDE4,
              ),
            ],
          ),
        ),

        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            28,
            20,
            45,
          ),

          child: Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    650,
              ),

              child: Form(
                key:
                    _formKey,

                autovalidateMode:
                    AutovalidateMode
                        .onUserInteraction,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        22,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            surface,

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE5DDCF,
                          ),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(
                              0xFF4C3E24,
                            ).withValues(
                              alpha:
                                  0.05,
                            ),

                            blurRadius:
                                20,

                            offset:
                                const Offset(
                              0,
                              7,
                            ),
                          ),
                        ],
                      ),

                      child:
                          const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            'RECEPCIÓN',

                            style:
                                TextStyle(
                              color:
                                  goldDark,

                              fontSize:
                                  11,

                              fontWeight:
                                  FontWeight
                                      .w700,

                              letterSpacing:
                                  2,
                            ),
                          ),

                          SizedBox(
                            height:
                                7,
                          ),

                          Text(
                            'Registrar Cliente',

                            style:
                                TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  29,

                              fontWeight:
                                  FontWeight
                                      .w700,

                              letterSpacing:
                                  -0.5,
                            ),
                          ),

                          SizedBox(
                            height:
                                7,
                          ),

                          Text(
                            'Captura la información del nuevo cliente para crear su acceso a GymFlow.',

                            style:
                                TextStyle(
                              color:
                                  textSecondary,

                              fontSize:
                                  13,

                              height:
                                  1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          22,
                    ),

                    _section(
                      'Datos personales',
                      Icons.person_outline_rounded,
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

                          maxLength:
                              100,

                          icon:
                              Icons
                                  .person_outline_rounded,
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

                          maxLength:
                              150,

                          icon:
                              Icons
                                  .email_outlined,
                        ),

                        _campo(
                          controller:
                              telefonoController,

                          label:
                              'Teléfono',

                          hint:
                              '4421234567',

                          validator:
                              validarTelefono,

                          keyboardType:
                              TextInputType.phone,

                          maxLength:
                              10,

                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],

                          icon:
                              Icons
                                  .phone_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    _section(
                      'Acceso',
                      Icons.lock_outline_rounded,
                      [
                        TextFormField(
                          controller:
                              passwordController,

                          enabled:
                              !cargando,

                          obscureText:
                              ocultarPassword,

                          validator:
                              validarPassword,

                          maxLength:
                              72,

                          style:
                              const TextStyle(
                            color:
                                textPrimary,

                            fontSize:
                                14,
                          ),

                          decoration:
                              _decoracion(
                            'Contraseña *',
                            'Mínimo 6 caracteres',
                            Icons
                                .lock_outline_rounded,
                          ).copyWith(
                            counterText:
                                '',

                            suffixIcon:
                                IconButton(
                              tooltip:
                                  ocultarPassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',

                              onPressed: () {
                                setState(
                                  () {
                                    ocultarPassword =
                                        !ocultarPassword;
                                  },
                                );
                              },

                              icon: Icon(
                                ocultarPassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,

                                color:
                                    goldDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    _section(
                      'Membresía y asistencia',
                      Icons
                          .card_membership_outlined,
                      [
                        DropdownButtonFormField<int>(
                          initialValue:
                              idMembresia,

                          dropdownColor:
                              surface,

                          style:
                              const TextStyle(
                            color:
                                textPrimary,

                            fontSize:
                                14,
                          ),

                          icon:
                              const Icon(
                            Icons
                                .keyboard_arrow_down_rounded,

                            color:
                                goldDark,
                          ),

                          decoration:
                              _decoracion(
                            'Membresía *',
                            'Selecciona una opción',
                            Icons
                                .card_membership_outlined,
                          ),

                          items:
                              const [
                            DropdownMenuItem(
                              value:
                                  1,

                              child:
                                  Text(
                                'BasicFlow',
                              ),
                            ),
                          ],

                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value <=
                                    0) {
                              return 'Selecciona una membresía válida.';
                            }

                            return null;
                          },

                          onChanged:
                              cargando
                                  ? null
                                  : (value) {
                                      setState(
                                        () {
                                          idMembresia =
                                              value;
                                        },
                                      );
                                    },
                        ),

                        _campo(
                          controller:
                              costoMensualController,

                          label:
                              'Costo mensual *',

                          hint:
                              '500.00',

                          validator:
                              validarCosto,

                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal:
                                true,
                          ),

                          inputFormatters:
                              _formatoDecimal(),

                          icon:
                              Icons
                                  .payments_outlined,
                        ),

                        _campo(
                          controller:
                              costoAnualController,

                          label:
                              'Costo anual *',

                          hint:
                              '5000.00',

                          validator:
                              validarCosto,

                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal:
                                true,
                          ),

                          inputFormatters:
                              _formatoDecimal(),

                          icon:
                              Icons
                                  .account_balance_wallet_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          26,
                    ),

                    SizedBox(
                      width:
                          double.infinity,

                      height:
                          54,

                      child:
                          FilledButton.icon(
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
                                          2,

                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .person_add_alt_1_rounded,

                                    size:
                                        21,
                                  ),

                        label: Text(
                          cargando
                              ? 'Registrando...'
                              : 'Registrar cliente',
                        ),

                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              gold,

                          foregroundColor:
                              Colors.white,

                          disabledBackgroundColor:
                              const Color(
                            0xFFD8C89F,
                          ),

                          disabledForegroundColor:
                              Colors.white,

                          elevation:
                              0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),

                          textStyle:
                              const TextStyle(
                            fontSize:
                                14,

                            fontWeight:
                                FontWeight.w700,
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

  List<TextInputFormatter>
      _formatoDecimal() {
    return [
      TextInputFormatter.withFunction(
        (oldValue, newValue) {
          if (RegExp(
            r'^\d{0,7}(\.\d{0,2})?$',
          ).hasMatch(
            newValue.text,
          )) {
            return newValue;
          }

          return oldValue;
        },
      ),
    ];
  }

  Widget _section(
    String titulo,
    IconData icon,
    List<Widget> children,
  ) {
    const surface =
        Color(
      0xFFFFFDF8,
    );

    const goldDark =
        Color(
      0xFF8A6814,
    );

    const textPrimary =
        Color(
      0xFF2F2A24,
    );

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            surface,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE5DDCF,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xFF4C3E24,
            ).withValues(
              alpha:
                  0.04,
            ),

            blurRadius:
                16,

            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width:
                    38,

                height:
                    38,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3EAD8,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE4D2AA,
                    ),
                  ),
                ),

                child: Icon(
                  icon,

                  color:
                      goldDark,

                  size:
                      20,
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              Expanded(
                child: Text(
                  titulo,

                  style:
                      const TextStyle(
                    color:
                        textPrimary,

                    fontSize:
                        17,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                20,
          ),

          for (
            int i = 0;
            i < children.length;
            i++
          ) ...[
            children[i],

            if (i <
                children.length - 1)
              const SizedBox(
                height:
                    16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required String? Function(String?)
        validator,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    List<TextInputFormatter>?
        inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller:
          controller,

      enabled:
          !cargando,

      validator:
          validator,

      keyboardType:
          keyboardType,

      inputFormatters:
          inputFormatters,

      maxLength:
          maxLength,

      style:
          const TextStyle(
        color:
            Color(
          0xFF2F2A24,
        ),

        fontSize:
            14,
      ),

      decoration:
          _decoracion(
        label,
        hint,
        icon,
      ).copyWith(
        counterText:
            '',
      ),
    );
  }

  InputDecoration _decoracion(
    String label,
    String hint,
    IconData icon,
  ) {
    const gold =
        Color(
      0xFFB58A2A,
    );

    const goldDark =
        Color(
      0xFF8A6814,
    );

    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      filled:
          true,

      fillColor:
          const Color(
        0xFFF8F4EC,
      ),

      prefixIcon:
          Icon(
        icon,

        color:
            goldDark,

        size:
            21,
      ),

      labelStyle:
          const TextStyle(
        color:
            Color(
          0xFF777067,
        ),

        fontSize:
            13,
      ),

      hintStyle:
          const TextStyle(
        color:
            Color(
          0xFFA39A8D,
        ),

        fontSize:
            13,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFE5DDCF,
          ),
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFE5DDCF,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              gold,

          width:
              1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFC21B2E,
          ),
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFC21B2E,
          ),

          width:
              1.5,
        ),
      ),

      errorStyle:
          const TextStyle(
        color:
            Color(
          0xFFC21B2E,
        ),

        fontSize:
            11,
      ),
    );
  }
}