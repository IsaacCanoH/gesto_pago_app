import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_challenge.dart';
import '../../data/models/auth_session.dart';

class TwoFactorViewModel extends ChangeNotifier {
  TwoFactorViewModel(this.repository, this._challenge) {
    if (!expired) _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  final AuthRepository repository;
  AuthChallenge _challenge;
  Timer? _timer;
  bool _disposed = false;

  bool verifying = false;
  bool resending = false;
  bool _invalidated = false;
  String? error;
  String? notice;

  bool get busy => verifying || resending;

  bool get expired => !_challenge.expiresAt.isAfter(DateTime.now());

  int get resendWaitSeconds {
    final milliseconds = _challenge.resendAt
        .difference(DateTime.now())
        .inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  }

  bool get needsNewLogin => expired || _invalidated;

  bool get canVerify => !busy && !needsNewLogin;
  bool get canResend => canVerify && resendWaitSeconds == 0;

  void clearError() {
    if (error == null || _invalidated) return;
    error = null;
    notifyListeners();
  }

  Future<AuthSession?> verify(String code) async {
    if (!canVerify) return null;
    notice = null;
    if (!_codePattern.hasMatch(code)) {
      error = 'Ingresa los seis dígitos del código.';
      notifyListeners();
      return null;
    }

    verifying = true;
    error = null;
    notifyListeners();
    try {
      return await repository.verify(_challenge.id, code);
    } on ApiException catch (failure) {
      _invalidated = failure.statusCode == 429;
      error = switch (failure.statusCode) {
        400 => 'Revisa el código de verificación e inténtalo de nuevo.',
        401 => 'El código es incorrecto o la verificación ya no está activa.',
        429 => 'Agotaste los intentos. Vuelve a iniciar sesión.',
        _ => failure.message,
      };
      return null;
    } finally {
      verifying = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> resend() async {
    if (!canResend) return false;
    resending = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      _challenge = await repository.resend(_challenge.id);
      notice = 'Enviamos un código nuevo a tu correo.';
      return true;
    } on ApiException catch (failure) {
      _invalidated = failure.statusCode == 400 || failure.statusCode == 401;
      error = switch (failure.statusCode) {
        400 ||
        401 => 'La verificación ya no está activa. Vuelve a iniciar sesión.',
        429 => 'Espera un momento antes de solicitar otro código.',
        _ => failure.message,
      };
      return false;
    } finally {
      resending = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _onTick(Timer timer) {
    if (needsNewLogin) timer.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  static final _codePattern = RegExp(r'^[0-9]{6}$');
}
