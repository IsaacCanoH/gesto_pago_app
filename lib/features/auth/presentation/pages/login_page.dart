import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_session.dart';
import '../view_models/login_view_model.dart';
import '../widgets/auth_page_layout.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.repository,
    required this.onSignedIn,
  });
  final AuthRepository repository;
  final ValueChanged<AuthSession> onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  late final model = LoginViewModel(widget.repository);
  bool showPassword = false;

  static final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!emailPattern.hasMatch(text)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  Future<void> submit() async {
    if (model.busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final submittedEmail = email.text.trim();
    final session = await model.signIn(submittedEmail, password.text);
    if (mounted && session != null) {
      widget.onSignedIn(session);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthPageLayout(
    showBrandName: true,
    title: 'Bienvenido',
    subtitle: 'Inicia sesión para continuar',
    child: ListenableBuilder(
      listenable: model,
      builder: (context, child) => AutofillGroup(
        child: Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: email,
                enabled: !model.busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                errorBuilder: (context, error) => FieldError(error),
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                enabled: !model.busy,
                obscureText: !showPassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: showPassword
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: model.busy
                        ? null
                        : () => setState(() => showPassword = !showPassword),
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                errorBuilder: (context, error) => FieldError(error),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Ingresa tu contraseña.'
                    : null,
              ),
              if (model.error != null) FieldError(model.error!),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: model.busy ? null : submit,
                child: model.busy
                    ? Semantics(
                        liveRegion: true,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Iniciando sesión…'),
                          ],
                        ),
                      )
                    : const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('¿No tienes una cuenta?'),
                  TextButton(
                    onPressed: model.busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                    child: const Text('Regístrate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
