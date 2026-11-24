import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../data/registration_repository.dart';
import '../controllers/registration_form_controller.dart';
import '../models/registration_step.dart';
import '../steps/address_step.dart';
import '../steps/contact_step.dart';
import '../steps/employment_step.dart';
import '../steps/identity_step.dart';
import '../steps/personal_data_step.dart';
import '../steps/review_step.dart';
import '../steps/security_step.dart';
import '../view_models/registration_view_model.dart';
import '../widgets/registration_layout.dart';
import 'registration_completed_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.repository});

  final RegistrationRepository repository;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = RegistrationFormController();
  final _scroll = ScrollController();
  late final _model = RegistrationViewModel(widget.repository);
  late final _changes = Listenable.merge([_form, _model]);
  RegistrationStep _step = RegistrationStep.personal;
  bool _editing = false;

  void _showStep(RegistrationStep step) {
    FocusScope.of(context).unfocus();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _step = step);
  }

  void _revealError(Iterable<RegistrationField> fields) {
    final field = _form.firstError(fields);
    if (field == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _form.key(field).currentContext;
      if (target == null) return;
      _form.focusNode(field).requestFocus();
      Scrollable.ensureVisible(
        target,
        alignment: 0.2,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _back() {
    if (_model.busy) return;
    _model.clearFailure();
    if (_editing) {
      _editing = false;
      _showStep(RegistrationStep.review);
    } else if (_step.index > 0) {
      _showStep(RegistrationStep.values[_step.index - 1]);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _continue() {
    if (_model.busy) return;
    if (!_form.validate(_step.fields)) {
      _revealError(_step.fields);
      return;
    }
    _model.clearFailure();
    if (_editing) {
      _editing = false;
      _showStep(RegistrationStep.review);
    } else if (_step != RegistrationStep.review) {
      _showStep(RegistrationStep.values[_step.index + 1]);
    }
  }

  void _edit(RegistrationStep step) {
    if (_model.busy) return;
    _model.clearFailure();
    _editing = true;
    _showStep(step);
  }

  Future<void> _submit() async {
    if (_model.busy || _model.result != null) return;
    if (!_form.validate(RegistrationField.values)) {
      final field = _form.firstError(RegistrationField.values)!;
      _editing = false;
      _showStep(RegistrationStep.forField(field));
      _revealError([field]);
      return;
    }
    FocusScope.of(context).unfocus();
    await _model.submit(_form.request);
    if (!mounted) return;
    if (_model.result != null) {
      _form.clearSecrets();
    } else if (_model.failure case final failure?
        when failure.fields.isNotEmpty) {
      _form.applyServerErrors(failure.fields);
      final field = _form.firstError(RegistrationField.values)!;
      _editing = true;
      _showStep(RegistrationStep.forField(field));
      _revealError([field]);
    }
  }

  void _signIn() =>
      Navigator.of(context).pop<String>(_form.text(RegistrationField.email));

  @override
  void dispose() {
    _form.dispose();
    _model.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _changes,
    builder: (context, child) {
      if (_model.result case final registered?) {
        return RegistrationCompletedPage(
          accountEnding: registered.accountEnding,
          initialBalance: registered.money,
          onSignIn: _signIn,
        );
      }
      final reviewing = _step == RegistrationStep.review;
      return PopScope(
        canPop: !_model.busy && _step == RegistrationStep.personal && !_editing,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: RegistrationLayout(
          onBack: _back,
          canGoBack: !_model.busy,
          scrollController: _scroll,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _model.busy
                    ? null
                    : reviewing
                    ? _submit
                    : _continue,
                child: _model.busy
                    ? const _RegistrationProgressLabel()
                    : Text(
                        reviewing
                            ? 'Crear mi cuenta'
                            : _editing
                            ? 'Volver al resumen'
                            : 'Continuar',
                      ),
              ),
              if (_model.failure?.uncertain ?? false)
                TextButton(
                  onPressed: _signIn,
                  child: const Text('Ir a iniciar sesión'),
                ),
            ],
          ),
          child: ExcludeFocus(
            excluding: _model.busy,
            child: AbsorbPointer(
              absorbing: _model.busy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegistrationProgress(
                    index: _step.index,
                    total: RegistrationStep.values.length,
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: PageHeading(_step.title, subtitle: _step.subtitle),
                  ),
                  if (_model.failure case final failure?) ...[
                    const SizedBox(height: 12),
                    FieldError(failure.message),
                  ],
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    layoutBuilder: (currentChild, previousChildren) =>
                        currentChild ?? const SizedBox.shrink(),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        RegistrationStep.personal => PersonalDataStep(
                          form: _form,
                        ),
                        RegistrationStep.identity => IdentityStep(form: _form),
                        RegistrationStep.contact => ContactStep(form: _form),
                        RegistrationStep.address => AddressStep(form: _form),
                        RegistrationStep.employment => EmploymentStep(
                          form: _form,
                        ),
                        RegistrationStep.security => SecurityStep(form: _form),
                        RegistrationStep.review => ReviewStep(
                          form: _form,
                          onEdit: _edit,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RegistrationProgressLabel extends StatelessWidget {
  const _RegistrationProgressLabel();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Flexible(child: Text('Creando cuenta…')),
      ],
    ),
  );
}
