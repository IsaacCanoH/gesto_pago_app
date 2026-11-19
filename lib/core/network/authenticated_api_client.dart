import 'api_client.dart';

typedef SessionTokenProvider = Future<String> Function(
  String sourceToken, {
  String? rejectedToken,
});

class AuthenticatedApiClient extends ApiClient {
  AuthenticatedApiClient(this.transport, this.tokenProvider, this.onRejected)
    : super(transport.baseUrl);

  final ApiClient transport;
  final SessionTokenProvider tokenProvider;
  final void Function(String sourceToken) onRejected;

  @override
  Future<Map<String, dynamic>> get(String path, {required String token}) =>
      _authenticated(token, (access) => transport.get(path, token: access));

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) {
    if (token == null) return transport.post(path, body, timeout: timeout);
    return _authenticated(
      token,
      (access) => transport.post(path, body, token: access, timeout: timeout),
    );
  }

  Future<Map<String, dynamic>> _authenticated(
    String sourceToken,
    Future<Map<String, dynamic>> Function(String access) request,
  ) async {
    final access = await tokenProvider(sourceToken);
    try {
      return await request(access);
    } on ApiException catch (failure) {
      if (failure.statusCode != 401) rethrow;
    }

    final renewed = await tokenProvider(sourceToken, rejectedToken: access);
    try {
      return await request(renewed);
    } on ApiException catch (failure) {
      if (failure.statusCode == 401) onRejected(sourceToken);
      rethrow;
    }
  }
}
