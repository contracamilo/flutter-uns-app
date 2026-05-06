import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

/// Inicia sesión con email y contraseña.
///
/// El UseCase recibe el repositorio por constructor (Inyección de
/// Dependencias): el BLoC nunca habla con el data source directamente.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User>> call(LoginParams params) {
    return _repository.loginWithEmail(params.email, params.password);
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
