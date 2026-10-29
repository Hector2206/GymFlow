import 'package:flutter/material.dart';

import '../models/admin_personal.dart';
import '../models/asistencia_personal.dart';
import '../services/admin_personal_service.dart';
import '../services/admin_asistencia_personal_service.dart';

class AdminHorariosAsistenciasPage extends StatefulWidget {
  const AdminHorariosAsistenciasPage({super.key});

  @override
  State<AdminHorariosAsistenciasPage> createState() =>
      _AdminHorariosAsistenciasPageState();
}

class _AdminHorariosAsistenciasPageState
    extends State<AdminHorariosAsistenciasPage> {
  static const _fondo = Color(0xFFF8F5EF);
  static const _colorTarjeta = Color(0xFFFFFDF8);
  static const _dorado = Color(0xFFB58A2A);
  static const _doradoOscuro = Color(0xFF8A6814);
  static const _texto = Color(0xFF2F2A24);
  static const _secundario = Color(0xFF777067);
  static const _rojo = Color(0xFFA03930);
  static const _borde = Color(0xFFE5DDCF);

  final _personalService = AdminPersonalService();
  final _asistenciaService = AdminAsistenciaPersonalService();

  List<AdminPersonal> _empleados = [];
  List<AsistenciaPersonal> _historial = [];

  int? _idEmpleadoEntrada;
  int? _idEmpleadoFiltro;
  int? _idAsistenciaSalida;

  late DateTime _fechaEntrada;
  late TimeOfDay _horaEntrada;
  late TimeOfDay _horaSalida;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool _cargandoPersonal = true;
  bool _cargandoHistorial = true;
  bool _guardando = false;
  bool _revisionPendiente = false;
  bool _mostrarHorarios = false;

  String? _errorPersonal;
  String? _errorHistorial;
  String? _errorOperacion;
  String? _exito;

  int _versionConsulta = 0;

  @override
  void initState() {
    super.initState();

    _fechaEntrada = DateTime.now();
    _horaEntrada = TimeOfDay.now();
    _horaSalida = TimeOfDay.now();

    _cargarPersonal();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _versionConsulta++;
    super.dispose();
  }

  String _fechaApi(DateTime fecha) {
    return '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  String _fechaVisible(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _horaApi(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}:00';
  }

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  List<AdminPersonal> get _empleadosActivos =>
      _empleados.where((e) => e.estaActivo && e.fechaBaja == null).toList();

  List<AsistenciaPersonal> get _pendientes =>
      _historial.where((a) => a.pendienteSalida).toList();

  AsistenciaPersonal? get _salidaSeleccionada {
    for (final asistencia in _pendientes) {
      if (asistencia.idAsistenciaPersonal == _idAsistenciaSalida) {
        return asistencia;
      }
    }

    return null;
  }

  Future<void> _cargarPersonal() async {
    try {
      final personal = await _personalService.obtenerPersonal();

      if (!mounted) return;

      personal.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

      setState(() {
        _empleados = personal;
        _cargandoPersonal = false;
        _errorPersonal = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargandoPersonal = false;
        _errorPersonal = _mensajeError(error);
      });
    }
  }

  Future<void> _cargarHistorial() async {
    if (_guardando) return;

    if (_fechaInicio != null &&
        _fechaFin != null &&
        _fechaInicio!.isAfter(_fechaFin!)) {
      setState(() {
        _errorHistorial = 'La fecha inicial no puede ser posterior a la final.';
      });
      return;
    }

    final version = ++_versionConsulta;

    setState(() {
      _cargandoHistorial = true;
      _errorHistorial = null;
    });

    try {
      final registros = await _asistenciaService.obtenerHistorial(
        idPersonal: _idEmpleadoFiltro,
        fechaInicio: _fechaInicio == null ? null : _fechaApi(_fechaInicio!),
        fechaFin: _fechaFin == null ? null : _fechaApi(_fechaFin!),
      );

      if (!mounted || version != _versionConsulta) return;

      setState(() {
        _historial = registros;
        _cargandoHistorial = false;

        if (!_pendientes.any(
          (a) => a.idAsistenciaPersonal == _idAsistenciaSalida,
        )) {
          _idAsistenciaSalida = null;
        }
      });
    } catch (error) {
      if (!mounted || version != _versionConsulta) return;

      setState(() {
        _historial = [];
        _cargandoHistorial = false;
        _errorHistorial = _mensajeError(error);
      });
    }
  }

  Future<DateTime?> _elegirFecha(DateTime inicial, {bool limitarHoy = false}) {
    final hoy = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: inicial.isAfter(hoy) && limitarHoy ? hoy : inicial,
      firstDate: DateTime(2020),
      lastDate: limitarHoy ? hoy : DateTime(2100),
    );
  }

  Future<TimeOfDay?> _elegirHora(TimeOfDay actual) {
    return showTimePicker(context: context, initialTime: actual);
  }

  Future<bool> _confirmar(String titulo, String detalle) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(titulo),
        content: Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return resultado == true;
  }

  Future<void> _registrarEntrada() async {
    if (_guardando || _revisionPendiente) return;

    AdminPersonal? empleado;

    for (final e in _empleadosActivos) {
      if (e.idPersonal == _idEmpleadoEntrada) {
        empleado = e;
        break;
      }
    }

    if (empleado == null) {
      setState(() => _errorOperacion = 'Selecciona un empleado activo.');
      return;
    }

    final fecha = _fechaApi(_fechaEntrada);
    final hoy = _fechaApi(DateTime.now());
    final hora = _horaApi(_horaEntrada);

    if (fecha.compareTo(hoy) > 0) {
      setState(() => _errorOperacion = 'No se permiten fechas futuras.');
      return;
    }

    if (fecha == hoy && hora.compareTo(_horaApi(TimeOfDay.now())) > 0) {
      setState(() => _errorOperacion = 'La entrada no puede ser futura.');
      return;
    }

    final confirmado = await _confirmar(
      'Confirmar entrada laboral',
      'Empleado: ${empleado.nombreCompleto}\n'
          'Fecha: $fecha\n'
          'Hora: $hora\n\n'
          'Este registro se guardará en PostgreSQL.',
    );

    if (!confirmado || !mounted) return;

    setState(() {
      _guardando = true;
      _errorOperacion = null;
      _exito = null;
    });

    try {
      final folio = await _asistenciaService.registrarEntrada(
        idPersonal: empleado.idPersonal,
        fecha: fecha,
        horaEntrada: hora,
      );

      if (!mounted) return;

      setState(() {
        _guardando = false;
        _exito = 'Entrada registrada. Folio #$folio.';
      });

      await _cargarHistorial();
    } catch (error) {
      if (!mounted) return;

      final texto = _mensajeError(error).toLowerCase();
      final incierto =
          texto.contains('tardó') ||
          texto.contains('conectar') ||
          texto.contains('http 5') ||
          error is FormatException;

      setState(() {
        _guardando = false;
        _errorOperacion = _mensajeError(error);
        _revisionPendiente = incierto;
      });

      if (!incierto) await _cargarHistorial();
    }
  }

  Future<void> _registrarSalida() async {
    if (_guardando || _revisionPendiente) return;

    final asistencia = _salidaSeleccionada;

    if (asistencia == null) {
      setState(() {
        _errorOperacion = 'Selecciona una asistencia pendiente.';
      });
      return;
    }

    final hora = _horaApi(_horaSalida);

    if (hora.compareTo(asistencia.horaEntrada) < 0) {
      setState(() {
        _errorOperacion =
            'La hora de salida no puede ser anterior a la entrada.';
      });
      return;
    }

    final confirmado = await _confirmar(
      'Confirmar salida laboral',
      'Empleado: ${asistencia.nombreCompleto}\n'
          'Fecha: ${asistencia.fechaVisible}\n'
          'Hora de salida: $hora\n\n'
          'No se podrá sobrescribir la salida después.',
    );

    if (!confirmado || !mounted) return;

    setState(() {
      _guardando = true;
      _errorOperacion = null;
      _exito = null;
    });

    try {
      final folio = await _asistenciaService.registrarSalida(
        idAsistencia: asistencia.idAsistenciaPersonal,
        horaSalida: hora,
      );

      if (!mounted) return;

      setState(() {
        _guardando = false;
        _idAsistenciaSalida = null;
        _exito = 'Salida registrada. Folio #$folio.';
      });

      await _cargarHistorial();
    } catch (error) {
      if (!mounted) return;

      final texto = _mensajeError(error).toLowerCase();
      final incierto =
          texto.contains('tardó') ||
          texto.contains('conectar') ||
          texto.contains('http 5') ||
          error is FormatException;

      setState(() {
        _guardando = false;
        _errorOperacion = _mensajeError(error);
        _revisionPendiente = incierto;
      });

      if (!incierto) await _cargarHistorial();
    }
  }

  Widget _tarjeta({required String titulo, required Widget contenido}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorTarjeta,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: _texto,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 17),
          contenido,
        ],
      ),
    );
  }

  Widget _selectorEmpleado({
    required int? valor,
    required List<AdminPersonal> opciones,
    required String etiqueta,
    required ValueChanged<int?> alCambiar,
  }) {
    final seleccion = opciones.any((e) => e.idPersonal == valor) ? valor : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('$etiqueta-$seleccion-${opciones.length}'),
      initialValue: seleccion,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ),
      items: opciones.map((empleado) {
        return DropdownMenuItem<int>(
          value: empleado.idPersonal,
          child: Text(
            '${empleado.nombreCompleto} — ${empleado.puesto}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _guardando ? null : alCambiar,
    );
  }

  Widget _campoFecha(String etiqueta, DateTime? fecha, VoidCallback accion) {
    return OutlinedButton.icon(
      onPressed: _guardando ? null : accion,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(
        '$etiqueta: ${fecha == null ? 'Todas' : _fechaVisible(fecha)}',
      ),
    );
  }

  Widget _pantallaAsistencias() {
    return Column(
      children: [
        _tarjeta(
          titulo: 'Registrar entrada laboral',
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_cargandoPersonal) const LinearProgressIndicator(),
              if (_errorPersonal != null)
                Text(_errorPersonal!, style: const TextStyle(color: _rojo)),
              _selectorEmpleado(
                valor: _idEmpleadoEntrada,
                opciones: _empleadosActivos,
                etiqueta: 'Empleado activo',
                alCambiar: (id) {
                  setState(() => _idEmpleadoEntrada = id);
                },
              ),
              const SizedBox(height: 13),
              _campoFecha('Fecha de entrada', _fechaEntrada, () async {
                final fecha = await _elegirFecha(
                  _fechaEntrada,
                  limitarHoy: true,
                );
                if (fecha != null && mounted) {
                  setState(() => _fechaEntrada = fecha);
                }
              }),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: _guardando
                    ? null
                    : () async {
                        final hora = await _elegirHora(_horaEntrada);
                        if (hora != null && mounted) {
                          setState(() => _horaEntrada = hora);
                        }
                      },
                icon: const Icon(Icons.access_time),
                label: Text('Hora de entrada: ${_horaApi(_horaEntrada)}'),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _dorado),
                onPressed:
                    _guardando ||
                        _revisionPendiente ||
                        _cargandoPersonal ||
                        _errorPersonal != null
                    ? null
                    : _registrarEntrada,
                icon: const Icon(Icons.login),
                label: const Text('Registrar entrada'),
              ),
            ],
          ),
        ),
        _tarjeta(
          titulo: 'Historial de asistencias',
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _selectorEmpleado(
                valor: _idEmpleadoFiltro,
                opciones: _empleados,
                etiqueta: 'Filtrar por empleado',
                alCambiar: (id) {
                  setState(() => _idEmpleadoFiltro = id);
                },
              ),
              const SizedBox(height: 12),
              _campoFecha('Desde', _fechaInicio, () async {
                final fecha = await _elegirFecha(
                  _fechaInicio ?? DateTime.now(),
                );
                if (fecha != null && mounted) {
                  setState(() => _fechaInicio = fecha);
                }
              }),
              const SizedBox(height: 7),
              _campoFecha('Hasta', _fechaFin, () async {
                final fecha = await _elegirFecha(_fechaFin ?? DateTime.now());
                if (fecha != null && mounted) {
                  setState(() => _fechaFin = fecha);
                }
              }),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _guardando
                        ? null
                        : () {
                            setState(() {
                              _idEmpleadoFiltro = null;
                              _fechaInicio = null;
                              _fechaFin = null;
                            });
                            _cargarHistorial();
                          },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtros'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _dorado),
                    onPressed: _guardando ? null : _cargarHistorial,
                    icon: const Icon(Icons.search),
                    label: const Text('Consultar'),
                  ),
                ],
              ),
              if (_cargandoHistorial)
                const Padding(
                  padding: EdgeInsets.all(15),
                  child: LinearProgressIndicator(),
                ),
              if (_errorHistorial != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorHistorial!,
                    style: const TextStyle(color: _rojo),
                  ),
                ),
              if (!_cargandoHistorial && _errorHistorial == null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    '${_historial.length} registros consultados',
                    style: const TextStyle(color: _secundario),
                  ),
                ),
            ],
          ),
        ),
        _tarjeta(
          titulo: 'Entradas pendientes de salida',
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_pendientes.isEmpty)
                const Text(
                  'No hay salidas pendientes en la consulta.',
                  style: TextStyle(color: _secundario),
                ),
              ..._pendientes.map((asistencia) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(asistencia.nombreCompleto),
                  subtitle: Text(
                    '${asistencia.fechaVisible} · '
                    'Entrada ${asistencia.entradaVisible}',
                  ),
                  trailing: const Icon(Icons.exit_to_app, color: _doradoOscuro),
                  selected:
                      _idAsistenciaSalida == asistencia.idAsistenciaPersonal,
                  onTap: _guardando
                      ? null
                      : () {
                          setState(() {
                            _idAsistenciaSalida =
                                asistencia.idAsistenciaPersonal;
                            _horaSalida = TimeOfDay.now();
                          });
                        },
                );
              }),
              if (_salidaSeleccionada != null) ...[
                const Divider(),
                Text(
                  'Salida de ${_salidaSeleccionada!.nombreCompleto}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _guardando
                      ? null
                      : () async {
                          final hora = await _elegirHora(_horaSalida);
                          if (hora != null && mounted) {
                            setState(() => _horaSalida = hora);
                          }
                        },
                  icon: const Icon(Icons.access_time),
                  label: Text('Hora de salida: ${_horaApi(_horaSalida)}'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _dorado),
                  onPressed: _guardando || _revisionPendiente
                      ? null
                      : _registrarSalida,
                  icon: const Icon(Icons.logout),
                  label: const Text('Confirmar salida'),
                ),
              ],
            ],
          ),
        ),
        _tarjeta(
          titulo: 'Historial y responsables',
          contenido: Column(
            children: [
              if (_historial.isEmpty)
                const Text(
                  'Sin registros para mostrar.',
                  style: TextStyle(color: _secundario),
                ),
              ..._historial.map((asistencia) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _fondo,
                      border: Border.all(color: _borde),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asistencia.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Folio #${asistencia.idAsistenciaPersonal}'
                          ' · ${asistencia.fechaVisible}',
                        ),
                        Text(
                          'Entrada: ${asistencia.entradaVisible}'
                          ' · Salida: ${asistencia.salidaVisible}',
                        ),
                        Text(
                          'Registró entrada: Administrador '
                          '#${asistencia.registradoPor}',
                        ),
                        Text(
                          asistencia.salidaRegistradaPor == null
                              ? 'Registró salida: Pendiente'
                              : 'Registró salida: Administrador '
                                    '#${asistencia.salidaRegistradaPor}',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Text(
                'Backend devuelve hasta 500 registros. '
                'Utiliza los filtros para consultar periodos concretos.',
                style: TextStyle(color: _secundario, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pantallaHorarios() {
    return _tarjeta(
      titulo: 'Horarios registrados del personal',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Se muestran los horarios del expediente. '
            'La asignación estructurada de turnos aún '
            'no tiene endpoints propios.',
            style: TextStyle(color: _secundario),
          ),
          const SizedBox(height: 14),
          if (_cargandoPersonal) const CircularProgressIndicator(),
          if (_errorPersonal != null)
            Text(_errorPersonal!, style: const TextStyle(color: _rojo)),
          ..._empleados.map(
            (empleado) => ListTile(
              leading: const Icon(Icons.badge_outlined, color: _doradoOscuro),
              title: Text(empleado.nombreCompleto),
              subtitle: Text(
                '${empleado.puesto}\n'
                'Horario: ${empleado.horario.isEmpty ? 'Sin especificar' : empleado.horario}',
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _colorTarjeta,
        foregroundColor: _doradoOscuro,
        title: const Text('Horarios y Asistencias'),
        actions: [
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: _guardando
                ? null
                : () {
                    _cargarPersonal();
                    _cargarHistorial();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 22, 17, 40),
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
            'Control de asistencia laboral',
            style: TextStyle(
              color: _texto,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registra entradas y salidas, consulta '
            'el historial y sus responsables.',
            style: TextStyle(color: _secundario),
          ),
          const SizedBox(height: 16),
          if (_errorOperacion != null)
            _tarjeta(
              titulo: 'Revisa esta operación',
              contenido: Text(
                _errorOperacion!,
                style: const TextStyle(color: _rojo),
              ),
            ),
          if (_exito != null)
            _tarjeta(
              titulo: 'Operación confirmada',
              contenido: Text(
                _exito!,
                style: const TextStyle(color: Color(0xFF287447)),
              ),
            ),
          if (_revisionPendiente)
            _tarjeta(
              titulo: 'Verificación necesaria',
              contenido: const Text(
                'El resultado de una operación fue incierto. '
                'Revisa el historial y confirma su estado '
                'antes de registrar otra entrada o salida.',
                style: TextStyle(color: _rojo),
              ),
            ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Asistencias'),
                icon: Icon(Icons.fact_check_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('Horarios'),
                icon: Icon(Icons.schedule),
              ),
            ],
            selected: {_mostrarHorarios},
            onSelectionChanged: (seleccion) {
              setState(() => _mostrarHorarios = seleccion.first);
            },
          ),
          const SizedBox(height: 20),
          if (_mostrarHorarios) _pantallaHorarios() else _pantallaAsistencias(),
        ],
      ),
    );
  }
}
