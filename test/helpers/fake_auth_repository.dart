// ============================================================
// FILE: fake_auth_repository.dart
// PURPOSE: Implementación fake de `AuthRepository` (contrato Domain)
//          para tests. Devuelve `Either<AuthFailure, T>` controlados.
// ============================================================

import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  // ── Respuestas configurables ─────────────────────────────────────────────
  User? loginResult;
  User? registerResult;

  AuthFailure? loginFailure;
  AuthFailure? registerFailure;
  AuthFailure? logoutFailure;

  // ── Registro de interacciones ────────────────────────────────────────────
  int loginCallCount = 0;
  String? lastLoginEmail;
  String? lastLoginPassword;

  int registerCallCount = 0;
  String? lastRegisterName;
  String? lastRegisterEmail;
  String? lastRegisterPassword;

  int logoutCallCount = 0;

  User? restoreSessionResult;
  int restoreSessionCallCount = 0;

  User? updateImageResult;
  int updateImageCallCount = 0;
  String? lastUpdateImageUserId;

  // ── Implementación ───────────────────────────────────────────────────────

  @override
  Future<Either<AuthFailure, User>> loginWithEmail(
    String email,
    String password,
  ) async {
    loginCallCount++;
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (loginFailure != null) return Left(loginFailure!);
    return Right(
      loginResult ?? User(id: 'fake-id', name: 'Test User', email: email),
    );
  }

  @override
  Future<Either<AuthFailure, User>> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    registerCallCount++;
    lastRegisterName = name;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    if (registerFailure != null) return Left(registerFailure!);
    return Right(
      registerResult ?? User(id: 'fake-id', name: name, email: email),
    );
  }

  @override
  Future<Either<AuthFailure, User>> loginWithGoogle() async {
    return const Right(
      User(id: 'google-id', name: 'Google User', email: 'google@test.com'),
    );
  }

  @override
  Future<Either<AuthFailure, User>> loginWithGithub() async {
    return const Right(
      User(id: 'github-id', name: 'GitHub User', email: 'github@test.com'),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    logoutCallCount++;
    if (logoutFailure != null) return Left(logoutFailure!);
    return const Right(unit);
  }

  @override
  Future<Either<AuthFailure, User?>> restoreSession() async {
    restoreSessionCallCount++;
    return Right(restoreSessionResult);
  }

  @override
  Future<Either<AuthFailure, User>> updateProfileImage(
    String userId,
    File image,
  ) async {
    updateImageCallCount++;
    lastUpdateImageUserId = userId;
    return Right(
      updateImageResult ??
          User(id: userId, name: 'Test User', email: 'fake@test.com'),
    );
  }
}
