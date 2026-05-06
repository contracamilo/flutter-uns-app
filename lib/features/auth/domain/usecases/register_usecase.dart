import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User>> call(RegisterParams params) {
    return _repository.registerWithEmail(
      params.name,
      params.email,
      params.password,
    );
  }
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}
