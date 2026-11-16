import '../../../core/network/api_client.dart';
import 'models/charge_account.dart';
import 'models/purchase_request.dart';
import 'models/purchase_result.dart';

typedef SubmitPurchase = Future<PurchaseResult> Function(
  PurchaseRequest request,
);

typedef LoadChargeAccounts = Future<List<ChargeAccount>> Function();

enum PurchaseField { account, pin }

class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message, {this.field});

  const PurchaseFailure.unknown()
    : this(
        'No pudimos confirmar el resultado del pago. Evita repetirlo hasta verificar el cargo.',
      );

  final String message;
  final PurchaseField? field;
}

class PurchasesRepository {
  const PurchasesRepository(this.client);
  final ApiClient client;

  Future<List<ChargeAccount>> loadAccounts(String token) async {
    final data = await client.get('cuentas/propias', token: token);
    final accounts = data['datos'];
    if (accounts is! List) {
      throw const ApiException('No pudimos leer tus cuentas.');
    }
    try {
      return List.unmodifiable(accounts.map(ChargeAccount.fromJson));
    } on FormatException {
      throw const ApiException('No pudimos leer tus cuentas.');
    }
  }

  Future<PurchaseResult> submit(String token, PurchaseRequest request) async {
    try {
      final data = await client.post(
        'pagos',
        request.toJson(),
        token: token,
        timeout: const Duration(seconds: 90),
      );
      return PurchaseResult.fromJson(data);
    } on ApiException catch (error) {
      throw switch ((error.statusCode, error.serverMessage)) {
        (401, _) => PurchaseFailure(error.message),
        (409, 'Saldo disponible insuficiente para realizar el pago') =>
          const PurchaseFailure(
            'Saldo insuficiente en tu cuenta.',
            field: PurchaseField.account,
          ),
        (404, 'Cuenta no encontrada') ||
        (409, 'La cuenta está inactiva') ||
        (403, 'No puedes pagar con una cuenta de otro cliente') =>
          PurchaseFailure(error.serverMessage!, field: PurchaseField.account),
        (403, 'PIN de autorización inválido') => const PurchaseFailure(
          'El PIN es incorrecto.',
          field: PurchaseField.pin,
        ),
        (429, 'PIN bloqueado temporalmente por intentos fallidos') ||
        (
          409,
          'El cliente debe configurar su PIN antes de realizar pagos',
        ) => PurchaseFailure(error.serverMessage!),
        _ => const PurchaseFailure.unknown(),
      };
    } on FormatException {
      throw const PurchaseFailure.unknown();
    }
  }
}
