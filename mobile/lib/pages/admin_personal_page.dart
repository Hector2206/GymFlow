import 'package:flutter/material.dart';

import '../models/admin_personal.dart';
import '../services/admin_personal_service.dart';
import 'admin_baja_personal_page.dart';
import 'admin_editar_personal_page.dart';
import 'admin_nomina_gestion_page.dart';
import 'admin_registrar_personal_page.dart';

// GYMFLOW - SPRINT 7
// PANEL ADMINISTRATIVO DE PERSONAL - ESTRUCTURA COMO WEB

class AdminPersonalPage extends StatefulWidget {
  const AdminPersonalPage({super.key});

  @override
  State<AdminPersonalPage> createState() => _AdminPersonalPageState();
}

class _AdminPersonalPageState extends State<AdminPersonalPage> {
  final AdminPersonalService _servicio = AdminPersonalService();

  static const _fondo = Color(0xFFF8F5EF);
  static const _superficie = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _borde = Color(0xFFE5DDCF);
  static const _rojo = Color(0xFFA03930);

  List<AdminPersonal> _empleados = [];
  bool _cargando = true;
  String? _error;
  String _filtroPuesto = '';
  String _filtroEstatus = '';
  int _versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarPersonal();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  Future<void> _cargarPersonal() async {
    final version = ++_versionConsulta;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final empleados = await _servicio.obtenerPersonal();
      if (!mounted || version != _versionConsulta) return;
      empleados.sort(
        (a, b) => a.nombreCompleto.toLowerCase().compareTo(
          b.nombreCompleto.toLowerCase(),
        ),
      );
      setState(() {
        _empleados = empleados;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<AdminPersonal> get _filtrados => _empleados.where((empleado) {
    return (_filtroPuesto.isEmpty || empleado.puesto == _filtroPuesto) &&
        (_filtroEstatus.isEmpty || empleado.estatus == _filtroEstatus);
  }).toList();

  void _mensaje(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? _rojo : const Color(0xFF287447),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // El selector se muestra DESPUÉS de elegir la operación.
  // La edición y la baja solo admiten personal activo.
  Future<AdminPersonal?> _seleccionarEmpleado({
    required String titulo,
    required bool soloActivos,
  }) async {
    if (_cargando || _error != null) {
      _mensaje('Actualiza primero el directorio de empleados.', error: true);
      return null;
    }

    final disponibles = _empleados
        .where((e) => !soloActivos || e.estaActivo)
        .toList();

    if (disponibles.isEmpty) {
      _mensaje(
        soloActivos
            ? 'No hay empleados activos para esta operación.'
            : 'No hay empleados registrados.',
        error: true,
      );
      return null;
    }

    return showDialog<AdminPersonal>(
      context: context,
      builder: (dialogContext) {
        String busqueda = '';
        return StatefulBuilder(
          builder: (context, cambiarDialogo) {
            final resultado = disponibles.where((e) {
              final palabra = busqueda.trim().toLowerCase();
              return e.nombreCompleto.toLowerCase().contains(palabra) ||
                  e.correo.toLowerCase().contains(palabra) ||
                  e.idPersonal.toString().contains(palabra);
            }).toList();

            return AlertDialog(
              title: Text(titulo),
              contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              content: SizedBox(
                width: 480,
                height: MediaQuery.sizeOf(context).height * 0.53,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: 'Buscar empleado',
                        hintText: 'Nombre, correo o ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (valor) => cambiarDialogo(() {
                        busqueda = valor;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: resultado.isEmpty
                          ? const Center(
                              child: Text('No hay empleados coincidentes.'),
                            )
                          : ListView.separated(
                              itemCount: resultado.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final e = resultado[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFF3EAD8),
                                    child: Icon(
                                      Icons.badge_outlined,
                                      color: _doradoOscuro,
                                    ),
                                  ),
                                  title: Text(
                                    e.nombreCompleto,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${e.puesto} · ${e.estatus} · ID ${e.idPersonal}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.pop(dialogContext, e),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _registrar() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const AdminRegistrarPersonalPage()),
    );
    if (!mounted) return;
    if (id != null && id > 0) {
      _mensaje('Empleado registrado correctamente. ID $id.');
    }
    await _cargarPersonal();
  }

  Future<void> _editar() async {
    final empleado = await _seleccionarEmpleado(
      titulo: 'Seleccionar empleado para editar',
      soloActivos: true,
    );
    if (!mounted || empleado == null) return;
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) =>
            AdminEditarPersonalPage(idPersonal: empleado.idPersonal),
      ),
    );
    if (!mounted) return;
    if (id != null && id > 0) {
      _mensaje('Empleado #$id actualizado correctamente.');
    }
    await _cargarPersonal();
  }

  Future<void> _darDeBaja() async {
    final empleado = await _seleccionarEmpleado(
      titulo: 'Seleccionar empleado para baja',
      soloActivos: true,
    );
    if (!mounted || empleado == null) return;

    final resultado = await Navigator.of(context).push<BajaPersonalResponse>(
      MaterialPageRoute(
        builder: (_) => AdminBajaPersonalPage(idPersonal: empleado.idPersonal),
      ),
    );
    if (!mounted) return;
    if (resultado != null) {
      final detalle = empleado.esEntrenador
          ? ' Clientes desasignados: ${resultado.clientesDesasignados}.'
          : '';
      _mensaje('Empleado #${resultado.idPersonal} dado de baja.$detalle');
    }
    await _cargarPersonal();
  }

  Future<void> _abrirNomina() async {
    final empleado = await _seleccionarEmpleado(
      titulo: 'Seleccionar empleado para nómina',
      soloActivos: false,
    );
    if (!mounted || empleado == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminNominaGestionPage(idPersonal: empleado.idPersonal),
      ),
    );
    if (!mounted) return;
    await _cargarPersonal();
  }

  Widget _tarjetaGestion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback accion,
  }) {
    return Material(
      color: _superficie,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: accion,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 39,
                width: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: _doradoOscuro, size: 22),
              ),
              const SizedBox(height: 11),
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _texto,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _secundario, fontSize: 11),
              ),
              const Spacer(),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Abrir módulo',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: _doradoOscuro, size: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelGestion() {
    final tarjetas = [
      _tarjetaGestion(
        icono: Icons.person_add_alt_1_outlined,
        titulo: 'Registrar empleado',
        descripcion: 'Dar de alta entrenadores y recepcionistas',
        accion: _registrar,
      ),
      _tarjetaGestion(
        icono: Icons.edit_note_outlined,
        titulo: 'Editar información',
        descripcion: 'Selecciona un empleado activo',
        accion: _editar,
      ),
      _tarjetaGestion(
        icono: Icons.folder_off_outlined,
        titulo: 'Bajas de empleados',
        descripcion: 'Registrar bajas y conservar historial',
        accion: _darDeBaja,
      ),
      _tarjetaGestion(
        icono: Icons.account_balance_wallet_outlined,
        titulo: 'Salarios y nómina',
        descripcion: 'Sueldos, historial y pagos',
        accion: _abrirNomina,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tarjetas.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 176,
          ),
          itemBuilder: (_, i) => tarjetas[i],
        );
      },
    );
  }

  Widget _selectorFiltro({
    required String titulo,
    required String valor,
    required List<DropdownMenuItem<String>> opciones,
    required ValueChanged<String?> cambiar,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$titulo-$valor'),
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: titulo,
        filled: true,
        fillColor: _superficie,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: opciones,
      onChanged: cambiar,
    );
  }

  Widget _tarjetaDirectorio(AdminPersonal empleado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFF3EAD8),
            child: Icon(Icons.person_outline, color: _doradoOscuro),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empleado.nombreCompleto,
                  style: const TextStyle(
                    color: _texto,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${empleado.puesto} · ID ${empleado.idPersonal}',
                  style: const TextStyle(color: _secundario, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  empleado.correo,
                  style: const TextStyle(color: _secundario, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sueldo mensual: \$${empleado.salario.toStringAsFixed(2)} MXN',
                  style: const TextStyle(color: _texto, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Horario: ${empleado.horario.isEmpty ? 'Sin asignar' : empleado.horario}',
                  style: const TextStyle(color: _secundario, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: empleado.estaActivo
                  ? const Color(0xFFE7F3E8)
                  : const Color(0xFFFCE9E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              empleado.estatus,
              style: TextStyle(
                color: empleado.estaActivo ? const Color(0xFF287447) : _rojo,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empleados = _filtrados;
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        title: const Text(
          'Administrar Empleados',
          style: TextStyle(color: _texto, fontWeight: FontWeight.w700),
        ),
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        actions: [
          IconButton(
            tooltip: 'Actualizar empleados',
            onPressed: _cargando ? null : _cargarPersonal,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _dorado,
        onRefresh: _cargarPersonal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 970),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / ADMINISTRACIÓN',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Equipo de GymFlow',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Consulta expedientes, puestos y estatus de los empleados.',
                    style: TextStyle(color: _secundario, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'GESTIÓN DEL PERSONAL',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gestión del personal',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Selecciona una función para administrar el equipo.',
                    style: TextStyle(color: _secundario, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _panelGestion(),
                  const SizedBox(height: 28),
                  const Text(
                    'DIRECTORIO LABORAL',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Personal registrado',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = constraints.maxWidth;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: ancho > 570 ? (ancho - 10) / 2 : ancho,
                            child: _selectorFiltro(
                              titulo: 'Puesto',
                              valor: _filtroPuesto,
                              opciones: const [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: 'Entrenador',
                                  child: Text('Entrenadores'),
                                ),
                                DropdownMenuItem(
                                  value: 'Recepcionista',
                                  child: Text('Recepcionistas'),
                                ),
                              ],
                              cambiar: (v) =>
                                  setState(() => _filtroPuesto = v ?? ''),
                            ),
                          ),
                          SizedBox(
                            width: ancho > 570 ? (ancho - 10) / 2 : ancho,
                            child: _selectorFiltro(
                              titulo: 'Estatus',
                              valor: _filtroEstatus,
                              opciones: const [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: 'Activo',
                                  child: Text('Activos'),
                                ),
                                DropdownMenuItem(
                                  value: 'Inactivo',
                                  child: Text('Inactivos'),
                                ),
                              ],
                              cambiar: (v) =>
                                  setState(() => _filtroEstatus = v ?? ''),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_error != null)
                    Column(
                      children: [
                        Text(_error!, style: const TextStyle(color: _rojo)),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _cargarPersonal,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      '${empleados.length} de ${_empleados.length} empleados',
                      style: const TextStyle(
                        color: _doradoOscuro,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (empleados.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No hay empleados con esos filtros.'),
                        ),
                      )
                    else
                      ...empleados.map(_tarjetaDirectorio),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
