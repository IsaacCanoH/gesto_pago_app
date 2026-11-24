enum RegistrationField {
  name('nombre', 'Nombre'),
  middleName('segundoNombre', 'Segundo nombre'),
  paternalSurname('apellidoPaterno', 'Apellido paterno'),
  maternalSurname('apellidoMaterno', 'Apellido materno'),
  birthDate('fechaNacimiento', 'Fecha de nacimiento'),
  sex('sexo', 'Sexo'),
  curp('curp', 'CURP'),
  rfc('rfc', 'RFC'),
  nationality('nacionalidad', 'Nacionalidad'),
  maritalStatus('estadoCivil', 'Estado civil'),
  email('correo', 'Correo electrónico'),
  mobilePhone('telefonoMovil', 'Teléfono móvil'),
  alternatePhone('telefonoAlternativo', 'Teléfono alternativo'),
  street('domicilio.calle', 'Calle'),
  exteriorNumber('domicilio.numeroExterior', 'Número exterior'),
  interiorNumber('domicilio.numeroInterior', 'Número interior'),
  neighborhood('domicilio.colonia', 'Colonia'),
  municipality('domicilio.municipio', 'Municipio o alcaldía'),
  state('domicilio.estado', 'Estado'),
  postalCode('domicilio.codigoPostal', 'Código postal'),
  country('domicilio.pais', 'País'),
  occupation('ocupacion', 'Ocupación'),
  company('empresa', 'Empresa'),
  monthlyIncome('ingresoMensual', 'Ingreso mensual'),
  password('contrasena', 'Contraseña'),
  passwordConfirmation(null, 'Confirmar contraseña'),
  pin('pin', 'PIN de compras'),
  pinConfirmation(null, 'Confirmar PIN');

  const RegistrationField(this.apiName, this.label);

  final String? apiName;
  final String label;

  bool get optional =>
      this == middleName || this == alternatePhone || this == interiorNumber;

  bool get secret =>
      this == password ||
      this == passwordConfirmation ||
      this == pin ||
      this == pinConfirmation;

  static RegistrationField? fromApiName(String name) {
    for (final field in values) {
      if (field.apiName == name) return field;
    }
    return null;
  }
}
