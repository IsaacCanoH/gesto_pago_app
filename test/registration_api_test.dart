import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/registration/data/models/client_registration_request.dart';
import 'package:gesto_pago_app/features/registration/data/registration_repository.dart';
import 'package:gesto_pago_app/features/registration/domain/models/registration_field.dart';

import 'support/registration_fixtures.dart';

void main() {
  late HttpServer server;
  late RegistrationRepository repository;
  late int status;
  var holdResponse = false;
  late Object response;
  late List<Map<String, dynamic>> requests;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    repository = RegistrationRepository(
      ApiClient(Uri.parse('http://127.0.0.1:${server.port}/api/')),
    );
    status = 201;
    holdResponse = false;
    response = {
      'codigo': 0,
      'datos': {
        'clienteId': 42,
        'numeroCuenta': '00000000000000000724',
        'saldoInicial': 0.0,
      },
    };
    requests = [];
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/clientes');
      expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
      expect(request.headers.contentType?.mimeType, 'application/json');
      requests.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>,
      );
      if (holdResponse) return;
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  test(
    'registra por HTTP sin JWT y acepta la respuesta 201 con datos reales',
    () async {
      final result = await repository.register(
        ClientRegistrationRequest(validRegistration()),
      );
      expect(requests, hasLength(1));
      expect(
        requests.single,
        ClientRegistrationRequest(validRegistration()).toJson(),
      );
      expect(result.id, 42);
      expect(result.accountEnding, '0724');
      expect(result.money, '\$0.00 MXN');
    },
  );

  test(
    'recupera los errores por campo de la API, incluidos los del domicilio',
    () async {
      status = 400;
      response = {
        'codigo': 1,
        'mensaje': 'Datos no válidos',
        'errores': {
          'correo': 'debe tener un formato válido',
          'domicilio.codigoPostal': 'debe tener exactamente 5 dígitos',
        },
      };
      await expectLater(
        repository.register(ClientRegistrationRequest(validRegistration())),
        throwsA(
          isA<RegistrationFailure>()
              .having(
                (failure) => failure.fields.keys,
                'campos',
                containsAll([
                  RegistrationField.email,
                  RegistrationField.postalCode,
                ]),
              )
              .having(
                (failure) => failure.uncertain,
                'resultado conocido',
                isFalse,
              ),
        ),
      );
      expect(requests, hasLength(1));
    },
  );

  for (final conflict in {
    'La CURP ya está registrada': RegistrationField.curp,
    'El RFC ya está registrado': RegistrationField.rfc,
    'El correo ya está registrado': RegistrationField.email,
  }.entries) {
    test(
      'asocia el conflicto de ${conflict.value.name} con su campo',
      () async {
        status = 409;
        response = {'codigo': 1, 'mensaje': conflict.key};
        await expectLater(
          repository.register(ClientRegistrationRequest(validRegistration())),
          throwsA(
            isA<RegistrationFailure>().having(
              (failure) => failure.fields[conflict.value],
              'mensaje',
              conflict.key,
            ),
          ),
        );
        expect(requests, hasLength(1));
      },
    );
  }

  test('no confirma éxito ni reintenta si la respuesta del registro está incompleta', () async {
    response = {
      'codigo': 0,
      'datos': {'clienteId': 42},
    };
    await expectLater(
      repository.register(ClientRegistrationRequest(validRegistration())),
      throwsA(
        isA<RegistrationFailure>().having(
          (failure) => failure.uncertain,
          'resultado incierto',
          isTrue,
        ),
      ),
    );
    expect(requests, hasLength(1));
  });

  test(
    'no muestra detalles internos del servidor ni repite solicitudes fallidas',
    () async {
      status = 500;
      response = {'codigo': 1, 'mensaje': 'SQL interno privado'};
      await expectLater(
        repository.register(ClientRegistrationRequest(validRegistration())),
        throwsA(
          isA<RegistrationFailure>()
              .having(
                (failure) => failure.uncertain,
                'resultado incierto',
                isTrue,
              )
              .having(
                (failure) => failure.message,
                'mensaje seguro',
                isNot(contains('SQL')),
              ),
        ),
      );
      expect(requests, hasLength(1));
    },
  );

  test('muestra el límite de solicitudes sin cambiarlo por un error de credenciales', () async {
    status = 429;
    response = {'codigo': 1, 'mensaje': 'Límite'};
    await expectLater(
      repository.register(ClientRegistrationRequest(validRegistration())),
      throwsA(
        isA<RegistrationFailure>()
            .having((failure) => failure.message, 'mensaje', contains('Espera'))
            .having(
              (failure) => failure.uncertain,
              'resultado conocido',
              isFalse,
            ),
      ),
    );
  });
  test('no reintenta un POST que vence después de enviarse', () async {
    holdResponse = true;
    final short = RegistrationRepository(
      _ShortTimeoutClient(repository.client.baseUrl),
    );
    await expectLater(
      short.register(ClientRegistrationRequest(validRegistration())),
      throwsA(
        isA<RegistrationFailure>().having(
          (failure) => failure.uncertain,
          'resultado incierto',
          isTrue,
        ),
      ),
    );
    expect(requests, hasLength(1));
  });

  test('trata una respuesta JSON inesperada como resultado incierto', () async {
    response = 'contenido inesperado';
    await expectLater(
      repository.register(ClientRegistrationRequest(validRegistration())),
      throwsA(
        isA<RegistrationFailure>().having(
          (failure) => failure.uncertain,
          'resultado incierto',
          isTrue,
        ),
      ),
    );
    expect(requests, hasLength(1));
  });
}

class _ShortTimeoutClient extends ApiClient {
  const _ShortTimeoutClient(super.baseUrl);

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) => super.post(
    path,
    body,
    token: token,
    timeout: const Duration(milliseconds: 500),
  );
}
