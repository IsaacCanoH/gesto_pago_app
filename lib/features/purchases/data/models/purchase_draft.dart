class PurchaseDraft {
  const PurchaseDraft({
    required this.serviceId,
    required this.productId,
    required this.type,
    required this.serviceName,
    required this.productName,
    required this.reference,
    required this.amountInCents,
  });

  final int serviceId;
  final int productId;
  final int type;
  final String serviceName;
  final String productName;
  final String reference;
  final int amountInCents;

  bool get fixed => type == 1;

  String get amountLabel {
    final units = amountInCents ~/ 100;
    final cents = (amountInCents % 100).toString().padLeft(2, '0');
    return '\$$units.$cents MXN';
  }
}
