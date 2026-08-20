import 'package:flutter/material.dart';
import 'pages/login_page.dart';

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
      home: const LoginPage(),
    );
  }
}