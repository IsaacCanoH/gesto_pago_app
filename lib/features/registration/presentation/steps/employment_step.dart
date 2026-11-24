import 'package:flutter/material.dart';

import '../controllers/registration_form_controller.dart';
import '../widgets/registration_fields.dart';

class EmploymentStep extends StatelessWidget {
  const EmploymentStep({super.key, required this.form});

  final RegistrationFormController form;

  @override
  Widget build(BuildContext context) => RegistrationFieldList(
    children: [
      RegistrationTextField(
        form: form,
        field: RegistrationField.occupation,
        label: 'Ocupación',
        hint: 'Tu ocupación',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.jobTitle],
      ),
      RegistrationTextField(
        form: form,
        field: RegistrationField.company,
        label: 'Empresa',
        hint: 'Nombre de la empresa',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.organizationName],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegistrationTextField(
            form: form,
            field: RegistrationField.monthlyIncome,
            label: 'Ingreso mensual',
            hint: '0.00',
            prefixText: '\$ ',
            suffixText: 'MXN',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const RegistrationHelp('Ingresa un importe mayor a cero.'),
        ],
      ),
    ],
  );
}
