import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.serverMessage,
    this.fieldErrors = const {},
    this.outcomeUnknown = false,
  });
  final String message;
  final int? statusCode;
  final String? serverMessage;
  final Map<String, String> fieldErrors;
  final bool outcomeUnknown;
}

class ApiClient {
  const ApiClient(this.baseUrl);
  final Uri? baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) => _request('POST', path, body: body, token: token, timeout: timeout);

  Future<Map<String, dynamic>> get(String path, {required String token}) =>
      _request('GET', path, token: token);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object>? body,
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (kIsWeb) {
      throw const ApiException('Abre Gesto Pago en Android para continuar.');
    }
    final base = baseUrl;
    if (base == null) {
      throw const ApiException(
        'Configura la dirección de la API para continuar.',
      );
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await _send(
        client,
        base,
        method,
        path,
        body,
        token,
      ).timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        'El servidor tardó en responder. Intenta de nuevo.',
        outcomeUnknown: method == 'POST',
      );
    } on IOException {
      throw ApiException(
        'No pudimos conectar. Revisa tu conexión e intenta de nuevo.',
        outcomeUnknown: method == 'POST',
      );
    } on FormatException {
      throw ApiException(
        'El servidor devolvió una respuesta inválida.',
        outcomeUnknown: method == 'POST',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _send(
    HttpClient client,
    Uri base,
    String method,
    String path,
    Map<String, Object>? body,
    String? token,
  ) async {
    final prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    final request = await client.openUrl(
      method,
      base.replace(path: '$prefix/$path'),
    );
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _readError(raw);
      throw _responseError(
        response.statusCode,
        authenticated: token != null,
        serverMessage: error.message,
        fieldErrors: error.fields,
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException();
  }

  ({String? message, Map<String, String> fields}) _readError(String raw) {
    try {
      final error = jsonDecode(raw);
      if (error is Map<String, dynamic> && error['codigo'] == 1) {
        final message = error['mensaje'];
        final errors = error['errores'];
        return (
          message: message is String ? message : null,
          fields: errors is Map
              ? Map.unmodifiable({
                  for (final entry in errors.entries)
                    if (entry.key is String && entry.value is String)
                      entry.key as String: entry.value as String,
                })
              : const {},
        );
      }
    } on FormatException {
      return (message: null, fields: const {});
    }
    return (message: null, fields: const {});
  }

  ApiException _responseError(
    int code, {
    required bool authenticated,
    required String? serverMessage,
    required Map<String, String> fieldErrors,
  }) {
    final message = switch (code) {
      400 =>
        authenticated
            ? 'La API no pudo procesar la solicitud.'
            : 'Revisa el correo y la contraseña.',
      401 =>
        authenticated
            ? 'Tu sesión ya no está activa. Inicia sesión de nuevo.'
            : 'El correo o la contraseña son incorrectos.',
      403 => 'La cuenta no tiene acceso. Verifica su estado.',
      429 => 'Espera un momento antes de intentar de nuevo.',
      _ => 'El servicio no está disponible. Intenta más tarde.',
    };
    return ApiException(
      message,
      statusCode: code,
      serverMessage: serverMessage,
      fieldErrors: fieldErrors,
    );
  }
}
