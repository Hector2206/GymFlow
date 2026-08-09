import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GymFlowApp());
}

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GymFlow',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String estadoBackend = '⚪ Sin verificar';
  String estadoBaseDatos = '⚪ Sin verificar';

  Future<void> verificarConexion() async {
    try {
      final health = await http.get(
        Uri.parse('https://projectgym-t958.onrender.com/health'),
      );

      final ping = await http.get(
        Uri.parse('https://projectgym-t958.onrender.com/ping'),
      );

      setState(() {
        estadoBackend =
            health.statusCode == 200 ? '🟢 Conectado' : '🔴 Error';

        estadoBaseDatos =
            ping.statusCode == 200 ? '🟢 Conectada' : '🔴 Error';
      });
    } catch (e) {
      setState(() {
        estadoBackend = '🔴 Sin conexión';
        estadoBaseDatos = '🔴 Sin conexión';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GYMFLOW',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Estado del sistema',
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: verificarConexion,
              child: const Text('Verificar conexión'),
            ),

            const SizedBox(height: 30),

            Text(
              'Backend: $estadoBackend',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              'Base de datos: $estadoBaseDatos',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}