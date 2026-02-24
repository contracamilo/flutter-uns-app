// ============================================================
// FILE: auth_provider.dart
// PURPOSE: Estado global de autenticación y punto de inyección
//          del repositorio de auth.
//
// ARQUITECTURA:
//   AuthNotifier ya no contiene lógica de negocio — delega
//   todas las operaciones a AuthRepository. Esto permite:
//   - Cambiar de mock a real cambiando UNA línea (authRepositoryProvider)
//   - Testear AuthNotifier inyectando un repo fake
//
// PARA CAMBIAR LA IMPLEMENTACIÓN:
//   En authRepositoryProvider, cambia:
//     MockAuthRepository()    → desarrollo/testing sin red
//     RemoteAuthRepository()  → OAuth real (Google + GitHub)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/features/auth/data/auth_repository.dart';
// import 'package:unisalle/features/auth/data/mock_auth_repository.dart'; // Activa para desarrollo sin red
import 'package:unisalle/features/auth/data/remote_auth_repository.dart';
import 'package:unisalle/models/user.dart';

// ── Repository provider ───────────────────────────────────────────────────
//
// Punto único de inyección de la implementación de auth.
//
// Cambia la implementación aquí para alternar entre mock y real:
//   MockAuthRepository()   — sin red, datos ficticios (desarrollo)
//   RemoteAuthRepository() — OAuth real (producción / integración)
//
// ⚠️ RemoteAuthRepository.loginWithEmail y .registerWithEmail lanzan
//    UnimplementedError hasta que el backend esté conectado.
//    Usa MockAuthRepository para desarrollo de UI con email/password.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository();
});

// ── Auth notifier ─────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Estado inicial: no autenticado.
    // TODO: Aquí podrías restaurar la sesión guardada localmente
    //   (shared_preferences, flutter_secure_storage, etc.) para
    //   mantener al usuario logueado entre reinicios de la app.
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).loginWithEmail(email, password),
    );
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).registerWithEmail(
            name,
            email,
            password,
          ),
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).loginWithGoogle(),
    );
  }

  Future<void> loginWithGithub() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).loginWithGithub(),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

// ── Providers públicos ────────────────────────────────────────────────────

/// Estado de autenticación: AsyncData(user) | AsyncData(null) | AsyncLoading | AsyncError
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

/// Derivado: true si el usuario está autenticado.
/// Usado por el router para el auth guard.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
