enum PurchaseStatus {
  successful('Pago exitoso'),
  rejected('Pago rechazado'),
  pending('Pago pendiente');

  const PurchaseStatus(this.label);

  final String label;
}

class PurchaseResult {
  const PurchaseResult({
    required this.upc,
    required this.status,
    this.createdAt,
    this.resolvedAt,
    this.authorization,
    this.requiresManualReview = false,
  });

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    final upc = json['upc'];
    final status = switch (json['estatus']) {
      'EXITOSO' => PurchaseStatus.successful,
      'FALLIDO' => PurchaseStatus.rejected,
      'PENDIENTE' => PurchaseStatus.pending,
      _ => throw const FormatException(),
    };
    if (upc is! String || upc.trim().isEmpty) throw const FormatException();
    final authorization = json['numeroAutorizacion'];
    return PurchaseResult(
      upc: upc,
      status: status,
      createdAt: _readDate(json['fechaCreacion']),
      resolvedAt: _readDate(json['fechaResolucion']),
      authorization: authorization is String && authorization.trim().isNotEmpty
          ? authorization
          : null,
      requiresManualReview: json['requiereRevisionManual'] == true,
    );
  }

  static DateTime? _readDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  final String upc;
  final PurchaseStatus status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? authorization;
  final bool requiresManualReview;
}
