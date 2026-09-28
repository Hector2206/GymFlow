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

    if (!(_formKey.currentState
            ?.validate() ??
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
          await pagoService
              .registrarPago(
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

        elevation: 0,

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

                size: 21,
              ),
            ),
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',

          height: 48,

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
            height: 1,

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
                maxWidth: 650,
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
                                  FontWeight
                                      .w700,

                              letterSpacing:
                                  2,
                            ),
                          ),

                          SizedBox(
                            height: 7,
                          ),

                          Text(
                            'Registrar Pago',

                            style:
                                TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  29,

                              fontWeight:
                                  FontWeight
                                      .w700,

                              letterSpacing:
                                  -0.5,
                            ),
                          ),

                          SizedBox(
                            height: 7,
                          ),

                          Text(
                            'Selecciona un cliente y registra el pago de su membresía.',

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
                      height: 22,
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
                                width: 40,
                                height: 40,

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

                                  size: 21,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              const Expanded(
                                child:
                                    Text(
                                  'Datos del pago',

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
                            height: 20,
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
                            _error(
                              errorClientes,
                              botonReintentar:
                                  true,
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
                                  _decoracion(
                                'Cliente',
                                icon:
                                    Icons
                                        .person_outline_rounded,
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

                              validator:
                                  (value) {
                                if (value ==
                                        null ||
                                    value <=
                                        0) {
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
                                decimal:
                                    true,
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
                                      newValue.text,
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
                                    textPrimary,

                                fontSize:
                                    14,

                                fontWeight:
                                    FontWeight.w600,
                              ),

                              decoration:
                                  _decoracion(
                                'Monto',
                                hint:
                                    '500.00',
                                icon:
                                    Icons
                                        .attach_money_rounded,
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
                                  _decoracion(
                                'Concepto del pago',
                                icon:
                                    Icons
                                        .receipt_long_outlined,
                              ),

                              items:
                                  const [
                                DropdownMenuItem(
                                  value:
                                      'Mensualidad',

                                  child:
                                      Text(
                                    'Mensualidad',

                                    style:
                                        TextStyle(
                                      color:
                                          textPrimary,
                                    ),
                                  ),
                                ),

                                DropdownMenuItem(
                                  value:
                                      'Anualidad',

                                  child:
                                      Text(
                                    'Anualidad',

                                    style:
                                        TextStyle(
                                      color:
                                          textPrimary,
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

                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .payments_outlined,

                                            size:
                                                21,
                                          ),

                                label: Text(
                                  procesandoPago
                                      ? 'Registrando...'
                                      : 'Registrar pago',
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
      ),
    );
  }

  InputDecoration _decoracion(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    const gold =
        Color(0xFFB58A2A);

    const goldDark =
        Color(0xFF8A6814);

    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      filled:
          true,

      fillColor:
          const Color(
        0xFFF8F4EC,
      ),

      prefixIcon:
          icon == null
              ? null
              : Icon(
                  icon,

                  color:
                      goldDark,

                  size: 21,
                ),

      labelStyle:
          const TextStyle(
        color:
            Color(
          0xFF777067,
        ),

        fontSize: 13,
      ),

      hintStyle:
          const TextStyle(
        color:
            Color(
          0xFFA39A8D,
        ),

        fontSize: 13,
      ),

      border:
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

          width: 1.5,
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

          width: 1.5,
        ),
      ),

      errorStyle:
          const TextStyle(
        color:
            Color(
          0xFFC21B2E,
        ),

        fontSize: 11,
      ),
    );
  }

  Widget _error(
    String mensaje, {
    bool botonReintentar = false,
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
            width: 44,
            height: 44,

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

              size: 26,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            mensaje,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Color(
                0xFF8F2030,
              ),

              fontSize: 13,

              fontWeight:
                  FontWeight.w600,

              height: 1.4,
            ),
          ),

          if (botonReintentar) ...[
            const SizedBox(
              height: 14,
            ),

            OutlinedButton.icon(
              onPressed:
                  cargarClientes,

              icon:
                  const Icon(
                Icons
                    .refresh_rounded,

                size: 19,
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
        ],
      ),
    );
  }

  Widget _resultado(
    ResultadoRegistroPago pago,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF2F8F2,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFB7D7BC,
          ),
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration:
                const BoxDecoration(
              color:
                  Color(
                0xFFDCEEDF,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .check_circle_rounded,

              color:
                  Color(
                0xFF2E7D32,
              ),

              size: 38,
            ),
          ),

          const SizedBox(
            height: 13,
          ),

          const Text(
            'PAGO REGISTRADO',

            style:
                TextStyle(
              color:
                  Color(
                0xFF2E7D32,
              ),

              fontWeight:
                  FontWeight.w800,

              fontSize: 17,

              letterSpacing:
                  0.4,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            pago.mensaje.isEmpty
                ? 'Pago registrado correctamente.'
                : pago.mensaje,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Color(
                0xFF2F2A24,
              ),

              fontSize: 14,

              fontWeight:
                  FontWeight.w700,

              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFE4F1E6,
              ),

              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),

            child: Text(
              '\$${pago.monto.toStringAsFixed(2)} MXN · ${pago.tipoPago}',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF285E2D,
                ),

                fontSize: 13,

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