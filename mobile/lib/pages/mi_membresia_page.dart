import 'package:flutter/material.dart';

import 'mis_pagos_page.dart';

class MiMembresiaPage extends StatelessWidget {
  const MiMembresiaPage({super.key});

  static const fondo = Color(0xFFF8F5EF);
  static const superficie = Color(0xFFFFFDF8);
  static const doradoOscuro = Color(0xFF8A6814);
  static const texto = Color(0xFF2F2A24);
  static const secundario = Color(0xFF777067);
  static const borde = Color(0xFFE5DDCF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Mi Membresía'),
        backgroundColor: superficie,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GYMFLOW / CLIENTE',
                  style: TextStyle(
                    color: doradoOscuro,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu membresía',
                  style: TextStyle(
                    color: texto,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: superficie,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                    side: const BorderSide(color: borde),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.card_membership_outlined,
                          color: doradoOscuro,
                          size: 40,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Información de membresía',
                          style: TextStyle(
                            color: texto,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Cuando Backend publique la consulta '
                          'protegida para el cliente, aquí '
                          'mostraremos el plan contratado, '
                          'su estado y las fechas de vigencia.',
                          style: TextStyle(color: secundario, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Consulta pendiente de integración.',
                          style: TextStyle(color: doradoOscuro, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MisPagosPage()),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Consultar mis pagos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
