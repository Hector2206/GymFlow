import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cliente_resumen.dart';
import '../services/cliente_consulta_service.dart';
import '../services/pago_service.dart';

class RegistrarPagoPage extends StatefulWidget {
  const RegistrarPagoPage({
    super.key,
  });

  @override
  State<RegistrarPagoPage> createState() =>
      _RegistrarPagoPageState();
}

class _RegistrarPagoPageState
    extends State<RegistrarPagoPage> {
  final _formKey =
      GlobalKey<FormState>();

  final clienteConsultaService =
      ClienteConsultaService();

  final pagoService =
      PagoService();

  final montoController =
      TextEditingController();

  List<ClienteResumen> clientes = [];

  int? idCliente;
  String? tipoPago;

  bool cargandoClientes = true;
  bool procesandoPago = false;

  String errorClientes = '';
  String errorFormulario = '';

  ResultadoRegistroPago? resultado;

  @override
  void initState() {
    super.initState();

    cargarClientes();
  }

  @override
  void dispose() {
    montoController.dispose();

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

  Future<void> cargarClientes() async {
    if (!mounted) {
      return;
    }

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

  String? validarMonto(
    String? value,
  ) {
    final texto =
        value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el monto del pago.';
    }

    final monto =
        double.tryParse(texto);

    if (monto == null ||
        !monto.isFinite) {
      return 'Ingresa un monto válido.';
    }

    if (monto <= 0) {
      return 'El monto debe ser mayor a \$0.';
    }

    if (monto > 100000) {
      return 'Verifica el monto ingresado.';
    }

    return null;
  }

  Future<void> registrarPago() async {
    FocusScope.of(context).unfocus();

    if (procesandoPago) {
      return;
    }

    setState(() {
      errorFormulario = '';
      resultado = null;
    });

    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    final monto =
        double.tryParse(
      montoController.text.trim(),
    );

    if (idCliente == null ||
        idCliente! <= 0 ||
        monto == null ||
        tipoPago == null) {
      return;
    }

    setState(() {
      procesandoPago = true;
    });

    try {
      final respuesta =
          await pagoService.registrarPago(
        idCliente: idCliente!,
        monto: monto,
        tipoPago: tipoPago!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        resultado = respuesta;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorFormulario =
            limpiarException(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          procesandoPago = false;
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
            child: Form(
              key: _formKey,
              autovalidateMode:
                  AutovalidateMode
                      .onUserInteraction,
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
                    'Registrar Pago',
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
                      border: Border.all(
                        color:
                            gold.withValues(
                          alpha: 0.18,
                        ),
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
                          _error(
                            errorClientes,
                            botonReintentar: true,
                          )
                        else if (clientes
                            .isEmpty)
                          _error(
                            'No hay clientes disponibles para registrar pagos.',
                          )
                        else ...[
                          DropdownButtonFormField<
                              int>(
                            initialValue:
                                idCliente,
                            isExpanded: true,
                            dropdownColor:
                                coal,
                            decoration:
                                _decoracion(
                              'Cliente',
                            ),
                            items: clientes
                                .map(
                                  (
                                    cliente,
                                  ) =>
                                      DropdownMenuItem<
                                          int>(
                                    value: cliente
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
                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value <= 0) {
                                return 'Selecciona un cliente.';
                              }

                              return null;
                            },
                            onChanged:
                                procesandoPago
                                    ? null
                                    : (value) {
                                        setState(
                                          () {
                                            idCliente =
                                                value;
                                          },
                                        );
                                      },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextFormField(
                            controller:
                                montoController,
                            enabled:
                                !procesandoPago,
                            validator:
                                validarMonto,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              TextInputFormatter
                                  .withFunction(
                                (
                                  oldValue,
                                  newValue,
                                ) {
                                  if (RegExp(
                                    r'^\d{0,6}(\.\d{0,2})?$',
                                  ).hasMatch(
                                    newValue
                                        .text,
                                  )) {
                                    return newValue;
                                  }

                                  return oldValue;
                                },
                              ),
                            ],
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),
                            decoration:
                                _decoracion(
                              'Monto',
                            ).copyWith(
                              hintText:
                                  '500.00',
                              prefixIcon:
                                  const Icon(
                                Icons
                                    .attach_money,
                                color: gold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                tipoPago,
                            dropdownColor:
                                coal,
                            decoration:
                                _decoracion(
                              'Concepto del pago',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value:
                                    'Mensualidad',
                                child: Text(
                                  'Mensualidad',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    'Anualidad',
                                child: Text(
                                  'Anualidad',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            validator:
                                (value) {
                              if (value !=
                                      'Mensualidad' &&
                                  value !=
                                      'Anualidad') {
                                return 'Selecciona el concepto del pago.';
                              }

                              return null;
                            },
                            onChanged:
                                procesandoPago
                                    ? null
                                    : (value) {
                                        setState(
                                          () {
                                            tipoPago =
                                                value;
                                          },
                                        );
                                      },
                          ),

                          const SizedBox(
                            height: 22,
                          ),

                          SizedBox(
                            width:
                                double.infinity,
                            height: 52,
                            child:
                                FilledButton.icon(
                              onPressed:
                                  procesandoPago
                                      ? null
                                      : registrarPago,
                              icon:
                                  procesandoPago
                                      ? const SizedBox(
                                          width:
                                              20,
                                          height:
                                              20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .payments_outlined,
                                        ),
                              label: Text(
                                procesandoPago
                                    ? 'Registrando...'
                                    : 'Registrar pago',
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

                  if (errorFormulario
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    _error(
                      errorFormulario,
                    ),
                  ],

                  if (resultado != null) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    _resultado(
                      resultado!,
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

  InputDecoration _decoracion(
    String label,
  ) {
    const gold =
        Color(0xFFD4AF37);

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor:
          const Color(0xFF101012),
      labelStyle: const TextStyle(
        color: Color(0xFFA9A9A9),
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: gold,
        ),
      ),
    );
  }

  Widget _error(
    String mensaje, {
    bool botonReintentar = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xFF2A1111),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            mensaje,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          if (botonReintentar) ...[
            const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  Widget _resultado(
    ResultadoRegistroPago pago,
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
            size: 45,
          ),
          const SizedBox(height: 10),
          Text(
            pago.mensaje.isEmpty
                ? 'Pago registrado correctamente.'
                : pago.mensaje,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${pago.monto.toStringAsFixed(2)} MXN · ${pago.tipoPago}',
            style: const TextStyle(
              color: Color(0xFFA9A9A9),
            ),
          ),
        ],
      ),
    );
  }
}