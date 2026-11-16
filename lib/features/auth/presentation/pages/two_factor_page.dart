import 'package:flutter/material.dart';

import '../../../../core/ui/code_input.dart';
import '../widgets/auth_page_layout.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({super.key});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final code = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: AuthPageLayout(
      title: 'Verificación en dos pasos',
      subtitle: 'Ingresa tu código privado de seis dígitos.',
      showBrandName: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CodeInput(controller: code, label: 'Código privado'),
          const SizedBox(height: 24),
          const FilledButton(onPressed: null, child: Text('Verificar código')),
          const TextButton(onPressed: null, child: Text('Reenviar código')),
        ],
      ),
    ),
  );
}
