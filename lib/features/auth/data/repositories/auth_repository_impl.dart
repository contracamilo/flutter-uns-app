import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/network/api_exceptions.dart';
import 'package:unisalle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:unisalle/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

/// Implementación de `AuthRepository` que orquesta los `DataSource`s y
/// traduce excepciones a `AuthFailure` para que las capas superiores
/// nunca tengan que hacer try/catch.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FirebaseAuthDataSource firebaseDataSource,
    required TokenStorage tokenStorage,
  })  : _remote = remoteDataSource,
        _firebase = firebaseDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final FirebaseAuthDataSource _firebase;
  final TokenStorage _tokenStorage;

  // ── Email / Password ────────────────────────────────────────────────────

  @override
  Future<Either<AuthFailure, User>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final session = await _remote.login(email, password);
      await _tokenStorage.save(session.token);
      return Right(session.user);
    } on DioException catch (e) {
      return Left(_mapBackendError(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<AuthFailure, User>> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final session = await _remote.register(name, email, password);
      await _tokenStorage.save(session.token);
      return Right(session.user);
    } on DioException catch (e) {
      return Left(_mapBackendError(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<AuthFailure, User?>> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return const Right(null);
    try {
      final user = await _remote.me();
      return Right(user);
    } on DioException {
      // El interceptor ya limpió el token si fue 401. Cualquier otro
      // error de red deja la sesión en limbo: devolvemos null para que
      // el usuario haga login manualmente, sin marcar fallo.
      return const Right(null);
    } catch (_) {
      return const Right(null);
    }
  }

  @override
  Future<Either<AuthFailure, User>> updateProfileImage(
    String userId,
    File image,
  ) async {
    try {
      final user = await _remote.updateProfileImage(userId, image);
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapBackendError(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  // ── OAuth (Firebase) ────────────────────────────────────────────────────

  @override
  Future<Either<AuthFailure, User>> loginWithGoogle() async {
    try {
      final user = await _firebase.signInWithGoogle();
      return Right(user);
    } on OAuthCancelled {
      return const Left(CancelledFailure());
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<AuthFailure, User>> loginWithGithub() async {
    try {
      final user = await _firebase.signInWithGithub();
      return Right(user);
    } on OAuthCancelled {
      return const Left(CancelledFailure());
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    await _tokenStorage.clear();
    await _firebase.signOut();
    return const Right(unit);
  }

  // ── Mapeo de errores ────────────────────────────────────────────────────

  AuthFailure _mapBackendError(DioException e) {
    final err = e.error;
    if (err is ValidationException) {
      final fields = <String, String>{
        for (final v in err.errors) v.field: v.message,
      };
      final summary = err.errors.isNotEmpty
          ? err.errors.map((v) => v.message).join('\n')
          : err.message;
      return ValidationFailure(summary, fieldErrors: fields);
    }
    if (err is UnauthorizedException) {
      return InvalidCredentialsFailure(err.message);
    }
    if (err is ApiException) {
      return UnexpectedFailure(err.message);
    }
    return const NetworkFailure();
  }

  AuthFailure _mapFirebaseError(fb.FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'No existe una cuenta con este email.',
      'wrong-password' => 'Contraseña incorrecta. Intenta de nuevo.',
      'invalid-credential' => 'Email o contraseña incorrectos.',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
      'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
      'email-already-in-use' => 'Ya existe una cuenta con este email.',
      'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres).',
      'invalid-email' => 'El formato del email no es válido.',
      'network-request-failed' => 'Sin conexión. Verifica tu red.',
      'popup-closed-by-user' => 'Login cancelado.',
      'popup-blocked' =>
        'El popup fue bloqueado. Permite popups para este sitio.',
      'operation-not-allowed' => 'Este método de login no está habilitado.',
      'account-exists-with-different-credential' =>
        'Ya existe una cuenta con este email usando otro método de login.',
      _ => 'Error de autenticación: ${e.message ?? e.code}',
    };

    return switch (e.code) {
      'wrong-password' || 'invalid-credential' || 'user-not-found' =>
        InvalidCredentialsFailure(message),
      'network-request-failed' => NetworkFailure(message),
      'popup-closed-by-user' => const CancelledFailure(),
      _ => UnexpectedFailure(message),
    };
  }
}
