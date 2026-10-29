import 'package:flutter/material.dart';

import '../models/admin_cliente.dart';
import '../services/admin_cliente_service.dart';

// GYMFLOW - SPRINT 7
// PANTALLA DE ADMINISTRACIÓN DE CLIENTES

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  final AdminClienteService _servicio = AdminClienteService();

  // COLORES OFICIALES

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _textoSecundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  // ESTADO DE LA CONSULTA

  List<AdminCliente> _clientes = [];

  bool _cargando = true;
  String? _error;

  int _numeroConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  // CONSULTAR CLIENTES REALES

  Future<void> _cargarClientes() async {
    final consultaActual = ++_numeroConsulta;

    setState(() {
      _cargando = true;
      _error = null;
      _clientes = [];
    });

    try {
      final resultado = await _servicio.obtenerTodos();

      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _clientes = resultado;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');

        _cargando = false;
      });
    }
  }

  // MOSTRAR FECHA SIN MODIFICAR EL DÍA

  String _mostrarFecha(String? fecha) {
    if (fecha == null || fecha.trim().isEmpty) {
      return 'Sin fecha';
    }

    final partes = fecha.split('-');

    if (partes.length == 3) {
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }

    return fecha;
  }

  // ETIQUETAS DE ESTATUS Y VIGENCIA

  Widget _etiqueta({required String texto, required bool positivo}) {
    final colorFondo = positivo
        ? const Color(0xFFE7F3E8)
        : const Color(0xFFFCE9E6);

    final colorTexto = positivo
        ? const Color(0xFF287447)
        : const Color(0xFFA03930);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: colorTexto,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // INFORMACIÓN DE CONTACTO

  Widget _filaInformacion({required IconData icono, required String texto}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 17, color: _doradoOscuro),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // TARJETA INDIVIDUAL DE CLIENTE

  Widget _tarjetaCliente(AdminCliente cliente) {
    final nombrePlan = cliente.nombrePlan.trim().isEmpty
        ? 'Sin nombre de plan'
        : cliente.nombrePlan;

    final telefono = cliente.telefono.trim().isEmpty
        ? 'Sin teléfono'
        : cliente.telefono;

    final vigenciaTexto = cliente.vigencia == 'SinPagos'
        ? 'Sin pagos'
        : cliente.vigencia;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borde),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C3E24).withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NOMBRE DEL CLIENTE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: _doradoOscuro,
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombreCompleto,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Cliente #${cliente.idCliente}',
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // CONTACTO
          _filaInformacion(icono: Icons.email_outlined, texto: cliente.correo),

          const SizedBox(height: 9),

          _filaInformacion(icono: Icons.phone_outlined, texto: telefono),

          const SizedBox(height: 16),

          const Divider(color: _borde, height: 1),

          const SizedBox(height: 16),

          // MEMBRESÍA
          const Text(
            'MEMBRESÍA',
            style: TextStyle(
              color: _doradoOscuro,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            nombrePlan,
            style: const TextStyle(
              color: _texto,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Plan #${cliente.idMembresia}',
            style: const TextStyle(color: _textoSecundario, fontSize: 12),
          ),

          const SizedBox(height: 17),

          // ESTATUS Y VIGENCIA
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _etiqueta(texto: cliente.estatus, positivo: cliente.estaActivo),

              _etiqueta(
                texto: vigenciaTexto,
                positivo: cliente.membresiaVigente,
              ),
            ],
          ),

          const SizedBox(height: 17),

          _filaInformacion(
            icono: Icons.event_outlined,
            texto:
                'Vencimiento: '
                '${_mostrarFecha(cliente.fechaVencimiento)}',
          ),
        ],
      ),
    );
  }

  // ESTADO DE CARGA

  Widget _vistaCarga() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 65),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _dorado),

            SizedBox(height: 18),

            Text(
              'Cargando clientes...',
              style: TextStyle(color: _textoSecundario, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ESTADO DE ERROR

  Widget _vistaError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFA03930), size: 48),

            const SizedBox(height: 14),

            const Text(
              'No fue posible cargar los clientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _texto,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _error ?? 'Ocurrió un error inesperado.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textoSecundario, fontSize: 13),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _cargarClientes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(foregroundColor: _doradoOscuro),
            ),
          ],
        ),
      ),
    );
  }

  // SIN CLIENTES REGISTRADOS

  Widget _vistaVacia() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 65),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.groups_outlined, color: _doradoOscuro, size: 50),

            SizedBox(height: 16),

            Text(
              'No hay clientes registrados',
              style: TextStyle(
                color: _texto,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Cuando existan clientes, '
              'aparecerán en esta sección.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,

      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Administrar Clientes',
          style: TextStyle(
            color: _texto,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        iconTheme: const IconThemeData(color: _doradoOscuro),

        actions: [
          IconButton(
            tooltip: 'Actualizar clientes',
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClientes,
          ),
        ],
      ),

      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _cargarClientes,

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
                    'Directorio de clientes',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Consulta los clientes registrados '
                    'y la información de sus membresías.',
                    style: TextStyle(
                      color: _textoSecundario,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 23),

                  if (!_cargando && _error == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EAD8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            color: _doradoOscuro,
                            size: 19,
                          ),

                          const SizedBox(width: 9),

                          Text(
                            '${_clientes.length} '
                            'clientes encontrados',
                            style: const TextStyle(
                              color: _doradoOscuro,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 21),

                  if (_cargando)
                    _vistaCarga()
                  else if (_error != null)
                    _vistaError()
                  else if (_clientes.isEmpty)
                    _vistaVacia()
                  else
                    ..._clientes.map(_tarjetaCliente),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
