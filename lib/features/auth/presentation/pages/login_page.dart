import 'package:flutter/material.dart';

import '../widgets/auth_page_layout.dart';
import '../widgets/auth_text_field.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Aquí se conectará la autenticación cuando esté disponible.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Bienvenido',
      subtitle: 'Inicia sesión para continuar',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthTextField(
              controller: _usernameController,
              label: 'Usuario',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8764C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text('Iniciar sesión'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿No tienes una cuenta?'),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('Regístrate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
