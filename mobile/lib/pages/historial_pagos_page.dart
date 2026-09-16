import 'package:flutter/material.dart';

import '../models/cliente_resumen.dart';
import '../models/pago_cliente.dart';
import '../services/cliente_consulta_service.dart';
import '../services/pago_service.dart';

class HistorialPagosPage extends StatefulWidget {
  const HistorialPagosPage({
    super.key,
  });

  @override
  State<HistorialPagosPage> createState() =>
      _HistorialPagosPageState();
}

class _HistorialPagosPageState
    extends State<HistorialPagosPage> {
  final ClienteConsultaService clienteConsultaService =
      ClienteConsultaService();

  final PagoService pagoService =
      PagoService();

  List<ClienteResumen> clientes = [];
  List<PagoCliente> pagos = [];

  int? idCliente;

  bool cargandoClientes = true;
  bool cargandoPagos = false;
  bool consultaRealizada = false;

  String error = '';

  @override
  void initState() {
    super.initState();

    cargarClientes();
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

  Future<void> cargarClientes() async {
    setState(() {
      cargandoClientes = true;
      error = '';
    });

    try {
      final resultado =
          await clienteConsultaService
              .obtenerClientes();

      if (!mounted) {
        return;
      }

      setState(() {
        clientes =
            resultado;

        cargandoClientes =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cargandoClientes =
            false;

        error =
            limpiarException(
          e,
        );
      });
    }
  }

  Future<void> consultarPagos() async {
    setState(() {
      error = '';
      pagos = [];
      consultaRealizada = false;
    });

    if (idCliente == null ||
        idCliente! <= 0) {
      setState(() {
        error =
            'Selecciona un cliente.';
      });

      return;
    }

    setState(() {
      cargandoPagos = true;
    });

    try {
      final resultado =
          await pagoService
              .consultarPagosCliente(
        idCliente!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        pagos =
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
          cargandoPagos = false;
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
    return '\$${monto.toStringAsFixed(2)} MXN';
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
                    'RECEPCIÓN',

                    style:
                        TextStyle(
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
                    'Historial de Pagos',

                    style:
                        TextStyle(
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
                    'Consulta los pagos registrados de los clientes.',

                    style:
                        TextStyle(
                      color: silver,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
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
                      color: coal,

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      border:
                          Border.all(
                        color:
                            gold.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Buscar cliente',

                          style:
                              TextStyle(
                            color: gold,

                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'Selecciona un cliente para consultar su historial.',

                          style:
                              TextStyle(
                            color: silver,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        if (cargandoClientes)
                          const Center(
                            child:
                                Padding(
                              padding:
                                  EdgeInsets.all(
                                18,
                              ),

                              child:
                                  CircularProgressIndicator(
                                color: gold,
                              ),
                            ),
                          )
                        else if (error.isNotEmpty &&
                            clientes.isEmpty)
                          Column(
                            children: [
                              _buildError(
                                error,
                              ),

                              const SizedBox(
                                height: 12,
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
                                    Icons.refresh,
                                  ),

                                  label:
                                      const Text(
                                    'Reintentar',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          DropdownButtonFormField<int>(
                            initialValue:
                                idCliente,

                            isExpanded:
                                true,

                            dropdownColor:
                                coal,

                            decoration:
                                InputDecoration(
                              labelText:
                                  'Cliente',

                              labelStyle:
                                  const TextStyle(
                                color:
                                    silver,
                              ),

                              prefixIcon:
                                  const Icon(
                                Icons.person_search_outlined,
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
                                ),
                              ),
                            ),

                            hint:
                                const Text(
                              'Selecciona un cliente',

                              style:
                                  TextStyle(
                                color:
                                    silver,
                              ),
                            ),

                            items:
                                clientes
                                    .map(
                                      (
                                        cliente,
                                      ) =>
                                          DropdownMenuItem<int>(
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
                                                Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),

                            onChanged:
                                cargandoPagos
                                    ? null
                                    : (
                                        value,
                                      ) {
                                        setState(
                                          () {
                                            idCliente =
                                                value;

                                            pagos = [];
                                            error = '';
                                            consultaRealizada =
                                                false;
                                          },
                                        );
                                      },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          SizedBox(
                            width:
                                double.infinity,

                            height: 50,

                            child:
                                FilledButton.icon(
                              onPressed:
                                  cargandoPagos
                                      ? null
                                      : consultarPagos,

                              icon:
                                  const Icon(
                                Icons.search,
                              ),

                              label:
                                  Text(
                                cargandoPagos
                                    ? 'Consultando...'
                                    : 'Consultar pagos',
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
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (cargandoPagos)
                    const Center(
                      child:
                          Padding(
                        padding:
                            EdgeInsets.all(
                          30,
                        ),

                        child:
                            CircularProgressIndicator(
                          color: gold,
                        ),
                      ),
                    ),

                  if (!cargandoPagos &&
                      error.isNotEmpty &&
                      clientes.isNotEmpty)
                    _buildError(
                      error,
                    ),

                  if (!cargandoPagos &&
                      error.isEmpty &&
                      consultaRealizada &&
                      pagos.isEmpty)
                    _buildVacio(),

                  if (!cargandoPagos &&
                      error.isEmpty &&
                      pagos.isNotEmpty)
                    _buildListaPagos(
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

  Widget _buildListaPagos({
    required Color gold,
    required Color silver,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Pagos encontrados: ${pagos.length}',

          style:
              TextStyle(
            color: silver,
            fontSize: 13,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        for (
          int i = 0;
          i < pagos.length;
          i++
        ) ...[
          Container(
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
                  alpha: 0.18,
                ),
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'PAGO #${pagos[i].idPago}',

                  style:
                      TextStyle(
                    color: gold,

                    fontSize: 13,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _fila(
                  'Fecha',
                  formatearFecha(
                    pagos[i],
                  ),
                  silver,
                ),

                _fila(
                  'Hora',
                  formatearHora(
                    pagos[i],
                  ),
                  silver,
                ),

                _fila(
                  'Monto',
                  formatearMonto(
                    pagos[i].monto,
                  ),
                  silver,
                ),

                _fila(
                  'Concepto',
                  pagos[i].tipoPago.isNotEmpty
                      ? pagos[i].tipoPago
                      : 'Sin información',
                  silver,
                ),
              ],
            ),
          ),

          if (i <
              pagos.length - 1)
            const SizedBox(
              height: 14,
            ),
        ],
      ],
    );
  }

  Widget _buildVacio() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
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
            alpha: 0.20,
          ),
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,

            color:
                Color(
              0xFF777777,
            ),

            size: 42,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Este cliente no tiene pagos registrados.',

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

  Widget _buildError(
    String mensaje,
  ) {
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
          0xFF2A1111,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE45C5C,
          ),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.error_outline,

            color:
                Color(
              0xFFE45C5C,
            ),
          ),

          const SizedBox(
            width: 12,
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

  Widget _fila(
    String titulo,
    String valor,
    Color silver,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child: Row(
        children: [
          Expanded(
            child:
                Text(
              titulo,

              style:
                  TextStyle(
                color: silver,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(
            width: 16,
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

                fontSize: 13,

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