import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/login_page.dart';

void main() => runApp(const GestoPagoApp());

class GestoPagoApp extends StatelessWidget {
  const GestoPagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesto Pago',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8764C1)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
