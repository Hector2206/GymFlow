import 'package:flutter/material.dart';

class MiCodigoPage extends StatelessWidget {
  const MiCodigoPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const coal = Color(0xFF1A1A1D);
    const silver = Color(0xFFA9A9A9);
    const dark = Color(0xFF101012);

    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 14,
            top: 6,
            bottom: 6,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: gold.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                color: gold,
              ),
            ),
          ),
        ),
        title: Image.asset(
          'assets/Logo_GymFlow.png',
          height: 48,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: gold.withValues(
              alpha: 0.30,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF29292E),
              coal,
              Color(0xFF0D0D0F),
            ],
            stops: [
              0.0,
              0.35,
              1.0,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              36,
              20,
              50,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 650,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLIENTE',
                      style: TextStyle(
                        color: gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      'Mi Código de Acceso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      'Presenta este código en recepción para registrar tu entrada.',
                      style: TextStyle(
                        color: silver,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        24,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1D1D20),
                            Color(0xFF151517),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: gold.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        height: 180,
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
