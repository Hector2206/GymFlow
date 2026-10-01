import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

import 'historial_asistencias_page.dart';
import 'historial_pagos_page.dart';
import 'login_page.dart';
import 'mi_codigo_page.dart';
import 'mis_asistencias_page.dart';
import 'mis_pagos_page.dart';
import 'profile_page.dart';
import 'registrar_asistencia_page.dart';
import 'registrar_cliente_page.dart';
import 'registrar_pago_page.dart';
import 'clientes_entrenador_page.dart';
import 'rutinas_page.dart';
import 'mi_rutina_page.dart';
import 'ejercicios_page.dart';


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

  void irRegistrarAsistencia(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const RegistrarAsistenciaPage(),
      ),
    );
  }

  void irHistorialAsistencias(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const HistorialAsistenciasPage(),
      ),
    );
  }

  void irRegistrarPago(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const RegistrarPagoPage(),
      ),
    );
  }

  void irHistorialPagos(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const HistorialPagosPage(),
      ),
    );
  }

  void irMiCodigoAcceso(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const MiCodigoPage(),
      ),
    );
  }

  void irMisAsistencias(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const MisAsistenciasPage(),
      ),
    );
  }

  void irMisPagos(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const MisPagosPage(),
      ),
    );
  }

  void proximamente(
    BuildContext context,
    String nombre,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            const Color(
          0xFFFFFDF8,
        ),

        elevation: 3,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          side:
              const BorderSide(
            color:
                Color(
              0xFFD8C8A5,
            ),
          ),
        ),

        content: Row(
          children: [
            Container(
              width: 30,
              height: 30,

              decoration:
                  const BoxDecoration(
                color:
                    Color(
                  0xFFB58A2A,
                ),
                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                '$nombre estará disponible próximamente.',

                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFF2F2A24,
                  ),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    const background =
        Color(
      0xFFF8F5EF,
    );

    const surface =
        Color(
      0xFFFFFDF8,
    );

    const goldDark =
        Color(
      0xFF8A6814,
    );

    const textPrimary =
        Color(
      0xFF2F2A24,
    );

    const textSecondary =
        Color(
      0xFF777067,
    );

    return Scaffold(
      backgroundColor:
          background,

      appBar: AppBar(
        backgroundColor:
            surface,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        shadowColor:
            const Color(
          0x144C3E24,
        ),

        titleSpacing: 18,

        title: Image.asset(
          'assets/Logo_GymFlow.png',

          height: 48,

          fit:
              BoxFit.contain,
        ),

        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 14,
            ),

            child: Container(
              width: 42,
              height: 42,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF8F4EC,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFD8C8A5,
                  ),
                ),
              ),

              child:
                  IconButton(
                padding:
                    EdgeInsets.zero,

                tooltip:
                    'Cerrar sesión',

                onPressed: () {
                  cerrarSesion(
                    context,
                  );
                },

                icon:
                    const Icon(
                  Icons.logout_rounded,

                  color:
                      goldDark,

                  size:
                      21,
                ),
              ),
            ),
          ),
        ],

        bottom:
            const PreferredSize(
          preferredSize:
              Size.fromHeight(
            1,
          ),

          child:
              Divider(
            height: 1,

            color:
                Color(
              0xFFE7DFD2,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Container(
          width:
              double.infinity,

          decoration:
              const BoxDecoration(
            gradient:
                LinearGradient(
              begin:
                  Alignment.topCenter,

              end:
                  Alignment.bottomCenter,

              colors: [
                Color(
                  0xFFF8F5EF,
                ),

                Color(
                  0xFFF2EDE4,
                ),
              ],
            ),
          ),

          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              28,
              18,
              40,
            ),

            child: Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 760,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        22,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            surface,

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE5DDCF,
                          ),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(
                              0xFF4C3E24,
                            ).withValues(
                              alpha:
                                  0.05,
                            ),

                            blurRadius:
                                22,

                            offset:
                                const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'GYMFLOW',

                            style:
                                TextStyle(
                              color:
                                  goldDark,

                              fontSize:
                                  11,

                              fontWeight:
                                  FontWeight
                                      .w700,

                              letterSpacing:
                                  2,
                            ),
                          ),

                          const SizedBox(
                            height:
                                7,
                          ),

                          Text(
                            'Hola, ${usuario.name}',

                            style:
                                const TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  29,

                              fontWeight:
                                  FontWeight
                                      .w700,

                              letterSpacing:
                                  -0.6,
                            ),
                          ),

                          const SizedBox(
                            height:
                                8,
                          ),

                          const Text(
                            'Bienvenido a tu espacio de gestión.',

                            style:
                                TextStyle(
                              color:
                                  textSecondary,

                              fontSize:
                                  14,

                              height:
                                  1.4,
                            ),
                          ),

                          const SizedBox(
                            height:
                                16,
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  14,

                              vertical:
                                  7,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF3EAD8,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),

                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFFD8C392,
                                ),
                              ),
                            ),

                            child: Text(
                              usuario.role,

                              style:
                                  const TextStyle(
                                color:
                                    goldDark,

                                fontSize:
                                    12,

                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          28,
                    ),

                    const Text(
                      'Accesos rápidos',

                      style:
                          TextStyle(
                        color:
                            textPrimary,

                        fontSize:
                            19,

                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    const Text(
                      'Selecciona una opción para continuar.',

                      style:
                          TextStyle(
                        color:
                            textSecondary,

                        fontSize:
                            13,
                      ),
                    ),

                    const SizedBox(
                      height:
                          18,
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
          ),
        ),
      ),

      bottomNavigationBar:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration:
            const BoxDecoration(
          color:
              surface,

          border:
              Border(
            top:
                BorderSide(
              color:
                  Color(
                0xFFE7DFD2,
              ),
            ),
          ),
        ),

        child:
            const SafeArea(
          top: false,

          child: Text(
            'GymFlow · Gestión inteligente para gimnasios',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  textSecondary,

              fontSize:
                  11,
            ),
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
          irRegistrarAsistencia(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.calendar_month_outlined,
        titulo:
            'Historial de Asistencias',
        subtitulo:
            'Consultar registros de entrada de clientes',
        onTap: () {
          irHistorialAsistencias(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.payments_outlined,
        titulo:
            'Registrar Pago',
        subtitulo:
            'Registrar pagos y renovaciones de clientes',
        onTap: () {
          irRegistrarPago(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.receipt_long_outlined,
        titulo:
            'Historial de Pagos',
        subtitulo:
            'Consultar los pagos registrados de clientes',
        onTap: () {
          irHistorialPagos(
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
            Icons.qr_code_2_outlined,
        titulo:
            'Mi Código de Acceso',
        subtitulo:
            'Consulta tu código personal para registrar tu entrada',
        onTap: () {
          irMiCodigoAcceso(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.calendar_month_outlined,
        titulo:
            'Mis Asistencias',
        subtitulo:
            'Consulta tu historial de asistencias',
        onTap: () {
          irMisAsistencias(
            context,
          );
        },
      ),

      _espacio(),

      _buildCard(
        icon:
            Icons.payments_outlined,
        titulo:
            'Mis Pagos',
        subtitulo:
            'Consulta tus pagos y renovaciones',
        onTap: () {
          irMisPagos(
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const MiRutinaPage(),
            ),
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const ClientesEntrenadorPage(),
              ),
            );
          },
        ),

      _espacio(),

      _buildCard(
        icon:
            Icons.fitness_center,
        titulo:
            'Ejercicios',
        subtitulo:
            'Crear y administrar ejercicios e imágenes',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const EjerciciosPage(),
            ),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const RutinasPage(),
            ),
          );
        },
      ),
      

    ];
  }

  Widget _espacio() {
    return const SizedBox(
      height: 14,
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    const gold =
        Color(
      0xFFB58A2A,
    );

    const goldDark =
        Color(
      0xFF8A6814,
    );

    const surface =
        Color(
      0xFFFFFDF8,
    );

    const textPrimary =
        Color(
      0xFF2F2A24,
    );

    const textSecondary =
        Color(
      0xFF777067,
    );

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        onTap:
            onTap,

        child: Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            18,
          ),

          decoration:
              BoxDecoration(
            color:
                surface,

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFFE5DDCF,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    const Color(
                  0xFF4C3E24,
                ).withValues(
                  alpha:
                      0.04,
                ),

                blurRadius:
                    16,

                offset:
                    const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                width:
                    54,

                height:
                    54,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3EAD8,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE4D2AA,
                    ),
                  ),
                ),

                child: Icon(
                  icon,

                  color:
                      goldDark,

                  size:
                      27,
                ),
              ),

              const SizedBox(
                width:
                    16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      titulo,

                      style:
                          const TextStyle(
                        color:
                            textPrimary,

                        fontSize:
                            16,

                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      subtitulo,

                      style:
                          const TextStyle(
                        color:
                            textSecondary,

                        fontSize:
                            13,

                        height:
                            1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              const Icon(
                Icons.chevron_right_rounded,

                color:
                    gold,

                size:
                    24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}