import '../../../core/network/api_client.dart';
import 'models/managed_account.dart';

class AccountsRepository {
  const AccountsRepository(this.client);
  final ApiClient client;

  Future<List<ManagedAccount>> load(String token) async {
    final response = await client.get('cuentas/propias/gestion', token: token);
    final data = response['datos'];
    if (response['codigo'] != 0 || data is! List) throw _invalidResponse;

    try {
      return List.unmodifiable(data.map(ManagedAccount.fromJson));
    } on FormatException {
      throw _invalidResponse;
    }
  }

  Future<void> deactivate(String token, int idCuenta) async {
    try {
      final response = await client.post('cuentas/desactivar', {
        'idCuenta': idCuenta,
      }, token: token);
      if (response['codigo'] != 0) {
        throw const ApiException(
          'No pudimos confirmar la desactivación. Actualiza tus cuentas.',
        );
      }
    } on ApiException catch (failure) {
      final message = switch (failure.statusCode) {
        404 => 'La cuenta ya no está disponible. Actualiza tus cuentas.',
        409 => 'La cuenta debe tener saldo cero para desactivarla.',
        null => 'No pudimos confirmar la desactivación. Actualiza tus cuentas.',
        _ => failure.message,
      };
      throw ApiException(message, statusCode: failure.statusCode);
    }
  }

  static const _invalidResponse = ApiException('No pudimos leer tus cuentas.');
}
