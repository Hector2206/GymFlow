import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_cliente.dart';
import '../services/admin_cliente_service.dart';

// GYMFLOW - SPRINT 7
// ADMINISTRAR CLIENTES CON FILTROS

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  final AdminClienteService _servicio = AdminClienteService();

  // COLORES GYMFLOW

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _textoSecundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  // CONTROLADORES DE BÚSQUEDA

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _correoController = TextEditingController();

  final TextEditingController _membresiaController = TextEditingController();

  String _estatus = '';
  String _vigencia = '';

  Timer? _temporizadorBusqueda;
  int _numeroConsulta = 0;

  // RESULTADOS

  List<AdminCliente> _clientes = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _temporizadorBusqueda?.cancel();

    _nombreController.dispose();
    _correoController.dispose();
    _membresiaController.dispose();

    super.dispose();
  }

  // COMPROBAR SI HAY FILTROS ACTIVOS

  bool get _hayFiltros {
    return _nombreController.text.trim().isNotEmpty ||
        _correoController.text.trim().isNotEmpty ||
        _membresiaController.text.trim().isNotEmpty ||
        _estatus.isNotEmpty ||
        _vigencia.isNotEmpty;
  }

  // CONSTRUIR LOS FILTROS

  AdminClienteFiltros _obtenerFiltros() {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final membresiaTexto = _membresiaController.text.trim();

    int? idMembresia;

    if (membresiaTexto.isNotEmpty) {
      idMembresia = int.tryParse(membresiaTexto);

      if (idMembresia == null || idMembresia <= 0) {
        throw Exception(
          'El ID de membresía debe ser '
          'un número entero mayor que cero.',
        );
      }
    }

    return AdminClienteFiltros(
      nombre: nombre.isEmpty ? null : nombre,
      correo: correo.isEmpty ? null : correo,
      estatus: _estatus.isEmpty ? null : _estatus,
      vigencia: _vigencia.isEmpty ? null : _vigencia,
      idMembresia: idMembresia,
    );
  }

  // BÚSQUEDA AUTOMÁTICA
  // Esperar 400 ms antes de consultar.

  void _programarBusqueda() {
    _temporizadorBusqueda?.cancel();

    // Invalidar cualquier consulta anterior.
    _numeroConsulta++;

    setState(() {
      _clientes = [];
      _error = null;
      _cargando = true;
    });

    _temporizadorBusqueda = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _cargarClientes();
      }
    });
  }

  // CONSULTAR CLIENTES EN BACKEND

  Future<void> _cargarClientes() async {
    _temporizadorBusqueda?.cancel();

    final consultaActual = ++_numeroConsulta;

    setState(() {
      _cargando = true;
      _error = null;
      _clientes = [];
    });

    try {
      final filtros = _obtenerFiltros();

      final resultado = await _servicio.buscarClientes(filtros: filtros);

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

  // LIMPIAR LOS CINCO FILTROS

  void _limpiarFiltros() {
    _nombreController.clear();
    _correoController.clear();
    _membresiaController.clear();

    setState(() {
      _estatus = '';
      _vigencia = '';
    });

    _programarBusqueda();
  }

  // CAMPO DE TEXTO

  Widget _campoBusqueda({
    required TextEditingController controller,
    required String etiqueta,
    required String sugerencia,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
    List<TextInputFormatter>? formato,
    int maximo = 150,
  }) {
    return TextField(
      controller: controller,
      maxLength: maximo,
      keyboardType: teclado,
      inputFormatters: formato,
      onChanged: (_) => _programarBusqueda(),
      onSubmitted: (_) => _cargarClientes(),
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: sugerencia,
        counterText: '',
        prefixIcon: Icon(icono, color: _doradoOscuro),
        filled: true,
        fillColor: _superficie,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dorado, width: 1.5),
        ),
      ),
    );
  }

  // SELECTOR DE ESTATUS O VIGENCIA

  Widget _selectorFiltro({
    required String etiqueta,
    required String valor,
    required IconData icono,
    required List<DropdownMenuItem<String>> opciones,
    required ValueChanged<String> alCambiar,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: _doradoOscuro),
        filled: true,
        fillColor: _superficie,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borde),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          isDense: true,
          items: opciones,
          onChanged: (nuevo) {
            if (nuevo == null) return;

            alCambiar(nuevo);
            _programarBusqueda();
          },
        ),
      ),
    );
  }

  // PANEL DE FILTROS

  Widget _panelFiltros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.manage_search_outlined,
                color: _doradoOscuro,
                size: 27,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar clientes',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Puedes combinar varios filtros. '
            'Los resultados se actualizan '
            'automáticamente.',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // NOMBRE
          _campoBusqueda(
            controller: _nombreController,
            etiqueta: 'Nombre del cliente',
            sugerencia: 'Ej. Juan Pérez',
            icono: Icons.person_search_outlined,
          ),

          const SizedBox(height: 14),

          // CORREO
          _campoBusqueda(
            controller: _correoController,
            etiqueta: 'Correo electrónico',
            sugerencia: 'Ej. cliente@correo.com',
            icono: Icons.email_outlined,
            teclado: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          // ESTATUS
          _selectorFiltro(
            etiqueta: 'Estatus del cliente',
            valor: _estatus,
            icono: Icons.verified_user_outlined,
            opciones: const [
              DropdownMenuItem(value: '', child: Text('Todos los estatus')),
              DropdownMenuItem(value: 'Activo', child: Text('Activo')),
              DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
            ],
            alCambiar: (valor) {
              setState(() {
                _estatus = valor;
              });
            },
          ),

          const SizedBox(height: 14),

          // VIGENCIA
          _selectorFiltro(
            etiqueta: 'Vigencia de membresía',
            valor: _vigencia,
            icono: Icons.card_membership_outlined,
            opciones: const [
              DropdownMenuItem(value: '', child: Text('Todas las vigencias')),
              DropdownMenuItem(value: 'Vigente', child: Text('Vigente')),
              DropdownMenuItem(value: 'Vencida', child: Text('Vencida')),
              DropdownMenuItem(value: 'SinPagos', child: Text('Sin pagos')),
            ],
            alCambiar: (valor) {
              setState(() {
                _vigencia = valor;
              });
            },
          ),

          const SizedBox(height: 14),

          // ID DE MEMBRESÍA
          _campoBusqueda(
            controller: _membresiaController,
            etiqueta: 'ID de membresía',
            sugerencia: 'Ej. 1',
            icono: Icons.numbers_outlined,
            teclado: TextInputType.number,
            formato: [FilteringTextInputFormatter.digitsOnly],
            maximo: 12,
          ),

          if (_hayFiltros) ...[
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.close),
                label: const Text('Limpiar filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _doradoOscuro,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFFD8C8A5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MOSTRAR FECHA SIN CAMBIAR DE DÍA

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
    final fondo = positivo ? const Color(0xFFE7F3E8) : const Color(0xFFFCE9E6);

    final textoColor = positivo
        ? const Color(0xFF287447)
        : const Color(0xFFA03930);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: textoColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // FILA DE INFORMACIÓN

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

  // TARJETA DE CLIENTE

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

          _filaInformacion(icono: Icons.email_outlined, texto: cliente.correo),

          const SizedBox(height: 9),

          _filaInformacion(icono: Icons.phone_outlined, texto: telefono),

          const SizedBox(height: 16),

          const Divider(color: _borde, height: 1),

          const SizedBox(height: 16),

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
                fontSize: 16,
                fontWeight: FontWeight.w700,
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

  // SIN RESULTADOS

  Widget _vistaVacia() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_outlined,
              color: _doradoOscuro,
              size: 50,
            ),

            const SizedBox(height: 16),

            Text(
              _hayFiltros
                  ? 'No encontramos coincidencias'
                  : 'No hay clientes registrados',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _texto,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _hayFiltros
                  ? 'Prueba con otros criterios '
                        'o limpia los filtros.'
                  : 'Cuando existan clientes, '
                        'aparecerán en esta sección.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textoSecundario, fontSize: 13),
            ),

            if (_hayFiltros) ...[
              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.close),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // PANTALLA PRINCIPAL

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

                  // PANEL DE BÚSQUEDA
                  _panelFiltros(),

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
