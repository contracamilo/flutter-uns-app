import 'dart:io';

import 'package:dio/dio.dart';
import 'package:unisalle/models/user.dart';

/// Resultado de un login/registro contra el backend Node.js:
/// el usuario formateado más el JWT firmado.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final User user;
  final String token;
}

/// Cliente del backend Node.js para los flujos de email/password
/// y operaciones del usuario autenticado (`/me`, upload de imagen).
///
/// El JWT se inyecta automáticamente vía interceptor del `Dio`
/// (ver `core/network/api_client.dart`).
class BackendAuthService {
  BackendAuthService(this._dio);

  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _sessionFromResponse(res);
  }

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

  Future<User> me() async {
    final res = await _dio.get('/users/me');
    final data = (res.data as Map<String, dynamic>)['user']
        as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<User> updateProfileImage(String userId, File image) async {
    final fileName = image.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: fileName),
    });
    final res = await _dio.put(
      '/users/$userId/image',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = (res.data as Map<String, dynamic>)['user']
        as Map<String, dynamic>;
    return User.fromJson(data);
  }

  AuthSession _sessionFromResponse(Response<dynamic> res) {
    final body = res.data as Map<String, dynamic>;
    final token = body['token'] as String;
    final user = User.fromJson(body['user'] as Map<String, dynamic>);
    return AuthSession(user: user, token: token);
  }
}
