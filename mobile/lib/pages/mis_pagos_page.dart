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

      if (mensaje.startsWith('Exception:')) {
        mensaje =
            mensaje
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
        entero.split('').reversed.toList();

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
                  alpha: 0.45,
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
                color: gold,
              ),
            ),
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),

        bottom:
            PreferredSize(
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
              Color(
                0xFF29292E,
              ),
              coal,
              Color(
                0xFF0D0D0F,
              ),
            ],

            stops: [
              0.0,
              0.35,
              1.0,
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

            child:
                SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

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
                        'CLIENTE',

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
                        'Mis Pagos',

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
                        'Consulta tus pagos y renovaciones registrados.',

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

                          border:
                              Border.all(
                            color:
                                gold.withValues(
                              alpha:
                                  0.16,
                            ),
                          ),
                        ),

                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Historial de pagos',

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
                                  7,
                            ),

                            const Text(
                              'Aquí puedes revisar los pagos registrados en tu cuenta.',

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

                            _buildContenido(
                              gold:
                                  gold,

                              silver:
                                  silver,
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
    required Color silver,
  }) {
    if (cargando) {
      return SizedBox(
        width:
            double.infinity,

        height:
            150,

        child:
            Center(
          child:
              Column(
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
                      silver,

                  fontSize:
                      14,
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
            0xFF990000,
          ).withValues(
            alpha:
                0.17,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFF990000,
            ).withValues(
              alpha:
                  0.80,
            ),
          ),
        ),

        child:
            Column(
          children: [
            const Icon(
              Icons.error_outline,
              color:
                  Color(
                0xFFFFAAAA,
              ),
              size:
                  38,
            ),

            const SizedBox(
              height:
                  10,
            ),

            Text(
              error,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFFFFAAAA,
                ),

                fontSize:
                    14,
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
                  Icon(
                Icons.refresh,
                color:
                    gold,
              ),

              label:
                  Text(
                'Reintentar',

                style:
                    TextStyle(
                  color:
                      gold,
                ),
              ),

              style:
                  OutlinedButton.styleFrom(
                side:
                    BorderSide(
                  color:
                      gold.withValues(
                    alpha:
                        0.50,
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
            0xFF101012,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                gold.withValues(
              alpha:
                  0.25,
            ),
          ),
        ),

        child:
            const Column(
          children: [
            Icon(
              Icons.payments_outlined,
              color:
                  Color(
                0xFF777777,
              ),
              size:
                  38,
            ),

            SizedBox(
              height:
                  12,
            ),

            Text(
              'Aún no tienes pagos registrados.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Color(
                  0xFF888888,
                ),

                fontSize:
                    14,
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
        Text(
          'Pagos registrados: ${pagos.length}',

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
          i < pagos.length;
          i++
        ) ...[
          _buildPagoCard(
            pago:
                pagos[i],

            gold:
                gold,

            silver:
                silver,
          ),

          if (
            i <
                pagos.length -
                    1
          )
            const SizedBox(
              height:
                  14,
            ),
        ],
      ],
    );
  }

  Widget _buildPagoCard({
    required PagoCliente pago,
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
          0xFF101012,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              gold.withValues(
            alpha:
                0.16,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'PAGO #${pago.idPago}',

            style:
                TextStyle(
              color:
                  gold,

              fontSize:
                  13,

              fontWeight:
                  FontWeight.bold,

              letterSpacing:
                  0.6,
            ),
          ),

          const SizedBox(
            height:
                13,
          ),

          _buildFila(
            etiqueta:
                'Fecha',

            valor:
                formatearFecha(
              pago,
            ),

            silver:
                silver,
          ),

          _buildFila(
            etiqueta:
                'Hora',

            valor:
                formatearHora(
              pago,
            ),

            silver:
                silver,
          ),

          _buildFila(
            etiqueta:
                'Monto',

            valor:
                formatearMonto(
              pago.monto,
            ),

            silver:
                silver,
          ),

          _buildFila(
            etiqueta:
                'Concepto',

            valor:
                pago.tipoPago.trim().isNotEmpty
                    ? pago.tipoPago
                    : 'Sin concepto',

            silver:
                silver,
          ),
        ],
      ),
    );
  }

  Widget _buildFila({
    required String etiqueta,
    required String valor,
    required Color silver,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            7,
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

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
                18,
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