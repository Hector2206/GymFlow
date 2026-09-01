import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

import 'login_page.dart';
import 'profile_page.dart';
import 'registrar_cliente_page.dart';

class HomePage extends StatelessWidget {
  final Usuario usuario;

  const HomePage({
    super.key,
    required this.usuario,
  });

  String get rolNormalizado =>
      usuario.role.trim().toLowerCase();

  bool get esAdministrador =>
      rolNormalizado == 'administrador';

  bool get esRecepcionista =>
      rolNormalizado == 'recepcionista';

  bool get esEntrenador =>
      rolNormalizado == 'entrenador';

  bool get esCliente =>
      rolNormalizado == 'cliente';

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

  void irPerfil(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          usuario: usuario,
        ),
      ),
    );
  }

  void irRegistrarCliente(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const RegistrarClientePage(),
      ),
    );
  }

  void proximamente(
    BuildContext context,
    String nombre,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$nombre estará disponible próximamente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor:
          const Color(0xFF101012),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF101012),

        elevation: 0,

        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 50,
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: IconButton(
              tooltip: 'Cerrar sesión',

              onPressed: () {
                cerrarSesion(
                  context,
                );
              },

              icon: const Icon(
                Icons.logout,
                color: gold,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            28,
            18,
            40,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Bienvenido a GymFlow',

                style: TextStyle(
                  color:
                      Color(0xFFA9A9A9),
                  fontSize: 15,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                'Hola, ${usuario.name}',

                style: const TextStyle(
                  color:
                      Colors.white,

                  fontSize: 30,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      gold.withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),

                  border:
                      Border.all(
                    color:
                        gold.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),

                child: Text(
                  usuario.role,

                  style:
                      const TextStyle(
                    color: gold,

                    fontSize: 13,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                height: 35,
              ),

              if (esRecepcionista)
                ..._tarjetasRecepcionista(
                  context,
                ),

              if (esCliente)
                ..._tarjetasCliente(
                  context,
                ),

              if (esAdministrador)
                ..._tarjetasAdministrador(
                  context,
                ),

              if (esEntrenador)
                ..._tarjetasEntrenador(
                  context,
                ),
            ],
          ),
        ),
      ),

      bottomNavigationBar:
          const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 14,
        ),

        child: Text(
          'GymFlow · Gestión inteligente para gimnasios',

          textAlign:
              TextAlign.center,

          style:
              TextStyle(
            color:
                Color(0xFF777777),

            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<Widget> _tarjetasRecepcionista(
    BuildContext context,
  ) {
    return [
      _buildCard(
        icon:
            Icons.person_outline,

        titulo:
            'Mi Perfil',

        subtitulo:
            'Consulta tu información de usuario',

        onTap: () {
          irPerfil(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.person_add_alt_1,

        titulo:
            'Registrar Cliente',

        subtitulo:
            'Dar de alta un nuevo cliente',

        onTap: () {
          irRegistrarCliente(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.check_circle_outline,

        titulo:
            'Registrar Asistencia',

        subtitulo:
            'Registrar la asistencia de un cliente',

        onTap: () {
          proximamente(
            context,
            'Registrar asistencia',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.groups_outlined,

        titulo:
            'Administrar Clientes',

        subtitulo:
            'Consultar y administrar clientes',

        onTap: () {
          proximamente(
            context,
            'Administrar clientes',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.fitness_center,

        titulo:
            'Asignación de Entrenadores',

        subtitulo:
            'Asignar clientes a entrenadores',

        onTap: () {
          proximamente(
            context,
            'Asignación de entrenadores',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.campaign_outlined,

        titulo:
            'Anuncios',

        subtitulo:
            'Administrar anuncios del gimnasio',

        onTap: () {
          proximamente(
            context,
            'Anuncios',
          );
        },
      ),
    ];
  }

  List<Widget> _tarjetasCliente(
    BuildContext context,
  ) {
    return [
      _buildCard(
        icon:
            Icons.person_outline,

        titulo:
            'Mi Perfil',

        subtitulo:
            'Consulta tu información personal',

        onTap: () {
          irPerfil(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.card_membership_outlined,

        titulo:
            'Membresía',

        subtitulo:
            'Consulta tu membresía actual',

        onTap: () {
          proximamente(
            context,
            'Membresía',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.fitness_center,

        titulo:
            'Rutinas',

        subtitulo:
            'Consulta tu rutina de entrenamiento',

        onTap: () {
          proximamente(
            context,
            'Rutinas',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.calendar_month_outlined,

        titulo:
            'Ver Asistencias',

        subtitulo:
            'Consulta tu historial de asistencias',

        onTap: () {
          proximamente(
            context,
            'Asistencias',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.campaign_outlined,

        titulo:
            'Anuncios',

        subtitulo:
            'Consulta anuncios y promociones',

        onTap: () {
          proximamente(
            context,
            'Anuncios',
          );
        },
      ),
    ];
  }

  List<Widget> _tarjetasAdministrador(
    BuildContext context,
  ) {
    return [
      _buildCard(
        icon:
            Icons.person_outline,

        titulo:
            'Mi Perfil',

        subtitulo:
            'Consulta tu información de administrador',

        onTap: () {
          irPerfil(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.groups_outlined,

        titulo:
            'Administrar Clientes',

        subtitulo:
            'Consultar y administrar clientes',

        onTap: () {
          proximamente(
            context,
            'Administrar clientes',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.badge_outlined,

        titulo:
            'Administrar Recepcionistas',

        subtitulo:
            'Consultar y administrar recepcionistas',

        onTap: () {
          proximamente(
            context,
            'Administrar recepcionistas',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.fitness_center,

        titulo:
            'Administrar Entrenadores',

        subtitulo:
            'Consultar y administrar entrenadores',

        onTap: () {
          proximamente(
            context,
            'Administrar entrenadores',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.admin_panel_settings_outlined,

        titulo:
            'Ver Administradores',

        subtitulo:
            'Consulta los administradores registrados',

        onTap: () {
          proximamente(
            context,
            'Ver administradores',
          );
        },
      ),
    ];
  }

  List<Widget> _tarjetasEntrenador(
    BuildContext context,
  ) {
    return [
      _buildCard(
        icon:
            Icons.person_outline,

        titulo:
            'Mi Perfil',

        subtitulo:
            'Consulta tu información de entrenador',

        onTap: () {
          irPerfil(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.groups_outlined,

        titulo:
            'Administrar mis Clientes',

        subtitulo:
            'Consulta los clientes que tienes asignados',

        onTap: () {
          proximamente(
            context,
            'Administrar mis clientes',
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.fitness_center,

        titulo:
            'Rutinas',

        subtitulo:
            'Crear y administrar rutinas de entrenamiento',

        onTap: () {
          proximamente(
            context,
            'Rutinas',
          );
        },
      ),
    ];
  }

  Widget _espacio() {
    return const SizedBox(
      height: 18,
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    const gold =
        Color(0xFFD4AF37);

    const coal =
        Color(0xFF1A1A1D);

    const silver =
        Color(0xFFA9A9A9);

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),

        onTap:
            onTap,

        child: Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            22,
          ),

          decoration:
              BoxDecoration(
            color:
                coal,

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            border:
                Border.all(
              color:
                  gold.withValues(
                alpha: 0.20,
              ),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration:
                    BoxDecoration(
                  color:
                      gold.withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,
                  color: gold,
                  size: 30,
                ),
              ),

              const SizedBox(
                width: 18,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      titulo,

                      style:
                          const TextStyle(
                        color:
                            Colors.white,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      subtitulo,

                      style:
                          const TextStyle(
                        color:
                            silver,

                        fontSize:
                            14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Icon(
                Icons.chevron_right,
                color: gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}