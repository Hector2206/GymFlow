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
  Widget build(BuildContext context) {
    const gold =
        Color(0xFFD4AF37);
    const dark =
        Color(0xFF101012);
    const coal =
        Color(0xFF1A1A1D);

    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),
      ),
      body: SingleChildScrollView(
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
                    'Control de Acceso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      22,
                    ),
                    decoration: BoxDecoration(
                      color: coal,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller:
                              codigoController,
                          focusNode:
                              codigoFocus,
                          enabled:
                              !procesando,
                          validator:
                              validarCodigo,
                          maxLength: 80,
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
                                Colors.white,
                            fontSize: 17,
                          ),
                          decoration:
                              InputDecoration(
                            labelText:
                                'Código de acceso',
                            hintText:
                                'Escanea o escribe el código',
                            counterText: '',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .barcode_reader,
                              color: gold,
                            ),
                            filled: true,
                            fillColor: dark,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 50,
                          child:
                              FilledButton.icon(
                            onPressed:
                                procesando
                                    ? null
                                    : registrar,
                            icon: procesando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .check_circle_outline,
                                  ),
                            label: Text(
                              procesando
                                  ? 'Validando...'
                                  : 'Validar acceso',
                            ),
                            style:
                                FilledButton
                                    .styleFrom(
                              backgroundColor:
                                  gold,
                              foregroundColor:
                                  Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          "El lector puede enviar ASIS'TEST'001; GymFlow lo normaliza automáticamente a ASIS-TEST-001.",
                          style: TextStyle(
                            color:
                                Color(
                              0xFFA9A9A9,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    _rechazado(error),
                  ],

                  if (resultado != null) ...[
                    const SizedBox(
                      height: 20,
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
    );
  }

  Widget _aprobado(
    ResultadoRegistroAsistencia r,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            const Color(0xFF10271A),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF49D17D),
            size: 48,
          ),
          const Text(
            'ACCESO APROBADO',
            style: TextStyle(
              color: Color(0xFF49D17D),
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (r.nombreCompleto
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              r.nombreCompleto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
          if (r.nombrePlan
              .isNotEmpty)
            Text(
              'Membresía: ${r.nombrePlan}',
              style: const TextStyle(
                color:
                    Color(
                  0xFFA9A9A9,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rechazado(
    String mensaje,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            const Color(0xFF2A1111),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cancel,
            color: Color(0xFFE45C5C),
            size: 45,
          ),
          const SizedBox(height: 8),
          const Text(
            'ACCESO RECHAZADO',
            style: TextStyle(
              color: Color(0xFFE45C5C),
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}