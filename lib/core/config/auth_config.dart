// ============================================================
// FILE: auth_config.dart
// PURPOSE: Centralized OAuth configuration constants.
//
// CREDENCIALES:
//   Los valores sensibles se inyectan en tiempo de compilación
//   mediante --dart-define-from-file y NO viven en el código fuente.
//
//   Archivo de valores: env/dev.json  (gitignored)
//   Plantilla:          env/dev.json.example  (committed)
//
//   Para correr la app:
//     flutter run --dart-define-from-file=env/dev.json
//
//   VS Code: ya configurado en .vscode/launch.json
//
// SEGURIDAD:
//   - client_secret de GitHub NUNCA va en el cliente.
//   - client_id es público por diseño (aparece en la URL de OAuth).
//   - Firebase API keys son identificadores de proyecto, no secretos.
//     Se protegen con restricciones en Google Cloud Console.
// ============================================================

/// Configuración para Google Sign-In.
///
/// El Client ID es leído automáticamente desde los archivos de plataforma:
///   iOS:     ios/Runner/GoogleService-Info.plist  (gitignored)
///   Android: android/app/google-services.json     (gitignored)
abstract class GoogleAuthConfig {
  /// Scopes solicitados al usuario de Google.
  static const List<String> scopes = ['email', 'profile'];
}

/// Configuración para GitHub OAuth 2.0 (Authorization Code Flow).
abstract class GithubAuthConfig {
  /// Client ID de la GitHub OAuth App.
  ///
  /// Valor inyectado desde env/dev.json via --dart-define-from-file.
  /// Si está vacío, el botón de GitHub estará deshabilitado en la UI.
  ///
  /// Para obtenerlo:
  ///   1. github.com/settings/developers → New OAuth App
  ///   2. Authorization callback URL: unisalle://auth/callback
  ///   3. Copia el Client ID en env/dev.json → "GITHUB_CLIENT_ID"
  static const String clientId = String.fromEnvironment('GITHUB_CLIENT_ID');

  /// true si el Client ID fue provisto correctamente.
  /// Usado para deshabilitar el botón de GitHub si falta la config.
  static bool get isConfigured => clientId.isNotEmpty;

  /// URL scheme del callback (debe coincidir con iOS Info.plist,
  /// AndroidManifest.xml y la config de la GitHub OAuth App).
  static const String callbackScheme = 'unisalle';

  /// URI completo de redirección registrado en GitHub OAuth App.
  static const String redirectUri = '$callbackScheme://auth/callback';

  /// Permisos solicitados a GitHub.
  static const String scope = 'read:user user:email';
}
