import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/version_service.dart';

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
  Widget build(
    BuildContext context,
  ) {
    const background =
        Color(0xFFF8F5EF);

    const surface =
        Color(0xFFFFFDF8);

    const goldDark =
        Color(0xFF8A6814);

    const textPrimary =
        Color(0xFF2F2A24);

    const textSecondary =
        Color(0xFF777067);

    const border =
        Color(0xFFE5DDCF);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: surface,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        leading: Padding(
          padding:
              const EdgeInsets.all(
            8,
          ),

          child: Container(
            decoration:
                BoxDecoration(
              color:
                  surface,

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

            child: IconButton(
              padding:
                  EdgeInsets.zero,

              tooltip:
                  'Regresar',

              onPressed: () {
                Navigator.of(
                  context,
                ).pop();
              },

              icon:
                  const Icon(
                Icons
                    .arrow_back_rounded,

                color:
                    goldDark,

                size:
                    21,
              ),
            ),
          ),
        ),

        title: Image.asset(
          'assets/Logo_GymFlow.png',

          height:
              48,

          fit:
              BoxFit.contain,
        ),

        bottom:
            const PreferredSize(
          preferredSize:
              Size.fromHeight(
            1,
          ),

          child: Divider(
            height:
                1,

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
              20,
              30,
              20,
              45,
            ),

            child: Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      650,
                ),

                child: Column(
                  children: [
                    const Text(
                      'MI PERFIL',

                      style:
                          TextStyle(
                        color:
                            goldDark,

                        fontSize:
                            11,

                        fontWeight:
                            FontWeight.w700,

                        letterSpacing:
                            2,
                      ),
                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    Container(
                      width:
                          104,

                      height:
                          104,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF3EAD8,
                        ),

                        shape:
                            BoxShape.circle,

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFD8C392,
                          ),

                          width:
                              2,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(
                              0xFF4C3E24,
                            ).withValues(
                              alpha:
                                  0.08,
                            ),

                            blurRadius:
                                20,

                            offset:
                                const Offset(
                              0,
                              7,
                            ),
                          ),
                        ],
                      ),

                      child:
                          const Icon(
                        Icons
                            .person_outline_rounded,

                        color:
                            goldDark,

                        size:
                            55,
                      ),
                    ),

                    const SizedBox(
                      height:
                          20,
                    ),

                    Text(
                      usuario.name,

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color:
                            textPrimary,

                        fontSize:
                            28,

                        fontWeight:
                            FontWeight.w700,

                        letterSpacing:
                            -0.5,
                      ),
                    ),

                    const SizedBox(
                      height:
                          9,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal:
                            16,

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
                              FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          30,
                    ),

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
                              border,
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
                        children: [
                          _datoPerfil(
                            icon:
                                Icons
                                    .badge_outlined,

                            titulo:
                                'ID de usuario',

                            valor:
                                usuario.idUsuario,
                          ),

                          const Divider(
                            height:
                                32,

                            color:
                                border,
                          ),

                          _datoPerfil(
                            icon:
                                Icons
                                    .person_outline,

                            titulo:
                                'Nombre',

                            valor:
                                usuario.name,
                          ),

                          const Divider(
                            height:
                                32,

                            color:
                                border,
                          ),

                          _datoPerfil(
                            icon:
                                Icons
                                    .email_outlined,

                            titulo:
                                'Correo electrónico',

                            valor:
                                usuario.correo,
                          ),

                          const Divider(
                            height:
                                32,

                            color:
                                border,
                          ),

                          _datoPerfil(
                            icon:
                                Icons
                                    .admin_panel_settings_outlined,

                            titulo:
                                'Tipo de usuario',

                            valor:
                                usuario.role,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          26,
                    ),

                    SizedBox(
                      width:
                          double.infinity,

                      height:
                          52,

                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          cerrarSesion(
                            context,
                          );
                        },

                        icon:
                            const Icon(
                          Icons
                              .logout_rounded,

                          size:
                              20,
                        ),

                        label:
                            const Text(
                          'Cerrar sesión',
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              const Color(
                            0xFF8F2030,
                          ),

                          backgroundColor:
                              const Color(
                            0xFFFFF8F7,
                          ),

                          side:
                              const BorderSide(
                            color:
                                Color(
                              0xFFE4B8B8,
                            ),
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),

                          textStyle:
                              const TextStyle(
                            fontSize:
                                14,

                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          30,
                    ),

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical:
                            18,
                      ),

                      decoration:
                          const BoxDecoration(
                        border:
                            Border(
                          top:
                              BorderSide(
                            color:
                                border,
                          ),
                        ),
                      ),

                      child:
                          Column(
                        children: [
                          Text(
                            'GymFlow Mobile',

                            style:
                                TextStyle(
                              color:
                                  textPrimary,

                              fontSize:
                                  12,

                              fontWeight:
                                  FontWeight.w600,

                              letterSpacing:
                                  0.3,
                            ),
                          ),

                          SizedBox(
                            height:
                                5,
                          ),

                          FutureBuilder<String?>(
                            future: VersionService().obtenerVersion(),
                            builder: (
                              context,
                              snapshot,
                            ) {
                              final version =
                                  snapshot.data;

                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  version == null) {
                                return const Text(
                                  'Versión del sistema',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                  ),
                                );
                              }

                              return Text(
                                'Versión $version',
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    const goldDark =
        Color(0xFF8A6814);

    const textPrimary =
        Color(0xFF2F2A24);

    const textSecondary =
        Color(0xFF777067);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,

      children: [
        Container(
          width:
              48,

          height:
              48,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF3EAD8,
            ),

            borderRadius:
                BorderRadius.circular(
              13,
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
                23,
          ),
        ),

        const SizedBox(
          width:
              15,
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
                      textSecondary,

                  fontSize:
                      11,

                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height:
                    5,
              ),

              Text(
                valor.isEmpty
                    ? 'Sin información'
                    : valor,

                style:
                    const TextStyle(
                  color:
                      textPrimary,

                  fontSize:
                      15,

                  fontWeight:
                      FontWeight.w700,

                  height:
                      1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}