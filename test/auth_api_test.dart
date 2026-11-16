import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/auth/data/auth_repository.dart';

void main() {
  test('envía el contrato del login y obtiene el JWT por HTTP', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requestResult = server.first.then((request) async {
      final json = jsonDecode(await utf8.decoder.bind(request).join());
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'datos': {
            'token': 'token-de-prueba',
            'expiraEn': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 5))
                .toIso8601String(),
          },
        }),
      );
      await request.response.close();
      return (request.method, request.uri.path, json);
    });

    final base = Uri.parse('http://127.0.0.1:${server.port}');
    final result = await AuthRepository(ApiClient(base))
        .signIn('usuario@example.com', 'clave privada');
    expect(result.token, 'token-de-prueba');
    final (method, path, json) = await requestResult;
    expect(method, 'POST');
    expect(path, '/auth/login');
    expect(json, {
      'correo': 'usuario@example.com',
      'contrasena': 'clave privada',
    });
  });
}
