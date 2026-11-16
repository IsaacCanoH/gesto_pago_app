enum PurchaseStatus {
  successful('Pago exitoso'),
  rejected('Pago rechazado'),
  pending('Pago pendiente');

  const PurchaseStatus(this.label);

  final String label;
}

class PurchaseResult {
  const PurchaseResult({required this.upc, required this.status});

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    final upc = json['upc'];
    final status = switch (json['estatus']) {
      'EXITOSO' => PurchaseStatus.successful,
      'FALLIDO' => PurchaseStatus.rejected,
      'PENDIENTE' => PurchaseStatus.pending,
      _ => throw const FormatException(),
    };
    if (upc is! String || upc.trim().isEmpty) throw const FormatException();
    return PurchaseResult(upc: upc, status: status);
  }

  final String upc;
  final PurchaseStatus status;
}
