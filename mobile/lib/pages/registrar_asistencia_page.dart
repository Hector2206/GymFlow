import 'package:flutter/material.dart';

import '../services/asistencia_service.dart';

class RegistrarAsistenciaPage
    extends StatefulWidget {
  const RegistrarAsistenciaPage({
    super.key,
  });

  @override
  State<RegistrarAsistenciaPage> createState() =>
      _RegistrarAsistenciaPageState();
}

class _RegistrarAsistenciaPageState
    extends State<RegistrarAsistenciaPage> {
  final AsistenciaService asistenciaService =
      AsistenciaService();

  final TextEditingController codigoController =
      TextEditingController();

  final FocusNode codigoFocus =
      FocusNode();

  bool procesando = false;

  ResultadoRegistroAsistencia? resultado;

  String error = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
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
    Object e,
  ) {
    String mensaje =
        e.toString().trim();

    if (mensaje.startsWith('Exception:')) {
      mensaje =
          mensaje
              .replaceFirst(
                'Exception:',
                '',
              )
              .trim();
    }

    return mensaje;
  }

  String formatearFecha(
    String fecha,
  ) {
    if (fecha.trim().isEmpty) {
      return '';
    }

    try {
      final date =
          DateTime.parse(
        fecha,
      ).toLocal();

      final dia =
          date.day
              .toString()
              .padLeft(
                2,
                '0',
              );

      final mes =
          date.month
              .toString()
              .padLeft(
                2,
                '0',
              );

      return '$dia/$mes/${date.year}';
    } catch (_) {
      return fecha;
    }
  }

  Future<void> registrar() async {
    if (procesando) {
      return;
    }

    final codigoNormalizado =
        asistenciaService.normalizarCodigo(
      codigoController.text,
    );

    codigoController.text =
        codigoNormalizado;

    codigoController.selection =
        TextSelection.collapsed(
      offset:
          codigoController.text.length,
    );

    setState(() {
      resultado = null;
      error = '';
    });

    if (codigoNormalizado.isEmpty) {
      setState(() {
        error =
            'Ingresa un código de acceso.';
      });

      codigoFocus.requestFocus();
      return;
    }

    final formatoValido =
        RegExp(
      r'^[A-Z0-9-]+$',
    ).hasMatch(
      codigoNormalizado,
    );

    if (!formatoValido) {
      setState(() {
        error =
            'El código solo puede contener letras, números y guiones.';
      });

      codigoFocus.requestFocus();
      return;
    }

    setState(() {
      procesando = true;
    });

    try {
      final respuesta =
          await asistenciaService
              .registrarPorCodigo(
        codigoNormalizado,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        resultado =
            respuesta;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        error =
            limpiarException(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          procesando = false;
        });

        codigoController.clear();

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
  Widget build(BuildContext context) {
    const gold =
        Color(0xFFD4AF37);

    const silver =
        Color(0xFFA9A9A9);

    const dark =
        Color(0xFF101012);

    const coal =
        Color(0xFF1A1A1D);

    return Scaffold(
      backgroundColor:
          dark,

      appBar: AppBar(
        backgroundColor:
            dark,

        elevation:
            0,

        leadingWidth:
            70,

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
                  alpha:
                      0.45,
                ),
              ),
            ),

            child: IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop();
              },

              icon:
                  const Icon(
                Icons.arrow_back,
                color:
                    gold,
              ),
            ),
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height:
              48,
        ),

        bottom:
            PreferredSize(
          preferredSize:
              const Size.fromHeight(
            1,
          ),

          child: Container(
            height:
                1,

            color:
                gold.withValues(
              alpha:
                  0.30,
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
              Color(
                0xFF29292E,
              ),
              coal,
              Color(
                0xFF0D0D0F,
              ),
            ],
          ),
        ),

        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            34,
            20,
            50,
          ),

          child:
              Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    650,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'RECEPCIÓN',

                    style:
                        TextStyle(
                      color:
                          gold,

                      fontSize:
                          13,

                      fontWeight:
                          FontWeight.bold,

                      letterSpacing:
                          2,
                    ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  const Text(
                    'Control de Acceso',

                    style:
                        TextStyle(
                      color:
                          Colors.white,

                      fontSize:
                          32,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  const Text(
                    'Registra la entrada de los clientes mediante su código personal.',

                    style:
                        TextStyle(
                      color:
                          silver,

                      fontSize:
                          15,

                      height:
                          1.4,
                    ),
                  ),

                  const SizedBox(
                    height:
                        30,
                  ),

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
                          coal,

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      border:
                          Border.all(
                        color:
                            gold.withValues(
                          alpha:
                              0.18,
                        ),
                      ),
                    ),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Registrar Asistencia',

                          style:
                              TextStyle(
                            color:
                                gold,

                            fontSize:
                                19,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height:
                              7,
                        ),

                        const Text(
                          'Ingresa o escanea el código de acceso del cliente.',

                          style:
                              TextStyle(
                            color:
                                silver,

                            fontSize:
                                14,
                          ),
                        ),

                        const SizedBox(
                          height:
                              22,
                        ),

                        TextField(
                          controller:
                              codigoController,

                          focusNode:
                              codigoFocus,

                          enabled:
                              !procesando,

                          textCapitalization:
                              TextCapitalization.characters,

                          textInputAction:
                              TextInputAction.done,

                          onSubmitted:
                              (_) {
                            registrar();
                          },

                          style:
                              const TextStyle(
                            color:
                                Colors.white,

                            fontSize:
                                17,

                            letterSpacing:
                                1,
                          ),

                          decoration:
                              InputDecoration(
                            labelText:
                                'Código de acceso',

                            hintText:
                                'Escanea o escribe el código',

                            labelStyle:
                                const TextStyle(
                              color:
                                  silver,
                            ),

                            hintStyle:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF666666,
                              ),
                            ),

                            prefixIcon:
                                const Icon(
                              Icons.barcode_reader,
                              color:
                                  gold,
                            ),

                            filled:
                                true,

                            fillColor:
                                dark,

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              borderSide:
                                  BorderSide(
                                color:
                                    gold.withValues(
                                  alpha:
                                      0.25,
                                ),
                              ),
                            ),

                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              borderSide:
                                  const BorderSide(
                                color:
                                    gold,

                                width:
                                    1.5,
                              ),
                            ),

                            disabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xFF444444,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),

                        Text(
                          procesando
                              ? 'Validando acceso...'
                              : 'El lector puede escribir el código y enviar Enter automáticamente.',

                          style:
                              TextStyle(
                            color:
                                procesando
                                    ? gold
                                    : silver,

                            fontSize:
                                12,
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
                              50,

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
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline,
                                      ),

                            label:
                                Text(
                              procesando
                                  ? 'Validando...'
                                  : 'Validar acceso',
                            ),

                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  gold,

                              foregroundColor:
                                  Colors.black,

                              disabledBackgroundColor:
                                  gold.withValues(
                                alpha:
                                    0.35,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(
                      height:
                          22,
                    ),

                    _buildRechazado(
                      mensaje:
                          error,
                    ),
                  ],

                  if (resultado != null) ...[
                    const SizedBox(
                      height:
                          22,
                    ),

                    if (resultado!.accesoAprobado)
                      _buildAprobado(
                        resultado!,
                      )
                    else
                      _buildRechazado(
                        mensaje:
                            resultado!.mensaje.isNotEmpty
                                ? resultado!.mensaje
                                : resultado!.motivo.isNotEmpty
                                    ? resultado!.motivo
                                    : 'El acceso fue rechazado.',

                        resultado:
                            resultado,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAprobado(
    ResultadoRegistroAsistencia respuesta,
  ) {
    const gold =
        Color(0xFFD4AF37);

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
          0xFF10271A,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF49D17D,
          ),
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons.check_circle,
            color:
                Color(
              0xFF49D17D,
            ),
            size:
                52,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'ACCESO APROBADO',

            style:
                TextStyle(
              color:
                  Color(
                0xFF49D17D,
              ),

              fontWeight:
                  FontWeight.bold,

              fontSize:
                  18,
            ),
          ),

          if (respuesta.nombreCompleto.isNotEmpty) ...[
            const SizedBox(
              height:
                  20,
            ),

            const Text(
              'Cliente identificado',

              style:
                  TextStyle(
                color:
                    Color(
                  0xFFA9A9A9,
                ),

                fontSize:
                    12,
              ),
            ),

            const SizedBox(
              height:
                  5,
            ),

            Text(
              respuesta.nombreCompleto,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    gold,

                fontSize:
                    20,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],

          if (respuesta.nombrePlan.isNotEmpty) ...[
            const SizedBox(
              height:
                  18,
            ),

            _datoResultado(
              'Membresía',
              respuesta.nombrePlan,
            ),
          ],

          if (respuesta.fechaVencimiento.isNotEmpty)
            _datoResultado(
              'Vencimiento',
              formatearFecha(
                respuesta.fechaVencimiento,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRechazado({
    required String mensaje,
    ResultadoRegistroAsistencia? resultado,
  }) {
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
          0xFF2A1111,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE45C5C,
          ),
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons.cancel,
            color:
                Color(
              0xFFE45C5C,
            ),
            size:
                50,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'ACCESO RECHAZADO',

            style:
                TextStyle(
              color:
                  Color(
                0xFFE45C5C,
              ),

              fontSize:
                  18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            mensaje,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white,

              fontSize:
                  14,
            ),
          ),

          if (resultado != null &&
              resultado.nombreCompleto.isNotEmpty) ...[
            const SizedBox(
              height:
                  18,
            ),

            _datoResultado(
              'Cliente',
              resultado.nombreCompleto,
            ),
          ],

          if (resultado != null &&
              resultado.nombrePlan.isNotEmpty)
            _datoResultado(
              'Membresía',
              resultado.nombrePlan,
            ),

          if (resultado != null &&
              resultado.fechaVencimiento.isNotEmpty)
            _datoResultado(
              'Vencimiento',
              formatearFecha(
                resultado.fechaVencimiento,
              ),
            ),
        ],
      ),
    );
  }

  Widget _datoResultado(
    String etiqueta,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top:
            10,
      ),

      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              etiqueta,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFFA9A9A9,
                ),

                fontSize:
                    13,
              ),
            ),
          ),

          const SizedBox(
            width:
                16,
          ),

          Flexible(
            child:
                Text(
              valor,

              textAlign:
                  TextAlign.right,

              style:
                  const TextStyle(
                color:
                    Colors.white,

                fontWeight:
                    FontWeight.bold,

                fontSize:
                    13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}