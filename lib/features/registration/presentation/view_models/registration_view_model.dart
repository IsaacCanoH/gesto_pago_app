import 'package:flutter/foundation.dart';

import '../../data/models/client_registration_request.dart';
import '../../data/models/registered_client.dart';
import '../../data/registration_repository.dart';

class RegistrationViewModel extends ChangeNotifier {
  RegistrationViewModel(this.repository);

  final RegistrationRepository repository;
  RegisteredClient? result;
  RegistrationFailure? failure;
  bool busy = false;
  bool _disposed = false;

  Future<void> submit(ClientRegistrationRequest request) async {
    if (_disposed || busy || result != null) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      final registered = await repository.register(request);
      if (!_disposed) result = registered;
    } on RegistrationFailure catch (error) {
      if (!_disposed) failure = error;
    } catch (_) {
      if (!_disposed) failure = const RegistrationFailure.unknown();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearFailure() {
    if (_disposed || busy || failure == null) return;
    failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
