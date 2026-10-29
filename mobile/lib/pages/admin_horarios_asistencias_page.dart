import 'package:flutter/material.dart';

import 'admin_modulo_preparado_page.dart';

class AdminHorariosAsistenciasPage extends StatelessWidget {
  const AdminHorariosAsistenciasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminModuloPreparadoPage(
      titulo: 'Horarios y Asistencias',
      subtitulo:
          'Organización de horarios, turnos '
          'y asistencia laboral del personal.',
      icono: Icons.calendar_month_outlined,
      funciones: [
        AdminFuncionPendiente(
          titulo: 'Consultar horarios',
          descripcion:
              'Visualizar los turnos asignados '
              'a entrenadores y recepcionistas.',
          icono: Icons.schedule_outlined,
        ),
        AdminFuncionPendiente(
          titulo: 'Asignar horarios',
          descripcion:
              'Registrar y actualizar turnos '
              'del personal autorizado.',
          icono: Icons.edit_calendar_outlined,
        ),
        AdminFuncionPendiente(
          titulo: 'Registrar asistencias',
          descripcion:
              'Registrar entradas del personal '
              'desde una operación administrativa.',
          icono: Icons.how_to_reg_outlined,
        ),
        AdminFuncionPendiente(
          titulo: 'Historial de asistencias',
          descripcion:
              'Consultar asistencias laborales '
              'registradas por empleado.',
          icono: Icons.history_outlined,
        ),
      ],
    );
  }
}
