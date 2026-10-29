import 'package:flutter/material.dart';

import '../services/admin_dashboard_service.dart';

// GYMFLOW - SPRINT 7
// PANTALLA DEL DASHBOARD ADMINISTRATIVO

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminDashboardService _servicio = AdminDashboardService();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _textoSecundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  // INDICADORES

  int? _totalClientes;
  int? _membresiasActivas;
  int? _asistenciasDia;
  int? _pagosRegistrados;

  bool _cargandoClientes = true;
  bool _cargandoMembresias = true;
  bool _cargandoAsistencias = true;
  bool _cargandoPagos = true;

  String? _errorClientes;
  String? _errorMembresias;
  String? _errorAsistencias;
  String? _errorPagos;

  // INGRESOS POR PERIODO

  DateTime? _desde;
  DateTime? _hasta;

  double? _ingresosPeriodo;
  String _periodoConsultadoDesde = '';
  String _periodoConsultadoHasta = '';

  bool _cargandoIngresos = false;
  String? _errorPeriodo;
  String? _errorIngresos;

  int _versionConsultaIngresos = 0;

  @override
  void initState() {
    super.initState();
    _actualizarIndicadores();
  }

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ACTUALIZAR LAS CUATRO ESTADÍSTICAS

  Future<void> _actualizarIndicadores() async {
    await Future.wait<void>([
      _cargarClientes(),
      _cargarMembresias(),
      _cargarAsistencias(),
      _cargarPagos(),
    ]);
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _cargandoClientes = true;
      _errorClientes = null;
      _totalClientes = null;
    });

    try {
      final resultado = await _servicio.obtenerTotalClientes();

      if (!mounted) return;

      setState(() {
        _totalClientes = resultado.totalClientes;
        _cargandoClientes = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorClientes = _mensajeError(error);
        _cargandoClientes = false;
      });
    }
  }

  Future<void> _cargarMembresias() async {
    setState(() {
      _cargandoMembresias = true;
      _errorMembresias = null;
      _membresiasActivas = null;
    });

    try {
      final resultado = await _servicio.obtenerMembresiasActivas();

      if (!mounted) return;

      setState(() {
        _membresiasActivas = resultado.membresiasActivas;
        _cargandoMembresias = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMembresias = _mensajeError(error);
        _cargandoMembresias = false;
      });
    }
  }

  Future<void> _cargarAsistencias() async {
    setState(() {
      _cargandoAsistencias = true;
      _errorAsistencias = null;
      _asistenciasDia = null;
    });

    try {
      final resultado = await _servicio.obtenerAsistenciasDia();

      if (!mounted) return;

      setState(() {
        _asistenciasDia = resultado.asistenciasDia;
        _cargandoAsistencias = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorAsistencias = _mensajeError(error);
        _cargandoAsistencias = false;
      });
    }
  }

  Future<void> _cargarPagos() async {
    setState(() {
      _cargandoPagos = true;
      _errorPagos = null;
      _pagosRegistrados = null;
    });

    try {
      final resultado = await _servicio.obtenerPagosRegistrados();

      if (!mounted) return;

      setState(() {
        _pagosRegistrados = resultado.pagosRegistrados;
        _cargandoPagos = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorPagos = _mensajeError(error);
        _cargandoPagos = false;
      });
    }
  }

  // FORMATO DE FECHAS YYYY-MM-DD

  String _formatoFecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  // FORMATO DE DINERO EN PESOS MEXICANOS

  String _formatoDinero(double cantidad) {
    final partes = cantidad.toStringAsFixed(2).split('.');
    final numero = partes[0];
    final negativo = numero.startsWith('-');

    final digitos = negativo ? numero.substring(1) : numero;

    final resultado = StringBuffer();

    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) {
        resultado.write(',');
      }

      resultado.write(digitos[i]);
    }

    final signo = negativo ? '-' : '';

    return '$signo\$${resultado.toString()}.${partes[1]}';
  }

  // SELECCIONAR FECHA DESDE O HASTA

  Future<void> _seleccionarFecha({required bool esInicial}) async {
    final fechaActual = esInicial ? _desde : _hasta;

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: esInicial
          ? 'Seleccionar fecha inicial'
          : 'Seleccionar fecha final',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (seleccionada == null || !mounted) return;

    setState(() {
      if (esInicial) {
        _desde = seleccionada;
      } else {
        _hasta = seleccionada;
      }

      // Invalidar respuestas de consultas anteriores.
      _versionConsultaIngresos++;

      _ingresosPeriodo = null;
      _periodoConsultadoDesde = '';
      _periodoConsultadoHasta = '';
      _errorPeriodo = null;
      _errorIngresos = null;
      _cargandoIngresos = false;
    });
  }

  // CONSULTAR INGRESOS REALES

  Future<void> _consultarIngresos() async {
    if (_cargandoIngresos) return;

    if (_desde == null || _hasta == null) {
      setState(() {
        _errorPeriodo = 'Debes seleccionar ambas fechas.';
      });
      return;
    }

    if (_desde!.isAfter(_hasta!)) {
      setState(() {
        _errorPeriodo =
            'La fecha inicial no puede ser posterior '
            'a la fecha final.';
      });
      return;
    }

    final desde = _formatoFecha(_desde!);
    final hasta = _formatoFecha(_hasta!);

    final version = ++_versionConsultaIngresos;

    setState(() {
      _cargandoIngresos = true;
      _errorPeriodo = null;
      _errorIngresos = null;
      _ingresosPeriodo = null;
    });

    try {
      final resultado = await _servicio.obtenerIngresosPeriodo(
        desde: desde,
        hasta: hasta,
      );

      if (!mounted || version != _versionConsultaIngresos) {
        return;
      }

      setState(() {
        _ingresosPeriodo = resultado.ingresosPeriodo;
        _periodoConsultadoDesde = resultado.desde;
        _periodoConsultadoHasta = resultado.hasta;
        _cargandoIngresos = false;
      });
    } catch (error) {
      if (!mounted || version != _versionConsultaIngresos) {
        return;
      }

      setState(() {
        _errorIngresos = _mensajeError(error);
        _cargandoIngresos = false;
      });
    }
  }

  // TARJETA DE ESTADÍSTICA

  Widget _tarjetaIndicador({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required int? valor,
    required bool cargando,
    required String? error,
    required VoidCallback reintentar,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borde),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C3E24).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EAD8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: _doradoOscuro, size: 25),
          ),

          const SizedBox(height: 14),

          Text(
            titulo,
            style: const TextStyle(
              color: _texto,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          if (cargando)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _dorado,
                  ),
                ),
                SizedBox(width: 12),
                Text('Cargando...'),
              ],
            )
          else if (error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFFA03930),
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: reintentar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            )
          else
            Text(
              valor?.toString() ?? '—',
              style: const TextStyle(
                color: _doradoOscuro,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),

          const SizedBox(height: 10),

          Text(
            descripcion,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // CAMPO DE FECHA

  Widget _campoFecha({
    required String etiqueta,
    required DateTime? fecha,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(color: _texto, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              fecha == null ? 'Seleccionar fecha' : _formatoFecha(fecha),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _doradoOscuro,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              side: const BorderSide(color: Color(0xFFD8C8A5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SECCIÓN FINANCIERA

  Widget _seccionIngresos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_outlined, color: _doradoOscuro, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ingresos por periodo',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Consulta los ingresos brutos '
            'registrados por pagos de clientes.',
            style: TextStyle(color: _textoSecundario, height: 1.4),
          ),

          const SizedBox(height: 22),

          _campoFecha(
            etiqueta: 'Fecha inicial',
            fecha: _desde,
            onPressed: () {
              _seleccionarFecha(esInicial: true);
            },
          ),

          const SizedBox(height: 16),

          _campoFecha(
            etiqueta: 'Fecha final',
            fecha: _hasta,
            onPressed: () {
              _seleccionarFecha(esInicial: false);
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cargandoIngresos ? null : _consultarIngresos,
              icon: const Icon(Icons.search),
              label: Text(
                _cargandoIngresos ? 'Consultando...' : 'Consultar ingresos',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _doradoOscuro,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFC6B38B),
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (_errorPeriodo != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorPeriodo!,
              style: const TextStyle(color: Color(0xFFA03930)),
            ),
          ],

          if (_cargandoIngresos) ...[
            const SizedBox(height: 22),
            const Center(child: CircularProgressIndicator(color: _dorado)),
          ],

          if (_errorIngresos != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorIngresos!,
              style: const TextStyle(color: Color(0xFFA03930)),
            ),
          ],

          if (_ingresosPeriodo != null) ...[
            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EAD8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8C392)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INGRESOS BRUTOS',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _formatoDinero(_ingresosPeriodo!),
                    style: const TextStyle(
                      color: _texto,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const Text(
                    'Pesos mexicanos (MXN)',
                    style: TextStyle(color: _textoSecundario, fontSize: 12),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Periodo: $_periodoConsultadoDesde '
                    'al $_periodoConsultadoHasta',
                    style: const TextStyle(
                      color: _textoSecundario,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'No se descuentan salarios '
                    'ni otros gastos.',
                    style: TextStyle(color: _textoSecundario, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        title: const Text(
          'Dashboard Administrativo',
          style: TextStyle(
            color: _texto,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        actions: [
          IconButton(
            tooltip: 'Actualizar estadísticas',
            icon: const Icon(Icons.refresh),
            onPressed: _actualizarIndicadores,
          ),
        ],
      ),

      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _actualizarIndicadores,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / ADMINISTRACIÓN',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Indicadores del gimnasio',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Información actualizada '
                    'desde el servidor de GymFlow.',
                    style: TextStyle(color: _textoSecundario, fontSize: 13),
                  ),

                  const SizedBox(height: 22),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dosColumnas = constraints.maxWidth >= 540;

                      final ancho = dosColumnas
                          ? (constraints.maxWidth - 14) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: ancho,
                            child: _tarjetaIndicador(
                              icono: Icons.groups_outlined,
                              titulo: 'Total de clientes',
                              descripcion: 'Clientes registrados',
                              valor: _totalClientes,
                              cargando: _cargandoClientes,
                              error: _errorClientes,
                              reintentar: _cargarClientes,
                            ),
                          ),
                          SizedBox(
                            width: ancho,
                            child: _tarjetaIndicador(
                              icono: Icons.card_membership_outlined,
                              titulo: 'Membresías activas',
                              descripcion:
                                  'Clientes activos '
                                  'con membresía vigente',
                              valor: _membresiasActivas,
                              cargando: _cargandoMembresias,
                              error: _errorMembresias,
                              reintentar: _cargarMembresias,
                            ),
                          ),
                          SizedBox(
                            width: ancho,
                            child: _tarjetaIndicador(
                              icono: Icons.calendar_month_outlined,
                              titulo: 'Asistencias del día',
                              descripcion: 'Accesos aprobados hoy',
                              valor: _asistenciasDia,
                              cargando: _cargandoAsistencias,
                              error: _errorAsistencias,
                              reintentar: _cargarAsistencias,
                            ),
                          ),
                          SizedBox(
                            width: ancho,
                            child: _tarjetaIndicador(
                              icono: Icons.payments_outlined,
                              titulo: 'Pagos registrados',
                              descripcion: 'Pagos de clientes',
                              valor: _pagosRegistrados,
                              cargando: _cargandoPagos,
                              error: _errorPagos,
                              reintentar: _cargarPagos,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  _seccionIngresos(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
