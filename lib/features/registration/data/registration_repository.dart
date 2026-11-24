import '../../../core/network/api_client.dart';
import '../domain/models/registration_field.dart';
import 'models/client_registration_request.dart';
import 'models/registered_client.dart';

class RegistrationFailure implements Exception {
  const RegistrationFailure(
    this.message, {
    this.fields = const {},
    this.uncertain = false,
  });

  const RegistrationFailure.unknown()
    : this(
        'No pudimos confirmar el registro. Intenta iniciar sesión con tu '
        'correo antes de volver a registrarte.',
        uncertain: true,
      );

  final String message;
  final Map<RegistrationField, String> fields;
  final bool uncertain;
}

class RegistrationRepository {
  const RegistrationRepository(this.client);

  final ApiClient client;

  Future<RegisteredClient> register(ClientRegistrationRequest request) async {
    try {
      final response = await client.post('clientes', request.toJson());
      if (response['codigo'] != 0) {
        throw const RegistrationFailure.unknown();
      }
      return RegisteredClient.fromJson(response['datos']);
    } on ApiException catch (failure) {
      throw _mapFailure(failure);
    } on FormatException {
      throw const RegistrationFailure.unknown();
    }
  }

  RegistrationFailure _mapFailure(ApiException failure) {
    final fields = <RegistrationField, String>{};
    if (failure.statusCode == 400) {
      for (final entry in failure.fieldErrors.entries) {
        final field = RegistrationField.fromApiName(entry.key);
        if (field != null) fields[field] = '${field.label}: ${entry.value}';
      }
    }
    final conflict = switch ((failure.statusCode, failure.serverMessage)) {
      (409, 'La CURP ya está registrada') => RegistrationField.curp,
      (409, 'El RFC ya está registrado') => RegistrationField.rfc,
      (409, 'El correo ya está registrado') => RegistrationField.email,
      (400, 'El cliente debe ser mayor de edad') => RegistrationField.birthDate,
      (400, final String message)
          when message.startsWith('La contraseña debe') =>
        RegistrationField.password,
      _ => null,
    };
    if (conflict != null) fields[conflict] = failure.serverMessage!;
    if (fields.isNotEmpty) {
      return RegistrationFailure(
        'Revisa los datos indicados para continuar.',
        fields: Map.unmodifiable(fields),
      );
    }
    if (failure.outcomeUnknown ||
        (failure.statusCode != null && failure.statusCode! >= 500)) {
      return const RegistrationFailure.unknown();
    }
    return RegistrationFailure(switch (failure.statusCode) {
      400 => 'Revisa tus datos. La API no pudo completar el registro.',
      409 => 'Ya existe un registro con estos datos. Revisa tu información.',
      401 ||
      403 => 'El servicio de registro no está disponible. Intenta más tarde.',
      429 => 'Espera un momento antes de volver a registrarte.',
      null => failure.message,
      _ => 'No pudimos completar el registro. Intenta más tarde.',
    });
  }
}
