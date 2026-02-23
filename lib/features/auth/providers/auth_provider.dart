import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/models/user.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (email == 'fail@test.com') {
        throw Exception('Credenciales incorrectas');
      }

      if (!email.contains('@') || password.length < 6) {
        throw Exception(
          'Email debe contener @ y la contraseña debe tener al menos 6 caracteres',
        );
      }

      return User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
      );
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!email.contains('@')) {
        throw Exception('Email no válido');
      }

      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      return User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
      );
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 1500));

      return User(
        id: 'google-user-001',
        name: 'Google User',
        email: 'googleuser@gmail.com',
      );
    });
  }

  Future<void> loginWithGithub() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 1500));

      return User(
        id: 'github-user-001',
        name: 'GitHub User',
        email: 'githubuser@users.noreply.github.com',
      );
    });
  }

  void logout() {
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
