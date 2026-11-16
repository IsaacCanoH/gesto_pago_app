import '../../../purchases/data/models/purchase_result.dart';

class PurchaseTransaction {
  const PurchaseTransaction({
    required this.product,
    required this.amount,
    required this.createdAt,
    required this.upc,
    required this.status,
    this.type,
  });

  factory PurchaseTransaction.fromJson(Map<String, dynamic> json) {
    final product = json['producto'];
    final amount = json['monto'];
    final rawDate = json['fechaCreacion'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final result = PurchaseResult.fromJson(json);
    if (product is! String ||
        product.trim().isEmpty ||
        amount is! num ||
        !amount.isFinite ||
        date == null) {
      throw const FormatException();
    }
    final type = json['tipoFront'];
    return PurchaseTransaction(
      product: product,
      amount: amount,
      createdAt: date,
      upc: result.upc,
      status: result.status,
      type: type is int ? type : null,
    );
  }

  final String product;
  final num amount;
  final DateTime createdAt;
  final String upc;
  final PurchaseStatus status;
  final int? type;

  PurchaseTransaction withStatus(PurchaseStatus status) => PurchaseTransaction(
    product: product,
    amount: amount,
    createdAt: createdAt,
    upc: upc,
    status: status,
    type: type,
  );

  String get statusLabel =>
      status == PurchaseStatus.rejected ? 'Pago fallido' : status.label;

  String get money => '\$${amount.toStringAsFixed(2)}';
}
