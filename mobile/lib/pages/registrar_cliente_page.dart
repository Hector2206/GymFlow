import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/membresia_activa.dart';
import '../services/cliente_service.dart';
import '../services/membresia_service.dart';

// GYMFLOW - REGISTRO DE CLIENTE (SPRINT 7)
// Los precios se consultan y muestran de solo lectura.
// Al registrar se envia IdMembresia, nunca precios.
class RegistrarClientePage extends StatefulWidget {
  const RegistrarClientePage({super.key});

  @override
  State<RegistrarClientePage> createState() => _RegistrarClientePageState();
}

class _RegistrarClientePageState extends State<RegistrarClientePage> {
  final _formKey = GlobalKey<FormState>();
  final _clienteService = ClienteService();
  final _membresiaService = MembresiaService();

  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _costoMensual = TextEditingController();
  final _costoAnual = TextEditingController();

  static const _fondo = Color(0xFFF8F5EF);
  static const _superficie = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _borde = Color(0xFFE5DDCF);
  static const _rojo = Color(0xFFA03930);

  List<MembresiaActiva> _membresias = [];
  int? _idMembresia;
  bool _cargandoMembresias = true;
  bool _registrando = false;
  bool _ocultarPassword = true;
  bool _registroIncierto = false;
  String _errorMembresias = '';

  @override
  void initState() {
    super.initState();
    _cargarMembresias();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _password.dispose();
    _costoMensual.dispose();
    _costoAnual.dispose();
    super.dispose();
  }

  Future<void> _cargarMembresias() async {
    if (_registrando || _registroIncierto) return;
    setState(() {
      _cargandoMembresias = true;
      _errorMembresias = '';
      _membresias = [];
      _idMembresia = null;
      _costoMensual.clear();
      _costoAnual.clear();
    });

    try {
      final lista = await _membresiaService.obtenerMembresiasActivas();
      if (!mounted) return;
      setState(() {
        _membresias = lista;
        _cargandoMembresias = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMembresias = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
        _cargandoMembresias = false;
      });
    }
  }

  void _seleccionarMembresia(int? id) {
    if (_registrando) return;
    setState(() {
      _idMembresia = id;
      _costoMensual.clear();
      _costoAnual.clear();
      for (final membresia in _membresias) {
        if (membresia.idMembresia == id) {
          _costoMensual.text = membresia.costoMensual.toStringAsFixed(2);
          _costoAnual.text = membresia.costoAnualidad.toStringAsFixed(2);
          break;
        }
      }
    });
  }

  String? _validarNombre(String? valor) {
    final nombre = valor?.trim() ?? '';
    if (nombre.length < 3 || nombre.length > 100) {
      return 'El nombre debe contener entre 3 y 100 caracteres.';
    }
    if (RegExp(r'\d').hasMatch(nombre) ||
        !RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(nombre)) {
      return 'Ingresa un nombre valido, sin numeros.';
    }
    return null;
  }

  String? _validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';
    if (correo.length > 150 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      return 'Ingresa un correo electronico valido.';
    }
    return null;
  }

  String? _validarTelefono(String? valor) {
    final tel = valor?.trim() ?? '';
    if (tel.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(tel)) {
      return 'El telefono debe tener 10 digitos.';
    }
    return null;
  }

  String? _validarPassword(String? valor) {
    final pass = valor ?? '';
    if (pass.trim().isEmpty || pass.length < 6 || pass.length > 72) {
      return 'La contrasena debe tener entre 6 y 72 caracteres.';
    }
    return null;
  }

  void _mensaje(String texto, {required bool exito}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: exito ? const Color(0xFF287447) : _rojo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombre.clear();
    _correo.clear();
    _telefono.clear();
    _password.clear();
    _seleccionarMembresia(null);
  }

  Future<void> _registrarCliente() async {
    if (_registrando || _cargandoMembresias || _registroIncierto) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final id = _idMembresia;
    if (id == null || !_membresias.any((m) => m.idMembresia == id)) {
      _mensaje('Selecciona una membresia activa del servidor.', exito: false);
      return;
    }

    setState(() => _registrando = true);
    try {
      final respuesta = await _clienteService.registrarCliente(
        correo: _correo.text,
        password: _password.text,
        nombreCompleto: _nombre.text,
        telefono: _telefono.text,
        idMembresia: id,
      );
      if (!mounted) return;

      final exito = respuesta['ok'] == true;
      _mensaje(
        respuesta['mensaje']?.toString() ?? 'No se pudo completar el registro.',
        exito: exito,
      );
      if (exito) {
        _limpiarFormulario();
      } else if (respuesta['resultadoIncierto'] == true) {
        // Evitar volver a enviar una alta que quiza ya se realizo.
        setState(() => _registroIncierto = true);
      }
    } catch (_) {
      if (!mounted) return;
      _mensaje('No fue posible completar el registro.', exito: false);
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  InputDecoration _decoracion(String etiqueta, IconData icono, {String? hint}) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: hint,
      prefixIcon: Icon(icono, color: _doradoOscuro),
      filled: true,
      fillColor: const Color(0xFFF8F4EC),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _borde),
        borderRadius: BorderRadius.circular(13),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _dorado, width: 1.5),
        borderRadius: BorderRadius.circular(13),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
    );
  }

  Widget _seccion(String titulo, IconData icono, List<Widget> campos) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: _doradoOscuro),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < campos.length; i++) ...[
            campos[i],
            if (i < campos.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    required IconData icono,
    String? Function(String?)? validator,
    TextInputType? teclado,
    List<TextInputFormatter>? formateadores,
    int? longitudMaxima,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_registrando && !_registroIncierto,
      validator: validator,
      keyboardType: teclado,
      inputFormatters: formateadores,
      maxLength: longitudMaxima,
      decoration: _decoracion(etiqueta, icono).copyWith(counterText: ''),
    );
  }

  Widget _contenidoMembresias() {
    if (_cargandoMembresias) {
      return const Padding(
        padding: EdgeInsets.all(15),
        child: Center(child: CircularProgressIndicator(color: _dorado)),
      );
    }
    if (_errorMembresias.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_errorMembresias, style: const TextStyle(color: _rojo)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _cargarMembresias,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar consulta'),
          ),
        ],
      );
    }
    if (_membresias.isEmpty) {
      return const Text(
        'El servidor no tiene membresias activas.',
        style: TextStyle(color: _secundario),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(_idMembresia),
          initialValue: _idMembresia,
          isExpanded: true,
          decoration: _decoracion(
            'Membresia *',
            Icons.card_membership_outlined,
            hint: 'Selecciona un plan activo',
          ),
          items: _membresias.map((m) {
            return DropdownMenuItem<int>(
              value: m.idMembresia,
              child: Text(m.nombrePlan, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          validator: (id) =>
              id == null || !_membresias.any((m) => m.idMembresia == id)
              ? 'Selecciona una membresia activa.'
              : null,
          onChanged: _registrando || _registroIncierto
              ? null
              : _seleccionarMembresia,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _costoMensual,
          readOnly: true,
          canRequestFocus: false,
          enableInteractiveSelection: false,
          decoration: _decoracion(
            'Precio mensual oficial',
            Icons.payments_outlined,
          ).copyWith(suffixText: 'MXN'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _costoAnual,
          readOnly: true,
          canRequestFocus: false,
          enableInteractiveSelection: false,
          decoration: _decoracion(
            'Precio anual oficial',
            Icons.account_balance_wallet_outlined,
          ).copyWith(suffixText: 'MXN'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Precios oficiales obtenidos de PostgreSQL. '
          'Recepcion no puede editarlos ni enviarlos en el registro.',
          style: TextStyle(color: _secundario, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: _superficie,
                      border: Border.all(color: _borde),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECEPCION / GYMFLOW',
                          style: TextStyle(
                            color: _doradoOscuro,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'Registrar Cliente',
                          style: TextStyle(
                            color: _texto,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Registra al cliente y asigna una membresia '
                          'con precios oficiales del gimnasio.',
                          style: TextStyle(color: _secundario, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _seccion('Datos personales', Icons.person_outline, [
                    _campo(
                      controller: _nombre,
                      etiqueta: 'Nombre completo *',
                      icono: Icons.person_outline,
                      validator: _validarNombre,
                      teclado: TextInputType.name,
                      longitudMaxima: 100,
                    ),
                    _campo(
                      controller: _correo,
                      etiqueta: 'Correo electronico *',
                      icono: Icons.email_outlined,
                      validator: _validarCorreo,
                      teclado: TextInputType.emailAddress,
                      longitudMaxima: 150,
                    ),
                    _campo(
                      controller: _telefono,
                      etiqueta: 'Telefono (opcional)',
                      icono: Icons.phone_outlined,
                      validator: _validarTelefono,
                      teclado: TextInputType.phone,
                      formateadores: [FilteringTextInputFormatter.digitsOnly],
                      longitudMaxima: 10,
                    ),
                  ]),
                  _seccion('Acceso', Icons.lock_outline, [
                    TextFormField(
                      controller: _password,
                      enabled: !_registrando && !_registroIncierto,
                      obscureText: _ocultarPassword,
                      validator: _validarPassword,
                      maxLength: 72,
                      decoration:
                          _decoracion(
                            'Contrasena *',
                            Icons.lock_outline,
                          ).copyWith(
                            counterText: '',
                            suffixIcon: IconButton(
                              tooltip: _ocultarPassword ? 'Mostrar' : 'Ocultar',
                              onPressed: () => setState(
                                () => _ocultarPassword = !_ocultarPassword,
                              ),
                              icon: Icon(
                                _ocultarPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                    ),
                  ]),
                  _seccion(
                    'Membresia y asistencia',
                    Icons.card_membership_outlined,
                    [_contenidoMembresias()],
                  ),
                  if (_registroIncierto) ...[
                    const Text(
                      'No intentes registrar al mismo cliente nuevamente '
                      'hasta verificar si el alta ya se realizo.',
                      style: TextStyle(color: _rojo),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed:
                          _registrando ||
                              _cargandoMembresias ||
                              _registroIncierto ||
                              _errorMembresias.isNotEmpty ||
                              _membresias.isEmpty
                          ? null
                          : _registrarCliente,
                      icon: _registrando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        _registrando ? 'Registrando...' : 'Registrar cliente',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _dorado,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
