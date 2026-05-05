import 'dart:io';

import 'package:unisalle/models/user.dart';

/// Lanzada cuando el usuario cancela voluntariamente un flujo OAuth.
/// No debe mostrarse como error en la UI.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Contrato común para todas las fuentes de autenticación.
///
/// IMPLEMENTACIONES:
///   - [MockAuthRepository]   — offline, sin red.
///   - [RemoteAuthRepository] — email/password contra el backend Node.js
///                              + OAuth Google/GitHub vía Firebase.
///
/// La inyección concreta vive en `authRepositoryProvider`
/// (`lib/features/auth/providers/auth_provider.dart`).
abstract class AuthRepository {
  Future<User> loginWithEmail(String email, String password);

  Future<User> registerWithEmail(String name, String email, String password);

  Future<User> loginWithGoogle();

  Future<User> loginWithGithub();

  Future<void> logout();

  /// Intenta restaurar la sesión a partir del JWT persistido en
  /// secure storage. Devuelve `null` si no hay token o el token ya no
  /// es válido (en cuyo caso la implementación limpia el token guardado).
  Future<User?> restoreSession();

  /// Sube una nueva imagen de perfil al backend y devuelve el usuario
  /// actualizado con la URL completa de la imagen. Solo soportado por
  /// la implementación remota — los flujos OAuth no exponen esto.
  Future<User> updateProfileImage(String userId, File image);
}
