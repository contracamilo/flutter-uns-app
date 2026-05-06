import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

/// Implementación offline de `AuthRepository` para desarrollo y demos.
/// `fail@test.com` fuerza un error para validar el manejo de fallos.
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<Either<AuthFailure, User>> loginWithEmail(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'fail@test.com') {
      return const Left(InvalidCredentialsFailure());
    }
    if (!email.contains('@') || password.length < 6) {
      return const Left(
        ValidationFailure(
          'Email debe contener @ y la contraseña mínimo 6 caracteres',
        ),
      );
    }
    return Right(
      User(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, User>> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!email.contains('@')) {
      return const Left(ValidationFailure('Email no válido'));
    }
    if (password.length < 6) {
      return const Left(
        ValidationFailure('La contraseña debe tener al menos 6 caracteres'),
      );
    }
    return Right(
      User(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, User>> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const Right(
      User(
        id: 'mock-google-001',
        name: 'Google User (Mock)',
        email: 'googleuser@gmail.com',
      ),
    );
  }

  @override
  Future<Either<AuthFailure, User>> loginWithGithub() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const Right(
      User(
        id: 'mock-github-001',
        name: 'GitHub User (Mock)',
        email: 'githubuser@users.noreply.github.com',
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    return const Right(unit);
  }

  @override
  Future<Either<AuthFailure, User?>> restoreSession() async {
    return const Right(null);
  }

  @override
  Future<Either<AuthFailure, User>> updateProfileImage(
    String userId,
    File image,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(
      User(
        id: userId,
        name: 'Mock User',
        email: 'mock@example.com',
        photoUrl: 'https://placehold.co/200x200/png',
      ),
    );
  }
}
