import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../models/mi_codigo_acceso.dart';
import '../services/codigo_acceso_service.dart';

class MiCodigoPage extends StatefulWidget {
  const MiCodigoPage({
    super.key,
  });

  @override
  State<MiCodigoPage> createState() =>
      _MiCodigoPageState();
}

class _MiCodigoPageState
    extends State<MiCodigoPage> {
  final CodigoAccesoService codigoAccesoService =
      CodigoAccesoService();

  bool cargando = true;
  String error = '';

  MiCodigoAcceso? codigo;

  @override
  void initState() {
    super.initState();

    cargarCodigo();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _activarBrilloCodigo();
      },
    );
  }

  Future<void> _activarBrilloCodigo() async {
    if (kIsWeb) {
      return;
    }

    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(
        1.0,
      );
    } catch (e) {
      debugPrint(
        'No se pudo aumentar el brillo: $e',
      );
    }
  }

  Future<void> _restaurarBrillo() async {
    if (kIsWeb) {
      return;
    }

    try {
      await ScreenBrightness.instance
          .resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint(
        'No se pudo restaurar el brillo: $e',
      );
    }
  }

  @override
  void dispose() {
    _restaurarBrillo();

    super.dispose();
  }

  Future<void> cargarCodigo() async {
    setState(() {
      cargando = true;
      error = '';
      codigo = null;
    });

    try {
      final resultado =
          await codigoAccesoService
              .obtenerMiCodigo();

      if (!mounted) {
        return;
      }

      setState(() {
        codigo = resultado;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      String mensaje =
          e.toString().trim();

      if (mensaje.startsWith(
        'Exception:',
      )) {
        mensaje = mensaje
            .replaceFirst(
              'Exception:',
              '',
            )
            .trim();
      }

      if (mensaje.isEmpty) {
        mensaje =
            'No se pudo cargar tu código de acceso.';
      }

      setState(() {
        error = mensaje;
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
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

      body: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final pantallaPequena =
              constraints.maxWidth < 380;

          final paddingHorizontal =
              pantallaPequena
                  ? 14.0
                  : 20.0;

          final paddingTarjeta =
              pantallaPequena
                  ? 16.0
                  : 24.0;

          return Container(
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

            child: SafeArea(
              top:
                  false,

              child:
                  SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(
                  paddingHorizontal,
                  30,
                  paddingHorizontal,
                  50,
                ),

                child: Center(
                  child:
                      ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth:
                          650,
                    ),

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
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              const Text(
                                'CLIENTE',

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

                              const SizedBox(
                                height:
                                    7,
                              ),

                              Text(
                                'Mi Código de Acceso',

                                style:
                                    TextStyle(
                                  color:
                                      textPrimary,

                                  fontSize:
                                      pantallaPequena
                                          ? 27
                                          : 29,

                                  fontWeight:
                                      FontWeight.w700,

                                  letterSpacing:
                                      -0.5,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    7,
                              ),

                              const Text(
                                'Presenta este código en recepción para registrar tu entrada.',

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
                              EdgeInsets.all(
                            paddingTarjeta,
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
                                    18,

                                offset:
                                    const Offset(
                                  0,
                                  6,
                                ),
                              ),
                            ],
                          ),

                          child:
                              _buildContenido(
                            gold:
                                gold,

                            goldDark:
                                goldDark,

                            textPrimary:
                                textPrimary,

                            textSecondary:
                                textSecondary,

                            pantallaPequena:
                                pantallaPequena,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContenido({
    required Color gold,
    required Color goldDark,
    required Color textPrimary,
    required Color textSecondary,
    required bool pantallaPequena,
  }) {
    if (cargando) {
      return SizedBox(
        height:
            280,

        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              CircularProgressIndicator(
                color:
                    gold,

                strokeWidth:
                    3,
              ),

              const SizedBox(
                height:
                    18,
              ),

              Text(
                'Cargando tu código...',

                style:
                    TextStyle(
                  color:
                      textSecondary,

                  fontSize:
                      14,

                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return SizedBox(
        width:
            double.infinity,

        height:
            280,

        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

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
                  Icons
                      .error_outline_rounded,

                  color:
                      Color(
                    0xFFC21B2E,
                  ),

                  size:
                      34,
                ),
              ),

              const SizedBox(
                height:
                    14,
              ),

              const Text(
                'No se pudo cargar tu código',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      Color(
                    0xFFC21B2E,
                  ),

                  fontSize:
                      17,

                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height:
                    8,
              ),

              Text(
                error,

                textAlign:
                    TextAlign.center,

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

              const SizedBox(
                height:
                    18,
              ),

              OutlinedButton.icon(
                onPressed:
                    cargarCodigo,

                icon:
                    const Icon(
                  Icons
                      .refresh_rounded,

                  size:
                      19,
                ),

                label:
                    const Text(
                  'Reintentar',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      goldDark,

                  backgroundColor:
                      const Color(
                    0xFFF8F4EC,
                  ),

                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xFFD8C8A5,
                    ),
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        18,

                    vertical:
                        12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final codigoAcceso =
        codigo?.codigoAcceso.trim() ?? '';

    final nombreCompleto =
        codigo?.nombreCompleto.trim() ?? '';

    if (codigoAcceso.isEmpty) {
      return SizedBox(
        width:
            double.infinity,

        height:
            280,

        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Container(
                width:
                    58,

                height:
                    58,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3EAD8,
                  ),

                  shape:
                      BoxShape.circle,

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE4D2AA,
                    ),
                  ),
                ),

                child: Icon(
                  Icons
                      .qr_code_2_rounded,

                  color:
                      goldDark,

                  size:
                      32,
                ),
              ),

              const SizedBox(
                height:
                    14,
              ),

              Text(
                'No hay un código de acceso disponible.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      textSecondary,

                  fontSize:
                      14,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width:
              double.infinity,

          padding:
              EdgeInsets.symmetric(
            horizontal:
                pantallaPequena
                    ? 10
                    : 16,

            vertical:
                pantallaPequena
                    ? 16
                    : 20,
          ),

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              16,
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
                      0.06,
                ),

                blurRadius:
                    14,

                offset:
                    const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),

          child: LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              return SizedBox(
                width:
                    constraints.maxWidth,

                height:
                    pantallaPequena
                        ? 100
                        : 120,

                child:
                    BarcodeWidget(
                  barcode:
                      Barcode.code128(),

                  data:
                      codigoAcceso,

                  drawText:
                      false,

                  color:
                      Colors.black,

                  backgroundColor:
                      Colors.white,

                  width:
                      constraints.maxWidth,

                  height:
                      pantallaPequena
                          ? 100
                          : 120,

                  padding:
                      EdgeInsets.zero,
                ),
              );
            },
          ),
        ),

        const SizedBox(
          height:
              24,
        ),

        Container(
          width:
              58,

          height:
              58,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF3EAD8,
            ),

            shape:
                BoxShape.circle,

            border:
                Border.all(
              color:
                  const Color(
                0xFFE4D2AA,
              ),
            ),
          ),

          child: Icon(
            Icons
                .person_outline_rounded,

            color:
                goldDark,

            size:
                30,
          ),
        ),

        const SizedBox(
          height:
              14,
        ),

        Text(
          'Código de acceso de',

          textAlign:
              TextAlign.center,

          style:
              TextStyle(
            color:
                textSecondary,

            fontSize:
                13,
          ),
        ),

        const SizedBox(
          height:
              5,
        ),

        Text(
          nombreCompleto.isNotEmpty
              ? nombreCompleto
              : 'Cliente GymFlow',

          textAlign:
              TextAlign.center,

          style:
              TextStyle(
            color:
                textPrimary,

            fontSize:
                pantallaPequena
                    ? 18
                    : 20,

            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(
          height:
              24,
        ),

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF8F4EC,
            ),

            borderRadius:
                BorderRadius.circular(
              14,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFFE8DDC8,
              ),
            ),
          ),

          child: Column(
            children: [
              Text(
                'TU CÓDIGO',

                textAlign:
                    TextAlign.center,

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

              const SizedBox(
                height:
                    9,
              ),

              FittedBox(
                fit:
                    BoxFit.scaleDown,

                child: Text(
                  codigoAcceso,

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        textPrimary,

                    fontSize:
                        pantallaPequena
                            ? 19
                            : 22,

                    fontWeight:
                        FontWeight.w800,

                    letterSpacing:
                        1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height:
              18,
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

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                Icons
                    .brightness_high_outlined,

                color:
                    goldDark,

                size:
                    18,
              ),

              const SizedBox(
                width:
                    9,
              ),

              Expanded(
                child: Text(
                  'El brillo de la pantalla aumenta automáticamente para facilitar la lectura del código.',

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
    );
  }
}