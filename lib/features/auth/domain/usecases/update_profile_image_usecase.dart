import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileImageUseCase {
  const UpdateProfileImageUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User>> call(UpdateProfileImageParams params) {
    return _repository.updateProfileImage(params.userId, params.image);
  }
}

class UpdateProfileImageParams extends Equatable {
  const UpdateProfileImageParams({required this.userId, required this.image});

  final String userId;
  final File image;

  @override
  List<Object?> get props => [userId, image.path];
}
