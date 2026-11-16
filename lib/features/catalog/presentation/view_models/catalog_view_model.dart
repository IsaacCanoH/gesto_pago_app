import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/catalog_repository.dart';
import '../../data/models/product.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this.repository, this.token);

  final CatalogRepository repository;
  final String token;
  List<Product> products = const [];
  ApiException? error;
  bool loading = false;
  bool _disposed = false;

  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await repository.load(token);
    } on ApiException catch (exception) {
      error = exception;
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
