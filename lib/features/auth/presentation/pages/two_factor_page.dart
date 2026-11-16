import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../../../core/ui/code_input.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_challenge.dart';
import '../../data/models/auth_session.dart';
import '../view_models/two_factor_view_model.dart';
import '../widgets/auth_page_layout.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({
    required this.repository,
    required this.challenge,
    super.key,
  });

  final AuthRepository repository;
  final AuthChallenge challenge;

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  static const _codeLabel = 'Código de verificación';

  final code = TextEditingController();
  late final model = TwoFactorViewModel(widget.repository, widget.challenge);

  Future<void> _verify() async {
    if (!model.canVerify) return;
    FocusScope.of(context).unfocus();
    final session = await model.verify(code.text);
    if (session != null &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop<AuthSession>(session);
    }
  }

  Future<void> _resend() async {
    FocusScope.of(context).unfocus();
    if (await model.resend() && mounted) code.clear();
  }

  @override
  void dispose() {
    code.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthPageLayout(
    appBar: AppBar(forceMaterialTransparency: true),
    title: 'Verificación en dos pasos',
    subtitle: 'Ingresa el código de seis dígitos que enviamos a tu correo.',
    showBrandName: true,
    alignWithSignIn: true,
    child: ListenableBuilder(
      listenable: model,
      builder: (context, child) {
        final wait = model.resendWaitSeconds;
        final error = model.expired && !model.busy
            ? 'El código venció. Vuelve a iniciar sesión.'
            : model.error;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ExcludeSemantics(
              child: Text(
                _codeLabel,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            CodeInput(
              controller: code,
              label: _codeLabel,
              enabled: model.canVerify,
              autofillHints: const [AutofillHints.oneTimeCode],
              onChanged: (_) => model.clearError(),
              onSubmitted: (_) => _verify(),
            ),
            if (error != null) FieldError(error),
            if (model.notice case final notice? when error == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(notice, style: const TextStyle(color: success)),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: model.canVerify ? _verify : null,
              child: model.verifying
                  ? const _WorkingLabel('Verificando…')
                  : const Text('Verificar código'),
            ),
            const SizedBox(height: 8),
            if (model.needsNewLogin)
              TextButton(
                onPressed: model.busy
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Volver a iniciar sesión'),
              )
            else
              TextButton(
                onPressed: model.canResend ? _resend : null,
                child: model.resending
                    ? const _WorkingLabel('Enviando código…')
                    : Text(
                        wait == 0
                            ? 'Reenviar código'
                            : 'Reenviar código en ${_formatWait(wait)}',
                        textAlign: TextAlign.center,
                      ),
              ),
          ],
        );
      },
    ),
  );

  String _formatWait(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _WorkingLabel extends StatelessWidget {
  const _WorkingLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(label)),
      ],
    ),
  );
}
