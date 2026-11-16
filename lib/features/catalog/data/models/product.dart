class Product {
  const Product({
    required this.serviceId,
    required this.service,
    required this.type,
    required this.offers,
  });

  final int serviceId;
  final String service;
  final int type;
  final List<ProductOffer> offers;

  bool get fixed => type == 1;

  String get description =>
      fixed ? 'Recarga de precio fijo' : offers.single.name;
}

class ProductOffer {
  const ProductOffer({required this.id, required this.name, this.price});

  final int id;
  final String name;
  final num? price;
}
