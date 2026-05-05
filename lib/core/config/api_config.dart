import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración del backend Node.js (auth con email/password,
/// `/users/me`, upload de imagen).
///
/// Resolución de la URL base, en orden:
///   1. `--dart-define=API_BASE_URL=...` (o entrada `API_BASE_URL`
///      en `env/dev.json` consumido vía `--dart-define-from-file`).
///   2. Default por plataforma:
///      - Android emulator → `http://10.0.2.2:3000` (10.0.2.2 es el
///        loopback del host visto desde el emulador).
///      - iOS simulator / desktop / web → `http://localhost:3000`.
///
/// Para un dispositivo físico en LAN, sobreescribir con la IP del host:
///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`.
abstract class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  /// Prefijo común a todos los endpoints REST.
  static const String apiPrefix = '/api';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);
}
