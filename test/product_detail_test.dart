import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/catalog/data/models/product.dart';
import 'package:gesto_pago_app/features/catalog/presentation/pages/product_detail_page.dart';
import 'package:gesto_pago_app/features/purchases/presentation/pages/purchase_page.dart';

Future<void> openProduct(WidgetTester tester, Product product) =>
    tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          product: product,
          loadAccounts: () async => [],
          consultPurchase: (_) async =>
              throw StateError('Consulta fuera de la prueba'),
          submitPurchase: (_) async =>
              throw StateError("Pago fuera de la prueba"),
        ),
      ),
    );

void main() {
  testWidgets(
    'conserva el producto elegido cuando dos denominaciones tienen el mismo precio',
    (tester) async {
      await openProduct(
        tester,
        const Product(
          serviceId: 21,
          service: 'Operador',
          type: 1,
          offers: [
            ProductOffer(
              id: 101,
              name: 'Recarga',
              price: 50,
              legend: 'Condiciones de recarga',
            ),
            ProductOffer(
              id: 102,
              name: 'Paquete',
              price: 50,
              legend: 'Condiciones del paquete',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Revisar compra'));
      await tester.pumpAndSettle();
      expect(find.text('Selecciona un importe.'), findsOneWidget);
      expect(find.textContaining('de 10 a 20 caracteres'), findsOneWidget);

      expect(find.text('Condiciones de recarga'), findsNothing);
      expect(find.text('Condiciones del paquete'), findsNothing);
      await tester.tap(find.text('Importe de recarga'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Paquete').last);
      await tester.pumpAndSettle();
      expect(find.text('Condiciones del paquete'), findsOneWidget);
      expect(find.text('Condiciones de recarga'), findsNothing);
      await tester.enterText(find.byType(TextFormField), '  CLIENTE1234  ');
      await tester.ensureVisible(find.text('Revisar compra'));
      await tester.tap(find.text('Revisar compra'));
      await tester.pumpAndSettle();

      final draft = tester
          .widget<PurchasePage>(find.byType(PurchasePage))
          .draft;
      expect(draft.productId, 102);
      expect(draft.serviceId, 21);
      expect(draft.type, 1);
      expect(draft.reference, 'CLIENTE1234');
      expect(draft.amountInCents, 5000);
      expect(find.text('Paquete'), findsOneWidget);
      expect(find.text(r'$50.00 MXN'), findsOneWidget);
    },
  );

  testWidgets(
    'valida el importe de un servicio y conserva los centavos al confirmar',
    (tester) async {
      await openProduct(
        tester,
        const Product(
          serviceId: 41,
          service: 'CFE',
          type: 2,
          offers: [
            ProductOffer(
              id: 201,
              name: 'Pago de luz',
              legend: 'Conserva tu comprobante.',
            ),
          ],
        ),
      );

      expect(find.text('Conserva tu comprobante.'), findsOneWidget);
      final reference = find.byType(TextFormField).at(0);
      final amount = find.byType(TextFormField).at(1);
      await tester.enterText(reference, ' 00124 ');
      for (final malformed in ['0', '-1', '10,001', '10000000000000']) {
        await tester.enterText(amount, malformed);
        await tester.ensureVisible(find.text('Revisar compra'));
        await tester.tap(find.text('Revisar compra'));
        await tester.pumpAndSettle();
        expect(find.textContaining('importe mayor a cero'), findsOneWidget);
        expect(find.byType(PurchasePage), findsNothing);
      }

      await tester.enterText(amount, '9999999999999,99');
      await tester.ensureVisible(find.text('Revisar compra'));
      await tester.tap(find.text('Revisar compra'));
      await tester.pumpAndSettle();

      final draft = tester
          .widget<PurchasePage>(find.byType(PurchasePage))
          .draft;
      expect(draft.productId, 201);
      expect(draft.serviceId, 41);
      expect(draft.type, 2);
      expect(draft.reference, '00124');
      expect(draft.amountInCents, 999999999999999);
      expect(find.text(r'$9999999999999.99 MXN'), findsOneWidget);
    },
  );
}
