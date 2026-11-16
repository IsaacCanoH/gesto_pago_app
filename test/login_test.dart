import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/app/app.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/auth/data/auth_repository.dart';
import 'package:gesto_pago_app/features/auth/data/models/auth_session.dart';
import 'package:gesto_pago_app/features/catalog/data/catalog_repository.dart';
import 'package:gesto_pago_app/features/catalog/data/models/product.dart';

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

class TestCatalogRepository extends CatalogRepository {
  TestCatalogRepository() : super(const ApiClient(null));

  String? token;

  @override
  Future<List<Product>> load(String token) async {
    this.token = token;
    return const [
      Product(
        serviceId: 1,
        service: 'Telcel',
        type: 1,
        offers: [ProductOffer(id: 1, name: 'Recarga', price: 100)],
      ),
    ];
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
      final catalog = TestCatalogRepository();
      await tester.pumpWidget(
        GestoPagoApp(authRepository: repository, catalogRepository: catalog),
      );
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
      expect(find.text('Recargas y pagos de servicios'), findsOneWidget);
      expect(find.text('Telcel'), findsOneWidget);
      expect(catalog.token, 'token-de-prueba');

      await tester.tap(find.text('Telcel'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del producto'), findsOneWidget);
      expect(find.text('Importe de recarga'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

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
      expect(find.text('Catálogo'), findsNothing);
    },
  );
}
