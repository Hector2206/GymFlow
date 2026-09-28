import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/usuario_service.dart';

import 'home_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
  });

  @override
  State<SplashPage> createState() =>
      _SplashPageState();
}

class _SplashPageState
    extends State<SplashPage> {
  final AuthService authService =
      AuthService();

  final UsuarioService usuarioService =
      UsuarioService();

  @override
  void initState() {
    super.initState();

    iniciarAplicacion();
  }

  Future<void> iniciarAplicacion() async {
    await Future.delayed(
      const Duration(
        seconds: 5,
      ),
    );

    if (!mounted) {
      return;
    }

    final token =
        await authService.obtenerToken();

    if (token == null ||
        token.isEmpty) {
      irLogin();

      return;
    }

    try {
      final usuario =
          await usuarioService
              .obtenerUsuarioActual();

      if (!mounted) {
        return;
      }

      if (usuario != null) {
        Navigator.of(context)
            .pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                HomePage(
              usuario: usuario,
            ),
          ),
          (route) => false,
        );

        return;
      }

      await authService
          .cerrarSesion();

      if (!mounted) {
        return;
      }

      irLogin();
    } catch (_) {
      await authService
          .cerrarSesion();

      if (!mounted) {
        return;
      }

      irLogin();
    }
  }

  void irLogin() {
    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
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

    const gold =
        Color(0xFFB58A2A);

    const textPrimary =
        Color(0xFF2F2A24);

    const textSecondary =
        Color(0xFF777067);

    return Scaffold(
      backgroundColor:
          background,

      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,

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

          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 32,
              ),

              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 420,
                ),

                child: Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 40,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        surface,

                    borderRadius:
                        BorderRadius.circular(
                      24,
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
                          alpha: 0.08,
                        ),

                        blurRadius:
                            28,

                        offset:
                            const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      Image.asset(
                        'assets/Logo_GymFlow.png',

                        width:
                            230,

                        fit:
                            BoxFit.contain,
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      const Text(
                        'GymFlow',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              textPrimary,

                          fontSize:
                              26,

                          fontWeight:
                              FontWeight.w700,

                          letterSpacing:
                              -0.5,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Gestión inteligente para tu gimnasio',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              textSecondary,

                          fontSize:
                              13,

                          height:
                              1.4,
                        ),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      const SizedBox(
                        width:
                            double.infinity,

                        child:
                            LinearProgressIndicator(
                          minHeight:
                              4,

                          backgroundColor:
                              Color(
                            0xFFE9E1D4,
                          ),

                          color:
                              gold,

                          borderRadius:
                              BorderRadius.all(
                            Radius.circular(
                              20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      const Text(
                        'Preparando tu experiencia...',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              textSecondary,

                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}