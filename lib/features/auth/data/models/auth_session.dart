class AuthSession {
  const AuthSession({required this.token, required this.expiresAt});

  factory AuthSession.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException();
    final token = json['token'];
    final expiry = json['expiraEn'];
    final expiresAt = expiry is String ? DateTime.tryParse(expiry) : null;
    if (token is! String ||
        token.trim().isEmpty ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      throw const FormatException();
    }
    return AuthSession(token: token, expiresAt: expiresAt);
  }

  final String token;
  final DateTime expiresAt;
}
