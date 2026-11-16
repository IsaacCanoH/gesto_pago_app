import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/app/app.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/auth/data/auth_repository.dart';
import 'package:gesto_pago_app/features/auth/data/models/auth_session.dart';

class DeferredAuthRepository extends AuthRepository {
  DeferredAuthRepository() : super(const ApiClient(null));

  final response = Completer<AuthSession>();
  int requests = 0;
  (String, String)? credentials;

  @override
  Future<AuthSession> signIn(String email, String password) {
    requests++;
    credentials = (email, password);
    return response.future;
  }
}

Future<void> fillCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'cliente@example.com',
  );
  await tester.enterText(find.byType(TextFormField).at(1), ' clave de prueba ');
}

void main() {
  testWidgets('valida campos sin enviar la solicitud', (tester) async {
    final repository = DeferredAuthRepository();
    await tester.pumpWidget(GestoPagoApp(authRepository: repository));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
    expect(repository.requests, 0);
  });

  testWidgets(
    'protege el envío y abre una sesión al recibir una respuesta válida',
    (tester) async {
      final repository = DeferredAuthRepository();
      await tester.pumpWidget(GestoPagoApp(authRepository: repository));
      await fillCredentials(tester);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Iniciando sesión…'));
      expect(repository.requests, 1);
      expect(repository.credentials, (
        'cliente@example.com',
        ' clave de prueba ',
      ));

      repository.response.complete(
        AuthSession(
          token: 'token-de-prueba',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada'), findsOneWidget);
      expect(find.text('cliente@example.com'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra el rechazo de las credenciales sin salir del formulario',
    (tester) async {
      final repository = DeferredAuthRepository();
      await tester.pumpWidget(GestoPagoApp(authRepository: repository));
      await fillCredentials(tester);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      repository.response.completeError(
        const ApiException('El correo o la contraseña son incorrectos.'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('El correo o la contraseña son incorrectos.'),
        findsOneWidget,
      );
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Sesión iniciada'), findsNothing);
    },
  );
}
