import 'package:dartz/dartz.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

class LoginWithGithubUseCase {
  const LoginWithGithubUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User>> call() => _repository.loginWithGithub();
}
