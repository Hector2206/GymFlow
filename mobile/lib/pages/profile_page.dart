import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final Usuario usuario;

  const ProfilePage({
    super.key,
    required this.usuario,
  });

  Future<void> cerrarSesion(
    BuildContext context,
  ) async {
    await AuthService().cerrarSesion();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const coal = Color(0xFF1A1A1D);
    const silver = Color(0xFFA9A9A9);

    return Scaffold(
      backgroundColor: const Color(0xFF101012),

      appBar: AppBar(
        backgroundColor: const Color(0xFF101012),
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: gold,
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 650,
              ),

              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),

                  Container(
                    width: 105,
                    height: 105,

                    decoration: BoxDecoration(
                      color: gold.withValues(
                        alpha: 0.10,
                      ),

                      shape: BoxShape.circle,

                      border: Border.all(
                        color: gold.withValues(
                          alpha: 0.55,
                        ),
                        width: 2,
                      ),
                    ),

                    child: const Icon(
                      Icons.person_outline,
                      color: gold,
                      size: 58,
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  Text(
                    usuario.name,
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: gold.withValues(
                        alpha: 0.10,
                      ),

                      borderRadius: BorderRadius.circular(
                        30,
                      ),

                      border: Border.all(
                        color: gold.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),

                    child: Text(
                      usuario.role,

                      style: const TextStyle(
                        color: gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(
                      24,
                    ),

                    decoration: BoxDecoration(
                      color: coal,

                      borderRadius: BorderRadius.circular(
                        20,
                      ),

                      border: Border.all(
                        color: gold.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),

                    child: Column(
                      children: [
                        _datoPerfil(
                          icon: Icons.badge_outlined,
                          titulo: 'ID de usuario',
                          valor: usuario.idUsuario,
                        ),

                        const Divider(
                          height: 32,
                          color: Color(0xFF353535),
                        ),

                        _datoPerfil(
                          icon: Icons.person_outline,
                          titulo: 'Nombre',
                          valor: usuario.name,
                        ),

                        const Divider(
                          height: 32,
                          color: Color(0xFF353535),
                        ),

                        _datoPerfil(
                          icon: Icons.email_outlined,
                          titulo: 'Correo',
                          valor: usuario.correo,
                        ),

                        const Divider(
                          height: 32,
                          color: Color(0xFF353535),
                        ),

                        _datoPerfil(
                          icon:
                              Icons.admin_panel_settings_outlined,
                          titulo: 'Rol',
                          valor: usuario.role,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: OutlinedButton.icon(
                      onPressed: () {
                        cerrarSesion(
                          context,
                        );
                      },

                      icon: const Icon(
                        Icons.logout,
                      ),

                      label: const Text(
                        'Cerrar sesión',
                      ),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: gold,

                        side: BorderSide(
                          color: gold.withValues(
                            alpha: 0.50,
                          ),
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'GymFlow · Gestión inteligente para gimnasios',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: silver,
                      fontSize: 12,
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

  Widget _datoPerfil({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    const gold = Color(0xFFD4AF37);
    const silver = Color(0xFFA9A9A9);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: gold.withValues(
              alpha: 0.10,
            ),

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: Icon(
            icon,
            color: gold,
          ),
        ),

        const SizedBox(
          width: 16,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                titulo,

                style: const TextStyle(
                  color: silver,
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                valor.isEmpty
                    ? 'Sin información'
                    : valor,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}