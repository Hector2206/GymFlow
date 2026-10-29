import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/admin_administrador.dart';
import '../services/admin_administradores_service.dart';
import '../services/auth_service.dart';

class AdminAdministradoresPage extends StatefulWidget {
  const AdminAdministradoresPage({super.key});

  @override
  State<AdminAdministradoresPage> createState() =>
      _AdminAdministradoresPageState();
}

class _AdminAdministradoresPageState extends State<AdminAdministradoresPage> {
  static const _fondo = Color(0xFFF8F5EF);
  static const _blanco = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _texto = Color(0xFF2F2A24);
  static const _gris = Color(0xFF777067);
  static const _rojo = Color(0xFFA03930);
  static const _verde = Color(0xFF287447);

  final _servicio = AdminAdministradoresService();
  final _auth = AuthService();

  List<AdminAdministrador> _administradores = [];
  bool _cargando = false;
  final bool _operando = false;
  String? _error;
  String _busqueda = '';
  int? _miIdUsuario;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _version++;
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _obtenerMiId();
    if (mounted) await _cargar();
  }

  Future<void> _obtenerMiId() async {
    try {
      final token = await _auth.obtenerToken();
      if (token == null) return;

      final partes = token.split('.');
      if (partes.length != 3) return;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );

      if (payload is! Map<String, dynamic>) return;

      final valor = payload['sub'] ?? payload['id_usuario'];

      final id = valor is int ? valor : int.tryParse(valor?.toString() ?? '');

      if (mounted) {
        setState(() {
          _miIdUsuario = id != null && id > 0 ? id : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _miIdUsuario = null);
    }
  }

  Future<void> _cargar() async {
    if (_cargando || _operando) return;

    final actual = ++_version;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final datos = await _servicio.obtenerAdministradores();

      if (!mounted || actual != _version) return;

      datos.sort(
        (a, b) => a.nombreCompleto.toLowerCase().compareTo(
          b.nombreCompleto.toLowerCase(),
        ),
      );

      setState(() {
        _administradores = datos;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || actual != _version) return;

      setState(() {
        _cargando = false;
        _error = _mensajeError(error);
      });
    }
  }

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _aviso(String texto, {bool esError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? _rojo : _verde,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fechaApi(DateTime fecha) {
    return '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return respuesta == true;
  }

  Future<void> _abrirFormulario({AdminAdministrador? administrador}) async {
    if (_operando) return;

    final editando = administrador != null;

    if (editando && !administrador.estaActivo) {
      _aviso('No se puede editar un administrador inactivo.', esError: true);
      return;
    }

    // Para edición se consulta el expediente actualizado.
    AdminAdministrador? actual = administrador;

    if (editando) {
      try {
        actual = await _servicio.obtenerPorId(administrador.idUsuario);
        if (!mounted) return;

        if (!actual.estaActivo) {
          _aviso('Esta cuenta ya está inactiva.', esError: true);
          await _cargar();
          return;
        }
      } catch (error) {
        _aviso(_mensajeError(error), esError: true);
        return;
      }
    }

    if (!mounted) return;

    final nombre = TextEditingController(text: actual?.nombreCompleto ?? '');
    final correo = TextEditingController(text: actual?.correo ?? '');
    final telefono = TextEditingController(text: actual?.telefono ?? '');
    final horario = TextEditingController(text: actual?.horario ?? '');
    final sueldo = TextEditingController();
    final password = TextEditingController();

    var fecha = DateTime.now();
    var guardando = false;
    var incierto = false;
    String? errorFormulario;
    var ocultarPassword = true;

    final llave = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogo) => StatefulBuilder(
        builder: (ctx, actualizar) => AlertDialog(
          backgroundColor: _blanco,
          title: Text(
            editando ? 'Editar administrador' : 'Registrar administrador',
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Form(
                key: llave,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _campo(
                      nombre,
                      'Nombre completo',
                      icono: Icons.person_outline,
                    ),
                    _campo(
                      correo,
                      'Correo electrónico',
                      icono: Icons.email_outlined,
                      teclado: TextInputType.emailAddress,
                    ),
                    _campo(
                      telefono,
                      'Teléfono de 10 dígitos',
                      icono: Icons.phone_outlined,
                      teclado: TextInputType.phone,
                    ),
                    _campo(
                      horario,
                      'Horario (ej. 09:00 - 17:00)',
                      icono: Icons.schedule,
                    ),

                    if (!editando) ...[
                      const SizedBox(height: 13),
                      OutlinedButton.icon(
                        onPressed: guardando
                            ? null
                            : () async {
                                final elegida = await showDatePicker(
                                  context: ctx,
                                  initialDate: fecha,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );

                                if (elegida != null) {
                                  actualizar(() => fecha = elegida);
                                }
                              },
                        icon: const Icon(Icons.calendar_today),
                        label: Text('Contratación: ${_fechaApi(fecha)}'),
                      ),
                      _campo(
                        sueldo,
                        'Sueldo mensual (MXN)',
                        icono: Icons.payments_outlined,
                        teclado: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: password,
                        obscureText: ocultarPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña inicial',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => actualizar(
                              () => ocultarPassword = !ocultarPassword,
                            ),
                          ),
                        ),
                        validator: (valor) {
                          if ((valor ?? '').length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (errorFormulario != null) ...[
                      const SizedBox(height: 13),
                      Text(
                        errorFormulario!,
                        style: const TextStyle(color: _rojo),
                      ),
                    ],

                    if (incierto) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'El resultado es incierto. Consulta '
                        'el listado antes de volver a guardar.',
                        style: TextStyle(color: _rojo),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(dialogo, false),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _dorado),
              onPressed: guardando || incierto
                  ? null
                  : () async {
                      if (!(llave.currentState?.validate() ?? false)) {
                        return;
                      }

                      final email = correo.text.trim();

                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email)) {
                        actualizar(() {
                          errorFormulario = 'Ingresa un correo válido.';
                        });
                        return;
                      }

                      if (!RegExp(r'^\d{10}$').hasMatch(telefono.text.trim())) {
                        actualizar(() {
                          errorFormulario =
                              'Ingresa un teléfono de 10 dígitos.';
                        });
                        return;
                      }

                      final salario = double.tryParse(sueldo.text.trim());

                      if (!editando &&
                          (salario == null ||
                              !salario.isFinite ||
                              salario <= 0)) {
                        actualizar(() {
                          errorFormulario = 'Ingresa un sueldo válido.';
                        });
                        return;
                      }

                      actualizar(() {
                        guardando = true;
                        errorFormulario = null;
                      });

                      try {
                        if (editando) {
                          await _servicio.editar(
                            idUsuario: administrador.idUsuario,
                            datos: EditarAdministradorRequest(
                              nombreCompleto: nombre.text,
                              correo: correo.text,
                              telefono: telefono.text,
                              horario: horario.text,
                            ),
                          );
                        } else {
                          await _servicio.crear(
                            CrearAdministradorRequest(
                              nombreCompleto: nombre.text,
                              correo: correo.text,
                              telefono: telefono.text,
                              fechaContratacion: _fechaApi(fecha),
                              sueldo: salario!,
                              horario: horario.text,
                              password: password.text,
                            ),
                          );
                        }

                        if (!dialogo.mounted) return;
                        Navigator.pop(dialogo, true);
                      } catch (error) {
                        if (!dialogo.mounted) return;

                        final texto = _mensajeError(error);

                        actualizar(() {
                          guardando = false;
                          errorFormulario = texto;

                          incierto =
                              texto.contains('tardó demasiado') ||
                              texto.contains('conectar con Backend') ||
                              texto.contains('HTTP 5') ||
                              error is FormatException;
                        });
                      }
                    },
              child: Text(
                guardando
                    ? 'Guardando...'
                    : editando
                    ? 'Guardar cambios'
                    : 'Registrar',
              ),
            ),
          ],
        ),
      ),
    );

    nombre.dispose();
    correo.dispose();
    telefono.dispose();
    horario.dispose();
    sueldo.dispose();
    password.dispose();

    if (!mounted) return;

    if (resultado == true) {
      _aviso(
        editando
            ? 'Administrador actualizado correctamente.'
            : 'Administrador registrado correctamente.',
      );
    }

    // También se consulta después de un resultado incierto.
    await _cargar();
  }

  Widget _campo(
    TextEditingController controlador,
    String etiqueta, {
    required IconData icono,
    TextInputType teclado = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controlador,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono),
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          if ((valor ?? '').trim().isEmpty) {
            return 'Campo obligatorio';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _darDeBaja(AdminAdministrador administrador) async {
    if (_operando || !administrador.estaActivo) return;

    // Si no se conoce el usuario actual, se bloquea la baja.
    if (_miIdUsuario == null) {
      _aviso(
        'No se pudo verificar tu identidad. '
        'Vuelve a iniciar sesión.',
        esError: true,
      );
      return;
    }

    if (administrador.idUsuario == _miIdUsuario) {
      _aviso('No puedes dar de baja tu propia cuenta.', esError: true);
      return;
    }

    final motivo = TextEditingController();
    var fecha = DateTime.now();
    var guardando = false;
    var resultadoIncierto = false;
    String? errorBaja;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogo) => StatefulBuilder(
        builder: (ctx, actualizar) => AlertDialog(
          title: const Text('Dar de baja administrador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  administrador.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: motivo,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de baja',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: guardando
                      ? null
                      : () async {
                          final elegida = await showDatePicker(
                            context: ctx,
                            initialDate: fecha,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (elegida != null) {
                            actualizar(() => fecha = elegida);
                          }
                        },
                  icon: const Icon(Icons.event),
                  label: Text('Fecha: ${_fechaApi(fecha)}'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esta operación desactivará el acceso '
                  'del administrador y conservará su auditoría.',
                ),
                if (errorBaja != null) ...[
                  const SizedBox(height: 10),
                  Text(errorBaja!, style: const TextStyle(color: _rojo)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(dialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _rojo),
              onPressed: guardando || resultadoIncierto
                  ? null
                  : () async {
                      if (motivo.text.trim().isEmpty) {
                        actualizar(() {
                          errorBaja = 'Escribe el motivo de baja.';
                        });
                        return;
                      }

                      final confirmado = await _confirmar(
                        'Confirmación final',
                        '¿Dar de baja a '
                            '${administrador.nombreCompleto}?\n\n'
                            'No se podrá utilizar la cuenta '
                            'para iniciar sesión.',
                      );

                      if (!confirmado || !dialogo.mounted) return;

                      actualizar(() {
                        guardando = true;
                        errorBaja = null;
                      });

                      try {
                        await _servicio.darDeBaja(
                          idUsuario: administrador.idUsuario,
                          datos: BajaAdministradorRequest(
                            motivoBaja: motivo.text,
                            fechaBaja: _fechaApi(fecha),
                          ),
                        );

                        if (!dialogo.mounted) return;
                        Navigator.pop(dialogo, true);
                      } catch (error) {
                        if (!dialogo.mounted) return;

                        final texto = _mensajeError(error);

                        actualizar(() {
                          guardando = false;
                          errorBaja = texto;
                          resultadoIncierto =
                              texto.contains('tardó demasiado') ||
                              texto.contains('conectar con Backend') ||
                              texto.contains('HTTP 5') ||
                              error is FormatException;
                        });
                      }
                    },
              child: Text(guardando ? 'Procesando...' : 'Dar de baja'),
            ),
          ],
        ),
      ),
    );

    motivo.dispose();

    if (!mounted) return;

    if (resultado == true) {
      _aviso('Administrador dado de baja correctamente.');
    }

    await _cargar();
  }

  Future<void> _verDetalle(AdminAdministrador administrador) async {
    if (_operando) return;

    AdminAdministrador detalle;

    try {
      detalle = await _servicio.obtenerPorId(administrador.idUsuario);
    } catch (error) {
      _aviso(_mensajeError(error), esError: true);
      return;
    }

    if (!mounted) return;

    final accion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _blanco,
        title: Text(detalle.nombreCompleto),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Correo: ${detalle.correo}'),
              Text('Teléfono: ${detalle.telefono}'),
              Text('Horario: ${detalle.horario}'),
              Text('Estado: ${detalle.estatus}'),
              Text('ID usuario: ${detalle.idUsuario}'),
              Text('ID personal: ${detalle.idPersonal}'),
              Text('Fecha alta: ${detalle.fechaAlta}'),
              if (detalle.fechaBaja != null)
                Text('Fecha baja: ${detalle.fechaBaja}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cerrar'),
            child: const Text('Cerrar'),
          ),
          if (detalle.estaActivo)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'editar'),
              child: const Text('Editar'),
            ),
          if (detalle.estaActivo &&
              _miIdUsuario != null &&
              detalle.idUsuario != _miIdUsuario)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'baja'),
              child: const Text('Dar de baja', style: TextStyle(color: _rojo)),
            ),
        ],
      ),
    );

    if (!mounted) return;

    if (accion == 'editar') {
      await _abrirFormulario(administrador: detalle);
    } else if (accion == 'baja') {
      await _darDeBaja(detalle);
    }
  }

  List<AdminAdministrador> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();

    return _administradores.where((admin) {
      return admin.nombreCompleto.toLowerCase().contains(texto) ||
          admin.correo.toLowerCase().contains(texto) ||
          admin.idUsuario.toString().contains(texto);
    }).toList();
  }

  Widget _tarjeta(AdminAdministrador admin) {
    return Card(
      color: _blanco,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: _dorado,
              ),
              title: Text(
                admin.nombreCompleto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${admin.correo}\n'
                'Horario: ${admin.horario.isEmpty ? 'Sin registrar' : admin.horario}\n'
                'Estado: ${admin.estatus}',
              ),
              isThreeLine: true,
            ),
            OutlinedButton.icon(
              onPressed: _operando ? null : () => _verDetalle(admin),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver detalles y acciones'),
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
        title: const Text(
          'Administrar Administradores',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: _blanco,
        foregroundColor: _texto,
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: _cargando || _operando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _dorado,
        foregroundColor: Colors.white,
        onPressed: _cargando || _operando ? null : () => _abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Registrar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
          const Text(
            'GYMFLOW / ADMINISTRACIÓN',
            style: TextStyle(
              color: _dorado,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Cuentas administrativas',
            style: TextStyle(
              color: _texto,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta, registra y administra '
            'las cuentas autorizadas de GymFlow.',
            style: TextStyle(color: _gris),
          ),
          const SizedBox(height: 21),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar administrador',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: _blanco,
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) {
              setState(() => _busqueda = valor);
            },
          ),
          const SizedBox(height: 18),
          if (_cargando)
            const Center(child: CircularProgressIndicator(color: _dorado))
          else if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: _rojo)),
            OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ] else if (_filtrados.isEmpty)
            const Card(
              color: _blanco,
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text('No se encontraron administradores.'),
                ),
              ),
            )
          else ...[
            Text(
              '${_filtrados.length} administradores encontrados',
              style: const TextStyle(color: _gris),
            ),
            const SizedBox(height: 12),
            ..._filtrados.map(_tarjeta),
          ],
        ],
      ),
    );
  }
}
