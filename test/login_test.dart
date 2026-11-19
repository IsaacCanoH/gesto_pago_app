import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/app/app.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/auth/data/auth_repository.dart';
import 'package:gesto_pago_app/features/auth/data/models/auth_challenge.dart';
import 'package:gesto_pago_app/features/auth/data/models/auth_session.dart';
import 'package:gesto_pago_app/features/catalog/data/catalog_repository.dart';
import 'package:gesto_pago_app/features/catalog/data/models/product.dart';

class DeferredAuthRepository extends AuthRepository {
  DeferredAuthRepository() : super(const ApiClient(null));

  final response = Completer<AuthChallenge>();
  final verification = Completer<AuthSession>();
  final resendResponse = Completer<AuthChallenge>();
  final verifications = <(String, String)>[];
  final resends = <String>[];
  final logoutTokens = <String>[];
  Completer<void> logoutResponse = Completer();
  int requests = 0;
  (String, String)? credentials;

  @override
  Future<AuthChallenge> signIn(String email, String password) {
    requests++;
    credentials = (email, password);
    return response.future;
  }

  @override
  Future<AuthSession> verify(String id, String code) {
    verifications.add((id, code));
    return verification.future;
  }

  @override
  Future<void> signOut(String token) {
    logoutTokens.add(token);
    return logoutResponse.future;
  }

  @override
  Future<AuthChallenge> resend(String id) {
    resends.add(id);
    return resendResponse.future;
  }
}

AuthChallenge challenge({
  String id = 'reto-inicial',
  Duration resendDelay = const Duration(minutes: 1),
}) {
  final now = DateTime.now();
  return AuthChallenge(
    id: id,
    expiresAt: now.add(const Duration(minutes: 5)),
    resendAt: now.add(resendDelay),
  );
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
    'protege ambos envíos y abre el catálogo solo después del código válido',
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

      repository.response.complete(challenge());
      await tester.pumpAndSettle();
      expect(find.text('Verificación en dos pasos'), findsOneWidget);
      expect(find.textContaining('Reenviar código en'), findsOneWidget);
      expect(catalog.token, isNull);

      final verify = find.text('Verificar código');
      await tester.tap(verify);
      await tester.pumpAndSettle();
      expect(find.text('Ingresa los seis dígitos del código.'), findsOneWidget);
      expect(repository.verifications, isEmpty);

      await tester.enterText(find.byType(TextField), '012345');
      await tester.ensureVisible(verify);
      await tester.tap(verify);
      await tester.pump();
      expect(find.text('Verificando…'), findsOneWidget);
      await tester.tap(find.text('Verificando…'));
      expect(repository.verifications, [('reto-inicial', '012345')]);
      expect(catalog.token, isNull);

      repository.verification.complete(
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
      await tester.pump();
      expect(repository.logoutTokens, ['token-de-prueba']);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar sesión'));
      expect(repository.logoutTokens.length, 1);
      repository.logoutResponse.completeError(
        const ApiException('Sin conexión'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Telcel'), findsOneWidget);
      expect(
        find.textContaining('No pudimos cerrar la sesión en el servidor'),
        findsOneWidget,
      );

      repository.logoutResponse = Completer<void>();
      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pump();
      repository.logoutResponse.complete();
      await tester.pumpAndSettle();
      expect(repository.logoutTokens, ['token-de-prueba', 'token-de-prueba']);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    },
  );

  testWidgets(
    'reenvía al vencer la espera y verifica con el identificador nuevo',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = DeferredAuthRepository();
      await tester.pumpWidget(GestoPagoApp(authRepository: repository));
      final brand = find.text('Gesto Pago');
      final loginBrandOffset = tester.getTopLeft(brand);
      await fillCredentials(tester);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      repository.response.complete(challenge(resendDelay: Duration.zero));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(brand), loginBrandOffset);
      final scaffoldFinder = find.byType(Scaffold);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      final appBarFinder = find.byType(AppBar);
      expect(
        tester.widget<AppBar>(appBarFinder).forceMaterialTransparency,
        isTrue,
      );
      expect(
        tester.getRect(find.byWidget(scaffold.body!)),
        tester.getRect(scaffoldFinder),
      );
      expect(
        tester.getTopLeft(find.text('Verificación en dos pasos')).dy,
        greaterThan(tester.getBottomLeft(appBarFinder).dy),
      );

      await tester.enterText(find.byType(TextField), '012345');
      final resend = find.text('Reenviar código');
      await tester.ensureVisible(resend);
      await tester.tap(resend);
      await tester.pump();
      expect(find.text('Enviando código…'), findsOneWidget);
      expect(repository.resends, ['reto-inicial']);

      repository.resendResponse.complete(challenge(id: 'reto-nuevo'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enviamos un código nuevo a tu correo.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
      expect(find.textContaining('Reenviar código en'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '098765');
      final verify = find.text('Verificar código');
      await tester.ensureVisible(verify);
      await tester.tap(verify);
      await tester.pump();
      repository.verification.completeError(
        const ApiException(
          'El correo o la contraseña son incorrectos.',
          statusCode: 401,
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.verifications, [('reto-nuevo', '098765')]);
      expect(
        find.text(
          'El código es incorrecto o la verificación ya no está activa.',
        ),
        findsOneWidget,
      );
      expect(find.text('Catálogo'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
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
