import 'package:flutter/foundation.dart';

class ApiConfig {
  static Uri? get baseUrl {
    const value = String.fromEnvironment('API_BASE_URL');
    if (value.isEmpty &&
        kDebugMode &&
        defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse('http://10.0.2.2:8080');
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri.scheme == 'https' || (kDebugMode && uri.scheme == 'http')
        ? uri
        : null;
  }
}
