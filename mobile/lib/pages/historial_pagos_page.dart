import 'package:flutter/material.dart';

import '../models/cliente_resumen.dart';
import '../models/pago_cliente.dart';
import '../services/cliente_consulta_service.dart';
import '../services/pago_service.dart';

class HistorialPagosPage
    extends StatefulWidget {
  const HistorialPagosPage({
    super.key,
  });

  @override
  State<HistorialPagosPage>
      createState() =>
          _HistorialPagosPageState();
}

class _HistorialPagosPageState
    extends State<HistorialPagosPage> {
  final clienteConsultaService =
      ClienteConsultaService();

  final pagoService =
      PagoService();

  List<ClienteResumen> clientes = [];
  List<PagoCliente> pagos = [];

  int? idCliente;

  bool cargandoClientes = true;
  bool cargandoPagos = false;
  bool consultaRealizada = false;

  String errorClientes = '';
  String errorPagos = '';

  @override
  void initState() {
    super.initState();

    cargarClientes();
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

  Future<void> cargarClientes() async {
    setState(() {
      cargandoClientes = true;
      errorClientes = '';
    });

    try {
      final lista =
          await clienteConsultaService
              .obtenerClientes();

      if (!mounted) {
        return;
      }

      setState(() {
        clientes = lista;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorClientes =
            limpiarException(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          cargandoClientes = false;
        });
      }
    }
  }

  Future<void> consultar() async {
    if (cargandoPagos) {
      return;
    }

    setState(() {
      errorPagos = '';
      pagos = [];
      consultaRealizada = false;
    });

    if (idCliente == null ||
        idCliente! <= 0) {
      setState(() {
        errorPagos =
            'Selecciona un cliente válido.';
      });

      return;
    }

    setState(() {
      cargandoPagos = true;
    });

    try {
      final lista =
          await pagoService
              .consultarPagosCliente(
        idCliente!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        pagos = lista;
        consultaRealizada = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorPagos =
            limpiarException(e);

        consultaRealizada = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          cargandoPagos = false;
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
                          'Historial de Pagos',

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
                          'Consulta los pagos y renovaciones registrados de cada cliente.',

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
                                    .receipt_long_outlined,

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
                                'Consultar pagos',

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

                        if (cargandoClientes)
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
                          )
                        else if (errorClientes
                            .isNotEmpty)
                          Column(
                            children: [
                              _mensaje(
                                errorClientes,
                                error:
                                    true,
                              ),

                              const SizedBox(
                                height:
                                    12,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,

                                child:
                                    OutlinedButton.icon(
                                  onPressed:
                                      cargarClientes,

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
                                        const Color(
                                      0xFFFFF8F7,
                                    ),

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
                              ),
                            ],
                          )
                        else if (clientes
                            .isEmpty)
                          _mensaje(
                            'No hay clientes disponibles.',
                          )
                        else ...[
                          DropdownButtonFormField<
                              int>(
                            initialValue:
                                idCliente,

                            isExpanded:
                                true,

                            dropdownColor:
                                surface,

                            style:
                                const TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  14,

                              fontWeight:
                                  FontWeight.w500,
                            ),

                            icon:
                                const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,

                              color:
                                  goldDark,
                            ),

                            decoration:
                                InputDecoration(
                              labelText:
                                  'Cliente',

                              filled:
                                  true,

                              fillColor:
                                  const Color(
                                0xFFF8F4EC,
                              ),

                              prefixIcon:
                                  const Icon(
                                Icons
                                    .person_outline_rounded,

                                color:
                                    goldDark,

                                size:
                                    21,
                              ),

                              labelStyle:
                                  const TextStyle(
                                color:
                                    textSecondary,

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

                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  13,
                                ),
                              ),
                            ),

                            items:
                                clientes
                                    .map(
                                      (
                                        cliente,
                                      ) =>
                                          DropdownMenuItem<
                                              int>(
                                        value:
                                            cliente.idCliente,

                                        child:
                                            Text(
                                          '${cliente.nombreCompleto} · ID ${cliente.idCliente}',

                                          overflow:
                                              TextOverflow.ellipsis,

                                          style:
                                              const TextStyle(
                                            color:
                                                textPrimary,

                                            fontSize:
                                                14,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),

                            onChanged:
                                cargandoPagos
                                    ? null
                                    : (value) {
                                        setState(
                                          () {
                                            idCliente =
                                                value;

                                            pagos = [];

                                            errorPagos =
                                                '';

                                            consultaRealizada =
                                                false;
                                          },
                                        );
                                      },
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
                                  cargandoPagos
                                      ? null
                                      : consultar,

                              icon:
                                  cargandoPagos
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
                                cargandoPagos
                                    ? 'Consultando...'
                                    : 'Consultar pagos',
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
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:
                        24,
                  ),

                  if (cargandoPagos)
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

                  if (!cargandoPagos &&
                      errorPagos.isNotEmpty)
                    _mensaje(
                      errorPagos,
                      error:
                          true,
                    ),

                  if (!cargandoPagos &&
                      errorPagos.isEmpty &&
                      consultaRealizada &&
                      pagos.isEmpty)
                    _mensaje(
                      'Este cliente no tiene pagos registrados.',
                    ),

                  if (!cargandoPagos &&
                      errorPagos.isEmpty &&
                      pagos.isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pagos encontrados',

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
                            '${pagos.length}',

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

                    ...pagos.map(
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
    PagoCliente pago,
  ) {
    final fecha =
        pago.fechaTransaccionDateTime;

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
                      .payments_outlined,

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
                        16,

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
                  '\$${pago.monto.toStringAsFixed(2)}',

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF8A6814,
                    ),

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w800,
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
                    .attach_money_rounded,

            titulo:
                'Monto',

            valor:
                '\$${pago.monto.toStringAsFixed(2)} MXN',
          ),

          const SizedBox(
            height:
                11,
          ),

          _dato(
            icon:
                Icons
                    .receipt_long_outlined,

            titulo:
                'Concepto',

            valor:
                pago.tipoPago.isEmpty
                    ? 'Sin información'
                    : pago.tipoPago,
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
                    .receipt_long_outlined,

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