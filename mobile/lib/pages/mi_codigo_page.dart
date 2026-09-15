import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

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
  }

  Future<void> cargarCodigo() async {
    setState(() {
      cargando = true;
      error = '';
      codigo = null;
    });

    try {
      final resultado =
          await codigoAccesoService.obtenerMiCodigo();

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

      if (mensaje.startsWith('Exception:')) {
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
  Widget build(BuildContext context) {
    const gold =
        Color(0xFFD4AF37);

    const coal =
        Color(0xFF1A1A1D);

    const silver =
        Color(0xFFA9A9A9);

    const dark =
        Color(0xFF101012);

    const errorColor =
        Color(0xFFE57373);

    return Scaffold(
      backgroundColor: dark,

      appBar: AppBar(
        backgroundColor: dark,
        elevation: 0,
        leadingWidth: 70,

        leading: Padding(
          padding: const EdgeInsets.only(
            left: 14,
            top: 6,
            bottom: 6,
          ),

          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),

              border: Border.all(
                color: gold.withValues(
                  alpha: 0.45,
                ),
              ),
            ),

            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },

              icon: const Icon(
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

            color: gold.withValues(
              alpha: 0.30,
            ),
          ),
        ),
      ),

      body: Container(
        width: double.infinity,

        decoration:
            const BoxDecoration(
          gradient: RadialGradient(
            center:
                Alignment.topCenter,

            radius: 1.5,

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

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'CLIENTE',

                      style: TextStyle(
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
                      'Mi Código de Acceso',

                      style: TextStyle(
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
                      'Presenta este código en recepción para registrar tu entrada.',

                      style: TextStyle(
                        color: silver,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    Container(
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
                            Color(
                              0xFF1D1D20,
                            ),
                            Color(
                              0xFF151517,
                            ),
                          ],
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        border: Border.all(
                          color:
                              gold.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),

                      child:
                          _buildContenido(
                        gold:
                            gold,
                        silver:
                            silver,
                        errorColor:
                            errorColor,
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

  Widget _buildContenido({
    required Color gold,
    required Color silver,
    required Color errorColor,
  }) {
    if (cargando) {
      return SizedBox(
        height: 280,

        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              CircularProgressIndicator(
                color: gold,
                strokeWidth: 3,
              ),

              const SizedBox(
                height: 18,
              ),

              Text(
                'Cargando tu código...',

                style: TextStyle(
                  color: silver,
                  fontSize: 15,
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
        width: double.infinity,
        height: 280,

        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                Icons.error_outline,
                color: errorColor,
                size: 42,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'No se pudo cargar tu código',

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: errorColor,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                error,

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: silver,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              OutlinedButton.icon(
                onPressed:
                    cargarCodigo,

                icon: Icon(
                  Icons.refresh,
                  color: gold,
                ),

                label: Text(
                  'Reintentar',

                  style: TextStyle(
                    color: gold,
                  ),
                ),

                style:
                    OutlinedButton.styleFrom(
                  side: BorderSide(
                    color:
                        gold.withValues(
                      alpha: 0.55,
                    ),
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
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
        width: double.infinity,
        height: 280,

        child: Center(
          child: Text(
            'No hay un código de acceso disponible.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color: silver,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),

          child: BarcodeWidget(
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

            height:
                110,

            width:
                double.infinity,
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        Text(
          'Código de acceso de',

          textAlign:
              TextAlign.center,

          style: TextStyle(
            color: silver,
            fontSize: 14,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          nombreCompleto.isNotEmpty
              ? nombreCompleto
              : 'Cliente GymFlow',

          textAlign:
              TextAlign.center,

          style: TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        Text(
          'TU CÓDIGO',

          textAlign:
              TextAlign.center,

          style: TextStyle(
            color: silver,
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          codigoAcceso,

          textAlign:
              TextAlign.center,

          style: const TextStyle(
            color:
                Colors.white,
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}