import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_session.dart';

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this.repository);

  final AuthRepository repository;
  AuthSession? current;
  String? initialToken;
  String? notice;
  String? logoutError;
  bool closing = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _expiry;
  Future<AuthSession>? _refreshing;

  void start(AuthSession session) {
    _generation++;
    _expiry?.cancel();
    current = session;
    initialToken = session.token;
    notice = null;
    logoutError = null;
    closing = false;
    _refreshing = null;
    _expiry = Timer(
      session.sessionExpiresAt.difference(DateTime.now()),
      checkExpiry,
    );
    notifyListeners();
  }

  void clear({String? message}) {
    _generation++;
    _expiry?.cancel();
    _refreshing = null;
    current = null;
    initialToken = null;
    notice = message;
    closing = false;
    logoutError = null;
    if (!_disposed) notifyListeners();
  }

  void checkExpiry() {
    final session = current;
    if (session != null && !session.sessionExpiresAt.isAfter(DateTime.now())) {
      clear(message: 'Tu sesión terminó. Inicia sesión de nuevo.');
    }
  }

  void reject(String sourceToken) {
    if (sourceToken == initialToken) {
      clear(message: 'Tu sesión terminó. Inicia sesión de nuevo.');
    }
  }

  Future<String> tokenForRequest(String sourceToken, {String? rejectedToken}) {
    if (closing) {
      throw const ApiException('Se está cerrando la sesión.', statusCode: 409);
    }
    return _accessToken(sourceToken, rejectedToken: rejectedToken);
  }

  Future<String> _accessToken(
    String sourceToken, {
    String? rejectedToken,
  }) async {
    checkExpiry();
    final session = current;
    if (_disposed || session == null || initialToken != sourceToken) {
      throw _expired;
    }
    final now = DateTime.now();
    final threshold = session.refreshToken == null
        ? now
        : now.add(const Duration(seconds: 30));
    if (session.expiresAt.isAfter(threshold) &&
        session.token != rejectedToken) {
      return session.token;
    }

    var operation = _refreshing;
    if (operation == null) {
      operation = _renew(session, _generation);
      _refreshing = operation;
    }
    try {
      return (await operation).token;
    } finally {
      if (identical(_refreshing, operation)) _refreshing = null;
    }
  }

  Future<AuthSession> _renew(AuthSession session, int generation) async {
    try {
      final refresh = session.refreshToken;
      if (refresh == null) throw _expired;
      final renewed = await repository.refresh(refresh);
      if (_disposed || generation != _generation) throw _expired;
      final expiry = session.refreshExpiresAt;
      final newExpiry = renewed.refreshExpiresAt;
      if (renewed.refreshToken == null ||
          expiry == null ||
          newExpiry == null ||
          !newExpiry.isAtSameMomentAs(expiry)) {
        throw const ApiException('La respuesta de renovación es inválida.');
      }
      current = renewed;
      notifyListeners();
      return renewed;
    } on ApiException {
      if (!_disposed && generation == _generation) {
        clear(message: 'No pudimos renovar tu sesión. Inicia sesión de nuevo.');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final sourceToken = initialToken;
    if (sourceToken == null || closing) return;
    final generation = _generation;
    closing = true;
    logoutError = null;
    notifyListeners();
    try {
      final token = await _accessToken(sourceToken);
      await repository.signOut(token);
      if (!_disposed && generation == _generation) clear();
    } on ApiException {
      if (!_disposed && generation == _generation) {
        logoutError =
            'No pudimos cerrar la sesión en el servidor. '
            'Revisa tu conexión y vuelve a pulsar Cerrar sesión.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        closing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    super.dispose();
  }

  static const _expired = ApiException(
    'Tu sesión ya no está activa. Inicia sesión de nuevo.',
    statusCode: 401,
  );
}
