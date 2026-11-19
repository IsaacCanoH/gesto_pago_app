import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/app/theme.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/accounts/data/accounts_repository.dart';
import 'package:gesto_pago_app/features/accounts/presentation/pages/accounts_page.dart';

void main() {
  testWidgets(
    'confirma una sola vez y actualiza la cuenta solo cuando la API acepta',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _AccountsClient();
      await tester.pumpWidget(
        MaterialApp(
          theme: gestoPagoTheme(),
          home: Scaffold(
            body: AccountsPage(
              repository: AccountsRepository(client),
              token: 'jwt-de-prueba',
              onSessionExpired: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final zeroAccount = find.byKey(const ValueKey(7));
      final fundedAccount = find.byKey(const ValueKey(8));
      final inactiveAccount = find.byKey(const ValueKey(9));
      final deactivate = find.descendant(
        of: zeroAccount,
        matching: find.text('Desactivar cuenta'),
      );
      final blocked = find.descendant(
        of: fundedAccount,
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<OutlinedButton>(blocked).onPressed, isNull);
      expect(
        find.descendant(
          of: inactiveAccount,
          matching: find.byType(OutlinedButton),
        ),
        findsNothing,
      );
      expect(
        find.text('La cuenta debe tener saldo cero para desactivarla.'),
        findsOneWidget,
      );

      await tester.ensureVisible(deactivate);
      await tester.tap(deactivate);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(client.requests, 0);

      await tester.tap(deactivate);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desactivar'));
      await tester.pump();
      expect(client.requests, 1);
      expect(find.text('Desactivando…'), findsOneWidget);
      await tester.tap(find.text('Desactivando…'));
      expect(client.requests, 1);
      client.response.completeError(
        const ApiException('Conflicto', statusCode: 409),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: zeroAccount, matching: find.text('Activa')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: zeroAccount,
          matching: find.text(
            'La cuenta debe tener saldo cero para desactivarla.',
          ),
        ),
        findsOneWidget,
      );

      client.response = Completer<Map<String, dynamic>>();
      await tester.ensureVisible(deactivate);
      await tester.tap(deactivate);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desactivar'));
      await tester.pump();
      client.response.complete({
        'codigo': 0,
        'mensaje': 'Cuenta desactivada correctamente',
      });
      await tester.pumpAndSettle();

      expect(client.requests, 2);
      expect(
        find.descendant(of: zeroAccount, matching: find.text('Inactiva')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: zeroAccount, matching: find.byType(OutlinedButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: fundedAccount, matching: find.text('Activa')),
        findsOneWidget,
      );
    },
  );
}

class _AccountsClient extends ApiClient {
  _AccountsClient() : super(null);

  int requests = 0;
  Completer<Map<String, dynamic>> response = Completer();

  @override
  Future<Map<String, dynamic>> get(String path, {required String token}) async {
    expect(path, 'cuentas/propias/gestion');
    expect(token, 'jwt-de-prueba');
    return {
      'codigo': 0,
      'datos': [
        {
          'idCuenta': 7,
          'ultimosDigitos': '0724',
          'saldo': 0,
          'estatus': 'ACTIVA',
        },
        {
          'idCuenta': 8,
          'ultimosDigitos': '1023',
          'saldo': 150,
          'estatus': 'ACTIVA',
        },
        {
          'idCuenta': 9,
          'ultimosDigitos': '9000',
          'saldo': 0,
          'estatus': 'INACTIVA',
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) {
    expect(path, 'cuentas/desactivar');
    expect(body, {'idCuenta': 7});
    expect(token, 'jwt-de-prueba');
    requests++;
    return response.future;
  }
}
