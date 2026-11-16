class PurchaseTransaction {
  const PurchaseTransaction({
    required this.product,
    required this.amount,
    required this.date,
    required this.upc,
    required this.account,
    required this.authorization,
    required this.fixed,
  });
  final String product;
  final double amount;
  final String date;
  final String upc;
  final String account;
  final String authorization;
  final bool fixed;

  String get money => '\$${amount.toStringAsFixed(2)}';
}
