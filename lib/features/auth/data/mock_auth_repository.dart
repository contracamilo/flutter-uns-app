// ============================================================
// FILE: mock_auth_repository.dart
// PURPOSE: Implementación de AuthRepository con datos ficticios.
//
// CUÁNDO USAR:
//   - Durante el desarrollo de UI antes de tener un backend
//   - En tests unitarios y de widgets
//   - Para demos y presentaciones sin credenciales reales
//
// COMPORTAMIENTO:
//   - Simula latencia de red con Future.delayed
//   - fail@test.com fuerza un error para probar el manejo de errores
//   - Google y GitHub devuelven usuarios predefinidos
// ============================================================

import 'package:unisalle/features/auth/data/auth_repository.dart';
import 'package:unisalle/models/user.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<User> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'fail@test.com') {
      throw Exception('Credenciales incorrectas');
    }
    if (!email.contains('@') || password.length < 6) {
      throw Exception(
        'Email debe contener @ y la contraseña mínimo 6 caracteres',
      );
    }

    return User(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      email: email,
    );
  }

  @override
  Future<User> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!email.contains('@')) throw Exception('Email no válido');
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    return User(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
  }

  @override
  Future<User> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const User(
      id: 'mock-google-001',
      name: 'Google User (Mock)',
      email: 'googleuser@gmail.com',
    );
  }

  @override
  Future<User> loginWithGithub() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const User(
      id: 'mock-github-001',
      name: 'GitHub User (Mock)',
      email: 'githubuser@users.noreply.github.com',
    );
  }

  @override
  Future<void> logout() async {
    // Nada que limpiar en el mock
  }
}
