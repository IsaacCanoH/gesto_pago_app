import '../../../core/network/api_client.dart';
import 'models/auth_session.dart';

class AuthRepository {
  const AuthRepository(this.client);
  final ApiClient client;

  Future<AuthSession> signIn(String email, String password) async {
    final response = await client.post('auth/login', {
      'correo': email,
      'contrasena': password,
    });
    try {
      return AuthSession.fromJson(response['datos']);
    } on FormatException {
      throw const ApiException(
        'No se pudo iniciar la sesión con la respuesta del servidor.',
      );
    }
  }
}
