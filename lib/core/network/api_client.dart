import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.serverMessage});
  final String message;
  final int? statusCode;
  final String? serverMessage;
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
      throw const ApiException(
        'Abre Gesto Pago en Android para iniciar sesión.',
      );
    }
    final base = baseUrl;
    if (base == null) {
      throw const ApiException(
        'Configura la dirección de la API para iniciar sesión.',
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
      throw const ApiException(
        'El servidor tardó en responder. Intenta de nuevo.',
      );
    } on IOException {
      throw const ApiException(
        'No pudimos conectar. Revisa tu conexión e intenta de nuevo.',
      );
    } on FormatException {
      throw const ApiException('El servidor devolvió una respuesta inválida.');
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
    if (response.statusCode != 200) {
      throw _responseError(
        response.statusCode,
        authenticated: token != null,
        serverMessage: _readErrorMessage(raw),
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException();
  }

  String? _readErrorMessage(String raw) {
    try {
      final error = jsonDecode(raw);
      if (error is Map<String, dynamic> && error['codigo'] == 1) {
        final message = error['mensaje'];
        if (message is String) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  ApiException _responseError(
    int code, {
    required bool authenticated,
    required String? serverMessage,
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
    );
  }
}
