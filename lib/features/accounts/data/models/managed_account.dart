class ManagedAccount {
  const ManagedAccount({
    required this.id,
    required this.lastFour,
    required this.balance,
    required this.status,
  });

  factory ManagedAccount.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException();
    final id = json['idCuenta'];
    final suffix = json['ultimosDigitos'];
    final balance = json['saldo'];
    final status = json['estatus'];
    if (id is! int ||
        id <= 0 ||
        balance is! num ||
        !balance.isFinite ||
        status is! String ||
        status.isEmpty) {
      throw const FormatException();
    }
    return ManagedAccount(
      id: id,
      lastFour: suffix is String && _suffixPattern.hasMatch(suffix)
          ? suffix
          : null,
      balance: balance,
      status: status,
    );
  }

  static final _suffixPattern = RegExp(r'^[0-9]{4}$');

  final int id;
  final String? lastFour;
  final num balance;
  final String status;

  bool get isActive => status == 'ACTIVA';
  bool get canDeactivate => isActive && balance == 0;

  ManagedAccount asInactive() => ManagedAccount(
    id: id,
    lastFour: lastFour,
    balance: balance,
    status: 'INACTIVA',
  );

  String get label =>
      lastFour == null ? 'Cuenta de cargo' : 'Cuenta •••• $lastFour';
  String get money => '\$${balance.toStringAsFixed(2)} MXN';
}
