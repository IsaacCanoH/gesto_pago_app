class ChargeAccount {
  const ChargeAccount({required this.id, required this.lastFour});

  factory ChargeAccount.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException();
    final id = json['idCuenta'];
    final lastFour = json['ultimosDigitos'];
    if (id is! int ||
        id <= 0 ||
        lastFour is! String ||
        !_suffixPattern.hasMatch(lastFour)) {
      throw const FormatException();
    }
    return ChargeAccount(id: id, lastFour: lastFour);
  }

  static final _suffixPattern = RegExp(r'^[0-9]{4}$');

  final int id;
  final String lastFour;

  String get label => 'Cuenta •••• $lastFour';
}
