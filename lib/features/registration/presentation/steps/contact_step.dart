import 'package:flutter/material.dart';

import '../controllers/registration_form_controller.dart';
import '../widgets/registration_fields.dart';

class ContactStep extends StatelessWidget {
  const ContactStep({super.key, required this.form});

  final RegistrationFormController form;

  @override
  Widget build(BuildContext context) => RegistrationFieldList(
    children: [
      RegistrationTextField(
        form: form,
        field: RegistrationField.email,
        label: 'Correo electrónico',
        hint: 'tu.correo@example.com',
        keyboardType: TextInputType.emailAddress,
        icon: Icons.mail_outline_rounded,
        autofillHints: const [AutofillHints.email],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegistrationTextField(
            form: form,
            field: RegistrationField.mobilePhone,
            label: 'Teléfono móvil',
            hint: '10 dígitos',
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
            autofillHints: const [AutofillHints.telephoneNumberNational],
          ),
          const RegistrationHelp('Ingresa el número sin espacios.'),
        ],
      ),
      RegistrationTextField(
        form: form,
        field: RegistrationField.alternatePhone,
        label: 'Teléfono alternativo (opcional)',
        hint: '10 dígitos',
        keyboardType: TextInputType.phone,
        icon: Icons.phone_outlined,
      ),
    ],
  );
}
