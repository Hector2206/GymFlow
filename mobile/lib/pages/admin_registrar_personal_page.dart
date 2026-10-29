import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_personal.dart';
import '../services/admin_personal_service.dart';

// GYMFLOW - SPRINT 7
// FORMULARIO DE ALTA DE EMPLEADOS

class AdminRegistrarPersonalPage extends StatefulWidget {
  const AdminRegistrarPersonalPage({super.key});

  @override
  State<AdminRegistrarPersonalPage> createState() =>
      _AdminRegistrarPersonalPageState();
}

class _AdminRegistrarPersonalPageState
    extends State<AdminRegistrarPersonalPage> {
  final _formKey = GlobalKey<FormState>();

  final AdminPersonalService _servicio = AdminPersonalService();

  // CONTROLADORES

  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _sueldo = TextEditingController();
  final _password = TextEditingController();
  final _confirmarPassword = TextEditingController();

  // ESTADO

  DateTime? _fechaContratacion;
  String? _puesto;

  bool _guardando = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;
  bool _errorFecha = false;
  bool _requiereRevision = false;

  String? _error;

  // COLORES GYMFLOW

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _sueldo.dispose();
    _password.dispose();
    _confirmarPassword.dispose();

    super.dispose();
  }

  // FORMATO YYYY-MM-DD PARA BACKEND

  String _formatoFecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  // SELECCIONAR FECHA DE CONTRATACIÓN

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaContratacion ?? hoy,
      firstDate: DateTime(2000),
      lastDate: hoy,
      helpText: 'Fecha de contratación',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (!mounted || fecha == null) return;

    setState(() {
      _fechaContratacion = fecha;
      _errorFecha = false;
      _error = null;
    });
  }

  // ESTILO COMÚN PARA LOS CAMPOS

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
    String? ayuda,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: ayuda,
      prefixIcon: Icon(icono, color: _doradoOscuro),
      suffixIcon: sufijo,
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

  // CAMPO DE TEXTO REUTILIZABLE

  Widget _campo({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    required FormFieldValidator<String> validar,
    TextInputType? teclado,
    String? ayuda,
    bool ocultar = false,
    Widget? sufijo,
    List<TextInputFormatter>? formateadores,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: teclado,
      obscureText: ocultar,
      inputFormatters: formateadores,
      validator: validar,
      enabled: !_guardando && !_requiereRevision,
      decoration: _decoracion(
        etiqueta: etiqueta,
        icono: icono,
        ayuda: ayuda,
        sufijo: sufijo,
      ),
    );
  }

  // VALIDAR DATOS Y PEDIR CONFIRMACIÓN

  Future<void> _registrar() async {
    if (_guardando || _requiereRevision) return;

    FocusScope.of(context).unfocus();

    final formularioValido = _formKey.currentState?.validate() ?? false;

    setState(() {
      _errorFecha = _fechaContratacion == null;
      _error = null;
    });

    if (!formularioValido || _fechaContratacion == null) {
      return;
    }

    final sueldo = double.tryParse(_sueldo.text.trim());

    if (sueldo == null || !sueldo.isFinite) {
      setState(() {
        _error = 'El sueldo no es válido.';
      });
      return;
    }

    // Confirmación antes de escribir en la BD.
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (contexto) {
        return AlertDialog(
          title: const Text('Confirmar registro'),
          content: Text(
            '¿Registrar a ${_nombre.text.trim()} '
            'como $_puesto con un sueldo mensual '
            'de \$${sueldo.toStringAsFixed(2)} MXN?\n\n'
            'Esta acción creará una cuenta real '
            'en GymFlow.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(contexto, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(contexto, true);
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final solicitud = CrearPersonalRequest(
        nombreCompleto: _nombre.text.trim(),
        correo: _correo.text.trim(),
        telefono: _telefono.text.trim(),
        fechaContratacion: _formatoFecha(_fechaContratacion!),
        puesto: _puesto!,
        sueldo: sueldo,
        password: _password.text,
      );

      final respuesta = await _servicio.crearPersonal(solicitud);

      if (!mounted) return;

      if (respuesta.idPersonal <= 0) {
        setState(() {
          _guardando = false;
          _requiereRevision = true;
          _error =
              'El servidor respondió al registro, '
              'pero no confirmó un ID válido. '
              'Revisa el directorio antes de intentar '
              'registrarlo nuevamente.';
        });
        return;
      }

      // Volver al directorio con el ID registrado.
      Navigator.of(context).pop(respuesta.idPersonal);
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      final incierto =
          mensaje.contains('tardó demasiado') ||
          mensaje.contains('conectar con el servidor');

      setState(() {
        _guardando = false;
        _requiereRevision = incierto;
        _error = incierto
            ? '$mensaje\n\nAntes de volver a enviar '
                  'el formulario, regresa al directorio '
                  'y comprueba si el empleado ya existe.'
            : mensaje;
      });
    }
  }

  // PANTALLA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _doradoOscuro),
        title: const Text(
          'Registrar empleado',
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
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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

                  const SizedBox(height: 9),

                  const Text(
                    'Nuevo integrante',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Registra entrenadores y '
                    'recepcionistas con su información '
                    'laboral.',
                    style: TextStyle(
                      color: _secundario,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
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
                          'DATOS DEL EMPLEADO',
                          style: TextStyle(
                            color: _doradoOscuro,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // NOMBRE
                        _campo(
                          controlador: _nombre,
                          etiqueta: 'Nombre completo',
                          icono: Icons.person_outline,
                          validar: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa el nombre.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // CORREO
                        _campo(
                          controlador: _correo,
                          etiqueta: 'Correo electrónico',
                          icono: Icons.email_outlined,
                          teclado: TextInputType.emailAddress,
                          validar: (valor) {
                            final correo = valor?.trim() ?? '';

                            if (correo.isEmpty) {
                              return 'Ingresa el correo.';
                            }

                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(correo)) {
                              return 'Correo no válido.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // TELÉFONO
                        _campo(
                          controlador: _telefono,
                          etiqueta: 'Teléfono',
                          icono: Icons.phone_outlined,
                          teclado: TextInputType.phone,
                          validar: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa el teléfono.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // PUESTO
                        DropdownButtonFormField<String>(
                          initialValue: _puesto,
                          isExpanded: true,
                          decoration: _decoracion(
                            etiqueta: 'Puesto',
                            icono: Icons.badge_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Entrenador',
                              child: Text('Entrenador'),
                            ),
                            DropdownMenuItem(
                              value: 'Recepcionista',
                              child: Text('Recepcionista'),
                            ),
                          ],
                          onChanged: _guardando || _requiereRevision
                              ? null
                              : (valor) {
                                  setState(() {
                                    _puesto = valor;
                                  });
                                },
                          validator: (valor) {
                            if (valor == null) {
                              return 'Selecciona un puesto.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // FECHA
                        const Text(
                          'Fecha de contratación',
                          style: TextStyle(
                            color: _texto,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _guardando || _requiereRevision
                                ? null
                                : _seleccionarFecha,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              _fechaContratacion == null
                                  ? 'Seleccionar fecha'
                                  : _formatoFecha(_fechaContratacion!),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _doradoOscuro,
                              padding: const EdgeInsets.all(15),
                              alignment: Alignment.centerLeft,
                              side: BorderSide(
                                color: _errorFecha
                                    ? const Color(0xFFA03930)
                                    : _borde,
                              ),
                            ),
                          ),
                        ),

                        if (_errorFecha) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Selecciona la fecha de contratación.',
                            style: TextStyle(
                              color: Color(0xFFA03930),
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // SUELDO
                        _campo(
                          controlador: _sueldo,
                          etiqueta: 'Sueldo mensual (MXN)',
                          icono: Icons.payments_outlined,
                          teclado: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          ayuda: 'Ej. 10000.00',
                          formateadores: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          validar: (valor) {
                            final texto = valor?.trim() ?? '';

                            if (texto.isEmpty) {
                              return 'Ingresa el sueldo mensual.';
                            }

                            if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(texto)) {
                              return 'Utiliza hasta dos decimales.';
                            }

                            final monto = double.tryParse(texto);

                            if (monto == null ||
                                !monto.isFinite ||
                                monto <= 0) {
                              return 'El sueldo debe ser mayor que cero.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'ACCESO A GYMFLOW',
                          style: TextStyle(
                            color: _doradoOscuro,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CONTRASEÑA
                        _campo(
                          controlador: _password,
                          etiqueta: 'Contraseña',
                          icono: Icons.lock_outline,
                          ocultar: !_mostrarPassword,
                          sufijo: IconButton(
                            tooltip: _mostrarPassword
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            onPressed: () {
                              setState(() {
                                _mostrarPassword = !_mostrarPassword;
                              });
                            },
                            icon: Icon(
                              _mostrarPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validar: (valor) {
                            if (valor == null || valor.length < 8) {
                              return 'Mínimo 8 caracteres.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // CONFIRMAR CONTRASEÑA
                        _campo(
                          controlador: _confirmarPassword,
                          etiqueta: 'Confirmar contraseña',
                          icono: Icons.lock_reset_outlined,
                          ocultar: !_mostrarConfirmacion,
                          sufijo: IconButton(
                            tooltip: _mostrarConfirmacion
                                ? 'Ocultar confirmación'
                                : 'Mostrar confirmación',
                            onPressed: () {
                              setState(() {
                                _mostrarConfirmacion = !_mostrarConfirmacion;
                              });
                            },
                            icon: Icon(
                              _mostrarConfirmacion
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validar: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Confirma la contraseña.';
                            }

                            if (valor != _password.text) {
                              return 'Las contraseñas no coinciden.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE9E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFA03930),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardando || _requiereRevision
                          ? null
                          : _registrar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: Text(
                        _guardando
                            ? 'Registrando empleado...'
                            : 'Registrar empleado',
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

                  if (_requiereRevision) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver y revisar el directorio'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  const Text(
                    'Solo los Administradores autorizados '
                    'pueden registrar empleados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _secundario, fontSize: 12),
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
