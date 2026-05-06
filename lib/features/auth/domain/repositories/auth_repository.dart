import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';

/// Contrato del repositorio de autenticación.
///
/// Vive en la capa de Dominio: no conoce HTTP, Firebase ni Dio. La
/// implementación concreta (`AuthRepositoryImpl`) traduce las llamadas
/// hacia los `DataSource`s y mapea cualquier excepción a `AuthFailure`.
abstract class AuthRepository {
  Future<Either<AuthFailure, User>> loginWithEmail(
    String email,
    String password,
  );

  Future<Either<AuthFailure, User>> registerWithEmail(
    String name,
    String email,
    String password,
  );

  Future<Either<AuthFailure, User>> loginWithGoogle();

  Future<Either<AuthFailure, User>> loginWithGithub();

  Future<Either<AuthFailure, Unit>> logout();

  /// Restaura la sesión a partir del JWT persistido. Devuelve `right(null)`
  /// si no hay token o el token ya no es válido. Solo devuelve `Left` si
  /// hubo un fallo inesperado del que conviene informar al usuario.
  Future<Either<AuthFailure, User?>> restoreSession();

  Future<Either<AuthFailure, User>> updateProfileImage(
    String userId,
    File image,
  );
}
