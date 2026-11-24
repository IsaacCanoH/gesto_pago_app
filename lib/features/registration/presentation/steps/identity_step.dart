import 'package:flutter/material.dart';

import '../controllers/registration_form_controller.dart';
import '../widgets/registration_fields.dart';

class IdentityStep extends StatelessWidget {
  const IdentityStep({super.key, required this.form});

  final RegistrationFormController form;

  @override
  Widget build(BuildContext context) => RegistrationFieldList(
    children: [
      RegistrationTextField(
        form: form,
        field: RegistrationField.curp,
        label: 'CURP',
        hint: '18 caracteres',
        capitalization: TextCapitalization.characters,
      ),
      RegistrationTextField(
        form: form,
        field: RegistrationField.rfc,
        label: 'RFC',
        hint: '13 caracteres',
        capitalization: TextCapitalization.characters,
      ),
      RegistrationTextField(
        form: form,
        field: RegistrationField.nationality,
        label: 'Nacionalidad',
        capitalization: TextCapitalization.words,
      ),
      RegistrationSelect(
        form: form,
        field: RegistrationField.maritalStatus,
        label: 'Estado civil',
        options: const [
          'Soltero/a',
          'Casado/a',
          'Unión libre',
          'Divorciado/a',
          'Viudo/a',
        ],
      ),
    ],
  );
}
