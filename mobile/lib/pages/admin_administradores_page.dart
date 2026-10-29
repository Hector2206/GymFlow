import 'package:flutter/material.dart';

import 'admin_modulo_preparado_page.dart';

class AdminAdministradoresPage extends StatelessWidget {
  const AdminAdministradoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminModuloPreparadoPage(
      titulo: 'Administrar Administradores',
      subtitulo:
          'Gestión protegida de cuentas '
          'con permisos administrativos.',
      icono: Icons.admin_panel_settings_outlined,
      funciones: [
        AdminFuncionPendiente(
          titulo: 'Consultar administradores',
          descripcion:
              'Mostrar cuentas reales con '
              'el rol Administrador.',
          icono: Icons.groups_outlined,
        ),
        AdminFuncionPendiente(
          titulo: 'Registrar administrador',
          descripcion:
              'Crear una cuenta administrativa '
              'con autorización del Backend.',
          icono: Icons.person_add_alt_1_outlined,
        ),
        AdminFuncionPendiente(
          titulo: 'Editar información',
          descripcion:
              'Modificar los datos permitidos '
              'de una cuenta existente.',
          icono: Icons.manage_accounts_outlined,
        ),
        AdminFuncionPendiente(
          titulo: 'Desactivar administrador',
          descripcion:
              'Dar de baja una cuenta sin perder '
              'su historial de auditoría.',
          icono: Icons.lock_person_outlined,
        ),
      ],
    );
  }
}
