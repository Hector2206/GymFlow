import 'package:flutter/material.dart';

import '../models/admin_administrador.dart';
import '../services/admin_administradores_service.dart';

class AdminAdministradoresPage extends StatefulWidget {
  const AdminAdministradoresPage({super.key});

  @override
  State<AdminAdministradoresPage> createState() =>
      _AdminAdministradoresPageState();
}

class _AdminAdministradoresPageState extends State<AdminAdministradoresPage> {
  final _servicio = AdminAdministradoresService();

  static const _fondo = Color(0xFFF8F5EF);
  static const _superficie = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _borde = Color(0xFFE5DDCF);
  static const _rojo = Color(0xFFA03930);
  static const _verde = Color(0xFF287447);

  List<AdminAdministrador> _administradores = [];

  bool _cargando = false;
  String? _error;
  String _busqueda = '';

  int _versionConsulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarAdministradores();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  Future<void> _cargarAdministradores() async {
    if (_cargando) return;

    final version = ++_versionConsulta;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _servicio.obtenerAdministradores();

      if (!mounted || version != _versionConsulta) {
        return;
      }

      resultado.sort(
        (a, b) => a.nombreCompleto.toLowerCase().compareTo(
          b.nombreCompleto.toLowerCase(),
        ),
      );

      setState(() {
        _administradores = resultado;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || version != _versionConsulta) {
        return;
      }

      setState(() {
        _cargando = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<AdminAdministrador> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();

    if (texto.isEmpty) {
      return _administradores;
    }

    return _administradores.where((administrador) {
      return administrador.nombreCompleto.toLowerCase().contains(texto) ||
          administrador.correo.toLowerCase().contains(texto) ||
          administrador.idUsuario.toString().contains(texto);
    }).toList();
  }

  int get _activos => _administradores.where((a) => a.estaActivo).length;

  Widget _resumen(String titulo, String cantidad) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _superficie,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(color: _secundario, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              cantidad,
              style: const TextStyle(
                color: _doradoOscuro,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAdministrador(AdminAdministrador admin) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: _doradoOscuro,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.nombreCompleto,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      admin.correo,
                      style: const TextStyle(color: _secundario, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Horario: ${admin.horario.isEmpty ? 'No registrado' : admin.horario}',
            style: const TextStyle(color: _secundario),
          ),

          const SizedBox(height: 6),

          Text(
            'ID de usuario: ${admin.idUsuario}',
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: admin.estaActivo
                  ? const Color(0xFFE7F3E8)
                  : const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              admin.estatus,
              style: TextStyle(
                color: admin.estaActivo ? _verde : _rojo,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (dialogo) => AlertDialog(
                    title: Text(admin.nombreCompleto),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Correo: ${admin.correo}'),
                          Text('Teléfono: ${admin.telefono}'),
                          Text('Horario: ${admin.horario}'),
                          Text('Estado: ${admin.estatus}'),
                          Text('ID Usuario: ${admin.idUsuario}'),
                          Text('ID Personal: ${admin.idPersonal}'),
                          Text('Fecha alta: ${admin.fechaAlta}'),
                          if (admin.fechaBaja != null)
                            Text('Fecha baja: ${admin.fechaBaja}'),
                        ],
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
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver detalles'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _doradoOscuro,
                side: const BorderSide(color: Color(0xFFD8C8A5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final administradores = _filtrados;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        foregroundColor: _doradoOscuro,
        title: const Text(
          'Administrar Administradores',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar administradores',
            onPressed: _cargando ? null : _cargarAdministradores,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
        children: [
          const Text(
            'GYMFLOW / ADMINISTRACIÓN',
            style: TextStyle(
              color: _doradoOscuro,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 9),

          const Text(
            'Cuentas administrativas',
            style: TextStyle(
              color: _texto,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Consulta las cuentas con permisos '
            'de Administrador registradas en GymFlow.',
            style: TextStyle(color: _secundario, fontSize: 13),
          ),

          const SizedBox(height: 23),

          if (_cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(color: _dorado),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, style: const TextStyle(color: _rojo)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _cargarAdministradores,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                _resumen('Total', '${_administradores.length}'),
                const SizedBox(width: 12),
                _resumen('Activos', '$_activos'),
              ],
            ),

            const SizedBox(height: 22),

            TextField(
              onChanged: (valor) {
                setState(() => _busqueda = valor);
              },
              decoration: InputDecoration(
                labelText: 'Buscar administrador',
                hintText: 'Nombre, correo o ID',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: _superficie,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),

            const SizedBox(height: 21),

            if (administradores.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: _superficie,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _borde),
                ),
                child: const Center(
                  child: Text(
                    'No se encontraron administradores.',
                    style: TextStyle(color: _secundario),
                  ),
                ),
              )
            else
              ...administradores.map(_tarjetaAdministrador),
          ],
        ],
      ),
    );
  }
}
