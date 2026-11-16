class Product {
  const Product(this.service, this.type, {this.denominations = const []});
  final String service;
  final int type;
  final List<int> denominations;

  bool get fixed => type == 1;
}
