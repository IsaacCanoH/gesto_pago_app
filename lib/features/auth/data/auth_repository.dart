import '../../../core/network/api_client.dart';
import 'models/auth_challenge.dart';
import 'models/auth_session.dart';

class AuthRepository {
  const AuthRepository(this.client);
  final ApiClient client;

  Future<AuthChallenge> signIn(String email, String password) async {
    final response = await client.post('auth/login', {
      'correo': email,
      'contrasena': password,
    });
    return _readChallenge(response);
  }

  Future<AuthChallenge> resend(String id) async {
    final response = await client.post('auth/2fa/reenviar', {
      'idVerificacion': id,
    });
    return _readChallenge(response);
  }

  Future<AuthSession> verify(String id, String code) async {
    final response = await client.post('auth/2fa/verificar', {
      'idVerificacion': id,
      'codigo': code,
    });
    try {
      return AuthSession.fromJson(response['datos']);
    } on FormatException {
      throw const ApiException('No pudimos leer la sesión del servidor.');
    }
  }

  AuthChallenge _readChallenge(Map<String, dynamic> response) {
    try {
      return AuthChallenge.fromJson(response['datos']);
    } on FormatException {
      throw const ApiException('No pudimos leer la verificación del servidor.');
    }
  }
}
