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

  List<AdminMembresia> membresias = [];
  bool cargando = true;
  String error = '';
  int versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    cargarMembresias();
  }

  @override
  void dispose() {
    versionConsulta++;
    super.dispose();
  }

  Future<void> cargarMembresias() async {
    final version = ++versionConsulta;

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final resultado = await _servicio.obtenerCatalogo();

      if (!mounted || version != versionConsulta) {
        return;
      }

      setState(() {
        membresias = resultado;
        cargando = false;
      });
    } catch (e) {
      if (!mounted || version != versionConsulta) {
        return;
      }

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  Widget tarjetaMembresia(AdminMembresia membresia) {
    return Card(
      color: superficie,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership_outlined, color: doradoOscuro),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    membresia.nombrePlan,
                    style: const TextStyle(
                      color: texto,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  membresia.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: membresia.activo
                        ? const Color(0xFF287447)
                        : secundario,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Precio mensual: '
              '\$${membresia.costoMensual.toStringAsFixed(2)} MXN',
              style: const TextStyle(color: texto),
            ),
            const SizedBox(height: 7),
            Text(
              'Precio anual: '
              '\$${membresia.costoAnualidad.toStringAsFixed(2)} MXN',
              style: const TextStyle(color: texto),
            ),
            if (membresia.descripcion.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                membresia.descripcion,
                style: const TextStyle(color: secundario),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'ID: ${membresia.idMembresia}',
              style: const TextStyle(color: secundario, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget funcionPendiente(String titulo, String descripcion, IconData icono) {
    return Card(
      color: superficie,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: borde),
      ),
      child: ListTile(
        leading: Icon(icono, color: doradoOscuro),
        title: Text(
          titulo,
          style: const TextStyle(color: texto, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$descripcion\n'
          'Interfaz de edición pendiente de integrar.',
          style: const TextStyle(color: secundario, fontSize: 12),
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
            tooltip: 'Actualizar',
            onPressed: cargando ? null : cargarMembresias,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: dorado,
        onRefresh: cargarMembresias,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'GYMFLOW / ADMINISTRACIÓN',
              style: TextStyle(
                color: doradoOscuro,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Catálogo oficial',
              style: TextStyle(
                color: texto,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Planes y precios consultados '
              'directamente desde Backend.',
              style: TextStyle(color: secundario),
            ),
            const SizedBox(height: 22),
            if (cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(26),
                  child: CircularProgressIndicator(color: dorado),
                ),
              )
            else if (error.isNotEmpty) ...[
              Text(error, style: const TextStyle(color: Color(0xFFA03930))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: cargarMembresias,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar consulta'),
              ),
            ] else if (membresias.isEmpty)
              const Text(
                'No hay membresías registradas.',
                style: TextStyle(color: secundario),
              )
            else
              ...membresias.map(tarjetaMembresia),
            const SizedBox(height: 24),
            const Text(
              'OPERACIONES POR INTEGRAR',
              style: TextStyle(
                color: doradoOscuro,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            funcionPendiente(
              'Crear membresía',
              'Registrar nuevos planes oficiales.',
              Icons.add_card_outlined,
            ),
            funcionPendiente(
              'Editar membresía',
              'Modificar nombre, descripción y precios.',
              Icons.edit_outlined,
            ),
            funcionPendiente(
              'Activar o desactivar',
              'Cambiar el estado de un plan.',
              Icons.toggle_on_outlined,
            ),
            funcionPendiente(
              'Historial de precios',
              'Consultar los cambios registrados.',
              Icons.history_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
