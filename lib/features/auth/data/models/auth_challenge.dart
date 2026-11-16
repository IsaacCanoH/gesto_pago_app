class AuthChallenge {
  const AuthChallenge({
    required this.id,
    required this.expiresAt,
    required this.resendAt,
  });

  factory AuthChallenge.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException();
    final id = json['idVerificacion'];
    final expiresAt = _readDate(json['expiraEn']);
    final resendAt = _readDate(json['reenviarDesde']);
    if (id is! String ||
        id.trim().isEmpty ||
        expiresAt == null ||
        resendAt == null) {
      throw const FormatException();
    }
    return AuthChallenge(id: id, expiresAt: expiresAt, resendAt: resendAt);
  }

  static DateTime? _readDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  final String id;
  final DateTime expiresAt;
  final DateTime resendAt;
}
