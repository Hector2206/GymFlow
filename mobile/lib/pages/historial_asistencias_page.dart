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
              .consultarPorCliente(id);

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
                  'Historial de Asistencias',
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
                  child: Form(
                    key: _formKey,
                    autovalidateMode:
                        AutovalidateMode
                            .onUserInteraction,
                    child: Column(
                      children: [
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
                              Icons
                                  .person_search_outlined,
                              color: gold,
                            ),
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
                                cargando
                                    ? null
                                    : consultar,
                            icon:
                                const Icon(
                              Icons.search,
                            ),
                            label: Text(
                              cargando
                                  ? 'Consultando...'
                                  : 'Consultar asistencias',
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
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (cargando)
                  const Center(
                    child:
                        CircularProgressIndicator(
                      color: gold,
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
                    asistencias.isNotEmpty)
                  ...asistencias.map(
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
    AsistenciaCliente a,
  ) {
    final fecha =
        a.fechaHoraDateTime;

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
            'Asistencia #${a.idAsistencia}',
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
            'Estado: ${a.estadoAcceso.isEmpty ? 'Sin información' : a.estadoAcceso}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            'Origen: ${a.origenRegistro.isEmpty ? 'Sin información' : a.origenRegistro}',
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
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: error
            ? const Color(0xFF2A1111)
            : const Color(0xFF171719),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}