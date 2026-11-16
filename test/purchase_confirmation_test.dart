import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/purchases/data/models/charge_account.dart';
import 'package:gesto_pago_app/features/purchases/data/models/purchase_draft.dart';
import 'package:gesto_pago_app/features/purchases/data/models/purchase_request.dart';
import 'package:gesto_pago_app/features/purchases/data/models/purchase_result.dart';
import 'package:gesto_pago_app/features/purchases/data/purchases_repository.dart';
import 'package:gesto_pago_app/features/purchases/presentation/pages/purchase_page.dart';
import 'package:gesto_pago_app/features/purchases/presentation/widgets/payment_progress_button.dart';

const draft = PurchaseDraft(
  serviceId: 20,
  productId: 201,
  type: 2,
  serviceName: 'Proveedor',
  productName: 'Pago de prueba',
  reference: '000123',
  amountInCents: 999999999999999,
);

void main() {
  testWidgets('preselecciona la cuenta única y muestra solo su terminación', (
    tester,
  ) async {
    PurchaseRequest? sent;
    await tester.pumpWidget(
      MaterialApp(
        home: PurchasePage(
          draft: draft,
          loadAccounts: () async => const [
            ChargeAccount(id: 9, lastFour: '0724'),
          ],
          submitPurchase: (request) async {
            sent = request;
            return const PurchaseResult(
              upc: 'P12345678901234',
              status: PurchaseStatus.successful,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cuenta •••• 0724'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<ChargeAccount>), findsNothing);
    await tester.enterText(find.byType(TextField), '037651');
    await tester.ensureVisible(find.text('Confirmar pago'));
    await tester.tap(find.text('Confirmar pago'));
    await tester.pumpAndSettle();
    expect(sent?.accountId, 9);
    expect(find.text('Pago exitoso'), findsOneWidget);
  });
  testWidgets(
    'valida cuenta y PIN, envía una sola vez y bloquea tras una respuesta incierta',
    (tester) async {
      final pending = Completer<PurchaseResult>();
      var requests = 0;
      PurchaseRequest? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: PurchasePage(
            draft: draft,
            loadAccounts: () async => const [
              ChargeAccount(id: 9, lastFour: '0724'),
              ChargeAccount(id: 10, lastFour: '8961'),
            ],
            submitPurchase: (request) {
              requests++;
              sent = request;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final confirm = find.text('Confirmar pago');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(find.text('Selecciona una cuenta de cargo.'), findsOneWidget);
      expect(find.text('Ingresa los seis dígitos del PIN.'), findsOneWidget);
      expect(requests, 0);

      final selector = find.byType(DropdownButtonFormField<ChargeAccount>);
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuenta 2 •••• 8961').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '037651');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.tap(confirm);
      await tester.pump();
      expect(requests, 1);
      expect(sent?.accountId, 10);
      expect(find.text('Procesando pago…'), findsOneWidget);
      pending.completeError(const PurchaseFailure.unknown());
      await tester.pumpAndSettle();
      expect(find.textContaining('Evita repetirlo'), findsOneWidget);
      expect(
        tester
            .widget<PaymentProgressButton>(find.byType(PaymentProgressButton))
            .onPressed,
        isNull,
      );
    },
  );
}
