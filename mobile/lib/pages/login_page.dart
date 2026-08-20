import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      cargando = true;
    });

    final resultado = await AuthService.login(
      correo: correoController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      cargando = false;
    });

    if (resultado['ok'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['mensaje'] ??
                'No se pudo iniciar sesión',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO
                    Image.asset(
                      'assets/Logo_GymFlow.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 4),

                    // NOMBRE
                    const Text(
                      'GYMFLOW',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B2447),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // CORREO
                    TextFormField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode:
                          AutovalidateMode.onUserInteraction,

                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'correo@ejemplo.com',
                        prefixIcon: const Icon(
                          Icons.email,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Ingresa tu correo';
                        }

                        final correo = value.trim();

                        final correoValido = RegExp(
                          r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                        );

                        if (!correoValido.hasMatch(correo)) {
                          return 'Ingresa un correo válido';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // CONTRASEÑA
                    TextFormField(
                      controller: passwordController,
                      obscureText: ocultarPassword,
                      autovalidateMode:
                          AutovalidateMode.onUserInteraction,

                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(
                          Icons.lock,
                        ),

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              ocultarPassword =
                                  !ocultarPassword;
                            });
                          },
                        ),
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }

                        if (value.length < 6) {
                          return 'La contraseña debe tener mínimo 6 caracteres';
                        }

                        if (value.length > 30) {
                          return 'La contraseña es demasiado larga';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // BOTÓN
                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton(
                        onPressed:
                            cargando ? null : iniciarSesion,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0B2447),
                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),

                        child: cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'GymFlow',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
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