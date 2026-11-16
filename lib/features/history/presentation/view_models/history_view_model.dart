import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../purchases/data/models/purchase_result.dart';
import '../../../purchases/data/purchases_repository.dart';
import '../../data/history_repository.dart';
import '../../data/models/transaction.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    required this.repository,
    required this.token,
    required this.consultPurchase,
  });

  final HistoryRepository repository;
  final String token;
  final ConsultPurchase consultPurchase;
  final _consulting = <String>{};
  final _consultErrors = <String, String>{};
  bool _disposed = false;

  int page = 0;
  int _requestedPage = 0;
  int totalPages = 0;
  bool loading = false;
  ApiException? error;
  List<PurchaseTransaction> transactions = const [];

  bool isConsulting(String upc) => _consulting.contains(upc);
  String? consultError(String upc) => _consultErrors[upc];

  Future<void> load(int requestedPage) async {
    if (_disposed || loading || _consulting.isNotEmpty) return;
    _requestedPage = requestedPage;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await repository.load(token, requestedPage);
      if (_disposed) return;
      page = data.number;
      totalPages = data.totalPages;
      transactions = data.transactions;
      _consultErrors.clear();
    } on ApiException catch (failure) {
      error = failure;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> retry() => load(_requestedPage);

  bool get canChangePage => !loading && _consulting.isEmpty;

  Future<void> consult(PurchaseTransaction transaction) async {
    final upc = transaction.upc;
    if (_disposed ||
        loading ||
        transaction.status != PurchaseStatus.pending ||
        !_consulting.add(upc)) {
      return;
    }

    _consultErrors.remove(upc);
    notifyListeners();
    try {
      final result = await consultPurchase(upc);
      if (_disposed) return;
      final status = result.status;
      transactions = List.unmodifiable(
        transactions.map(
          (item) => item.upc == upc ? item.withStatus(status) : item,
        ),
      );
    } on ApiException catch (failure) {
      _consultErrors[upc] = failure.message;
    } finally {
      _consulting.remove(upc);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
