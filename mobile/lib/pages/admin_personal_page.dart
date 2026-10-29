import 'package:flutter/material.dart';

import '../models/admin_personal.dart';
import '../services/admin_personal_service.dart';
import 'admin_registrar_personal_page.dart';
// GYMFLOW - SPRINT 7
// PANTALLA ADMINISTRATIVA DE PERSONAL

class AdminPersonalPage extends StatefulWidget {
  const AdminPersonalPage({super.key});

  @override
  State<AdminPersonalPage> createState() => _AdminPersonalPageState();
}

class _AdminPersonalPageState extends State<AdminPersonalPage> {
  final AdminPersonalService _servicio = AdminPersonalService();

  // COLORES GYMFLOW

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _textoSecundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  // EMPLEADOS Y CONSULTA

  List<AdminPersonal> _empleados = [];

  bool _cargando = true;
  String? _error;

  int _numeroConsulta = 0;

  // FILTROS

  String _filtroPuesto = '';
  String _filtroEstatus = '';

  @override
  void initState() {
    super.initState();
    _cargarPersonal();
  }

  @override
  void dispose() {
    _numeroConsulta++;
    super.dispose();
  }

  // ====================================
  // CONSULTAR EMPLEADOS DEL BACKEND
  // ====================================

  Future<void> _cargarPersonal() async {
    final consultaActual = ++_numeroConsulta;

    setState(() {
      _cargando = true;
      _error = null;
      _empleados = [];
    });

    try {
      final resultado = await _servicio.obtenerPersonal();

      if (!mounted || consultaActual != _numeroConsulta) {
        return;
      }

      setState(() {
        _empleados = resultado;
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

  // ====================================
  // ABRIR FORMULARIO DE REGISTRO
  // ====================================

  Future<void> _abrirRegistro() async {
    final idPersonal = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const AdminRegistrarPersonalPage()),
    );

    if (!mounted) return;

    if (idPersonal != null && idPersonal > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Empleado registrado correctamente. '
            'ID de personal: $idPersonal.',
          ),
          backgroundColor: const Color(0xFF287447),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _cargarPersonal();
    }
  }

  // ====================================
  // FILTROS LOCALES DEL DIRECTORIO
  // ====================================

  List<AdminPersonal> get _empleadosFiltrados {
    return _empleados.where((empleado) {
      final cumplePuesto =
          _filtroPuesto.isEmpty || empleado.puesto == _filtroPuesto;

      final cumpleEstatus =
          _filtroEstatus.isEmpty || empleado.estatus == _filtroEstatus;

      return cumplePuesto && cumpleEstatus;
    }).toList();
  }

  bool get _hayFiltros {
    return _filtroPuesto.isNotEmpty || _filtroEstatus.isNotEmpty;
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroPuesto = '';
      _filtroEstatus = '';
    });
  }

  // ====================================
  // FORMATO DE FECHAS
  // ====================================

  String _mostrarFecha(String? fecha) {
    if (fecha == null || fecha.trim().isEmpty) {
      return 'Sin fecha';
    }

    // Conservar el día calendario recibido.
    // No convertir a UTC.

    final valor = fecha.trim();

    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(valor)) {
      return '${valor.substring(8, 10)}/'
          '${valor.substring(5, 7)}/'
          '${valor.substring(0, 4)}';
    }

    return valor;
  }

  // ====================================
  // FORMATO DE SALARIO MENSUAL
  // ====================================

  String _mostrarSalario(double salario) {
    if (!salario.isFinite) {
      return 'No disponible';
    }

    final partes = salario.abs().toStringAsFixed(2).split('.');

    final digitos = partes[0];
    final resultado = StringBuffer();

    for (int i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) {
        resultado.write(',');
      }

      resultado.write(digitos[i]);
    }

    final signo = salario < 0 ? '-' : '';

    return '$signo\$${resultado.toString()}'
        '.${partes[1]} MXN';
  }

  // ====================================
  // ETIQUETAS DE PUESTO Y ESTATUS
  // ====================================

  Widget _etiqueta({
    required String texto,
    required Color fondo,
    required Color colorTexto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fondo,
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

  // ====================================
  // FILAS DE INFORMACIÓN
  // ====================================

  Widget _detalle({
    required IconData icono,
    required String etiqueta,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: _doradoOscuro),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(color: _textoSecundario, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Text(
                  valor,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================
  // SELECTORES DE FILTRO
  // ====================================

  Widget _selectorFiltro({
    required String etiqueta,
    required String valor,
    required List<DropdownMenuItem<String>> opciones,
    required ValueChanged<String> alCambiar,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        filled: true,
        fillColor: _superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borde),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isDense: true,
          isExpanded: true,
          items: opciones,
          onChanged: (nuevo) {
            if (nuevo != null) {
              alCambiar(nuevo);
            }
          },
        ),
      ),
    );
  }

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
              Icon(Icons.filter_list, color: _doradoOscuro, size: 24),

              SizedBox(width: 10),

              Text(
                'Filtrar personal',
                style: TextStyle(
                  color: _texto,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _selectorFiltro(
            etiqueta: 'Puesto',
            valor: _filtroPuesto,
            opciones: const [
              DropdownMenuItem(value: '', child: Text('Todos los empleados')),
              DropdownMenuItem(
                value: 'Entrenador',
                child: Text('Entrenadores'),
              ),
              DropdownMenuItem(
                value: 'Recepcionista',
                child: Text('Recepcionistas'),
              ),
            ],
            alCambiar: (valor) {
              setState(() {
                _filtroPuesto = valor;
              });
            },
          ),

          const SizedBox(height: 15),

          _selectorFiltro(
            etiqueta: 'Estatus',
            valor: _filtroEstatus,
            opciones: const [
              DropdownMenuItem(value: '', child: Text('Todos los estatus')),
              DropdownMenuItem(value: 'Activo', child: Text('Activos')),
              DropdownMenuItem(value: 'Inactivo', child: Text('Inactivos')),
            ],
            alCambiar: (valor) {
              setState(() {
                _filtroEstatus = valor;
              });
            },
          ),

          if (_hayFiltros) ...[
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.close),
              label: const Text('Limpiar filtros'),
              style: OutlinedButton.styleFrom(foregroundColor: _doradoOscuro),
            ),
          ],
        ],
      ),
    );
  }

  // ====================================
  // TARJETA DEL EMPLEADO
  // ====================================

  Widget _tarjetaEmpleado(AdminPersonal empleado) {
    final horario = empleado.horario.trim().isEmpty
        ? 'Sin asignar'
        : empleado.horario;

    final telefono = empleado.telefono.trim().isEmpty
        ? 'Sin teléfono'
        : empleado.telefono;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(19),
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
          // ENCABEZADO
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.badge_outlined,
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
                      empleado.nombreCompleto,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Personal #${empleado.idPersonal}',
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

          const SizedBox(height: 16),

          // PUESTO Y ESTATUS
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _etiqueta(
                texto: empleado.puesto,
                fondo: const Color(0xFFF3EAD8),
                colorTexto: _doradoOscuro,
              ),

              _etiqueta(
                texto: empleado.estatus,
                fondo: empleado.estaActivo
                    ? const Color(0xFFE7F3E8)
                    : const Color(0xFFFCE9E6),
                colorTexto: empleado.estaActivo
                    ? const Color(0xFF287447)
                    : const Color(0xFFA03930),
              ),
            ],
          ),

          const SizedBox(height: 17),

          const Divider(color: _borde, height: 1),

          const SizedBox(height: 17),

          // INFORMACIÓN LABORAL
          _detalle(
            icono: Icons.email_outlined,
            etiqueta: 'Correo electrónico',
            valor: empleado.correo,
          ),

          _detalle(
            icono: Icons.phone_outlined,
            etiqueta: 'Teléfono',
            valor: telefono,
          ),

          _detalle(
            icono: Icons.payments_outlined,
            etiqueta: 'Sueldo mensual',
            valor: _mostrarSalario(empleado.salario),
          ),

          _detalle(
            icono: Icons.schedule_outlined,
            etiqueta: 'Horario',
            valor: horario,
          ),

          _detalle(
            icono: Icons.calendar_today_outlined,
            etiqueta: 'Fecha de contratación',
            valor: _mostrarFecha(empleado.fechaContratacion),
          ),

          _detalle(
            icono: Icons.event_busy_outlined,
            etiqueta: 'Fecha de baja',
            valor: _mostrarFecha(empleado.fechaBaja),
          ),
        ],
      ),
    );
  }

  // ====================================
  // ESTADO DE CARGA
  // ====================================

  Widget _vistaCarga() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 65),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _dorado),

            SizedBox(height: 18),

            Text(
              'Cargando empleados...',
              style: TextStyle(color: _textoSecundario),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // ESTADO DE ERROR
  // ====================================

  Widget _vistaError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFA03930), size: 48),

            const SizedBox(height: 15),

            const Text(
              'No fue posible cargar empleados',
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
              onPressed: _cargarPersonal,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(foregroundColor: _doradoOscuro),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // ESTADO SIN RESULTADOS
  // ====================================

  Widget _vistaVacia() {
    final sinEmpleados = _empleados.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.groups_outlined, color: _doradoOscuro, size: 50),

            const SizedBox(height: 15),

            Text(
              sinEmpleados
                  ? 'No hay empleados registrados'
                  : 'No encontramos coincidencias',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _texto,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              sinEmpleados
                  ? 'Cuando existan empleados, '
                        'aparecerán aquí.'
                  : 'Prueba con otros filtros.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textoSecundario),
            ),

            if (!sinEmpleados && _hayFiltros) ...[
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

  // ====================================
  // PANTALLA PRINCIPAL
  // ====================================

  @override
  Widget build(BuildContext context) {
    final filtrados = _empleadosFiltrados;

    return Scaffold(
      backgroundColor: _fondo,

      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),

        title: const Text(
          'Administrar Personal',
          style: TextStyle(
            color: _texto,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Actualizar personal',
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPersonal,
          ),
        ],
      ),

      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _cargarPersonal,

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
                    'Equipo de GymFlow',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Consulta entrenadores, '
                    'recepcionistas y sus datos laborales.',
                    style: TextStyle(
                      color: _textoSecundario,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 23),

                  const SizedBox(height: 23),

                  // REGISTRAR NUEVO EMPLEADO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _abrirRegistro,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Registrar empleado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _doradoOscuro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 23),

                  // FILTROS
                  _panelFiltros(),

                  const SizedBox(height: 23),

                  // RESUMEN
                  if (!_cargando && _error == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
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
                            '${filtrados.length} de '
                            '${_empleados.length} empleados',
                            style: const TextStyle(
                              color: _doradoOscuro,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 21),

                  // RESULTADOS
                  if (_cargando)
                    _vistaCarga()
                  else if (_error != null)
                    _vistaError()
                  else if (filtrados.isEmpty)
                    _vistaVacia()
                  else
                    ...filtrados.map(_tarjetaEmpleado),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
