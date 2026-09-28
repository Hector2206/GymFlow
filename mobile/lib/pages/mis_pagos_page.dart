import 'package:flutter/material.dart';

import '../models/pago_cliente.dart';
import '../services/pago_service.dart';

class MisPagosPage extends StatefulWidget {
  const MisPagosPage({
    super.key,
  });

  @override
  State<MisPagosPage> createState() =>
      _MisPagosPageState();
}

class _MisPagosPageState
    extends State<MisPagosPage> {
  final PagoService pagoService =
      PagoService();

  bool cargando = true;
  String error = '';

  List<PagoCliente> pagos = [];

  @override
  void initState() {
    super.initState();

    cargarPagos();
  }

  Future<void> cargarPagos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final resultado =
          await pagoService.obtenerMisPagos();

      if (!mounted) {
        return;
      }

      setState(() {
        pagos = resultado;
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
            'No fue posible cargar tus pagos.';
      }

      setState(() {
        error = mensaje;
        pagos = [];
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
    PagoCliente pago,
  ) {
    final fecha =
        pago.fechaTransaccionDateTime;

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
    PagoCliente pago,
  ) {
    final fecha =
        pago.fechaTransaccionDateTime;

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

  String formatearMonto(
    double monto,
  ) {
    final partes =
        monto
            .toStringAsFixed(
              2,
            )
            .split(
              '.',
            );

    final entero =
        partes[0];

    final decimal =
        partes.length > 1
            ? partes[1]
            : '00';

    final caracteres =
        entero
            .split('')
            .reversed
            .toList();

    final resultado =
        <String>[];

    for (
      int i = 0;
      i < caracteres.length;
      i++
    ) {
      if (
        i > 0 &&
        i % 3 == 0
      ) {
        resultado.add(
          ',',
        );
      }

      resultado.add(
        caracteres[i],
      );
    }

    final enteroFormateado =
        resultado.reversed.join();

    return '\$$enteroFormateado.$decimal MXN';
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
            left:
                14,
            top:
                6,
            bottom:
                6,
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

        child: SafeArea(
          top:
              false,

          child:
              RefreshIndicator(
            onRefresh:
                cargarPagos,

            color:
                gold,

            backgroundColor:
                surface,

            child:
                SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                30,
                20,
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
                            const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
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

                            SizedBox(
                              height:
                                  7,
                            ),

                            Text(
                              'Mis Pagos',

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
                              'Consulta tus pagos y renovaciones registrados.',

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
                                      40,

                                  height:
                                      40,

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
                                        .payments_outlined,

                                    color:
                                        goldDark,

                                    size:
                                        21,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      12,
                                ),

                                const Expanded(
                                  child:
                                      Text(
                                    'Historial de pagos',

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
                                  8,
                            ),

                            const Text(
                              'Aquí puedes revisar los pagos registrados en tu cuenta. Desliza hacia abajo para actualizar.',

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

                            const SizedBox(
                              height:
                                  20,
                            ),

                            _buildContenido(
                              gold:
                                  gold,

                              goldDark:
                                  goldDark,

                              textPrimary:
                                  textPrimary,

                              textSecondary:
                                  textSecondary,
                            ),
                          ],
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

  Widget _buildContenido({
    required Color gold,
    required Color goldDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (cargando) {
      return SizedBox(
        width:
            double.infinity,

        height:
            150,

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
                    16,
              ),

              Text(
                'Cargando pagos...',

                style:
                    TextStyle(
                  color:
                      textSecondary,

                  fontSize:
                      13,

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
            0xFFFFF5F5,
          ),

          borderRadius:
              BorderRadius.circular(
            14,
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
                  50,

              height:
                  50,

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
                    30,
              ),
            ),

            const SizedBox(
              height:
                  12,
            ),

            Text(
              error,

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

            const SizedBox(
              height:
                  14,
            ),

            OutlinedButton.icon(
              onPressed:
                  cargarPagos,

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
                    const Color(
                  0xFF8F2030,
                ),

                backgroundColor:
                    Colors.white,

                side:
                    const BorderSide(
                  color:
                      Color(
                    0xFFE4B8B8,
                  ),
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
          ],
        ),
      );
    }

    if (pagos.isEmpty) {
      return Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.symmetric(
          horizontal:
              18,

          vertical:
              28,
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
            Container(
              width:
                  54,

              height:
                  54,

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
                    .payments_outlined,

                color:
                    goldDark,

                size:
                    29,
              ),
            ),

            const SizedBox(
              height:
                  13,
            ),

            Text(
              'Aún no tienes pagos registrados.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    textSecondary,

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

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pagos registrados',

                style:
                    TextStyle(
                  color:
                      textPrimary,

                  fontSize:
                      15,

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
                '${pagos.length}',

                style:
                    TextStyle(
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

        for (
          int i = 0;
          i < pagos.length;
          i++
        ) ...[
          _buildPagoCard(
            pago:
                pagos[i],
          ),

          if (i <
              pagos.length - 1)
            const SizedBox(
              height:
                  12,
            ),
        ],
      ],
    );
  }

  Widget _buildPagoCard({
    required PagoCliente pago,
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
          0xFFFFFDF8,
        ),

        borderRadius:
            BorderRadius.circular(
          15,
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
                  0.035,
            ),

            blurRadius:
                12,

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
                      .receipt_long_outlined,

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
                  'Pago #${pago.idPago}',

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF2F2A24,
                    ),

                    fontSize:
                        15,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      10,

                  vertical:
                      5,
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
                ),

                child: Text(
                  formatearMonto(
                    pago.monto,
                  ),

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF8A6814,
                    ),

                    fontSize:
                        11,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                15,
          ),

          _buildFila(
            icon:
                Icons
                    .calendar_today_outlined,

            etiqueta:
                'Fecha',

            valor:
                formatearFecha(
              pago,
            ),
          ),

          _buildFila(
            icon:
                Icons
                    .schedule_outlined,

            etiqueta:
                'Hora',

            valor:
                formatearHora(
              pago,
            ),
          ),

          _buildFila(
            icon:
                Icons
                    .attach_money_rounded,

            etiqueta:
                'Monto',

            valor:
                formatearMonto(
              pago.monto,
            ),
          ),

          _buildFila(
            icon:
                Icons
                    .receipt_long_outlined,

            etiqueta:
                'Concepto',

            valor:
                pago.tipoPago
                        .trim()
                        .isNotEmpty
                    ? pago.tipoPago
                    : 'Sin concepto',
          ),
        ],
      ),
    );
  }

  Widget _buildFila({
    required IconData icon,
    required String etiqueta,
    required String valor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            7,
      ),

      child: Row(
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
            child: Text(
              etiqueta,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF777067,
                ),

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(
            width:
                18,
          ),

          Flexible(
            child: Text(
              valor,

              textAlign:
                  TextAlign.right,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF2F2A24,
                ),

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}