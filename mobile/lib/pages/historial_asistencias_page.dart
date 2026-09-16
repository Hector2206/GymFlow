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
  State<HistorialAsistenciasPage> createState() =>
      _HistorialAsistenciasPageState();
}

class _HistorialAsistenciasPageState
    extends State<HistorialAsistenciasPage> {
  final AsistenciaService asistenciaService =
      AsistenciaService();

  final TextEditingController idClienteController =
      TextEditingController();

  bool cargando = false;
  bool consultaRealizada = false;

  String error = '';

  List<AsistenciaCliente> asistencias = [];

  @override
  void dispose() {
    idClienteController.dispose();

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

  Future<void> consultar() async {
    final idCliente =
        int.tryParse(
      idClienteController.text.trim(),
    );

    setState(() {
      error = '';
      asistencias = [];
      consultaRealizada = false;
    });

    if (idCliente == null ||
        idCliente <= 0) {
      setState(() {
        error =
            'Ingresa un ID de cliente válido.';
      });

      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final resultado =
          await asistenciaService
              .consultarPorCliente(
        idCliente,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        asistencias =
            resultado;

        consultaRealizada =
            true;
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

        consultaRealizada =
            true;
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  String formatearFecha(
    AsistenciaCliente asistencia,
  ) {
    final fecha =
        asistencia.fechaHoraDateTime;

    if (fecha == null) {
      return 'Sin fecha';
    }

    final dia =
        fecha.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final mes =
        fecha.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$dia/$mes/${fecha.year}';
  }

  String formatearHora(
    AsistenciaCliente asistencia,
  ) {
    final fecha =
        asistencia.fechaHoraDateTime;

    if (fecha == null) {
      return 'Sin hora';
    }

    var hora =
        fecha.hour;

    final periodo =
        hora >= 12
            ? 'p. m.'
            : 'a. m.';

    if (hora == 0) {
      hora = 12;
    } else if (hora > 12) {
      hora -= 12;
    }

    final minutos =
        fecha.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hora:$minutos $periodo';
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
                    'Historial de Asistencias',

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
                    'Consulta los registros de entrada de un cliente.',

                    style:
                        TextStyle(
                      color:
                          silver,

                      fontSize:
                          15,
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
                          'Buscar cliente',

                          style:
                              TextStyle(
                            color:
                                gold,

                            fontSize:
                                18,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        const Text(
                          'Ingresa el ID del cliente para consultar sus asistencias.',

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
                              20,
                        ),

                        TextField(
                          controller:
                              idClienteController,

                          keyboardType:
                              TextInputType.number,

                          textInputAction:
                              TextInputAction.search,

                          enabled:
                              !cargando,

                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],

                          onSubmitted:
                              (_) {
                            consultar();
                          },

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),

                          decoration:
                              InputDecoration(
                            labelText:
                                'ID de cliente',

                            hintText:
                                'Ej. 15',

                            prefixIcon:
                                const Icon(
                              Icons.person_search_outlined,
                              color:
                                  gold,
                            ),

                            labelStyle:
                                const TextStyle(
                              color:
                                  silver,
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
                              50,

                          child:
                              FilledButton.icon(
                            onPressed:
                                cargando
                                    ? null
                                    : consultar,

                            icon:
                                const Icon(
                              Icons.search,
                            ),

                            label:
                                Text(
                              cargando
                                  ? 'Consultando...'
                                  : 'Consultar asistencias',
                            ),

                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  gold,

                              foregroundColor:
                                  Colors.black,

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

                  const SizedBox(
                    height:
                        24,
                  ),

                  if (cargando)
                    const Center(
                      child:
                          Padding(
                        padding:
                            EdgeInsets.all(
                          30,
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
                    _buildMensajeError(
                      error,
                    ),

                  if (!cargando &&
                      error.isEmpty &&
                      consultaRealizada &&
                      asistencias.isEmpty)
                    _buildVacio(),

                  if (!cargando &&
                      error.isEmpty &&
                      asistencias.isNotEmpty)
                    _buildResultados(
                      gold:
                          gold,

                      silver:
                          silver,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMensajeError(
    String mensaje,
  ) {
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
            const Color(
          0xFF2A1111,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
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
          Row(
        children: [
          const Icon(
            Icons.error_outline,
            color:
                Color(
              0xFFE45C5C,
            ),
          ),

          const SizedBox(
            width:
                14,
          ),

          Expanded(
            child:
                Text(
              mensaje,

              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal:
            20,

        vertical:
            30,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF171719,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFD4AF37,
          ).withValues(
            alpha:
                0.20,
          ),
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color:
                Color(
              0xFF777777,
            ),
            size:
                42,
          ),

          SizedBox(
            height:
                12,
          ),

          Text(
            'Este cliente no tiene asistencias registradas.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
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

  Widget _buildResultados({
    required Color gold,
    required Color silver,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Asistencias encontradas: ${asistencias.length}',

          style:
              TextStyle(
            color:
                silver,

            fontSize:
                13,
          ),
        ),

        const SizedBox(
          height:
              14,
        ),

        for (
          int i = 0;
          i < asistencias.length;
          i++
        ) ...[
          _buildAsistencia(
            asistencia:
                asistencias[i],

            gold:
                gold,

            silver:
                silver,
          ),

          if (i <
              asistencias.length - 1)
            const SizedBox(
              height:
                  14,
            ),
        ],
      ],
    );
  }

  Widget _buildAsistencia({
    required AsistenciaCliente asistencia,
    required Color gold,
    required Color silver,
  }) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF171719,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
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
          Text(
            'ASISTENCIA #${asistencia.idAsistencia}',

            style:
                TextStyle(
              color:
                  gold,

              fontSize:
                  13,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          _fila(
            'Fecha',
            formatearFecha(
              asistencia,
            ),
            silver,
          ),

          _fila(
            'Hora',
            formatearHora(
              asistencia,
            ),
            silver,
          ),

          _fila(
            'Estado',
            asistencia.estadoAcceso.isNotEmpty
                ? asistencia.estadoAcceso
                : 'Sin estado',
            silver,
          ),

          _fila(
            'Origen',
            asistencia.origenRegistro.isNotEmpty
                ? asistencia.origenRegistro
                : 'Sin información',
            silver,
          ),
        ],
      ),
    );
  }

  Widget _fila(
    String etiqueta,
    String valor,
    Color silver,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            6,
      ),

      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              etiqueta,

              style:
                  TextStyle(
                color:
                    silver,

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

                fontSize:
                    13,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}