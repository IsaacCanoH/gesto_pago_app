import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/app/shell.dart';
import 'package:gesto_pago_app/app/theme.dart';
import 'package:gesto_pago_app/features/catalog/data/catalog_repository.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/history/data/history_repository.dart';
import 'package:gesto_pago_app/features/history/presentation/pages/history_page.dart';
import 'package:gesto_pago_app/features/purchases/data/purchases_repository.dart';

void main() {
  testWidgets('navega entre pestañas y vuelve del detalle al historial', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _HistoryClient();

    await tester.pumpWidget(
      MaterialApp(
        theme: gestoPagoTheme(),
        home: AppShell(
          catalogRepository: CatalogRepository(client),
          historyRepository: HistoryRepository(client),
          purchasesRepository: PurchasesRepository(client),
          token: 'jwt-de-prueba',
          onExit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    final purchase = find.text('UPC EXITOSO-1');
    await tester.ensureVisible(purchase);
    await tester.tap(purchase);
    await tester.pumpAndSettle();

    expect(find.text('Detalle de compra'), findsOneWidget);
    expect(find.text('Exitoso'), findsOneWidget);
    expect(find.text('Fecha de confirmación'), findsOneWidget);
    expect(find.text('018347'), findsOneWidget);
    expect(find.text('•••• 0724'), findsOneWidget);
    expect(find.byTooltip('Copiar UPC'), findsOneWidget);
    expect(find.text('Volver al historial').hitTestable(), findsOneWidget);
    expect(client.consultedUpcs, ['EXITOSO-1']);

    await tester.tap(find.text('Volver al historial'));
    await tester.pumpAndSettle();
    expect(find.text('Historial de pagos'), findsOneWidget);
    expect(client.requestedPages, [0]);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Catálogo'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recargas y pagos de servicios'), findsOneWidget);
    expect(client.catalogRequests, 1);
  });

  testWidgets('consulta el mismo UPC y actualiza solo el pago pendiente', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _HistoryClient();
    await _openHistory(tester, client);

    expect(find.text('Pago pendiente'), findsOneWidget);
    expect(find.text('Pago exitoso'), findsOneWidget);
    expect(find.text('Pago fallido'), findsOneWidget);
    expect(find.text('Consultar estado'), findsOneWidget);
    expect(find.text('UPC PENDIENTE-1'), findsOneWidget);

    final button = find.text('Consultar estado');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Consultando…'), findsOneWidget);

    client.consultation.completeError(const ApiException('Falló la consulta.'));
    await tester.pumpAndSettle();
    expect(find.text('Falló la consulta.'), findsOneWidget);
    expect(find.text('Pago pendiente'), findsOneWidget);

    client.consultation = Completer<Map<String, dynamic>>();
    await tester.tap(button);
    client.consultation.complete({'upc': 'PENDIENTE-1', 'estatus': 'FALLIDO'});
    await tester.pumpAndSettle();
    expect(find.text('Pago pendiente'), findsNothing);
    expect(find.text('Pago fallido'), findsNWidgets(2));
    expect(find.text('Pago exitoso'), findsOneWidget);
    expect(find.text('Consultar estado'), findsNothing);
    expect(find.text('Falló la consulta.'), findsNothing);
    expect(find.text('Historial de pagos'), findsOneWidget);
    expect(client.consultedUpcs, ['PENDIENTE-1', 'PENDIENTE-1']);
    expect(client.requestedPages, [0]);
  });

  testWidgets('pide al servidor cada página y reintenta la que falló', (
    tester,
  ) async {
    final client = _HistoryClient()..failNextPage = true;
    await _openHistory(tester, client);
    expect(find.text('Página 1 de 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Página 1 de 2'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 2'), findsOneWidget);
    expect(find.text('UPC EXITOSO-2'), findsOneWidget);
    expect(find.text('Consultar estado'), findsNothing);
    expect(client.requestedPages, [0, 1, 1]);
  });
}

Future<void> _openHistory(WidgetTester tester, _HistoryClient client) async {
  final purchases = PurchasesRepository(client);
  await tester.pumpWidget(
    MaterialApp(
      home: HistoryPage(
        repository: HistoryRepository(client),
        token: 'jwt-de-prueba',
        consultPurchase: (upc) => purchases.consult('jwt-de-prueba', upc),
        onSessionExpired: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _HistoryClient extends ApiClient {
  _HistoryClient() : super(null);

  Completer<Map<String, dynamic>> consultation = Completer();
  final requestedPages = <int>[];
  final consultedUpcs = <String>[];
  bool failNextPage = false;
  int catalogRequests = 0;

  @override
  Future<Map<String, dynamic>> get(String path, {required String token}) async {
    expect(path, 'gestopago/productos');
    expect(token, 'jwt-de-prueba');
    catalogRequests++;
    return {'datos': []};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    expect(token, 'jwt-de-prueba');
    if (path == 'pagos/consultar') {
      final upc = body['upc'] as String;
      expect(body, {'upc': upc, 'ocultarNumeroCuenta': true});
      consultedUpcs.add(upc);
      if (upc == 'EXITOSO-1') {
        return {
          'upc': upc,
          'estatus': 'EXITOSO',
          'fechaResolucion': '2026-11-10T12:05:00Z',
          'numeroAutorizacion': '018347',
          'ultimosDigitos': '0724',
        };
      }
      expect(upc, 'PENDIENTE-1');
      return consultation.future;
    }

    expect(path, 'pagos/historial');
    final page = body['pagina']! as int;
    expect(body, {'pagina': page, 'tamanio': 10});
    requestedPages.add(page);
    if (page == 1 && failNextPage) {
      failNextPage = false;
      throw const ApiException('Falló la página.');
    }
    return {
      'codigo': 0,
      'datos': {
        'content': page == 0
            ? [
                _payment('PENDIENTE-1', 'PENDIENTE', 1),
                _payment('EXITOSO-1', 'EXITOSO', 2),
                _payment('FALLIDO-1', 'FALLIDO', null),
              ]
            : [_payment('EXITOSO-2', 'EXITOSO', 2)],
        'page': {'number': page, 'totalPages': 2},
      },
    };
  }

  Map<String, dynamic> _payment(String upc, String status, int? type) => {
    'upc': upc,
    'producto': 'Servicio de prueba',
    'monto': 49.99,
    'fechaCreacion': '2026-11-10T12:00:00Z',
    'estatus': status,
    'tipoFront': type,
  };
}
