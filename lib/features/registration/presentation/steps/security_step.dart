import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../../../core/ui/code_input.dart';
import '../controllers/registration_form_controller.dart';
import '../widgets/registration_fields.dart';

class SecurityStep extends StatelessWidget {
  const SecurityStep({super.key, required this.form});

  final RegistrationFormController form;

  @override
  Widget build(BuildContext context) => RegistrationFieldList(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(
            form: form,
            field: RegistrationField.password,
            label: 'Contraseña',
          ),
          const RegistrationHelp(
            'Al menos 8 caracteres, con mayúscula, minúscula, número y símbolo.',
          ),
        ],
      ),
      _PasswordField(
        form: form,
        field: RegistrationField.passwordConfirmation,
        label: 'Confirmar contraseña',
      ),
      _PinField(
        form: form,
        field: RegistrationField.pin,
        label: 'PIN de compras',
        help: 'Usarás estos seis dígitos para autorizar pagos.',
      ),
      _PinField(
        form: form,
        field: RegistrationField.pinConfirmation,
        label: 'Confirmar PIN',
      ),
    ],
  );
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.form,
    required this.field,
    required this.label,
  });

  final RegistrationFormController form;
  final RegistrationField field;
  final String label;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => RegistrationTextField(
    form: widget.form,
    field: widget.field,
    label: widget.label,
    obscureText: !_visible,
    autofillHints: const [AutofillHints.newPassword],
    suffix: IconButton(
      tooltip: _visible
          ? 'Ocultar ${widget.label.toLowerCase()}'
          : 'Mostrar ${widget.label.toLowerCase()}',
      onPressed: () => setState(() => _visible = !_visible),
      icon: Icon(
        _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: action,
      ),
    ),
  );
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.form,
    required this.field,
    required this.label,
    this.help,
  });

  final RegistrationFormController form;
  final RegistrationField field;
  final String label;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final error = form.error(field);
    return Column(
      key: form.key(field),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CodeInput(
          controller: form[field],
          focusNode: form.focusNode(field),
          label: label,
          secret: true,
          hasError: error != null,
        ),
        if (error != null) FieldError(error),
        if (help case final message?) RegistrationHelp(message),
      ],
    );
  }
}
