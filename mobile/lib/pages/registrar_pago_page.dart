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
  final ClienteConsultaService clienteConsultaService =
      ClienteConsultaService();

  final PagoService pagoService =
      PagoService();

  final TextEditingController montoController =
      TextEditingController();

  List<ClienteResumen> clientes = [];

  int? idCliente;
  String? tipoPago;

  bool cargandoClientes = true;
  bool procesandoPago = false;

  String errorClientes = '';
  String errorFormulario = '';

  ResultadoRegistroPago? resultadoPago;

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
      errorClientes = '';
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

        errorClientes =
            limpiarException(
          e,
        );
      });
    }
  }

  double? obtenerMonto() {
    final texto =
        montoController.text
            .trim()
            .replaceAll(
              ',',
              '',
            );

    return double.tryParse(
      texto,
    );
  }

  String formatearFecha(
    String fecha,
  ) {
    if (fecha.trim().isEmpty) {
      return 'Sin información';
    }

    try {
      final valor =
          DateTime.parse(
        fecha,
      ).toLocal();

      final dia =
          valor.day
              .toString()
              .padLeft(
                2,
                '0',
              );

      final mes =
          valor.month
              .toString()
              .padLeft(
                2,
                '0',
              );

      return '$dia/$mes/${valor.year}';
    } catch (_) {
      return fecha;
    }
  }

  String formatearMonto(
    double monto,
  ) {
    return '\$${monto.toStringAsFixed(2)} MXN';
  }

  Future<void> registrarPago() async {
    if (procesandoPago) {
      return;
    }

    setState(() {
      errorFormulario = '';
      resultadoPago = null;
    });

    if (idCliente == null ||
        idCliente! <= 0) {
      setState(() {
        errorFormulario =
            'Selecciona un cliente.';
      });

      return;
    }

    final monto =
        obtenerMonto();

    if (monto == null) {
      setState(() {
        errorFormulario =
            'Ingresa el monto del pago.';
      });

      return;
    }

    if (monto <= 0) {
      setState(() {
        errorFormulario =
            'El monto debe ser mayor a \$0.';
      });

      return;
    }

    if (monto > 100000) {
      setState(() {
        errorFormulario =
            'Verifica el monto ingresado.';
      });

      return;
    }

    if (tipoPago != 'Mensualidad' &&
        tipoPago != 'Anualidad') {
      setState(() {
        errorFormulario =
            'Selecciona el concepto del pago.';
      });

      return;
    }

    setState(() {
      procesandoPago = true;
    });

    try {
      final respuesta =
          await pagoService
              .registrarPago(
        idCliente:
            idCliente!,
        monto:
            monto,
        tipoPago:
            tipoPago!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        resultadoPago =
            respuesta;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorFormulario =
            limpiarException(
          e,
        );
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
                    'Registrar Pago',

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
                    'Registra pagos y renovaciones de los clientes.',

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
                          'Datos del pago',

                          style:
                              TextStyle(
                            color: gold,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
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
                        else if (errorClientes.isNotEmpty)
                          Column(
                            children: [
                              _mensajeError(
                                errorClientes,
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
                                _inputDecoration(
                              label:
                                  'Cliente',

                              icon:
                                  Icons.person_outline,

                              gold:
                                  gold,

                              silver:
                                  silver,

                              dark:
                                  dark,
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
                                procesandoPago
                                    ? null
                                    : (
                                        value,
                                      ) {
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

                          TextField(
                            controller:
                                montoController,

                            enabled:
                                !procesandoPago,

                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),

                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(
                                  r'^\d*\.?\d{0,2}',
                                ),
                              ),
                            ],

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),

                            decoration:
                                _inputDecoration(
                              label:
                                  'Monto',

                              icon:
                                  Icons.attach_money,

                              gold:
                                  gold,

                              silver:
                                  silver,

                              dark:
                                  dark,

                              hint:
                                  'Ej. 500.00',
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          DropdownButtonFormField<String>(
                            initialValue:
                                tipoPago,

                            dropdownColor:
                                coal,

                            decoration:
                                _inputDecoration(
                              label:
                                  'Concepto del pago',

                              icon:
                                  Icons.receipt_long_outlined,

                              gold:
                                  gold,

                              silver:
                                  silver,

                              dark:
                                  dark,
                            ),

                            hint:
                                const Text(
                              'Selecciona un concepto',

                              style:
                                  TextStyle(
                                color:
                                    silver,
                              ),
                            ),

                            items:
                                const [
                              DropdownMenuItem<String>(
                                value:
                                    'Mensualidad',

                                child:
                                    Text(
                                  'Mensualidad',

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ),

                              DropdownMenuItem<String>(
                                value:
                                    'Anualidad',

                                child:
                                    Text(
                                  'Anualidad',

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ),
                            ],

                            onChanged:
                                procesandoPago
                                    ? null
                                    : (
                                        value,
                                      ) {
                                        setState(
                                          () {
                                            tipoPago =
                                                value;
                                          },
                                        );
                                      },
                          ),

                          const SizedBox(
                            height: 20,
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
                                          Icons.payments_outlined,
                                        ),

                              label:
                                  Text(
                                procesandoPago
                                    ? 'Registrando...'
                                    : 'Registrar pago',
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

                  if (errorFormulario.isNotEmpty) ...[
                    const SizedBox(
                      height: 22,
                    ),

                    _mensajeError(
                      errorFormulario,
                    ),
                  ],

                  if (resultadoPago != null) ...[
                    const SizedBox(
                      height: 22,
                    ),

                    _resultadoExito(
                      resultadoPago!,
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color gold,
    required Color silver,
    required Color dark,
    String? hint,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      labelStyle:
          TextStyle(
        color:
            silver,
      ),

      hintStyle:
          const TextStyle(
        color:
            Color(
          0xFF666666,
        ),
      ),

      prefixIcon:
          Icon(
        icon,
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
            alpha: 0.25,
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
            BorderSide(
          color:
              gold,
        ),
      ),
    );
  }

  Widget _mensajeError(
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

  Widget _resultadoExito(
    ResultadoRegistroPago resultado,
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
          0xFF10271A,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF49D17D,
          ),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color:
                Color(
              0xFF49D17D,
            ),
            size: 50,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            resultado.mensaje.isNotEmpty
                ? resultado.mensaje
                : 'Pago registrado correctamente.',

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Color(
                0xFF49D17D,
              ),

              fontSize: 17,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          _filaResultado(
            'Monto',
            formatearMonto(
              resultado.monto,
            ),
          ),

          _filaResultado(
            'Concepto',
            resultado.tipoPago,
          ),

          _filaResultado(
            'Renovación',
            resultado.esRenovacion
                ? 'Sí'
                : 'No',
          ),

          _filaResultado(
            'Membresía activa',
            resultado.membresiaActiva
                ? 'Sí'
                : 'No',
          ),

          if (resultado.fechaVencimiento.isNotEmpty)
            _filaResultado(
              'Nuevo vencimiento',
              formatearFecha(
                resultado.fechaVencimiento,
              ),
            ),
        ],
      ),
    );
  }

  Widget _filaResultado(
    String titulo,
    String valor,
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
                  const TextStyle(
                color:
                    Color(
                  0xFFA9A9A9,
                ),

                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
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