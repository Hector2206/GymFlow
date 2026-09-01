import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/usuario_service.dart';
import '../widgets/google_login_button.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  final formKey =
      GlobalKey<FormState>();

  final correoController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final AuthService authService =
      AuthService();

  final UsuarioService
      usuarioService =
      UsuarioService();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (!formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final loginCorrecto =
          await authService.login(
        correo:
            correoController.text,
        password:
            passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (!loginCorrecto) {
        mostrarMensaje(
          'Correo o contraseña incorrectos.',
        );

        return;
      }

      await validarSesion();
    } catch (_) {
      if (!mounted) {
        return;
      }

      mostrarMensaje(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> iniciarSesionGoogle(
    String idToken,
  ) async {
    if (cargando) {
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final resultado =
          await authService
              .loginGoogle(
        googleToken: idToken,
      );

      if (!mounted) {
        return;
      }

      final correcto =
          resultado['ok'] == true;

      if (!correcto) {
        await authService
            .cerrarSesion();

        if (!mounted) {
          return;
        }

        final statusCode =
            resultado[
                'statusCode'];

        if (statusCode == 401 ||
            statusCode == 404) {
          mostrarMensaje(
            'No encontramos una cuenta registrada con este correo. Acude a recepción para que registren tu cuenta.',
          );
        } else {
          final mensaje =
              resultado[
                      'mensaje']
                  ?.toString();

          mostrarMensaje(
            mensaje == null ||
                    mensaje.isEmpty
                ? 'No se pudo iniciar sesión con Google.'
                : mensaje,
          );
        }

        return;
      }

      await validarSesion();
    } catch (_) {
      if (!mounted) {
        return;
      }

      mostrarMensaje(
        'No se pudo iniciar sesión con Google.',
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> validarSesion() async {
    final usuario =
        await usuarioService
            .obtenerUsuarioActual();

    if (!mounted) {
      return;
    }

    if (usuario == null) {
      await authService
          .cerrarSesion();

      if (!mounted) {
        return;
      }

      mostrarMensaje(
        'No se pudo validar la sesión.',
      );

      return;
    }

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
  }

  void mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        backgroundColor:
            const Color(
          0xFF990000,
        ),
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(
          seconds: 5,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFF101012,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 28,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/Logo_GymFlow.png',
                      width: 230,
                      fit:
                          BoxFit.contain,
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 28,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Ingresa a tu cuenta de GymFlow',
                      textAlign:
                          TextAlign
                              .center,
                      style: TextStyle(
                        color:
                            Color(
                          0xFFA9A9A9,
                        ),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 35,
                    ),

                    TextFormField(
                      controller:
                          correoController,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Correo',
                        prefixIcon:
                            Icon(
                          Icons.email_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .trim()
                                .isEmpty) {
                          return 'Ingresa tu correo.';
                        }

                        if (!value
                            .contains(
                          '@',
                        )) {
                          return 'Ingresa un correo válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextFormField(
                      controller:
                          passwordController,
                      obscureText:
                          ocultarPassword,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Contraseña',
                        prefixIcon:
                            const Icon(
                          Icons
                              .lock_outline,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed:
                              () {
                            setState(() {
                              ocultarPassword =
                                  !ocultarPassword;
                            });
                          },
                          icon: Icon(
                            ocultarPassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                        border:
                            const OutlineInputBorder(),
                      ),
                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'Ingresa tu contraseña.';
                        }

                        if (value.length <
                            6) {
                          return 'La contraseña debe tener al menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton(
                        onPressed:
                            cargando
                                ? null
                                : iniciarSesion,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFD4AF37,
                          ),
                          foregroundColor:
                              const Color(
                            0xFF101012,
                          ),
                        ),
                        child: cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Color(
                                    0xFF101012,
                                  ),
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    const Row(
                      children: [
                        Expanded(
                          child:
                              Divider(),
                        ),
                        Padding(
                          padding:
                              EdgeInsets
                                  .symmetric(
                            horizontal:
                                14,
                          ),
                          child: Text(
                            'o',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFFA9A9A9,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              Divider(),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    GoogleLoginButton(
                      onToken:
                          iniciarSesionGoogle,
                      onError:
                          mostrarMensaje,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    const Text(
                      'Para iniciar sesión con Google, tu correo debe haber sido registrado previamente por recepción.',
                      textAlign:
                          TextAlign
                              .center,
                      style: TextStyle(
                        color:
                            Color(
                          0xFFA9A9A9,
                        ),
                        fontSize: 13,
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
}