import 'purchase_draft.dart';

class PurchaseRequest {
  const PurchaseRequest({
    required this.draft,
    required this.accountId,
    required this.pin,
  });

  final PurchaseDraft draft;
  final int accountId;
  final String pin;

  Map<String, Object> toJson() => {
    'idCuenta': accountId,
    'idServicio': draft.serviceId,
    'idProducto': draft.productId,
    'tipoFront': draft.type,
    'montoPago': draft.amountInCents / 100,
    'referencia': draft.reference,
    'pin': pin,
  };
}
