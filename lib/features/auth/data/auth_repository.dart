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

  Future<AuthSession> refresh(String refreshToken) async {
    final response = await client.post('auth/refresh', {
      'refreshToken': refreshToken,
    });
    try {
      return AuthSession.fromJson(response['datos']);
    } on FormatException {
      throw const ApiException('No pudimos leer la renovación de sesión.');
    }
  }

  Future<void> signOut(String token) async {
    try {
      final response = await client.post('auth/logout', {}, token: token);
      if (response['codigo'] != 0) {
        throw const ApiException('No pudimos confirmar el cierre de sesión.');
      }
    } on ApiException catch (failure) {
      if (failure.statusCode != 401) rethrow;
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
