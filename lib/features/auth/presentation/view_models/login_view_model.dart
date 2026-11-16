import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_challenge.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this.repository);
  final AuthRepository repository;
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<AuthChallenge?> signIn(String email, String password) async {
    if (busy) return null;
    busy = true;
    error = null;
    notifyListeners();
    try {
      return await repository.signIn(email.trim(), password);
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
