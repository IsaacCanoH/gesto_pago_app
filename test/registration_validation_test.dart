import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/registration/data/models/client_registration_request.dart';
import 'package:gesto_pago_app/features/registration/data/models/registered_client.dart';

import 'package:gesto_pago_app/features/registration/domain/validation/registration_validator.dart';
import 'package:gesto_pago_app/features/registration/presentation/controllers/registration_form_controller.dart';

import 'support/registration_fixtures.dart';

void main() {
  final validator = RegistrationValidator(now: () => DateTime(2026, 11, 18));

  test(
    'acepta los datos completos y omite solo los campos opcionales vacíos',
    () {
      final values = validRegistration();
      for (final field in RegistrationField.values) {
        expect(validator.validate(field, values), isNull, reason: field.name);
        final empty = {...values, field: ''};
        expect(
          validator.validate(field, empty),
          field.optional ? isNull : isNotNull,
          reason: field.name,
        );
      }
    },
  );

  test('respeta fechas reales y el límite exacto de mayoría de edad', () {
    String? birth(String value) => validator.validate(
      RegistrationField.birthDate,
      {...validRegistration(), RegistrationField.birthDate: value},
    );
    expect(birth('18/11/2008'), isNull);
    expect(birth('19/11/2008'), 'Debes tener 18 años o más.');
    expect(birth('31/04/1998'), isNotNull);
    expect(birth('29/02/2007'), isNotNull);
    expect(birth('29/02/2008'), isNull);
    expect(birth('18/11/2026'), isNotNull);
    expect(birth('1998-11-15'), isNotNull);
    final leap = RegistrationValidator(now: () => DateTime(2044, 2, 29));
    expect(
      leap.validate(RegistrationField.birthDate, {
        ...validRegistration(),
        RegistrationField.birthDate: '01/03/2026',
      }),
      isNotNull,
    );
    expect(
      leap.validate(RegistrationField.birthDate, {
        ...validRegistration(),
        RegistrationField.birthDate: '28/02/2026',
      }),
      isNull,
    );
  });

  test('valida nombres, identificadores y formatos de contacto', () {
    final invalid = {
      RegistrationField.name: 'Ana1',
      RegistrationField.middleName: 'A',
      RegistrationField.paternalSurname: List.filled(51, 'a').join(),
      RegistrationField.maternalSurname: 'López!',
      RegistrationField.curp: 'LOHM981115XDFPRR01',
      RegistrationField.rfc: 'LOHM981115AB!',
      RegistrationField.email: 'mariana@correo',
      RegistrationField.mobilePhone: '551234567',
      RegistrationField.alternatePhone: '55 1234 5678',
      RegistrationField.postalCode: '0600A',
      RegistrationField.nationality: List.filled(61, 'a').join(),
      RegistrationField.maritalStatus: List.filled(21, 'a').join(),
      RegistrationField.street: List.filled(151, 'a').join(),
      RegistrationField.interiorNumber: List.filled(21, 'a').join(),
      RegistrationField.municipality: List.filled(101, 'a').join(),
    };
    for (final entry in invalid.entries) {
      expect(
        validator.validate(entry.key, {
          ...validRegistration(),
          entry.key: entry.value,
        }),
        isNotNull,
        reason: entry.key.name,
      );
    }
    expect(
      validator.validate(RegistrationField.name, {
        ...validRegistration(),
        RegistrationField.name: 'Ángela Ñandú',
      }),
      isNull,
    );
    expect(
      validator.validate(RegistrationField.curp, {
        ...validRegistration(),
        RegistrationField.curp: 'lohm981115mdfprr01',
      }),
      isNull,
    );
  });

  test('aplica la precisión y el importe mínimo de ingreso mensual', () {
    for (final value in [
      '0',
      '0.00',
      '-1',
      '1.001',
      '1,000.00',
      '1e3',
      'NaN',
      '10000000000000',
    ]) {
      expect(
        validator.validate(RegistrationField.monthlyIncome, {
          ...validRegistration(),
          RegistrationField.monthlyIncome: value,
        }),
        isNotNull,
        reason: value,
      );
    }
    for (final value in ['0.01', '18000,50', '9999999999999.99']) {
      expect(
        validator.validate(RegistrationField.monthlyIncome, {
          ...validRegistration(),
          RegistrationField.monthlyIncome: value,
        }),
        isNull,
        reason: value,
      );
    }
  });

  test(
    'respeta los 72 bytes UTF-8 y confirma contraseña y PIN sin recortarlos',
    () {
      final boundary = '${List.filled(34, 'Á').join()}aa1!';
      expect(
        validator.validate(RegistrationField.password, {
          ...validRegistration(),
          RegistrationField.password: boundary,
        }),
        isNull,
      );
      expect(
        validator.validate(RegistrationField.password, {
          ...validRegistration(),
          RegistrationField.password: '${boundary}a',
        }),
        isNotNull,
      );
      for (final password in [
        'Corta1!',
        'sindigitos!',
        'SINSIMBOLO1',
        'SinSimbolo1',
        'SinNumero!',
      ]) {
        expect(
          validator.validate(RegistrationField.password, {
            ...validRegistration(),
            RegistrationField.password: password,
          }),
          isNotNull,
          reason: password,
        );
      }
      expect(
        validator.validate(RegistrationField.passwordConfirmation, {
          ...validRegistration(),
          RegistrationField.passwordConfirmation: 'ClaveSegura1!',
        }),
        'Las contraseñas no coinciden.',
      );
      expect(
        validator.validate(RegistrationField.pinConfirmation, {
          ...validRegistration(),
          RegistrationField.pinConfirmation: '123456',
        }),
        'Los PIN no coinciden.',
      );
      expect(
        validator.validate(RegistrationField.pin, {
          ...validRegistration(),
          RegistrationField.pin: '01234a',
        }),
        isNotNull,
      );
    },
  );

  test('mapea el contrato sin confirmaciones y conserva una instantánea de los datos', () {
    final values = validRegistration()
      ..[RegistrationField.name] = ' Mariana '
      ..[RegistrationField.curp] = 'lohm981115mdfprr01'
      ..[RegistrationField.monthlyIncome] = '18000,50';
    final request = ClientRegistrationRequest(values);
    values[RegistrationField.name] = 'Otro nombre';
    expect(request.toJson(), {
      'nombre': 'Mariana',
      'apellidoPaterno': 'López',
      'apellidoMaterno': 'Herrera',
      'fechaNacimiento': '1998-11-15',
      'sexo': 'Mujer',
      'curp': 'LOHM981115MDFPRR01',
      'rfc': 'LOHM981115AB1',
      'nacionalidad': 'Mexicana',
      'estadoCivil': 'Soltero/a',
      'correo': 'mariana@example.com',
      'telefonoMovil': '5512345678',
      'ocupacion': 'Analista',
      'empresa': 'Servicios SA',
      'ingresoMensual': 18000.5,
      'contrasena': ' ClaveSegura1! ',
      'pin': '012345',
      'domicilio': {
        'calle': 'Reforma',
        'numeroExterior': '123',
        'colonia': 'Centro',
        'municipio': 'Cuauhtémoc',
        'estado': 'Ciudad de México',
        'codigoPostal': '06000',
        'pais': 'México',
      },
    });
    final withOptionals = ClientRegistrationRequest({
      ...validRegistration(),
      RegistrationField.middleName: ' Isabel ',
      RegistrationField.alternatePhone: '5512340000',
      RegistrationField.interiorNumber: ' 4B ',
    }).toJson();
    expect(withOptionals['segundoNombre'], 'Isabel');
    expect(withOptionals['telefonoAlternativo'], '5512340000');
    expect((withOptionals['domicilio'] as Map)['numeroInterior'], '4B');
  });

  test('rechaza confirmaciones incompletas y conserva solo la terminación de cuenta', () {
    final valid = {
      'clienteId': 42,
      'numeroCuenta': '00000000000000000724',
      'saldoInicial': 0,
    };
    final client = RegisteredClient.fromJson(valid);
    expect(client.accountEnding, '0724');
    expect(client.money, '\$0.00 MXN');
    for (final invalid in [
      null,
      {},
      {...valid, 'clienteId': 0},
      {...valid, 'numeroCuenta': '0724'},
      {...valid, 'saldoInicial': -1},
      {...valid, 'saldoInicial': double.nan},
    ]) {
      expect(() => RegisteredClient.fromJson(invalid), throwsFormatException);
    }
  });

  test('actualiza validaciones dependientes y errores del servidor al corregir datos', () {
    final form = RegistrationFormController(validator: validator);
    addTearDown(form.dispose);
    validRegistration().forEach((field, value) => form[field].text = value);
    expect(form.validate(RegistrationField.values), isTrue);
    form[RegistrationField.password].text = 'OtraClave1!';
    expect(form.error(RegistrationField.passwordConfirmation), isNotNull);
    form[RegistrationField.passwordConfirmation].text = 'OtraClave1!';
    expect(form.error(RegistrationField.passwordConfirmation), isNull);
    form.applyServerErrors({
      RegistrationField.email: 'El correo ya está registrado',
    });
    form[RegistrationField.email].selection = const TextSelection.collapsed(
      offset: 2,
    );
    expect(form.error(RegistrationField.email), 'El correo ya está registrado');
    expect(form.validate([RegistrationField.email]), isFalse);
    form[RegistrationField.email].text = 'nuevo@example.com';
    expect(form.error(RegistrationField.email), isNull);
    form.clearSecrets();
    for (final field in RegistrationField.values.where(
      (field) => field.secret,
    )) {
      expect(form[field].text, isEmpty);
    }
  });
}
