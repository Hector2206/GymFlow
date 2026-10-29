import 'package:flutter/material.dart';

import '../models/admin_personal.dart';
import '../services/admin_personal_service.dart';

// GYMFLOW - SPRINT 7
// BAJA LOGICA DE EMPLEADOS

class AdminBajaPersonalPage extends StatefulWidget {
  final int idPersonal;

  const AdminBajaPersonalPage({super.key, required this.idPersonal});

  @override
  State<AdminBajaPersonalPage> createState() => _AdminBajaPersonalPageState();
}

class _AdminBajaPersonalPageState extends State<AdminBajaPersonalPage> {
  final AdminPersonalService _servicio = AdminPersonalService();

  final TextEditingController _motivo = TextEditingController();

  static const Color _fondo = Color(0xFFF8F5EF);
  static const Color _superficie = Color(0xFFFFFDF8);
  static const Color _dorado = Color(0xFFB58A2A);
  static const Color _doradoOscuro = Color(0xFF8A6814);
  static const Color _texto = Color(0xFF2F2A24);
  static const Color _secundario = Color(0xFF777067);
  static const Color _borde = Color(0xFFE5DDCF);
  static const Color _peligro = Color(0xFFA03930);

  AdminPersonal? _empleado;

  bool _cargando = true;
  bool _guardando = false;
  bool _confirmacionLeida = false;
  bool _resultadoIncierto = false;

  String? _errorCarga;
  String? _errorBaja;

  @override
  void initState() {
    super.initState();
    _cargarEmpleado();
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  // CONSULTAR EL EXPEDIENTE REAL

  Future<void> _cargarEmpleado() async {
    if (_guardando || _resultadoIncierto) return;

    setState(() {
      _cargando = true;
      _errorCarga = null;
      _empleado = null;
    });

    try {
      final empleado = await _servicio.obtenerPersonalPorId(widget.idPersonal);

      if (!mounted) return;

      if (empleado.idPersonal != widget.idPersonal) {
        throw Exception('El servidor devolvió un empleado diferente.');
      }

      if (!empleado.estaActivo) {
        throw Exception(
          'Este empleado ya está inactivo. '
          'No es posible registrar otra baja.',
        );
      }

      setState(() {
        _empleado = empleado;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // VALIDAR MOTIVO Y CONFIRMAR BAJA

  Future<void> _confirmarBaja() async {
    if (_guardando || _cargando || _resultadoIncierto || _empleado == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    final motivo = _motivo.text.trim();
    final empleado = _empleado!;

    if (motivo.isEmpty || motivo.length > 200) {
      setState(() {
        _errorBaja = 'Escribe un motivo entre 1 y 200 caracteres.';
      });
      return;
    }

    if (!_confirmacionLeida) {
      setState(() {
        _errorBaja =
            'Debes aceptar la confirmación '
            'antes de continuar.';
      });
      return;
    }

    setState(() {
      _errorBaja = null;
    });

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _peligro),
              SizedBox(width: 8),
              Expanded(child: Text('Confirmar baja laboral')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estás a punto de dar de baja a:'),

                const SizedBox(height: 12),

                Text(
                  empleado.nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),

                Text(
                  '${empleado.puesto} · '
                  'ID ${empleado.idPersonal}',
                ),

                const SizedBox(height: 14),

                Text('Motivo: $motivo'),

                const SizedBox(height: 14),

                const Text(
                  'Esta operación desactivará '
                  'su acceso a GymFlow y registrará '
                  'la baja laboral.',
                  style: TextStyle(color: _peligro),
                ),

                if (empleado.esEntrenador) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Los clientes asignados a este '
                    'entrenador quedarán sin entrenador.',
                    style: TextStyle(
                      color: _peligro,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No, regresar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _peligro),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sí, confirmar baja'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    setState(() {
      _guardando = true;
      _errorBaja = null;
    });

    try {
      final respuesta = await _servicio.darDeBajaPersonal(
        idPersonal: widget.idPersonal,
        motivo: motivo,
      );

      if (!mounted) return;

      // No aceptar una respuesta inesperada
      // como confirmación de éxito.
      if (respuesta.idPersonal != widget.idPersonal ||
          respuesta.clientesDesasignados < 0) {
        setState(() {
          _guardando = false;
          _resultadoIncierto = true;
          _errorBaja =
              'El servidor devolvió una respuesta '
              'inesperada. Revisa el estatus del '
              'empleado antes de realizar otra operación.';
        });
        return;
      }

      setState(() {
        _guardando = false;
      });

      Navigator.of(context).pop(respuesta);
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      // Una baja no debe reenviarse sin
      // comprobar antes su resultado.
      setState(() {
        _guardando = false;
        _resultadoIncierto = true;
        _errorBaja =
            '$mensaje\n\nRegresa al directorio '
            'y verifica si la cuenta ya está '
            'inactiva antes de intentar otra baja.';
      });
    }
  }

  // INFORMACION DEL EMPLEADO

  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(color: _secundario, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: _texto,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    final empleado = _empleado!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // EXPEDIENTE
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
              _dato('Nombre completo', empleado.nombreCompleto),
              _dato('ID de personal', '${empleado.idPersonal}'),
              _dato('Puesto', empleado.puesto),
              _dato('Correo', empleado.correo),
              _dato('Estado actual', empleado.estatus),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ADVERTENCIA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE9E6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8BAB4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _peligro),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Consecuencias de la baja',
                      style: TextStyle(
                        color: _peligro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Se desactivará el acceso del '
                'empleado y quedarán registrados '
                'la fecha y el motivo de baja.',
                style: TextStyle(color: _texto),
              ),
              if (empleado.esEntrenador) ...[
                const SizedBox(height: 12),
                const Text(
                  'Sus clientes asignados '
                  'quedarán sin entrenador.',
                  style: TextStyle(
                    color: _peligro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Su historial laboral se conservará.',
                style: TextStyle(color: _texto),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // MOTIVO
        TextField(
          controller: _motivo,
          maxLength: 200,
          minLines: 3,
          maxLines: 5,
          enabled: !_guardando && !_resultadoIncierto,
          onChanged: (_) {
            if (_errorBaja != null) {
              setState(() {
                _errorBaja = null;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Motivo de baja *',
            hintText: 'Escribe el motivo de la baja laboral',
            alignLabelWithHint: true,
            filled: true,
            fillColor: _superficie,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borde),
            ),
          ),
        ),

        const SizedBox(height: 10),

        CheckboxListTile(
          value: _confirmacionLeida,
          onChanged: _guardando || _resultadoIncierto
              ? null
              : (valor) {
                  setState(() {
                    _confirmacionLeida = valor ?? false;
                  });
                },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _doradoOscuro,
          title: const Text(
            'He revisado el expediente y comprendo '
            'que esta baja desactivará la cuenta '
            'del empleado.',
            style: TextStyle(color: _texto, fontSize: 13),
          ),
        ),

        if (_errorBaja != null) ...[
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE9E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_errorBaja!, style: const TextStyle(color: _peligro)),
          ),
        ],

        const SizedBox(height: 20),

        // BOTON DE BAJA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _guardando || _resultadoIncierto ? null : _confirmarBaja,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_off_outlined),
            label: Text(
              _guardando ? 'Registrando baja...' : 'Revisar y confirmar baja',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _peligro,
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
              label: const Text('Volver y verificar expediente'),
            ),
          ),
        ],
      ],
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
            'Baja de empleado',
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
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registrar baja laboral',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Revisa cuidadosamente la '
                    'información antes de continuar.',
                    style: TextStyle(color: _secundario),
                  ),
                  const SizedBox(height: 23),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: CircularProgressIndicator(color: _dorado),
                      ),
                    )
                  else if (_errorCarga != null) ...[
                    Text(_errorCarga!, style: const TextStyle(color: _peligro)),
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
