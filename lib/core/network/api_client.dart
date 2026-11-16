import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
}

class ApiClient {
  const ApiClient(this.baseUrl);
  final Uri? baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, String> body,
  ) async {
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
      return await _post(
        client,
        base,
        path,
        body,
      ).timeout(const Duration(seconds: 15));
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

  Future<Map<String, dynamic>> _post(
    HttpClient client,
    Uri base,
    String path,
    Map<String, String> body,
  ) async {
    final prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    final request = await client.postUrl(base.replace(path: '$prefix/$path'));
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(jsonEncode(body));
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();
    switch (response.statusCode) {
      case 200:
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const FormatException();
      case 401:
        throw const ApiException('El correo o la contraseña son incorrectos.');
      case 403:
        throw const ApiException(
          'La cuenta no tiene acceso. Verifica su estado.',
        );
      case 400:
        throw const ApiException('Revisa el correo y la contraseña.');
      case 429:
        throw const ApiException(
          'Espera un momento antes de intentar de nuevo.',
        );
      default:
        throw const ApiException(
          'El servicio no está disponible. Intenta más tarde.',
        );
    }
  }
}
