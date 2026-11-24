import '../../domain/models/registration_field.dart';

enum RegistrationStep {
  personal(
    'Datos personales',
    'Escribe tus datos como aparecen en tu identificación.',
    [
      RegistrationField.name,
      RegistrationField.middleName,
      RegistrationField.paternalSurname,
      RegistrationField.maternalSurname,
      RegistrationField.birthDate,
      RegistrationField.sex,
    ],
  ),
  identity('Identificación', 'Completa tus datos de identificación.', [
    RegistrationField.curp,
    RegistrationField.rfc,
    RegistrationField.nationality,
    RegistrationField.maritalStatus,
  ]),
  contact(
    'Contacto',
    'Usaremos tu correo para verificar el inicio de sesión.',
    [
      RegistrationField.email,
      RegistrationField.mobilePhone,
      RegistrationField.alternatePhone,
    ],
  ),
  address('Dirección', 'Indica tu domicilio actual.', [
    RegistrationField.street,
    RegistrationField.exteriorNumber,
    RegistrationField.interiorNumber,
    RegistrationField.neighborhood,
    RegistrationField.municipality,
    RegistrationField.state,
    RegistrationField.postalCode,
    RegistrationField.country,
  ]),
  employment('Actividad económica', 'Completa tu información laboral.', [
    RegistrationField.occupation,
    RegistrationField.company,
    RegistrationField.monthlyIncome,
  ]),
  security('Seguridad', 'Crea tu contraseña y tu PIN de compras.', [
    RegistrationField.password,
    RegistrationField.passwordConfirmation,
    RegistrationField.pin,
    RegistrationField.pinConfirmation,
  ]),
  review(
    'Revisa tus datos',
    'Puedes editar cada sección antes de crear tu cuenta.',
    [],
  );

  const RegistrationStep(this.title, this.subtitle, this.fields);

  final String title;
  final String subtitle;
  final List<RegistrationField> fields;

  static RegistrationStep forField(RegistrationField field) =>
      values.firstWhere((step) => step.fields.contains(field));
}
