// ============================================================
// FILE: auth_repository.dart
// PURPOSE: Contrato abstracto para todas las operaciones de auth.
//
// PATRÓN REPOSITORY:
//   La capa de UI (providers, screens) depende SOLO de esta
//   interfaz, nunca de la implementación concreta.
//   Esto permite:
//   - Cambiar de mock a real sin tocar la UI
//   - Testear con implementaciones fake controladas
//   - Implementar múltiples backends (Firebase, custom API, etc.)
//
// IMPLEMENTACIONES DISPONIBLES:
//   - MockAuthRepository  → offline, datos fijos, sin red
//   - RemoteAuthRepository → OAuth real (Google + GitHub)
//
// Para cambiar la implementación activa, edita authRepositoryProvider
// en lib/features/auth/providers/auth_provider.dart.
// ============================================================

import 'package:unisalle/models/user.dart';

/// Lanzada cuando el usuario cancela voluntariamente un flujo OAuth.
/// No debe mostrarse como error en la UI.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

abstract class AuthRepository {
  /// Autentica con email y contraseña.
  Future<User> loginWithEmail(String email, String password);

  /// Registra una nueva cuenta con email y contraseña.
  Future<User> registerWithEmail(String name, String email, String password);

  /// Autentica mediante Google Sign-In (OAuth 2.0).
  /// Abre el selector de cuentas nativo de Google.
  Future<User> loginWithGoogle();

  /// Autentica mediante GitHub OAuth 2.0 (Authorization Code Flow).
  /// Abre un browser in-app para el flujo de autorización.
  Future<User> loginWithGithub();

  /// Cierra la sesión y limpia los tokens locales.
  Future<void> logout();
}
