import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/auth/data/auth_repository.dart';

void main() {
  test(
    'usa el nuevo identificador al verificar y obtiene el JWT por HTTP',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <(String, String, Object?)>[];
      final now = DateTime.now().toUtc();
      final expiry = now.add(const Duration(minutes: 5)).toIso8601String();
      final resendAt = now.add(const Duration(minutes: 1)).toIso8601String();
      final sessionExpiry = now.add(const Duration(days: 7)).toIso8601String();
      final subscription = server.listen((request) async {
        final json = jsonDecode(await utf8.decoder.bind(request).join());
        requests.add((request.method, request.uri.path, json));
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/auth/logout') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer token-renovado',
          );
        }
        final data = switch (request.uri.path) {
          '/auth/login' => {
            'idVerificacion': 'reto-inicial',
            'expiraEn': expiry,
            'reenviarDesde': resendAt,
          },
          '/auth/2fa/reenviar' => {
            'idVerificacion': 'reto-nuevo',
            'expiraEn': expiry,
            'reenviarDesde': resendAt,
          },
          '/auth/2fa/verificar' => {
            'token': 'token-de-prueba',
            'expiraEn': expiry,
            'refreshToken': 'refresh-inicial',
            'refreshExpiraEn': sessionExpiry,
          },
          '/auth/refresh' => {
            'token': 'token-renovado',
            'expiraEn': expiry,
            'refreshToken': 'refresh-nuevo',
            'refreshExpiraEn': sessionExpiry,
          },
          '/auth/logout' => null,
          _ => throw StateError('Ruta inesperada'),
        };
        request.response.write(jsonEncode({'codigo': 0, 'datos': data}));
        await request.response.close();
      });
      addTearDown(subscription.cancel);

      final base = Uri.parse('http://127.0.0.1:${server.port}');
      final repository = AuthRepository(ApiClient(base));
      final first = await repository.signIn(
        'usuario@example.com',
        'clave privada',
      );
      expect(first.id, 'reto-inicial');
      expect(first.resendAt, DateTime.parse(resendAt));
      final resent = await repository.resend(first.id);
      final result = await repository.verify(resent.id, '012345');
      expect(result.token, 'token-de-prueba');
      final renewed = await repository.refresh(result.refreshToken!);
      expect(renewed.refreshToken, 'refresh-nuevo');
      await repository.signOut(renewed.token);
      expect(
        requests
            .map((request) => [request.$1, request.$2, request.$3])
            .toList(),
        [
          [
            'POST',
            '/auth/login',
            {'correo': 'usuario@example.com', 'contrasena': 'clave privada'},
          ],
          [
            'POST',
            '/auth/2fa/reenviar',
            {'idVerificacion': 'reto-inicial'},
          ],
          [
            'POST',
            '/auth/2fa/verificar',
            {'idVerificacion': 'reto-nuevo', 'codigo': '012345'},
          ],
          [
            'POST',
            '/auth/refresh',
            {'refreshToken': 'refresh-inicial'},
          ],
          ['POST', '/auth/logout', {}],
        ],
      );
    },
  );
}
