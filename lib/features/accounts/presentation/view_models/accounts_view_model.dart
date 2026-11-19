import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/accounts_repository.dart';
import '../../data/models/managed_account.dart';

class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel(this.repository, this.token);

  final AccountsRepository repository;
  final String token;

  List<ManagedAccount> accounts = const [];
  ApiException? error;
  ApiException? deactivationError;
  int? failedAccountId;
  int? deactivatingId;
  bool loading = false;
  bool _disposed = false;

  bool get busy => loading || deactivatingId != null;
  bool get sessionExpired =>
      error?.statusCode == 401 || deactivationError?.statusCode == 401;

  Future<void> load() async {
    if (busy || _disposed) return;
    loading = true;
    error = null;
    deactivationError = null;
    failedAccountId = null;
    notifyListeners();
    try {
      final result = await repository.load(token);
      if (!_disposed) accounts = result;
    } on ApiException catch (failure) {
      error = failure;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> deactivate(ManagedAccount account) async {
    if (busy || _disposed || sessionExpired || !account.canDeactivate) return;
    deactivatingId = account.id;
    failedAccountId = null;
    deactivationError = null;
    notifyListeners();
    try {
      await repository.deactivate(token, account.id);
      if (_disposed) return;
      accounts = List.unmodifiable(
        accounts.map(
          (item) => item.id == account.id ? item.asInactive() : item,
        ),
      );
    } on ApiException catch (failure) {
      failedAccountId = account.id;
      deactivationError = failure;
    } finally {
      deactivatingId = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
