// ============================================================
// FILE: auth_provider_test.dart
// PURPOSE: Tests unitarios para AuthNotifier y providers derivados.
//
// QUÉ SE PRUEBA:
//   - Estado inicial del notifier
//   - Transiciones de estado en login / register / logout
//   - Que los argumentos llegan correctamente al repositorio
//   - Que logout limpia el estado con try/finally (aunque el repo falle)
//   - Proveedores derivados: isAuthenticatedProvider
//
// HERRAMIENTAS:
//   - ProviderContainer: crea un scope de Riverpod en tests sin widgets.
//   - overrides: inyecta FakeAuthRepository en lugar de RemoteAuthRepository.
//   - addTearDown: libera el container después de cada test.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisalle/features/auth/providers/auth_provider.dart';
import 'package:unisalle/models/user.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  group('AuthNotifier', () {
    late FakeAuthRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      // Libera el container y sus suscripciones al terminar cada test.
      addTearDown(container.dispose);
    });

    // ── Estado inicial ────────────────────────────────────────────────────

    test('estado inicial es AsyncData(null)', () async {
      // AsyncNotifier.build() devuelve un Future, así que el primer estado
      // es AsyncLoading hasta que el Future resuelva. Esperamos con .future.
      await container.read(authProvider.future);
      expect(container.read(authProvider), const AsyncData<User?>(null));
    });

    test('isAuthenticatedProvider empieza en false', () {
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    // ── login ─────────────────────────────────────────────────────────────

    group('login', () {
      test('éxito → AsyncData con el usuario devuelto por el repositorio',
          () async {
        final expected =
            User(id: 'u1', name: 'Ana', email: 'ana@test.com');
        repo.loginResult = expected;

        await container
            .read(authProvider.notifier)
            .login('ana@test.com', '123456');

        expect(container.read(authProvider), AsyncData<User?>(expected));
        expect(container.read(isAuthenticatedProvider), isTrue);
      });

      test('pasa el email y la contraseña exactos al repositorio', () async {
        await container
            .read(authProvider.notifier)
            .login('test@correo.com', 'pass123');

        expect(repo.lastLoginEmail, 'test@correo.com');
        expect(repo.lastLoginPassword, 'pass123');
        expect(repo.loginCallCount, 1);
      });

      test('error → AsyncError, isAuthenticated sigue en false', () async {
        repo.loginError = Exception('Email o contraseña incorrectos.');

        await container
            .read(authProvider.notifier)
            .login('x@test.com', 'wrong');

        final state = container.read(authProvider);
        expect(state.hasError, isTrue);
        expect(
          state.error.toString(),
          contains('Email o contraseña incorrectos.'),
        );
        expect(container.read(isAuthenticatedProvider), isFalse);
      });
    });

    // ── register ──────────────────────────────────────────────────────────

    group('register', () {
      test('éxito → AsyncData con nombre y email correctos', () async {
        await container
            .read(authProvider.notifier)
            .register('Ana', 'ana@test.com', '123456');

        final user = container.read(authProvider).value;
        expect(user?.name, 'Ana');
        expect(user?.email, 'ana@test.com');
        expect(container.read(isAuthenticatedProvider), isTrue);
      });

      test('error → AsyncError, no autenticado', () async {
        repo.registerError =
            Exception('Ya existe una cuenta con este email.');

        await container
            .read(authProvider.notifier)
            .register('Ana', 'existing@test.com', '123456');

        expect(container.read(authProvider).hasError, isTrue);
        expect(container.read(isAuthenticatedProvider), isFalse);
      });
    });

    // ── logout ────────────────────────────────────────────────────────────

    group('logout', () {
      // Cada test de este grupo parte de un usuario autenticado.
      setUp(() async {
        await container
            .read(authProvider.notifier)
            .login('user@test.com', '123456');
        expect(container.read(isAuthenticatedProvider), isTrue);
      });

      test('limpia el estado a AsyncData(null)', () async {
        await container.read(authProvider.notifier).logout();

        expect(container.read(authProvider), const AsyncData<User?>(null));
        expect(container.read(isAuthenticatedProvider), isFalse);
      });

      test('estado queda en null aunque el repositorio falle (catch + assign)',
          () async {
        // Simula un error de red al cerrar sesión en el backend.
        repo.logoutError = Exception('Error de red');

        // AuthNotifier.logout() captura el error internamente y NO lo
        // re-lanza: el usuario siempre queda deslogueado localmente.
        await container.read(authProvider.notifier).logout();

        expect(container.read(authProvider), const AsyncData<User?>(null));
        expect(container.read(isAuthenticatedProvider), isFalse);
      });

      test('llama al repositorio exactamente una vez', () async {
        await container.read(authProvider.notifier).logout();

        expect(repo.logoutCallCount, 1);
      });
    });

    // ── proveedores sociales ──────────────────────────────────────────────

    test('loginWithGoogle → usuario autenticado con email de Google', () async {
      await container.read(authProvider.notifier).loginWithGoogle();

      expect(container.read(authProvider).value?.email, 'google@test.com');
      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    test('loginWithGithub → usuario autenticado con email de GitHub', () async {
      await container.read(authProvider.notifier).loginWithGithub();

      expect(container.read(authProvider).value?.email, 'github@test.com');
      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    // ── restoreSession ────────────────────────────────────────────────────

    group('restoreSession (build inicial)', () {
      test('sin token guardado → AsyncData(null)', () async {
        // FakeAuthRepository.restoreSession() devuelve null por defecto.
        await container.read(authProvider.future);
        expect(container.read(authProvider), const AsyncData<User?>(null));
      });

      test('con token válido → usuario autenticado al arrancar', () async {
        final restored =
            User(id: 'u9', name: 'Restored', email: 'r@test.com');
        repo.restoreSessionResult = restored;

        // Recreamos el container para forzar build() con el resultado nuevo.
        container.dispose();
        container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        await container.read(authProvider.future);
        expect(container.read(authProvider).value, restored);
        expect(container.read(isAuthenticatedProvider), isTrue);
        expect(repo.restoreSessionCallCount, 1);
      });
    });
  });
}
