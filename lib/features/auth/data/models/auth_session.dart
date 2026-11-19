class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    this.refreshToken,
    this.refreshExpiresAt,
  });

  factory AuthSession.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException();
    final token = json['token'];
    final expiresAt = _readDate(json['expiraEn']);
    final refresh = json['refreshToken'];
    final refreshExpiry = _readDate(json['refreshExpiraEn']);
    if (token is! String ||
        token.trim().isEmpty ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      throw const FormatException();
    }
    if ((refresh != null || json['refreshExpiraEn'] != null) &&
        (refresh is! String ||
            refresh.trim().isEmpty ||
            refreshExpiry == null ||
            !refreshExpiry.isAfter(DateTime.now()))) {
      throw const FormatException();
    }
    return AuthSession(
      token: token,
      expiresAt: expiresAt,
      refreshToken: refresh as String?,
      refreshExpiresAt: refreshExpiry,
    );
  }

  static DateTime? _readDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  final String token;
  final DateTime expiresAt;
  final String? refreshToken;
  final DateTime? refreshExpiresAt;

  DateTime get sessionExpiresAt => refreshExpiresAt ?? expiresAt;
}
