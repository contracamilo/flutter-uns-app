import 'dart:io';

import 'package:dio/dio.dart';
import 'package:unisalle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:unisalle/features/auth/data/models/user_model.dart';

/// Implementación de `AuthRemoteDataSource` contra el backend Node.js
/// (`/auth/login`, `/auth/register`, `/users/me`, multipart).
///
/// El JWT se inyecta automáticamente vía el interceptor del `Dio`
/// (ver `core/network/api_client.dart`).
class BackendAuthDataSource implements AuthRemoteDataSource {
  BackendAuthDataSource(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> login(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _sessionFromResponse(res);
  }

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await _dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return _sessionFromResponse(res);
  }

  @override
  Future<UserModel> me() async {
    final res = await _dio.get('/users/me');
    final data =
        (res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> updateProfileImage(String userId, File image) async {
    final fileName = image.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: fileName),
    });
    final res = await _dio.put(
      '/users/$userId/image',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data =
        (res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  AuthSession _sessionFromResponse(Response<dynamic> res) {
    final body = res.data as Map<String, dynamic>;
    final token = body['token'] as String;
    final user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
    return AuthSession(user: user, token: token);
  }
}
