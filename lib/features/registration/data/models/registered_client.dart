class RegisteredClient {
  const RegisteredClient({
    required this.id,
    required this.accountEnding,
    required this.initialBalance,
  });

  final int id;
  final String accountEnding;
  final num initialBalance;

  factory RegisteredClient.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException();
    final id = json['clienteId'];
    final account = json['numeroCuenta'];
    final balance = json['saldoInicial'];
    if (id is! int ||
        id <= 0 ||
        account is! String ||
        !RegExp(r'^[0-9]{20}$').hasMatch(account) ||
        balance is! num ||
        !balance.isFinite ||
        balance < 0) {
      throw const FormatException();
    }
    return RegisteredClient(
      id: id,
      accountEnding: account.substring(account.length - 4),
      initialBalance: balance,
    );
  }

  String get money => '\$${initialBalance.toStringAsFixed(2)} MXN';
}
