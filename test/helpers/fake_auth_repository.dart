// ============================================================
// FILE: fake_auth_repository.dart
// PURPOSE: Implementación fake de AuthRepository para tests.
//
// PATRÓN: Test Double (Fake)
//   Un Fake es una implementación simplificada pero funcional
//   de una dependencia. Permite:
//   - Controlar exactamente qué devuelve cada método
//   - Simular errores de red, auth o servidor
//   - Verificar qué argumentos se pasaron (interaction testing)
//   - Ejecutar tests sin Firebase ni red
// ============================================================

import 'dart:io';

import 'package:unisalle/features/auth/data/auth_repository.dart';
import 'package:unisalle/models/user.dart';

class FakeAuthRepository implements AuthRepository {
  // ── Respuestas configurables ─────────────────────────────────────────────
  //
  // Establece estos valores antes de llamar al método que quieres probar.
  // Si son null, se devuelve un usuario genérico / se completa sin error.

  User? loginResult;
  User? registerResult;

  // Errores configurables: si no son null, el método correspondiente lanza.
  Exception? loginError;
  Exception? registerError;
  Exception? logoutError;

  // ── Registro de interacciones ────────────────────────────────────────────
  //
  // Útil para verificar que la UI pasó los argumentos correctos.

  int loginCallCount = 0;
  String? lastLoginEmail;
  String? lastLoginPassword;

  int logoutCallCount = 0;

  // ── Implementación ───────────────────────────────────────────────────────

  @override
  Future<User> loginWithEmail(String email, String password) async {
    loginCallCount++;
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (loginError != null) throw loginError!;
    return loginResult ?? User(id: 'fake-id', name: 'Test User', email: email);
  }

  @override
  Future<User> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    if (registerError != null) throw registerError!;
    return registerResult ?? User(id: 'fake-id', name: name, email: email);
  }

  @override
  Future<User> loginWithGoogle() async =>
      User(id: 'google-id', name: 'Google User', email: 'google@test.com');

  @override
  Future<User> loginWithGithub() async =>
      User(id: 'github-id', name: 'GitHub User', email: 'github@test.com');

  @override
  Future<void> logout() async {
    logoutCallCount++;
    if (logoutError != null) throw logoutError!;
  }

  // ── Restaurar sesión / actualizar imagen ────────────────────────────────

  User? restoreSessionResult;
  int restoreSessionCallCount = 0;

  User? updateImageResult;
  int updateImageCallCount = 0;
  String? lastUpdateImageUserId;

  @override
  Future<User?> restoreSession() async {
    restoreSessionCallCount++;
    return restoreSessionResult;
  }

  @override
  Future<User> updateProfileImage(String userId, File image) async {
    updateImageCallCount++;
    lastUpdateImageUserId = userId;
    return updateImageResult ??
        User(id: userId, name: 'Test User', email: 'fake@test.com');
  }
}
