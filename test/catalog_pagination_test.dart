import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/catalog/data/catalog_repository.dart';
import 'package:gesto_pago_app/features/catalog/data/models/product.dart';
import 'package:gesto_pago_app/features/catalog/presentation/pages/catalog_page.dart';

class CatalogFixture extends CatalogRepository {
  const CatalogFixture() : super(const ApiClient(null));

  @override
  Future<List<Product>> load(String token) async => List.generate(12, (index) {
    final number = index + 1;
    final fixed = number <= 10;
    return Product(
      serviceId: number,
      service: 'Proveedor $number',
      type: fixed ? 1 : 2,
      offers: [
        ProductOffer(id: number, name: 'Pago', price: fixed ? 50 : null),
      ],
    );
  });
}

void main() {
  testWidgets('muestra diez entradas y reinicia la página al filtrar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(480, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogPage(
            repository: const CatalogFixture(),
            token: 'token-de-prueba',
            onSessionExpired: () {},
            onProductSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(10));
    expect(find.text('Página 1 de 2'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Página anterior',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Proveedor 11'), findsOneWidget);
    expect(find.text('Página 2 de 2'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Página siguiente',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Página anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Página 1 de 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recargas'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(10));
    expect(find.text('Proveedor 1'), findsOneWidget);
    expect(find.text('Proveedor 11'), findsNothing);
    expect(find.byTooltip('Página siguiente'), findsNothing);
  });
}
