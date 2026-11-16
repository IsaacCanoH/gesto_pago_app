import '../../../core/network/api_client.dart';
import 'models/product.dart';

class CatalogRepository {
  const CatalogRepository(this.client);

  final ApiClient client;

  Future<List<Product>> load(String token) async {
    final response = await client.get('gestopago/productos', token: token);
    final data = response['datos'];
    if (data is! List) {
      throw const ApiException('El servidor devolvió un catálogo inválido.');
    }
    final fixedGroups = <int, List<ProductOffer>>{};
    final serviceNames = <int, String>{};
    final services = <Product>[];
    for (final row in data) {
      if (row is! Map<String, dynamic>) continue;
      final type = row['tipoFront'];
      final category = row['idCatTipoServicio'];
      final serviceId = row['idServicio'];
      final id = row['idProducto'];
      final service = row['servicio'];
      final name = row['producto'];
      final price = row['precio'];
      final legend = _readLegend(row['leyenda']);
      if ((type != 1 && type != 2) ||
          category == 10 ||
          category == 11 ||
          serviceId is! int ||
          serviceId <= 0 ||
          id is! int ||
          id <= 0 ||
          service is! String ||
          service.trim().isEmpty ||
          name is! String ||
          name.trim().isEmpty) {
        continue;
      }
      if (type == 1) {
        if (price is! num || !price.isFinite || price <= 0) continue;
        serviceNames.putIfAbsent(serviceId, service.trim);
        (fixedGroups[serviceId] ??= []).add(
          ProductOffer(id: id, name: name.trim(), price: price, legend: legend),
        );
      } else {
        services.add(
          Product(
            serviceId: serviceId,
            service: service.trim(),
            type: 2,
            offers: List.unmodifiable([
              ProductOffer(id: id, name: name.trim(), legend: legend),
            ]),
          ),
        );
      }
    }
    final products = [
      for (final group in fixedGroups.entries)
        Product(
          serviceId: group.key,
          service: serviceNames[group.key]!,
          type: 1,
          offers: List.unmodifiable(
            group.value..sort((a, b) {
              final priceOrder = a.price!.compareTo(b.price!);
              return priceOrder == 0 ? a.name.compareTo(b.name) : priceOrder;
            }),
          ),
        ),
      ...services,
    ];
    products.sort((a, b) {
      final serviceOrder = a.service.toLowerCase().compareTo(
        b.service.toLowerCase(),
      );
      return serviceOrder == 0
          ? a.description.compareTo(b.description)
          : serviceOrder;
    });
    return List.unmodifiable(products);
  }

  String? _readLegend(Object? value) {
    if (value is! String) return null;
    final text = value
        .replaceAll(
          RegExp(r'[ \t]*<br\s*/?>[ \t]*(?:\r?\n)?', caseSensitive: false),
          '\n',
        )
        .trim();
    return text.isEmpty ? null : text;
  }
}
