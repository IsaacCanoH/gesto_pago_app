import 'package:flutter/material.dart';

import '../../domain/validation/registration_validator.dart';
import '../controllers/registration_form_controller.dart';
import '../widgets/registration_fields.dart';

class PersonalDataStep extends StatelessWidget {
  const PersonalDataStep({super.key, required this.form});

  final RegistrationFormController form;

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final selection = await showDatePicker(
      context: context,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      initialDate:
          RegistrationValidator.parseBirthDate(
            form.text(RegistrationField.birthDate),
          ) ??
          DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selection == null || !context.mounted) return;
    form[RegistrationField.birthDate].text =
        '${selection.day.toString().padLeft(2, '0')}/'
        '${selection.month.toString().padLeft(2, '0')}/${selection.year}';
  }

  @override
  Widget build(BuildContext context) => RegistrationFieldList(
    children: [
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.name,
        label: 'Nombre',
        hint: 'Tu nombre',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.givenName],
      ),
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.middleName,
        label: 'Segundo nombre (opcional)',
        hint: 'Segundo nombre',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.middleName],
      ),
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.paternalSurname,
        label: 'Apellido paterno',
        hint: 'Primer apellido',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.familyName],
      ),
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.maternalSurname,
        label: 'Apellido materno',
        hint: 'Segundo apellido',
        capitalization: TextCapitalization.words,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegistrationFieldPair(
            firstFlex: 3,
            secondFlex: 2,
            first: RegistrationTextField(
              inlineLabel: true,
              form: form,
              field: RegistrationField.birthDate,
              label: 'Fecha de nacimiento',
              hint: 'DD/MM/AAAA',
              readOnly: true,
              onTap: () => _pickBirthDate(context),
              suffix: const Icon(Icons.calendar_today_outlined, size: 20),
            ),
            second: RegistrationSelect(
              inlineLabel: true,
              form: form,
              field: RegistrationField.sex,
              label: 'Sexo',
              options: const ['Mujer', 'Hombre'],
            ),
          ),
          const RegistrationHelp('Debes tener 18 años o más.'),
        ],
      ),
    ],
  );
}
