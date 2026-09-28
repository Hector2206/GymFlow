import 'package:flutter/material.dart';

import '../services/asistencia_service.dart';

class RegistrarAsistenciaPage
    extends StatefulWidget {
  const RegistrarAsistenciaPage({
    super.key,
  });

  @override
  State<RegistrarAsistenciaPage>
      createState() =>
          _RegistrarAsistenciaPageState();
}

class _RegistrarAsistenciaPageState
    extends State<RegistrarAsistenciaPage> {
  final _formKey =
      GlobalKey<FormState>();

  final asistenciaService =
      AsistenciaService();

  final codigoController =
      TextEditingController();

  final codigoFocus =
      FocusNode();

  bool procesando = false;

  String error = '';

  ResultadoRegistroAsistencia?
      resultado;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (mounted) {
          codigoFocus.requestFocus();
        }
      },
    );
  }

  @override
  void dispose() {
    codigoController.dispose();
    codigoFocus.dispose();

    super.dispose();
  }

  String limpiarException(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception:',
          '',
        )
        .trim();
  }

  String? validarCodigo(
    String? value,
  ) {
    final codigo =
        asistenciaService
            .normalizarCodigo(
      value ?? '',
    );

    if (codigo.isEmpty) {
      return 'Ingresa un código de acceso.';
    }

    if (codigo.length > 80) {
      return 'El código es demasiado largo.';
    }

    if (!RegExp(
      r'^[A-Z0-9-]+$',
    ).hasMatch(codigo)) {
      return 'El código solo puede contener letras, números y guiones.';
    }

    return null;
  }

  Future<void> registrar() async {
    if (procesando) {
      return;
    }

    FocusScope.of(context).unfocus();

    final normalizado =
        asistenciaService
            .normalizarCodigo(
      codigoController.text,
    );

    codigoController.text =
        normalizado;

    if (!(_formKey.currentState
            ?.validate() ??
        false)) {
      codigoFocus.requestFocus();
      return;
    }

    setState(() {
      procesando = true;
      resultado = null;
      error = '';
    });

    try {
      final respuesta =
          await asistenciaService
              .registrarPorCodigo(
        normalizado,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        resultado = respuesta;
      });

      codigoController.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        error =
            limpiarException(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          procesando = false;
        });

        Future.delayed(
          const Duration(
            milliseconds: 150,
          ),
          () {
            if (mounted) {
              codigoFocus.requestFocus();
            }
          },
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    const background =
        Color(0xFFF8F5EF);

    const surface =
        Color(0xFFFFFDF8);

    const gold =
        Color(0xFFB58A2A);

    const goldDark =
        Color(0xFF8A6814);

    const textPrimary =
        Color(0xFF2F2A24);

    const textSecondary =
        Color(0xFF777067);

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
                                  FontWeight.w700,

                              letterSpacing:
                                  2,
                            ),
                          ),

                          SizedBox(
                            height:
                                7,
                          ),

                          Text(
                            'Control de Acceso',

                            style:
                                TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  29,

                              fontWeight:
                                  FontWeight.w700,

                              letterSpacing:
                                  -0.5,
                            ),
                          ),

                          SizedBox(
                            height:
                                7,
                          ),

                          Text(
                            'Escanea o captura el código del cliente para validar su entrada.',

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

                    Container(
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
                            CrossAxisAlignment
                                .start,

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

                                child:
                                    const Icon(
                                  Icons
                                      .barcode_reader,

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

                              const Expanded(
                                child:
                                    Text(
                                  'Código de acceso',

                                  style:
                                      TextStyle(
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

                          TextFormField(
                            controller:
                                codigoController,

                            focusNode:
                                codigoFocus,

                            enabled:
                                !procesando,

                            validator:
                                validarCodigo,

                            maxLength:
                                80,

                            textCapitalization:
                                TextCapitalization
                                    .characters,

                            textInputAction:
                                TextInputAction
                                    .done,

                            onFieldSubmitted:
                                (_) {
                              registrar();
                            },

                            style:
                                const TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight.w600,

                              letterSpacing:
                                  0.6,
                            ),

                            decoration:
                                InputDecoration(
                              labelText:
                                  'Código de acceso',

                              hintText:
                                  'Escanea o escribe el código',

                              counterText:
                                  '',

                              filled:
                                  true,

                              fillColor:
                                  const Color(
                                0xFFF8F4EC,
                              ),

                              prefixIcon:
                                  const Icon(
                                Icons
                                    .qr_code_scanner_rounded,

                                color:
                                    goldDark,
                              ),

                              labelStyle:
                                  const TextStyle(
                                color:
                                    textSecondary,

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
                            ),
                          ),

                          const SizedBox(
                            height:
                                18,
                          ),

                          SizedBox(
                            width:
                                double.infinity,

                            height:
                                52,

                            child:
                                FilledButton.icon(
                              onPressed:
                                  procesando
                                      ? null
                                      : registrar,

                              icon:
                                  procesando
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
                                              .check_circle_outline_rounded,

                                          size:
                                              21,
                                        ),

                              label: Text(
                                procesando
                                    ? 'Validando...'
                                    : 'Validar acceso',
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

                          const SizedBox(
                            height:
                                14,
                          ),

                          Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets.all(
                              13,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF8F4EC,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFFE8DDC8,
                                ),
                              ),
                            ),

                            child:
                                const Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Icon(
                                  Icons
                                      .info_outline_rounded,

                                  color:
                                      goldDark,

                                  size:
                                      18,
                                ),

                                SizedBox(
                                  width:
                                      9,
                                ),

                                Expanded(
                                  child:
                                      Text(
                                    "El lector puede enviar ASIS'TEST'001; GymFlow lo normaliza automáticamente a ASIS-TEST-001.",

                                    style:
                                        TextStyle(
                                      color:
                                          textSecondary,

                                      fontSize:
                                          12,

                                      height:
                                          1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (error.isNotEmpty) ...[
                      const SizedBox(
                        height:
                            20,
                      ),

                      _rechazado(
                        error,
                      ),
                    ],

                    if (resultado != null) ...[
                      const SizedBox(
                        height:
                            20,
                      ),

                      resultado!
                              .accesoAprobado
                          ? _aprobado(
                              resultado!,
                            )
                          : _rechazado(
                              resultado!
                                      .mensaje
                                      .isNotEmpty
                                  ? resultado!
                                      .mensaje
                                  : resultado!
                                          .motivo
                                          .isNotEmpty
                                      ? resultado!
                                          .motivo
                                      : 'Acceso rechazado.',
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _aprobado(
    ResultadoRegistroAsistencia r,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF2F8F2,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFB7D7BC,
          ),
        ),
      ),

      child: Column(
        children: [
          Container(
            width:
                58,

            height:
                58,

            decoration:
                const BoxDecoration(
              color:
                  Color(
                0xFFDCEEDF,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .check_circle_rounded,

              color:
                  Color(
                0xFF2E7D32,
              ),

              size:
                  38,
            ),
          ),

          const SizedBox(
            height:
                13,
          ),

          const Text(
            'ACCESO APROBADO',

            style:
                TextStyle(
              color:
                  Color(
                0xFF2E7D32,
              ),

              fontWeight:
                  FontWeight.w800,

              fontSize:
                  17,

              letterSpacing:
                  0.4,
            ),
          ),

          if (r.nombreCompleto
              .isNotEmpty) ...[
            const SizedBox(
              height:
                  13,
            ),

            Text(
              r.nombreCompleto,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF2F2A24,
                ),

                fontWeight:
                    FontWeight.w700,

                fontSize:
                    16,
              ),
            ),
          ],

          if (r.nombrePlan
              .isNotEmpty) ...[
            const SizedBox(
              height:
                  5,
            ),

            Text(
              'Membresía: ${r.nombrePlan}',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF777067,
                ),

                fontSize:
                    13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rechazado(
    String mensaje,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFFF5F5,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFEDB9BF,
          ),
        ),
      ),

      child: Column(
        children: [
          Container(
            width:
                58,

            height:
                58,

            decoration:
                const BoxDecoration(
              color:
                  Color(
                0xFFF8DDDF,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons.cancel_rounded,

              color:
                  Color(
                0xFFC21B2E,
              ),

              size:
                  37,
            ),
          ),

          const SizedBox(
            height:
                13,
          ),

          const Text(
            'ACCESO RECHAZADO',

            style:
                TextStyle(
              color:
                  Color(
                0xFFC21B2E,
              ),

              fontWeight:
                  FontWeight.w800,

              fontSize:
                  17,

              letterSpacing:
                  0.4,
            ),
          ),

          const SizedBox(
            height:
                9,
          ),

          Text(
            mensaje,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Color(
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
        ],
      ),
    );
  }
}