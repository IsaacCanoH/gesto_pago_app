import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/app/app.dart';
import 'package:gesto_pago_app/app/theme.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/registration/data/models/client_registration_request.dart';
import 'package:gesto_pago_app/features/registration/data/models/registered_client.dart';
import 'package:gesto_pago_app/features/registration/data/registration_repository.dart';
import 'package:gesto_pago_app/features/registration/presentation/controllers/registration_form_controller.dart';
import 'package:gesto_pago_app/features/registration/presentation/pages/register_page.dart';
import 'package:gesto_pago_app/features/registration/presentation/pages/registration_completed_page.dart';
import 'package:gesto_pago_app/features/registration/presentation/widgets/registration_fields.dart';

import 'support/registration_fixtures.dart';

class _RegistrationRepository extends RegistrationRepository {
  _RegistrationRepository() : super(const ApiClient(null));

  final requests = <ClientRegistrationRequest>[];
  Completer<RegisteredClient> response = Completer();

  @override
  Future<RegisteredClient> register(ClientRegistrationRequest request) {
    requests.add(request);
    return response.future;
  }
}

RegistrationFormController seedForm(WidgetTester tester) {
  final form = tester
      .widget<RegistrationTextField>(find.byType(RegistrationTextField).first)
      .form;
  validRegistration().forEach((field, value) => form[field].text = value);
  return form;
}

Future<void> nextStep(WidgetTester tester) async {
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

Future<void> openReview(WidgetTester tester) async {
  for (var step = 0; step < 6; step++) {
    await nextStep(tester);
  }
}

Widget _registrationApp(_RegistrationRepository repository) => MaterialApp(
  theme: gestoPagoTheme(),
  home: RegisterPage(repository: repository),
);

void main() {
  testWidgets('impide avanzar con campos inválidos y muestra errores en rojo', (
    tester,
  ) async {
    final repository = _RegistrationRepository();
    await tester.pumpWidget(_registrationApp(repository));
    final field = tester.widget<RegistrationTextField>(
      find.byType(RegistrationTextField).first,
    );
    await tester.enterText(find.byType(TextField).first, 'A1');
    await nextStep(tester);
    expect(find.text('Paso 1 de 7'), findsOneWidget);
    expect(find.text('Usa solo letras y espacios.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsWidgets);
    expect(field.form.focusNode(RegistrationField.name).hasFocus, isTrue);
    expect(repository.requests, isEmpty);
    await tester.enterText(find.byType(TextField).first, 'Ángela');
    await tester.pumpAndSettle();
    expect(find.text('Usa solo letras y espacios.'), findsNothing);
  });

  testWidgets('conserva los datos al volver y editar desde el resumen', (
    tester,
  ) async {
    final repository = _RegistrationRepository();
    await tester.pumpWidget(_registrationApp(repository));
    seedForm(tester);
    await nextStep(tester);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Mariana',
    );
    await openReview(tester);
    expect(find.text('Revisa tus datos'), findsOneWidget);
    expect(find.text('Mariana López Herrera'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(repository.requests, isEmpty);
    await tester.ensureVisible(find.byTooltip('Editar datos personales'));
    await tester.tap(find.byTooltip('Editar datos personales'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Mariana Isabel');
    await tester.tap(find.text('Volver al resumen'));
    await tester.pumpAndSettle();
    expect(find.text('Mariana Isabel López Herrera'), findsOneWidget);
    expect(find.text('Revisa tus datos'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 640),
    const Size(393, 852),
    const Size(800, 600),
  ]) {
    testWidgets(
      'valida y recorre los pasos en ${size.width} x ${size.height}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_registrationApp(_RegistrationRepository()));
        await nextStep(tester);
        expect(tester.takeException(), isNull);
        seedForm(tester);
        for (var step = 0; step < 7; step++) {
          expect(find.text('Paso ${step + 1} de 7'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(find.byType(FilledButton)).bottom,
            lessThanOrEqualTo(size.height),
          );
          if (step < 6) await nextStep(tester);
        }
      },
    );
  }

  testWidgets('permite recorrer el formulario con texto grande y teclado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: gestoPagoTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
            viewInsets: const EdgeInsets.only(bottom: 240),
          ),
          child: child!,
        ),
        home: RegisterPage(repository: _RegistrationRepository()),
      ),
    );
    await nextStep(tester);
    expect(tester.takeException(), isNull);
    seedForm(tester);
    for (var step = 0; step < 7; step++) {
      expect(tester.takeException(), isNull);
      if (step < 6) await nextStep(tester);
    }
  });

  testWidgets(
    'conserva la fecha seleccionada al volver a abrir el calendario',
    (tester) async {
      await tester.pumpWidget(_registrationApp(_RegistrationRepository()));
      final form = seedForm(tester);
      final birth = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is RegistrationTextField &&
              widget.field == RegistrationField.birthDate,
        ),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(birth);
      await tester.tap(birth);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .initialDate,
        DateTime(1998, 11, 15),
      );
      await tester.tap(find.text('Seleccionar'));
      await tester.pumpAndSettle();
      expect(form[RegistrationField.birthDate].text, '15/11/1998');
    },
  );

  testWidgets(
    'envía una sola vez y confirma solo después de la respuesta del servidor',
    (tester) async {
      final repository = _RegistrationRepository();
      await tester.pumpWidget(_registrationApp(repository));
      final form = seedForm(tester);
      await openReview(tester);
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      expect(find.text('Creando cuenta…'), findsOneWidget);
      expect(find.text('Registro completado'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == 'Volver',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Creando cuenta…'));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.toJson()['pin'], '012345');
      repository.response.complete(
        const RegisteredClient(
          id: 42,
          accountEnding: '0724',
          initialBalance: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Registro completado'), findsOneWidget);
      expect(find.text('•••• 0724'), findsOneWidget);
      expect(find.text('\$0.00 MXN'), findsOneWidget);
      expect(find.text('Crear mi cuenta'), findsNothing);
      expect(form[RegistrationField.password].text, isEmpty);
      expect(form[RegistrationField.pin].text, isEmpty);
    },
  );

  testWidgets(
    'lleva el error de correo al campo y permite corregirlo sin perder datos',
    (tester) async {
      final repository = _RegistrationRepository();
      await tester.pumpWidget(_registrationApp(repository));
      final form = seedForm(tester);
      await openReview(tester);
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      repository.response.completeError(
        const RegistrationFailure(
          'Revisa los datos indicados para continuar.',
          fields: {RegistrationField.email: 'El correo ya está registrado'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Paso 3 de 7'), findsOneWidget);
      expect(find.text('El correo ya está registrado'), findsOneWidget);
      expect(form[RegistrationField.name].text, 'Mariana');
      final email = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is RegistrationTextField &&
              widget.field == RegistrationField.email,
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(email, 'nuevo@example.com');
      await tester.pumpAndSettle();
      expect(find.text('El correo ya está registrado'), findsNothing);
      await tester.tap(find.text('Volver al resumen'));
      await tester.pumpAndSettle();
      repository.response = Completer();
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.toJson()['correo'], 'nuevo@example.com');
      repository.response.complete(
        const RegisteredClient(
          id: 43,
          accountEnding: '0725',
          initialBalance: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Registro completado'), findsOneWidget);
    },
  );

  testWidgets(
    'un resultado incierto permite ir a iniciar sesión sin registrar de nuevo',
    (tester) async {
      final repository = _RegistrationRepository();
      await tester.pumpWidget(_registrationApp(repository));
      seedForm(tester);
      await openReview(tester);
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      repository.response.completeError(const RegistrationFailure.unknown());
      await tester.pumpAndSettle();
      expect(find.text('Registro completado'), findsNothing);
      expect(find.text('Ir a iniciar sesión'), findsOneWidget);
      expect(
        find.textContaining('No pudimos confirmar el registro'),
        findsOneWidget,
      );
      expect(repository.requests, hasLength(1));
    },
  );

  testWidgets(
    'vuelve al inicio de sesión con el correo y sin autenticar automáticamente',
    (tester) async {
      final repository = _RegistrationRepository();
      await tester.pumpWidget(GestoPagoApp(registrationRepository: repository));
      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();
      seedForm(tester);
      await openReview(tester);
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      repository.response.complete(
        const RegisteredClient(
          id: 42,
          accountEnding: '0724',
          initialBalance: 0,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.controller!.text, 'mariana@example.com');
      expect(fields.last.controller!.text, isEmpty);
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.text('Catálogo'), findsNothing);
    },
  );

  testWidgets('descarta una respuesta tardía si la pantalla ya se cerró', (
    tester,
  ) async {
    final repository = _RegistrationRepository();
    await tester.pumpWidget(_registrationApp(repository));
    seedForm(tester);
    await openReview(tester);
    await tester.tap(find.text('Crear mi cuenta'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    repository.response.completeError(const RegistrationFailure.unknown());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('la confirmación presenta solo los datos recibidos', (
    tester,
  ) async {
    var signInPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: gestoPagoTheme(),
        home: RegistrationCompletedPage(
          accountEnding: '1234',
          initialBalance: '\$0.00 MXN',
          onSignIn: () => signInPressed = true,
        ),
      ),
    );
    expect(find.text('Registro completado'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);
    expect(find.text('\$0.00 MXN'), findsOneWidget);
    await tester.tap(find.text('Iniciar sesión'));
    expect(signInPressed, isTrue);
  });
  testWidgets('valida las confirmaciones de contraseña y PIN antes de enviar', (
    tester,
  ) async {
    final repository = _RegistrationRepository();
    await tester.pumpWidget(_registrationApp(repository));
    final form = seedForm(tester);
    form[RegistrationField.passwordConfirmation].text = 'OtraClave1!';
    form[RegistrationField.pinConfirmation].text = '123456';
    for (var step = 0; step < 5; step++) {
      await nextStep(tester);
    }
    await nextStep(tester);
    expect(find.text('Paso 6 de 7'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(find.text('Los PIN no coinciden.'), findsOneWidget);
    expect(repository.requests, isEmpty);
    form[RegistrationField.passwordConfirmation].text =
        form[RegistrationField.password].text;
    form[RegistrationField.pinConfirmation].text =
        form[RegistrationField.pin].text;
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsNothing);
    expect(find.text('Los PIN no coinciden.'), findsNothing);
    await nextStep(tester);
    expect(find.text('Revisa tus datos'), findsOneWidget);
  });
}
