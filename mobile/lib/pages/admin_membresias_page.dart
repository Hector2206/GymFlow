import 'package:flutter/material.dart';

import '../models/admin_membresia.dart';
import '../services/admin_membresia_service.dart';

class AdminMembresiasPage extends StatefulWidget {
  const AdminMembresiasPage({super.key});

  @override
  State<AdminMembresiasPage> createState() => _AdminMembresiasPageState();
}

class _AdminMembresiasPageState extends State<AdminMembresiasPage> {
  final _servicio = AdminMembresiaService();

  static const fondo = Color(0xFFF8F5EF);
  static const superficie = Color(0xFFFFFDF8);
  static const dorado = Color(0xFFB58A2A);
  static const doradoOscuro = Color(0xFF8A6814);
  static const texto = Color(0xFF2F2A24);
  static const secundario = Color(0xFF777067);
  static const borde = Color(0xFFE5DDCF);
  static const rojo = Color(0xFFA03930);
  static const verde = Color(0xFF287447);

  List<AdminMembresia> _membresias = [];
  bool _cargando = true;
  bool _operando = false;
  String _error = '';
  int _versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  Future<void> _cargar() async {
    final version = ++_versionConsulta;

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final lista = await _servicio.obtenerCatalogo();

      if (!mounted || version != _versionConsulta) return;

      setState(() {
        _membresias = lista;
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

  void _mensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: error ? rojo : verde,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _ejecutar(
    Future<void> Function() operacion,
    String confirmacion,
  ) async {
    if (_operando) return;

    setState(() => _operando = true);

    try {
      await operacion();
      if (!mounted) return;

      await _cargar();
      if (!mounted) return;

      _mensaje(confirmacion);
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() => _operando = false);
      }
    }
  }

  String? _validarPrecio(String? valor) {
    final textoPrecio = valor?.trim() ?? '';
    final numero = double.tryParse(textoPrecio);

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(textoPrecio) ||
        numero == null ||
        !numero.isFinite ||
        numero <= 0) {
      return 'Escribe un precio válido (ej. 250.00).';
    }

    return null;
  }

  Future<void> _abrirFormulario([AdminMembresia? original]) async {
    if (_operando) return;

    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: original?.nombrePlan ?? '');
    final descripcion = TextEditingController(
      text: original?.descripcion ?? '',
    );
    final mensual = TextEditingController(
      text: original?.costoMensual.toStringAsFixed(2) ?? '',
    );
    final anual = TextEditingController(
      text: original?.costoAnualidad.toStringAsFixed(2) ?? '',
    );

    final datos = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogo) => AlertDialog(
        backgroundColor: superficie,
        title: Text(original == null ? 'Crear membresía' : 'Editar membresía'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombre,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del plan *',
                      prefixIcon: Icon(Icons.card_membership),
                    ),
                    validator: (valor) {
                      if ((valor ?? '').trim().isEmpty) {
                        return 'Escribe el nombre de la membresía.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descripcion,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mensual,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio mensual *',
                      prefixText: '\$ ',
                    ),
                    validator: _validarPrecio,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: anual,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio anual *',
                      prefixText: '\$ ',
                    ),
                    validator: _validarPrecio,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Los precios guardados serán oficiales. '
                    'El Backend conserva el historial de cambios.',
                    style: TextStyle(fontSize: 12, color: secundario),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: doradoOscuro),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              Navigator.pop(dialogo, {
                'nombre': nombre.text.trim(),
                'descripcion': descripcion.text.trim(),
                'mensual': mensual.text.trim(),
                'anual': anual.text.trim(),
              });
            },
            child: Text(original == null ? 'Crear plan' : 'Guardar cambios'),
          ),
        ],
      ),
    );

    nombre.dispose();
    descripcion.dispose();
    mensual.dispose();
    anual.dispose();

    if (datos == null || !mounted) return;

    final precioMensual = double.parse(datos['mensual']!);
    final precioAnual = double.parse(datos['anual']!);

    await _ejecutar(
      () => original == null
          ? _servicio.crearMembresia(
              nombrePlan: datos['nombre']!,
              descripcion: datos['descripcion']!,
              costoMensual: precioMensual,
              costoAnualidad: precioAnual,
            )
          : _servicio.editarMembresia(
              idMembresia: original.idMembresia,
              nombrePlan: datos['nombre']!,
              descripcion: datos['descripcion']!,
              costoMensual: precioMensual,
              costoAnualidad: precioAnual,
            ),
      original == null
          ? 'Membresía creada correctamente.'
          : 'Membresía actualizada correctamente.',
    );
  }

  Future<void> _cambiarEstado(AdminMembresia membresia) async {
    if (_operando) return;

    final nuevoEstado = !membresia.activo;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        backgroundColor: superficie,
        title: Text(nuevoEstado ? 'Activar membresía' : 'Desactivar membresía'),
        content: Text(
          '¿Deseas ${nuevoEstado ? 'activar' : 'desactivar'} '
          'el plan "${membresia.nombrePlan}"?\n\n'
          'La operación quedará registrada en Backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: nuevoEstado ? verde : rojo,
            ),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await _ejecutar(
      () => _servicio.cambiarEstado(
        idMembresia: membresia.idMembresia,
        activo: nuevoEstado,
      ),
      nuevoEstado
          ? 'Membresía activada correctamente.'
          : 'Membresía desactivada correctamente.',
    );
  }

  Future<void> _mostrarHistorial(AdminMembresia membresia) async {
    if (_operando) return;

    setState(() => _operando = true);

    try {
      final historial = await _servicio.obtenerHistorial(membresia.idMembresia);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogo) => AlertDialog(
          backgroundColor: superficie,
          title: Text('Historial: ${membresia.nombrePlan}'),
          content: SizedBox(
            width: 480,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: historial.isEmpty
                  ? const Text('Todavía no hay cambios de precio registrados.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: historial.length,
                      itemBuilder: (_, indice) {
                        final registro = historial[indice];

                        return Card(
                          color: fondo,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: doradoOscuro,
                            ),
                            title: Text(
                              'Mensual: '
                              '\$${registro.costoMensual.toStringAsFixed(2)}'
                              '\nAnual: '
                              '\$${registro.costoAnualidad.toStringAsFixed(2)}',
                            ),
                            subtitle: Text(
                              'Fecha: ${registro.registradoEn}\n'
                              'Origen: ${registro.origen}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogo),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() => _operando = false);
      }
    }
  }

  Widget _tarjeta(AdminMembresia plan) {
    return Card(
      color: superficie,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership_outlined, color: doradoOscuro),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan.nombrePlan,
                    style: const TextStyle(
                      color: texto,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  plan.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: plan.activo ? verde : rojo,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (plan.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.descripcion, style: const TextStyle(color: secundario)),
            ],
            const SizedBox(height: 15),
            Text(
              'Mensualidad: '
              '\$${plan.costoMensual.toStringAsFixed(2)} MXN',
              style: const TextStyle(color: texto, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              'Anualidad: '
              '\$${plan.costoAnualidad.toStringAsFixed(2)} MXN',
              style: const TextStyle(color: texto, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(
              'ID de membresía: ${plan.idMembresia}',
              style: const TextStyle(color: secundario, fontSize: 12),
            ),
            const Divider(height: 25),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _operando ? null : () => _abrirFormulario(plan),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: _operando ? null : () => _cambiarEstado(plan),
                  icon: Icon(
                    plan.activo
                        ? Icons.toggle_off_outlined
                        : Icons.toggle_on_outlined,
                    size: 18,
                  ),
                  label: Text(plan.activo ? 'Desactivar' : 'Activar'),
                ),
                TextButton.icon(
                  onPressed: _operando ? null : () => _mostrarHistorial(plan),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Historial'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Administrar Membresías'),
        backgroundColor: superficie,
        actions: [
          IconButton(
            tooltip: 'Actualizar catálogo',
            onPressed: _cargando || _operando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: dorado,
        onRefresh: _operando ? () async {} : _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'GYMFLOW / ADMINISTRACIÓN',
              style: TextStyle(
                color: doradoOscuro,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Membresías',
              style: TextStyle(
                color: texto,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Administra los planes y sus precios oficiales.',
              style: TextStyle(color: secundario),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _operando ? null : () => _abrirFormulario(),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Crear nueva membresía'),
                style: FilledButton.styleFrom(
                  backgroundColor: doradoOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (_operando) const LinearProgressIndicator(color: dorado),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(child: CircularProgressIndicator(color: dorado)),
              )
            else if (_error.isNotEmpty) ...[
              Text(_error, style: const TextStyle(color: rojo)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar consulta'),
              ),
            ] else if (_membresias.isEmpty)
              const Text(
                'No hay membresías registradas.',
                style: TextStyle(color: secundario),
              )
            else
              ..._membresias.map(_tarjeta),
          ],
        ),
      ),
    );
  }
}
