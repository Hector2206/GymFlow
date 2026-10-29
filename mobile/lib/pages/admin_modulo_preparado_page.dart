import 'package:flutter/material.dart';

class AdminFuncionPendiente {
  final String titulo;
  final String descripcion;
  final IconData icono;

  const AdminFuncionPendiente({
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });
}

class AdminModuloPreparadoPage extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final List<AdminFuncionPendiente> funciones;

  const AdminModuloPreparadoPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.funciones,
  });

  static const fondo = Color(0xFFF8F5EF);
  static const superficie = Color(0xFFFFFDF8);
  static const dorado = Color(0xFFB58A2A);
  static const doradoOscuro = Color(0xFF8A6814);
  static const texto = Color(0xFF2F2A24);
  static const secundario = Color(0xFF777067);
  static const borde = Color(0xFFE5DDCF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: superficie,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GYMFLOW / ADMINISTRACIÓN',
                  style: TextStyle(
                    color: doradoOscuro,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EAD8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icono, size: 30, color: doradoOscuro),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: texto,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitulo,
                  style: const TextStyle(color: secundario, fontSize: 14),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EAD8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4D2AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: doradoOscuro),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este módulo está preparado para '
                          'integrar los endpoints del Backend. '
                          'Por ahora no registra ni modifica datos.',
                          style: TextStyle(color: texto, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'FUNCIONALIDADES POR INTEGRAR',
                  style: TextStyle(
                    color: doradoOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final funcion in funciones)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: superficie,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: borde),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(funcion.icono, color: doradoOscuro),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  funcion.titulo,
                                  style: const TextStyle(
                                    color: texto,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  funcion.descripcion,
                                  style: const TextStyle(
                                    color: secundario,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Pendiente de endpoint',
                                  style: TextStyle(
                                    color: doradoOscuro,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
