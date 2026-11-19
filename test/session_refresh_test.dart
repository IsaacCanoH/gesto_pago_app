import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/core/network/authenticated_api_client.dart';
import 'package:gesto_pago_app/features/auth/data/auth_repository.dart';
import 'package:gesto_pago_app/features/auth/data/models/auth_session.dart';
import 'package:gesto_pago_app/features/auth/presentation/view_models/session_view_model.dart';

void main() {
  test(
    'coordina peticiones simultáneas y cierra usando el acceso renovado',
    () async {
      final auth = _RefreshRepository();
      final sessions = SessionViewModel(auth);
      addTearDown(sessions.dispose);
      final transport = _Transport();
      final client = AuthenticatedApiClient(
        transport,
        sessions.tokenForRequest,
        sessions.reject,
      );
      final expiry = DateTime.now().toUtc().add(const Duration(days: 7));
      sessions.start(_session('anterior', 'refresh-1', expiry, expired: true));

      final requests = List.generate(
        3,
        (_) => client.get('cuentas/propias', token: 'anterior'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(auth.refreshRequests, ['refresh-1']);
      expect(transport.accesses, isEmpty);
      auth.response.complete(_session('nuevo', 'refresh-2', expiry));
      await Future.wait(requests);
      expect(transport.accesses, ['nuevo', 'nuevo', 'nuevo']);
      expect(
        await sessions.tokenForRequest('anterior', rejectedToken: 'anterior'),
        'nuevo',
      );
      expect(auth.refreshRequests, ['refresh-1']);

      await sessions.signOut();
      expect(auth.logoutTokens, ['nuevo']);
      expect(sessions.current, isNull);
    },
  );

  test(
    'renueva una vez tras un 401 y termina si el servidor vuelve a rechazar',
    () async {
      final auth = _RefreshRepository();
      final sessions = SessionViewModel(auth);
      addTearDown(sessions.dispose);
      final transport = _Transport()..rejectAll = true;
      final client = AuthenticatedApiClient(
        transport,
        sessions.tokenForRequest,
        sessions.reject,
      );
      final expiry = DateTime.now().toUtc().add(const Duration(days: 7));
      sessions.start(_session('anterior', 'refresh-1', expiry));
      auth.response.complete(_session('nuevo', 'refresh-2', expiry));

      await expectLater(
        client.get('cuentas/propias', token: 'anterior'),
        throwsA(isA<ApiException>()),
      );
      expect(transport.accesses, ['anterior', 'nuevo']);
      expect(auth.refreshRequests, ['refresh-1']);
      expect(sessions.current, isNull);
    },
  );

  test('no repite un pago al perder la conexión con el servidor', () async {
    final auth = _RefreshRepository();
    final sessions = SessionViewModel(auth);
    addTearDown(sessions.dispose);
    final transport = _Transport();
    final client = AuthenticatedApiClient(
      transport,
      sessions.tokenForRequest,
      sessions.reject,
    );
    final expiry = DateTime.now().toUtc().add(const Duration(days: 7));
    sessions.start(_session('anterior', 'refresh-1', expiry));

    await expectLater(
      client.post('pagos', {'idCuenta': 7}, token: 'anterior'),
      throwsA(isA<ApiException>()),
    );
    expect(transport.payments, 1);
    expect(auth.refreshRequests, isEmpty);
    expect(sessions.current, isNotNull);
  });

  test(
    'una respuesta perdida de refresh exige volver a iniciar sesión',
    () async {
      final auth = _RefreshRepository();
      final sessions = SessionViewModel(auth);
      addTearDown(sessions.dispose);
      final expiry = DateTime.now().toUtc().add(const Duration(days: 7));
      sessions.start(_session('anterior', 'refresh-1', expiry, expired: true));
      final request = sessions.tokenForRequest('anterior');
      auth.response.completeError(
        const ApiException('Tiempo de espera agotado'),
      );
      await expectLater(request, throwsA(isA<ApiException>()));
      expect(sessions.current, isNull);
      await expectLater(
        sessions.tokenForRequest('anterior'),
        throwsA(isA<ApiException>()),
      );
      expect(auth.refreshRequests, ['refresh-1']);
    },
  );

  test('una renovación atrasada no reemplaza una sesión nueva', () async {
    final auth = _RefreshRepository();
    final sessions = SessionViewModel(auth);
    addTearDown(sessions.dispose);
    final expiry = DateTime.now().toUtc().add(const Duration(days: 7));
    sessions.start(_session('anterior', 'refresh-1', expiry, expired: true));
    final request = sessions.tokenForRequest('anterior');
    sessions.start(_session('otra-sesion', 'otro-refresh', expiry));
    auth.response.complete(_session('nuevo', 'refresh-2', expiry));
    await expectLater(request, throwsA(isA<ApiException>()));
    expect(sessions.current?.token, 'otra-sesion');
  });
}

AuthSession _session(
  String token,
  String refresh,
  DateTime expiry, {
  bool expired = false,
}) => AuthSession(
  token: token,
  expiresAt: DateTime.now().toUtc().add(Duration(minutes: expired ? -1 : 10)),
  refreshToken: refresh,
  refreshExpiresAt: expiry,
);

class _RefreshRepository extends AuthRepository {
  _RefreshRepository() : super(const ApiClient(null));
  final response = Completer<AuthSession>();
  final refreshRequests = <String>[];
  final logoutTokens = <String>[];

  @override
  Future<AuthSession> refresh(String token) {
    refreshRequests.add(token);
    return response.future;
  }

  @override
  Future<void> signOut(String token) async {
    logoutTokens.add(token);
  }
}

class _Transport extends ApiClient {
  _Transport() : super(null);
  final accesses = <String>[];
  bool rejectAll = false;
  int payments = 0;

  @override
  Future<Map<String, dynamic>> get(String path, {required String token}) async {
    accesses.add(token);
    if (rejectAll) throw const ApiException('Sesión inválida', statusCode: 401);
    return {'codigo': 0, 'datos': []};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    expect(path, 'pagos');
    payments++;
    throw const ApiException('Se perdió la conexión');
  }
}
