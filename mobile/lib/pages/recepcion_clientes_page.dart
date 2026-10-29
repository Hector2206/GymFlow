import 'package:flutter/material.dart';

import '../models/cliente_resumen.dart';
import '../services/cliente_consulta_service.dart';
import 'asignacion_entrenadores_page.dart';

class RecepcionClientesPage extends StatefulWidget {
  const RecepcionClientesPage({super.key});

  @override
  State<RecepcionClientesPage> createState() => _RecepcionClientesPageState();
}

class _RecepcionClientesPageState extends State<RecepcionClientesPage> {
  final _servicio = ClienteConsultaService();
  final _busqueda = TextEditingController();

  static const fondo = Color(0xFFF8F5EF);
  static const superficie = Color(0xFFFFFDF8);
  static const dorado = Color(0xFFB58A2A);
  static const doradoOscuro = Color(0xFF8A6814);
  static const texto = Color(0xFF2F2A24);
  static const secundario = Color(0xFF777067);
  static const borde = Color(0xFFE5DDCF);

  List<ClienteResumen> clientes = [];
  bool cargando = true;
  String error = '';
  int versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  @override
  void dispose() {
    versionConsulta++;
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> cargarClientes() async {
    final version = ++versionConsulta;

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final resultado = await _servicio.obtenerClientes();

      if (!mounted || version != versionConsulta) {
        return;
      }

      setState(() {
        clientes = resultado;
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

  List<ClienteResumen> get clientesFiltrados {
    final buscar = _busqueda.text.trim().toLowerCase();

    if (buscar.isEmpty) {
      return clientes;
    }

    return clientes.where((cliente) {
      return cliente.nombreCompleto.toLowerCase().contains(buscar) ||
          cliente.idCliente.toString().contains(buscar);
    }).toList();
  }

  Widget tarjetaCliente(ClienteResumen cliente) {
    return Card(
      color: superficie,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: borde),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF3EAD8),
          child: Icon(Icons.person_outline, color: doradoOscuro),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: const TextStyle(color: texto, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('Cliente #${cliente.idCliente}'),
            const SizedBox(height: 5),
            Text(
              cliente.nombreEntrenador?.isNotEmpty == true
                  ? 'Entrenador: ${cliente.nombreEntrenador}'
                  : 'Sin entrenador asignado',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibles = clientesFiltrados;

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Administrar Clientes'),
        backgroundColor: superficie,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargando ? null : cargarClientes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: dorado,
        onRefresh: cargarClientes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'GYMFLOW / RECEPCIÓN',
              style: TextStyle(
                color: doradoOscuro,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Directorio de clientes',
              style: TextStyle(
                color: texto,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consulta clientes registrados '
              'y sus entrenadores asignados.',
              style: TextStyle(color: secundario),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 18),
            if (cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: dorado),
                ),
              )
            else if (error.isNotEmpty) ...[
              Text(error, style: const TextStyle(color: Color(0xFFA03930))),
              TextButton.icon(
                onPressed: cargarClientes,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ] else if (visibles.isEmpty)
              const Text(
                'No se encontraron clientes.',
                style: TextStyle(color: secundario),
              )
            else
              ...visibles.map(tarjetaCliente),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AsignacionEntrenadoresPage(),
                  ),
                );
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Ir a asignación de entrenadores'),
            ),
            const SizedBox(height: 12),
            const Text(
              'La edición y baja de clientes '
              'requiere endpoints adicionales. '
              'Esta pantalla no modifica registros.',
              style: TextStyle(color: secundario, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
