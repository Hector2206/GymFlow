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
                  'Historial de Pagos',
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
                      if (cargandoClientes)
                        const Padding(
                          padding:
                              EdgeInsets.all(
                            20,
                          ),
                          child:
                              CircularProgressIndicator(
                            color: gold,
                          ),
                        )
                      else if (errorClientes
                          .isNotEmpty)
                        Column(
                          children: [
                            _mensaje(
                              errorClientes,
                              error: true,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
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
                          isExpanded: true,
                          dropdownColor: coal,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Cliente',
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
                          items: clientes
                              .map(
                                (
                                  cliente,
                                ) =>
                                    DropdownMenuItem<
                                        int>(
                                  value:
                                      cliente
                                          .idCliente,
                                  child: Text(
                                    '${cliente.nombreCompleto} · ID ${cliente.idCliente}',
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
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
                          height: 16,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              FilledButton.icon(
                            onPressed:
                                cargandoPagos
                                    ? null
                                    : consultar,
                            icon:
                                const Icon(
                              Icons.search,
                            ),
                            label: Text(
                              cargandoPagos
                                  ? 'Consultando...'
                                  : 'Consultar pagos',
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
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (cargandoPagos)
                  const Center(
                    child:
                        CircularProgressIndicator(
                      color: gold,
                    ),
                  ),

                if (!cargandoPagos &&
                    errorPagos.isNotEmpty)
                  _mensaje(
                    errorPagos,
                    error: true,
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
                    pagos.isNotEmpty)
                  ...pagos.map(
                    _tarjeta,
                  ),
              ],
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

    final fechaTexto = fecha == null
        ? 'Sin fecha'
        : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    final horaTexto = fecha == null
        ? 'Sin hora'
        : '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF171719),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Pago #${pago.idPago}',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fecha: $fechaTexto',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            'Hora: $horaTexto',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            'Monto: \$${pago.monto.toStringAsFixed(2)} MXN',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            'Concepto: ${pago.tipoPago.isEmpty ? 'Sin información' : pago.tipoPago}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensaje(
    String mensaje, {
    bool error = false,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: error
            ? const Color(0xFF2A1111)
            : const Color(0xFF171719),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        mensaje,
        textAlign:
            TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}