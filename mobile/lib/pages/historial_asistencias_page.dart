import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/asistencia_cliente.dart';
import '../services/asistencia_service.dart';

class HistorialAsistenciasPage
    extends StatefulWidget {
  const HistorialAsistenciasPage({
    super.key,
  });

  @override
  State<HistorialAsistenciasPage>
      createState() =>
          _HistorialAsistenciasPageState();
}

class _HistorialAsistenciasPageState
    extends State<HistorialAsistenciasPage> {
  final _formKey =
      GlobalKey<FormState>();

  final asistenciaService =
      AsistenciaService();

  final idController =
      TextEditingController();

  bool cargando = false;
  bool consultaRealizada = false;

  String error = '';

  List<AsistenciaCliente> asistencias =
      [];

  @override
  void dispose() {
    idController.dispose();

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

  String? validarId(
    String? value,
  ) {
    final texto =
        value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el ID del cliente.';
    }

    final id =
        int.tryParse(texto);

    if (id == null ||
        id <= 0) {
      return 'El ID debe ser mayor a 0.';
    }

    return null;
  }

  Future<void> consultar() async {
    if (cargando) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      error = '';
      asistencias = [];
      consultaRealizada = false;
    });

    if (!(_formKey.currentState
            ?.validate() ??
        false)) {
      return;
    }

    final id =
        int.parse(
      idController.text.trim(),
    );

    setState(() {
      cargando = true;
    });

    try {
      final lista =
          await asistenciaService
              .consultarPorCliente(
        id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        asistencias = lista;
        consultaRealizada = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        error =
            limpiarException(e);

        consultaRealizada = true;
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
                          'Historial de Asistencias',

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
                          'Consulta las entradas registradas de un cliente.',

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
                                      .person_search_outlined,

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
                                  'Buscar cliente',

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
                                idController,

                            enabled:
                                !cargando,

                            validator:
                                validarId,

                            keyboardType:
                                TextInputType
                                    .number,

                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,

                              LengthLimitingTextInputFormatter(
                                9,
                              ),
                            ],

                            textInputAction:
                                TextInputAction
                                    .search,

                            onFieldSubmitted:
                                (_) {
                              consultar();
                            },

                            style:
                                const TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  14,

                              fontWeight:
                                  FontWeight.w600,
                            ),

                            decoration:
                                InputDecoration(
                              labelText:
                                  'ID de cliente',

                              hintText:
                                  'Ej. 15',

                              filled:
                                  true,

                              fillColor:
                                  const Color(
                                0xFFF8F4EC,
                              ),

                              prefixIcon:
                                  const Icon(
                                Icons
                                    .person_search_outlined,

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
                                16,
                          ),

                          SizedBox(
                            width:
                                double.infinity,

                            height:
                                52,

                            child:
                                FilledButton.icon(
                              onPressed:
                                  cargando
                                      ? null
                                      : consultar,

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
                                              .search_rounded,

                                          size:
                                              21,
                                        ),

                              label: Text(
                                cargando
                                    ? 'Consultando...'
                                    : 'Consultar asistencias',
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

                  const SizedBox(
                    height:
                        24,
                  ),

                  if (cargando)
                    const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          24,
                        ),

                        child:
                            CircularProgressIndicator(
                          color:
                              gold,
                        ),
                      ),
                    ),

                  if (!cargando &&
                      error.isNotEmpty)
                    _mensaje(
                      error,
                      error: true,
                    ),

                  if (!cargando &&
                      error.isEmpty &&
                      consultaRealizada &&
                      asistencias.isEmpty)
                    _mensaje(
                      'Este cliente no tiene asistencias registradas.',
                    ),

                  if (!cargando &&
                      error.isEmpty &&
                      asistencias.isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Asistencias encontradas',

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

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                11,

                            vertical:
                                6,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF3EAD8,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFD8C392,
                              ),
                            ),
                          ),

                          child: Text(
                            '${asistencias.length}',

                            style:
                                const TextStyle(
                              color:
                                  goldDark,

                              fontSize:
                                  12,

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    ...asistencias.map(
                      _tarjeta,
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

  Widget _tarjeta(
    AsistenciaCliente a,
  ) {
    final fecha =
        a.fechaHoraDateTime;

    final fechaTexto =
        fecha == null
            ? 'Sin fecha'
            : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    final horaTexto =
        fecha == null
            ? 'Sin hora'
            : '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            12,
      ),

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFFFDF8,
        ),

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
                  0.04,
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

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width:
                    42,

                height:
                    42,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3EAD8,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
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
                      .event_available_outlined,

                  color:
                      Color(
                    0xFF8A6814,
                  ),

                  size:
                      22,
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              Expanded(
                child: Text(
                  'Asistencia #${a.idAsistencia}',

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF2F2A24,
                    ),

                    fontSize:
                        16,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          _dato(
            icon:
                Icons
                    .calendar_today_outlined,

            titulo:
                'Fecha',

            valor:
                fechaTexto,
          ),

          const SizedBox(
            height:
                11,
          ),

          _dato(
            icon:
                Icons
                    .schedule_outlined,

            titulo:
                'Hora',

            valor:
                horaTexto,
          ),

          const SizedBox(
            height:
                11,
          ),

          _dato(
            icon:
                Icons
                    .verified_outlined,

            titulo:
                'Estado',

            valor:
                a.estadoAcceso.isEmpty
                    ? 'Sin información'
                    : a.estadoAcceso,
          ),

          const SizedBox(
            height:
                11,
          ),

          _dato(
            icon:
                Icons
                    .input_rounded,

            titulo:
                'Origen',

            valor:
                a.origenRegistro.isEmpty
                    ? 'Sin información'
                    : a.origenRegistro,
          ),
        ],
      ),
    );
  }

  Widget _dato({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,

          color:
              const Color(
            0xFF8A6814,
          ),

          size:
              18,
        ),

        const SizedBox(
          width:
              10,
        ),

        Expanded(
          child: RichText(
            text: TextSpan(
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF2F2A24,
                ),

                fontSize:
                    13,

                height:
                    1.4,
              ),

              children: [
                TextSpan(
                  text:
                      '$titulo: ',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                TextSpan(
                  text:
                      valor,

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF777067,
                    ),

                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mensaje(
    String mensaje, {
    bool error = false,
  }) {
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
            error
                ? const Color(
                    0xFFFFF5F5,
                  )
                : const Color(
                    0xFFFFFDF8,
                  ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              error
                  ? const Color(
                      0xFFEDB9BF,
                    )
                  : const Color(
                      0xFFE5DDCF,
                    ),
        ),
      ),

      child: Column(
        children: [
          Icon(
            error
                ? Icons
                    .error_outline_rounded
                : Icons
                    .event_busy_outlined,

            color:
                error
                    ? const Color(
                        0xFFC21B2E,
                      )
                    : const Color(
                        0xFF8A6814,
                      ),

            size:
                34,
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
                TextStyle(
              color:
                  error
                      ? const Color(
                          0xFF8F2030,
                        )
                      : const Color(
                          0xFF777067,
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