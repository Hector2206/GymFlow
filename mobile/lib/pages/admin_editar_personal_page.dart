import 'package:flutter/material.dart';

import '../models/admin_personal.dart';
import '../services/admin_personal_service.dart';

// GYMFLOW - SPRINT 7
// EDITAR INFORMACION DE EMPLEADOS

class AdminEditarPersonalPage extends StatefulWidget {
  final int idPersonal;

  const AdminEditarPersonalPage({super.key, required this.idPersonal});

  @override
  State<AdminEditarPersonalPage> createState() =>
      _AdminEditarPersonalPageState();
}

class _AdminEditarPersonalPageState extends State<AdminEditarPersonalPage> {
  final _formKey = GlobalKey<FormState>();

  final AdminPersonalService _servicio = AdminPersonalService();

  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _horario = TextEditingController();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  AdminPersonal? _empleado;

  bool _cargando = true;
  bool _guardando = false;
  bool _resultadoIncierto = false;

  String? _errorCarga;
  String? _errorGuardado;

  @override
  void initState() {
    super.initState();
    _cargarEmpleado();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _horario.dispose();
    super.dispose();
  }

  // CONSULTAR EXPEDIENTE ACTUAL DEL BACKEND

  Future<void> _cargarEmpleado() async {
    if (_guardando) return;

    setState(() {
      _cargando = true;
      _errorCarga = null;
      _errorGuardado = null;
      _empleado = null;
    });

    try {
      final resultado = await _servicio.obtenerPersonalPorId(widget.idPersonal);

      if (!mounted) return;

      if (resultado.idPersonal != widget.idPersonal) {
        throw Exception('El servidor devolvió otro empleado.');
      }

      if (!resultado.estaActivo) {
        throw Exception('No se puede editar un empleado inactivo.');
      }

      _nombre.text = resultado.nombreCompleto;
      _correo.text = resultado.correo;
      _telefono.text = resultado.telefono;
      _horario.text = resultado.horario;

      setState(() {
        _empleado = resultado;
        _cargando = false;
        _resultadoIncierto = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // COMPROBAR QUE HAYA CAMBIOS REALES

  bool get _hayCambios {
    final empleado = _empleado;

    if (empleado == null) return false;

    return _nombre.text.trim() != empleado.nombreCompleto.trim() ||
        _correo.text.trim().toLowerCase() !=
            empleado.correo.trim().toLowerCase() ||
        _telefono.text.trim() != empleado.telefono.trim() ||
        _horario.text.trim() != empleado.horario.trim();
  }

  // DECIDIR SI UN ERROR REQUIERE VERIFICACION

  bool _esResultadoIncierto(String mensaje) {
    final texto = mensaje.toLowerCase();

    return texto.contains('tardó demasiado') ||
        texto.contains('conectar con el servidor') ||
        texto.contains('servidor no pudo completar') ||
        texto.contains('código 500') ||
        texto.contains('código 502') ||
        texto.contains('código 503') ||
        texto.contains('código 504');
  }

  // GUARDAR CAMBIOS

  Future<void> _guardarCambios() async {
    if (_guardando || _cargando || _resultadoIncierto || _empleado == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_hayCambios) {
      setState(() {
        _errorGuardado = 'No hay cambios que guardar.';
      });
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar cambios'),
          content: Text(
            '¿Deseas actualizar los datos de '
            '${_empleado!.nombreCompleto}?\n\n'
            'Los cambios se guardarán en GymFlow. '
            'El sueldo y el puesto no se modificarán.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    setState(() {
      _guardando = true;
      _errorGuardado = null;
    });

    try {
      final datos = EditarPersonalRequest(
        nombreCompleto: _nombre.text.trim(),
        correo: _correo.text.trim().toLowerCase(),
        telefono: _telefono.text.trim(),
        horario: _horario.text.trim(),
      );

      final respuesta = await _servicio.editarPersonal(
        idPersonal: widget.idPersonal,
        datos: datos,
      );

      if (!mounted) return;

      if (respuesta.idPersonal != widget.idPersonal) {
        setState(() {
          _guardando = false;
          _resultadoIncierto = true;
          _errorGuardado =
              'El servidor respondió con un ID inesperado. '
              'Consulta el expediente antes de '
              'intentar guardar nuevamente.';
        });
        return;
      }

      Navigator.of(context).pop(widget.idPersonal);
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      final incierto = _esResultadoIncierto(mensaje);

      setState(() {
        _guardando = false;
        _resultadoIncierto = incierto;
        _errorGuardado = incierto
            ? '$mensaje\n\nNo podemos confirmar si '
                  'la actualización se guardó. '
                  'Regresa al directorio y verifica '
                  'los datos antes de volver a editar.'
            : mensaje;
      });
    }
  }

  // ESTILO DE CAMPOS

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: etiqueta,
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
    );
  }

  Widget _campo({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    required int maximo,
    TextInputType teclado = TextInputType.text,
    bool esCorreo = false,
  }) {
    return TextFormField(
      controller: controlador,
      maxLength: maximo,
      keyboardType: teclado,
      enabled: !_guardando && !_resultadoIncierto,
      decoration: _decoracion(etiqueta: etiqueta, icono: icono),
      validator: (valor) {
        final texto = valor?.trim() ?? '';

        if (texto.isEmpty) {
          return 'Este campo es obligatorio.';
        }

        if (texto.length > maximo) {
          return 'Máximo $maximo caracteres.';
        }

        if (esCorreo &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(texto)) {
          return 'Ingresa un correo válido.';
        }

        return null;
      },
    );
  }

  // INFORMACION NO EDITABLE

  Widget _datoInformativo(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              etiqueta,
              style: const TextStyle(color: _secundario, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: _texto,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FORMULARIO

  Widget _formulario() {
    final empleado = _empleado!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                const Text(
                  'EXPEDIENTE LABORAL',
                  style: TextStyle(
                    color: _doradoOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                _datoInformativo('ID del empleado', '${empleado.idPersonal}'),
                _datoInformativo('Puesto', empleado.puesto),
                _datoInformativo(
                  'Sueldo mensual',
                  '\$${empleado.salario.toStringAsFixed(2)} MXN',
                ),
                _datoInformativo('Contratación', empleado.fechaContratacion),
                _datoInformativo('Estatus', empleado.estatus),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
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
                const Text(
                  'DATOS EDITABLES',
                  style: TextStyle(
                    color: _doradoOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 19),

                _campo(
                  controlador: _nombre,
                  etiqueta: 'Nombre completo',
                  icono: Icons.person_outline,
                  maximo: 150,
                ),

                const SizedBox(height: 12),

                _campo(
                  controlador: _correo,
                  etiqueta: 'Correo electrónico',
                  icono: Icons.email_outlined,
                  teclado: TextInputType.emailAddress,
                  esCorreo: true,
                  maximo: 150,
                ),

                const SizedBox(height: 12),

                _campo(
                  controlador: _telefono,
                  etiqueta: 'Teléfono',
                  icono: Icons.phone_outlined,
                  teclado: TextInputType.phone,
                  maximo: 20,
                ),

                const SizedBox(height: 12),

                _campo(
                  controlador: _horario,
                  etiqueta: 'Horario laboral',
                  icono: Icons.schedule_outlined,
                  maximo: 100,
                ),
              ],
            ),
          ),

          if (_errorGuardado != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE9E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorGuardado!,
                style: const TextStyle(color: Color(0xFFA03930), fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardando || _resultadoIncierto
                  ? null
                  : _guardarCambios,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _guardando ? 'Guardando cambios...' : 'Guardar cambios',
              ),
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

          if (_resultadoIncierto) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver y revisar expediente'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        backgroundColor: _fondo,
        appBar: AppBar(
          backgroundColor: _superficie,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _doradoOscuro),
          title: const Text(
            'Editar empleado',
            style: TextStyle(
              color: _texto,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GYMFLOW / ADMINISTRACIÓN',
                    style: TextStyle(
                      color: _doradoOscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Actualizar expediente',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Modifica los datos del empleado '
                    'sin cambiar su puesto ni sueldo.',
                    style: TextStyle(color: _secundario, fontSize: 13),
                  ),

                  const SizedBox(height: 24),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_errorCarga != null) ...[
                    Text(
                      _errorCarga!,
                      style: const TextStyle(color: Color(0xFFA03930)),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: _cargarEmpleado,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ] else if (_empleado != null)
                    _formulario(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
