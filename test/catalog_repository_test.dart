import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/features/catalog/data/catalog_repository.dart';

Map<String, Object?> productRow({
  required int id,
  required int serviceId,
  required String service,
  required String name,
  required int type,
  int category = 2,
  num? price,
}) => {
  'idProducto': id,
  'idServicio': serviceId,
  'servicio': service,
  'producto': name,
  'tipoFront': type,
  'idCatTipoServicio': category,
  'precio': price,
};

void main() {
  test(
    'consulta el catálogo con JWT y conserva las opciones reales de pago',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requestResult = server.first.then((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'datos': [
              productRow(
                id: 101,
                serviceId: 1,
                service: 'Telcel',
                name: 'Recarga',
                type: 1,
                price: 100,
              ),
              productRow(
                id: 102,
                serviceId: 1,
                service: 'Telcel',
                name: 'Paquete',
                type: 1,
                price: 50.50,
              ),
              productRow(
                id: 103,
                serviceId: 1,
                service: 'Telcel',
                name: 'Sin importe',
                type: 1,
              ),
              productRow(
                id: 201,
                serviceId: 2,
                service: 'CFE',
                name: 'Pago de luz',
                type: 2,
                price: 10,
              ),
              productRow(
                id: 202,
                serviceId: 2,
                service: 'CFE',
                name: 'Consulta',
                type: 4,
              ),
              productRow(
                id: 301,
                serviceId: 3,
                service: 'Proveedor PIN',
                name: 'PIN',
                type: 1,
                category: 10,
                price: 50,
              ),
              productRow(
                id: 302,
                serviceId: 3,
                service: 'Proveedor PIN',
                name: 'Otro PIN',
                type: 2,
                category: 11,
              ),
            ],
          }),
        );
        await request.response.close();
        return (
          request.method,
          request.uri.path,
          request.headers.value(HttpHeaders.authorizationHeader),
        );
      });

      final url = Uri.parse('http://127.0.0.1:${server.port}');
      final products = await CatalogRepository(ApiClient(url))
          .load('token-de-prueba');
      expect(await requestResult, (
        'GET',
        '/gestopago/productos',
        'Bearer token-de-prueba',
      ));
      expect(products.map((product) => product.service), ['CFE', 'Telcel']);
      final cfe = products.first;
      expect(cfe.fixed, isFalse);
      expect(cfe.offers.single.price, isNull);
      final telcel = products.last;
      expect(telcel.fixed, isTrue);
      expect(telcel.offers.map((option) => option.id), [102, 101]);
      expect(telcel.offers.map((option) => option.price), [50.50, 100]);
    },
  );
}
