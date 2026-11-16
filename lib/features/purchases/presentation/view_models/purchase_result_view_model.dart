import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/purchase_result.dart';
import '../../data/purchases_repository.dart';

class PurchaseResultViewModel extends ChangeNotifier {
  PurchaseResultViewModel({required this.consult, required this.result});

  final ConsultPurchase consult;
  PurchaseResult? result;
  bool loading = false;
  String? error;
  bool _disposed = false;

  Future<void> refresh() async {
    final current = result;
    if (loading ||
        _disposed ||
        current == null ||
        current.status != PurchaseStatus.pending) {
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      result = await consult(current.upc);
    } on ApiException catch (failure) {
      error = failure.message;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
