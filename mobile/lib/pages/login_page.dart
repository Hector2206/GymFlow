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

  final UsuarioService usuarioService =
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
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        margin:
            const EdgeInsets.all(
          18,
        ),

        backgroundColor:
            const Color(
          0xFFFFF6F6,
        ),

        elevation:
            3,

        duration:
            const Duration(
          seconds: 5,
        ),

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
              0xFFEDB9BF,
            ),
          ),
        ),

        content: Row(
          children: [
            Container(
              width:
                  30,

              height:
                  30,

              decoration:
                  const BoxDecoration(
                color:
                    Color(
                  0xFFC21B2E,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Center(
                child: Text(
                  '!',

                  style:
                      TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        16,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width:
                  12,
            ),

            Expanded(
              child: Text(
                mensaje,

                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFF8F2030,
                  ),

                  fontSize:
                      13,

                  fontWeight:
                      FontWeight.w600,

                  height:
                      1.4,
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
    const surface =
        Color(
      0xFFFFFDF8,
    );

    const gold =
        Color(
      0xFFB58A2A,
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

    const border =
        Color(
      0xFFE5DDCF,
    );

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF8F5EF,
      ),

      body: SafeArea(
        child: Container(
          width:
              double.infinity,

          height:
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
                const EdgeInsets.symmetric(
              horizontal:
                  22,

              vertical:
                  30,
            ),

            child: Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      460,
                ),

                child: Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        24,

                    vertical:
                        32,
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
                          border,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(
                          0xFF4C3E24,
                        ).withValues(
                          alpha:
                              0.07,
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

                  child: Form(
                    key:
                        formKey,

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,

                      children: [
                        Center(
                          child:
                              Image.asset(
                            'assets/Logo_GymFlow.png',

                            width:
                                215,

                            fit:
                                BoxFit
                                    .contain,
                          ),
                        ),

                        const SizedBox(
                          height:
                              25,
                        ),

                        const Text(
                          'BIENVENIDO',

                          textAlign:
                              TextAlign
                                  .center,

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

                        const Text(
                          'Iniciar sesión',

                          textAlign:
                              TextAlign
                                  .center,

                          style:
                              TextStyle(
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
                          'Ingresa a tu cuenta de GymFlow',

                          textAlign:
                              TextAlign
                                  .center,

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
                              32,
                        ),

                        const Text(
                          'Correo electrónico',

                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF3C362F,
                            ),

                            fontSize:
                                13,

                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        TextFormField(
                          controller:
                              correoController,

                          keyboardType:
                              TextInputType
                                  .emailAddress,

                          textInputAction:
                              TextInputAction
                                  .next,

                          style:
                              const TextStyle(
                            color:
                                textPrimary,

                            fontSize:
                                14,
                          ),

                          decoration:
                              const InputDecoration(
                            hintText:
                                'correo@ejemplo.com',

                            prefixIcon:
                                Icon(
                              Icons
                                  .email_outlined,
                            ),
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
                          height:
                              20,
                        ),

                        const Text(
                          'Contraseña',

                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF3C362F,
                            ),

                            fontSize:
                                13,

                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        TextFormField(
                          controller:
                              passwordController,

                          obscureText:
                              ocultarPassword,

                          textInputAction:
                              TextInputAction
                                  .done,

                          onFieldSubmitted:
                              (_) {
                            if (!cargando) {
                              iniciarSesion();
                            }
                          },

                          style:
                              const TextStyle(
                            color:
                                textPrimary,

                            fontSize:
                                14,
                          ),

                          decoration:
                              InputDecoration(
                            hintText:
                                'Ingresa tu contraseña',

                            prefixIcon:
                                const Icon(
                              Icons
                                  .lock_outline,
                            ),

                            suffixIcon:
                                IconButton(
                              tooltip:
                                  ocultarPassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',

                              onPressed:
                                  () {
                                setState(
                                  () {
                                    ocultarPassword =
                                        !ocultarPassword;
                                  },
                                );
                              },

                              icon: Icon(
                                ocultarPassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),

                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value
                                    .isEmpty) {
                              return 'Ingresa tu contraseña.';
                            }

                            if (value
                                    .length <
                                6) {
                              return 'La contraseña debe tener al menos 6 caracteres.';
                            }

                            return null;
                          },
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
                              ElevatedButton(
                            onPressed:
                                cargando
                                    ? null
                                    : iniciarSesion,

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  gold,

                              foregroundColor:
                                  surface,

                              disabledBackgroundColor:
                                  const Color(
                                0xFFD8C89F,
                              ),

                              disabledForegroundColor:
                                  surface,

                              elevation:
                                  0,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  13,
                                ),
                              ),
                            ),

                            child:
                                cargando
                                    ? const SizedBox(
                                        width:
                                            22,

                                        height:
                                            22,

                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,

                                          color:
                                              surface,
                                        ),
                                      )
                                    : const Text(
                                        'Iniciar sesión',

                                        style:
                                            TextStyle(
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
                              26,
                        ),

                        const Row(
                          children: [
                            Expanded(
                              child:
                                  Divider(
                                color:
                                    border,
                              ),
                            ),

                            Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                horizontal:
                                    14,
                              ),

                              child:
                                  Text(
                                'o',

                                style:
                                    TextStyle(
                                  color:
                                      textSecondary,

                                  fontSize:
                                      13,
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                                  Divider(
                                color:
                                    border,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              24,
                        ),

                        GoogleLoginButton(
                          onToken:
                              iniciarSesionGoogle,

                          onError:
                              mostrarMensaje,
                        ),

                        const SizedBox(
                          height:
                              22,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF8F4EC,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFE8DDC8,
                              ),
                            ),
                          ),

                          child:
                              const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Icon(
                                Icons
                                    .info_outline_rounded,

                                size:
                                    19,

                                color:
                                    goldDark,
                              ),

                              SizedBox(
                                width:
                                    10,
                              ),

                              Expanded(
                                child:
                                    Text(
                                  'Para iniciar sesión con Google, tu correo debe haber sido registrado previamente por recepción.',

                                  style:
                                      TextStyle(
                                    color:
                                        textSecondary,

                                    fontSize:
                                        12,

                                    height:
                                        1.45,
                                  ),
                                ),
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
        ),
      ),
    );
  }
}