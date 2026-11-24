import 'package:flutter/material.dart';

import '../controllers/registration_form_controller.dart';
import '../widgets/registration_fields.dart';

class AddressStep extends StatelessWidget {
  const AddressStep({super.key, required this.form});

  final RegistrationFormController form;

  static const _states = [
    'Aguascalientes',
    'Baja California',
    'Baja California Sur',
    'Campeche',
    'Chiapas',
    'Chihuahua',
    'Ciudad de México',
    'Coahuila',
    'Colima',
    'Durango',
    'Estado de México',
    'Guanajuato',
    'Guerrero',
    'Hidalgo',
    'Jalisco',
    'Michoacán',
    'Morelos',
    'Nayarit',
    'Nuevo León',
    'Oaxaca',
    'Puebla',
    'Querétaro',
    'Quintana Roo',
    'San Luis Potosí',
    'Sinaloa',
    'Sonora',
    'Tabasco',
    'Tamaulipas',
    'Tlaxcala',
    'Veracruz',
    'Yucatán',
    'Zacatecas',
  ];

  @override
  Widget build(BuildContext context) => RegistrationFieldList(
    children: [
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.street,
        label: 'Calle',
        hint: 'Nombre de la calle',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.streetAddressLine1],
      ),
      RegistrationFieldPair(
        firstFlex: 4,
        secondFlex: 6,
        first: RegistrationTextField(
          inlineLabel: true,
          form: form,
          field: RegistrationField.exteriorNumber,
          label: 'Número exterior',
          hint: 'Núm.',
        ),
        second: RegistrationTextField(
          inlineLabel: true,
          form: form,
          field: RegistrationField.interiorNumber,
          label: 'Número interior (opcional)',
          hint: 'Núm.',
        ),
      ),
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.neighborhood,
        label: 'Colonia',
        hint: 'Tu colonia',
        capitalization: TextCapitalization.words,
      ),
      RegistrationTextField(
        inlineLabel: true,
        form: form,
        field: RegistrationField.municipality,
        label: 'Municipio o alcaldía',
        hint: 'Tu municipio o alcaldía',
        capitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.addressCity],
      ),
      RegistrationSelect(
        inlineLabel: true,
        form: form,
        field: RegistrationField.state,
        label: 'Estado',
        options: _states,
      ),
      RegistrationFieldPair(
        firstFlex: 4,
        secondFlex: 6,
        first: RegistrationTextField(
          inlineLabel: true,
          form: form,
          field: RegistrationField.postalCode,
          label: 'Código postal',
          hint: '5 dígitos',
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.postalCode],
        ),
        second: RegistrationTextField(
          inlineLabel: true,
          form: form,
          field: RegistrationField.country,
          label: 'País',
          capitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.countryName],
        ),
      ),
    ],
  );
}
