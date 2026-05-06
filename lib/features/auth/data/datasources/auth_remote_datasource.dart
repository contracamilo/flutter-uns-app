import 'dart:io';

import 'package:unisalle/features/auth/data/models/user_model.dart';

/// Resultado de un login/registro contra el backend Node.js:
/// el usuario formateado más el JWT firmado.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final UserModel user;
  final String token;
}

/// Contrato que abstrae la fuente remota de auth (Node.js).
///
/// Separar el contrato del Dio concreto permite que el repositorio
/// no dependa de un cliente HTTP específico y facilita los tests.
abstract class AuthRemoteDataSource {
  Future<AuthSession> login(String email, String password);

  Future<AuthSession> register(String name, String email, String password);

  Future<UserModel> me();

  Future<UserModel> updateProfileImage(String userId, File image);
}
