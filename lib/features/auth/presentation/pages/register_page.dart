import 'package:flutter/material.dart';

import '../widgets/auth_page_layout.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Aquí se conectará el registro cuando esté disponible.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Crear cuenta',
      subtitle: 'Completa tus datos para registrarte',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthTextField(
              controller: _nameController,
              label: 'Nombre',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
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
                child: const Text('Registrarme'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Ya tienes una cuenta?'),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Inicia sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
