// ============================================================
// FILE: auth_provider.dart
// PURPOSE: Estado global de autenticación + inyección del repositorio.
//
// ARQUITECTURA:
//   AuthNotifier delega toda la lógica a AuthRepository.
//   El repositorio activo es RemoteAuthRepository, que combina:
//     • Backend Node.js (JWT) para email/password
//     • Firebase Auth para Google y GitHub OAuth
//
//   Para activar el modo mock (sin red, datos ficticios) cambia
//   `authRepositoryProvider` a `MockAuthRepository()`.
// ============================================================

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/network/api_client.dart';
import 'package:unisalle/features/auth/data/auth_repository.dart';
import 'package:unisalle/features/auth/data/backend_auth_service.dart';
import 'package:unisalle/features/auth/data/remote_auth_repository.dart';
import 'package:unisalle/models/user.dart';

// ── Servicios y dependencias ──────────────────────────────────────────────

final backendAuthServiceProvider = Provider<BackendAuthService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BackendAuthService(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(
    backendAuth: ref.watch(backendAuthServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// ── Auth notifier ─────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Restaura la sesión persistida (JWT en secure storage). Si no hay
    // token o el token está expirado, devuelve null y el router redirige
    // al flujo de welcome/login.
    return ref.read(authRepositoryProvider).restoreSession();
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
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Si el repositorio falla (ej. sin red), ignoramos el error.
      // El estado local se limpia de todas formas para que el router
      // siempre redirija a /welcome al pulsar el botón de cerrar sesión.
    }
    state = const AsyncData(null);
  }

  /// Sube una nueva imagen de perfil al backend y refresca el usuario
  /// expuesto por este notifier.
  Future<void> updateProfileImage(File image) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = await ref
        .read(authRepositoryProvider)
        .updateProfileImage(current.id, image);
    state = AsyncData(updated);
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
