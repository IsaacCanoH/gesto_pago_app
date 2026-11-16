import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/purchases/data/models/purchase_draft.dart';
import 'package:gesto_pago_app/features/purchases/data/models/purchase_request.dart';
import 'package:gesto_pago_app/features/purchases/data/models/purchase_result.dart';
import 'package:gesto_pago_app/features/purchases/data/purchases_repository.dart';

const draft = PurchaseDraft(
  serviceId: 20,
  productId: 201,
  type: 2,
  serviceName: 'Proveedor',
  productName: 'Pago de prueba',
  reference: '000123',
  amountInCents: 999999999999999,
);
const accountId = 9;

void main() {
  test('envía el contrato autenticado y diferencia saldo insuficiente de un resultado incierto', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final bodies = <(String, String, String?, String)>[];
    final accountsRequest = Completer<(String, String?)>();
    server.listen((request) async {
      if (request.method == 'GET') {
        accountsRequest.complete((
          request.uri.path,
          request.headers.value('authorization'),
        ));
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'datos': [
              {'idCuenta': 9, 'ultimosDigitos': '0724'},
            ],
          }),
        );
        await request.response.close();
        return;
      }
      final body = await utf8.decoder.bind(request).join();
      bodies.add((
        request.method,
        request.uri.path,
        request.headers.value('authorization'),
        body,
      ));
      final (code, response) = switch (bodies.length) {
        1 => (200, {'estatus': 'PENDIENTE', 'upc': 'P12345678901234'}),
        2 => (
          409,
          {
            'codigo': 1,
            'mensaje': 'Saldo disponible insuficiente para realizar el pago',
          },
        ),
        _ => (502, {'codigo': 1, 'mensaje': 'Resultado incierto'}),
      };
      request.response.statusCode = code;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });

    final repository = PurchasesRepository(
      ApiClient(Uri.parse('http://127.0.0.1:${server.port}')),
    );
    final accounts = await repository.loadAccounts('jwt-de-prueba');
    expect(await accountsRequest.future, (
      '/cuentas/propias',
      'Bearer jwt-de-prueba',
    ));
    expect(accounts.single.id, accountId);
    expect(accounts.single.label, 'Cuenta •••• 0724');
    const request = PurchaseRequest(
      draft: draft,
      accountId: accountId,
      pin: '037651',
    );
    final result = await repository.submit('jwt-de-prueba', request);
    expect(result.status, PurchaseStatus.pending);
    expect(result.upc, 'P12345678901234');
    final (method, path, authorization, body) = bodies.single;
    expect(
      (method, path, authorization),
      ('POST', '/pagos', 'Bearer jwt-de-prueba'),
    );
    expect(jsonDecode(body), {
      'idCuenta': accountId,
      'idServicio': 20,
      'idProducto': 201,
      'tipoFront': 2,
      'montoPago': 9999999999999.99,
      'referencia': '000123',
      'pin': '037651',
    });
    expect(body, contains('"montoPago":9999999999999.99'));

    await expectLater(
      repository.submit('jwt-de-prueba', request),
      throwsA(
        isA<PurchaseFailure>().having(
          (e) => e.field,
          'campo',
          PurchaseField.account,
        ),
      ),
    );
    await expectLater(
      repository.submit('jwt-de-prueba', request),
      throwsA(
        isA<PurchaseFailure>()
            .having((e) => e.field, 'campo', isNull)
            .having((e) => e.message, 'mensaje', contains('Evita repetirlo')),
      ),
    );
  });
}
