import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/charge_account.dart';
import '../../data/models/purchase_request.dart';
import '../../data/models/purchase_result.dart';
import '../../data/purchases_repository.dart';

class PurchaseViewModel extends ChangeNotifier {
  PurchaseViewModel({required this.send, required this.fetchAccounts});

  final SubmitPurchase send;
  final LoadChargeAccounts fetchAccounts;
  List<ChargeAccount> accounts = const [];
  ChargeAccount? selectedAccount;
  ApiException? accountsError;
  bool loadingAccounts = false;
  bool processing = false;
  PurchaseResult? result;
  PurchaseFailure? failure;
  bool _disposed = false;

  bool get canSubmit =>
      !loadingAccounts &&
      accounts.isNotEmpty &&
      !processing &&
      result == null &&
      (failure == null || failure!.field != null);

  Future<void> loadAccounts() async {
    if (loadingAccounts || processing || _disposed) return;
    loadingAccounts = true;
    accountsError = null;
    notifyListeners();
    try {
      accounts = await fetchAccounts();
      selectedAccount = accounts.length == 1 ? accounts.single : null;
    } on ApiException catch (error) {
      accountsError = error;
    } finally {
      loadingAccounts = false;
      if (!_disposed) notifyListeners();
    }
  }

  void selectAccount(ChargeAccount? account) {
    selectedAccount = account;
    if (failure?.field == PurchaseField.account) failure = null;
    notifyListeners();
  }

  Future<void> submit(PurchaseRequest request) async {
    if (_disposed || !canSubmit || selectedAccount?.id != request.accountId) {
      return;
    }
    processing = true;
    failure = null;
    notifyListeners();
    try {
      result = await send(request);
    } on PurchaseFailure catch (error) {
      failure = error;
    } finally {
      processing = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
