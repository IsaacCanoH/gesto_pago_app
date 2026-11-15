import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/main.dart';

void main() {
  testWidgets('muestra el formulario de inicio de sesión', (tester) async {
    await tester.pumpWidget(const GestoPagoApp());

    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('navega a la pantalla de registro', (tester) async {
    await tester.pumpWidget(const GestoPagoApp());

    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
  });
}
