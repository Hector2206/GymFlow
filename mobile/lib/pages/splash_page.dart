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
    // Dejamos visible el Splash durante 5 segundos,
    // igual que en la versión Web.
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

    // Si no existe token, enviamos directamente
    // al inicio de sesión.
    if (token == null ||
        token.isEmpty) {
      irLogin();

      return;
    }

    try {
      // No confiamos solamente en el token guardado.
      // Lo validamos contra el backend.
      final usuario =
          await usuarioService.obtenerUsuarioActual();

      if (!mounted) {
        return;
      }

      if (usuario != null) {
        Navigator.of(context)
            .pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomePage(
              usuario: usuario,
            ),
          ),
          (route) => false,
        );

        return;
      }

      // Si el backend rechaza el token,
      // eliminamos la sesión local.
      await authService.cerrarSesion();

      if (!mounted) {
        return;
      }

      irLogin();
    } catch (_) {
      // Si no se puede validar la sesión,
      // evitamos dejar al usuario dentro
      // únicamente por tener un token guardado.
      await authService.cerrarSesion();

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
    return Scaffold(
      backgroundColor:
          const Color(0xFF101012),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 40,
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Image.asset(
                'assets/Logo_GymFlow.png',

                width: 280,

                fit: BoxFit.contain,
              ),

              const SizedBox(
                height: 35,
              ),

              const SizedBox(
                width: 28,
                height: 28,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,

                  color:
                      Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}