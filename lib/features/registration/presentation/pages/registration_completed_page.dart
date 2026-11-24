import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../widgets/registration_layout.dart';

class RegistrationCompletedPage extends StatelessWidget {
  const RegistrationCompletedPage({
    super.key,
    required this.accountEnding,
    required this.initialBalance,
    required this.onSignIn,
  });

  final String accountEnding;
  final String initialBalance;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => RegistrationLayout(
    footer: FilledButton(
      onPressed: onSignIn,
      child: const Text('Iniciar sesión'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 36),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFD9F2E4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: success),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: const PageHeading(
            'Registro completado',
            subtitle: 'Tu cuenta de Gesto Pago está lista.',
          ),
        ),
        const SizedBox(height: 32),
        Surface(
          child: Column(
            children: [
              ReceiptRow('Cuenta de cargo', '•••• $accountEnding'),
              const Divider(),
              ReceiptRow('Saldo inicial', initialBalance),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Inicia sesión con tu correo y contraseña.',
          style: TextStyle(color: muted, fontSize: 16, height: 1.5),
        ),
      ],
    ),
  );
}
