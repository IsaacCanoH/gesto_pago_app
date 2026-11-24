import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../controllers/registration_form_controller.dart';
import '../models/registration_step.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key, required this.form, required this.onEdit});

  final RegistrationFormController form;
  final ValueChanged<RegistrationStep> onEdit;

  String _summary(RegistrationStep step) => switch (step) {
    RegistrationStep.personal => form.joined([
      RegistrationField.name,
      RegistrationField.middleName,
      RegistrationField.paternalSurname,
      RegistrationField.maternalSurname,
    ]),
    RegistrationStep.identity =>
      form.text(RegistrationField.curp).isNotEmpty &&
              form.text(RegistrationField.rfc).isNotEmpty
          ? 'CURP y RFC capturados'
          : '',
    RegistrationStep.contact => form.text(RegistrationField.email),
    RegistrationStep.address => form.joined([
      RegistrationField.neighborhood,
      RegistrationField.state,
    ], separator: ', '),
    RegistrationStep.employment => form.joined([
      RegistrationField.occupation,
      RegistrationField.monthlyIncome,
    ], separator: ' · '),
    RegistrationStep.security =>
      form.text(RegistrationField.password).isNotEmpty &&
              form.text(RegistrationField.pin).isNotEmpty
          ? 'Contraseña y PIN capturados'
          : '',
    RegistrationStep.review => '',
  };

  @override
  Widget build(BuildContext context) {
    final sections = RegistrationStep.values
        .where((section) => section != RegistrationStep.review)
        .toList();
    return Surface(
      child: Column(
        children: [
          for (var index = 0; index < sections.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sections[index].title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _summary(sections[index]).isEmpty
                              ? 'Sin capturar'
                              : _summary(sections[index]),
                          style: const TextStyle(color: muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar ${sections[index].title.toLowerCase()}',
                    onPressed: () => onEdit(sections[index]),
                    icon: const Icon(Icons.edit_outlined, color: action),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
