// ============================================================
// FILE: backend_auth_service_test.dart
// PURPOSE: Tests unitarios de la integración con el backend Node.js.
//
// HERRAMIENTAS:
//   - http_mock_adapter: intercepta requests del cliente Dio y devuelve
//     respuestas controladas, sin necesidad de levantar el backend.
//
// COBERTURA:
//   - login OK / login 401
//   - register OK / register 422 con errores por campo
//   - me OK / me 401 (token expirado)
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/network/api_client.dart';
import 'package:unisalle/core/network/api_exceptions.dart';
import 'package:unisalle/features/auth/data/backend_auth_service.dart';

class _InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

void main() {
  late _InMemoryTokenStorage tokenStorage;
  late Dio dio;
  late DioAdapter adapter;
  late BackendAuthService service;

  setUp(() {
    tokenStorage = _InMemoryTokenStorage();
    dio = buildApiClient(tokenStorage);
    adapter = DioAdapter(dio: dio);
    service = BackendAuthService(dio);
  });

  group('login', () {
    test('200 OK → devuelve User + token', () async {
      adapter.onPost(
        '/auth/login',
        (req) => req.reply(200, {
          'ok': true,
          'token': 'jwt-abc',
          'user': {
            'id': 1,
            'name': 'Ana',
            'email': 'ana@test.com',
            'image': null,
            'roles': ['user'],
          },
        }),
        data: {'email': 'ana@test.com', 'password': '123456'},
      );

      final session = await service.login('ana@test.com', '123456');

      expect(session.token, 'jwt-abc');
      expect(session.user.id, '1');
      expect(session.user.name, 'Ana');
      expect(session.user.roles, ['user']);
    });

    test('401 → DioException con UnauthorizedException', () async {
      adapter.onPost(
        '/auth/login',
        (req) => req.reply(401, {
          'ok': false,
          'message': 'Credenciales incorrectas.',
        }),
        data: {'email': 'x@test.com', 'password': 'wrong'},
      );

      // Pre-cargamos un token para verificar que el interceptor lo limpia
      // tras un 401.
      await tokenStorage.save('stale-token');

      Object? captured;
      try {
        await service.login('x@test.com', 'wrong');
      } on DioException catch (e) {
        captured = e.error;
      }

      expect(captured, isA<UnauthorizedException>());
      expect(await tokenStorage.read(), isNull);
    });
  });

  group('register', () {
    test('422 con errors[] → DioException con ValidationException', () async {
      adapter.onPost(
        '/auth/register',
        (req) => req.reply(400, {
          'ok': false,
          'message': 'Datos inválidos',
          'errors': [
            {'path': 'email', 'msg': 'Email no válido'},
            {'path': 'password', 'msg': 'Mínimo 6 caracteres'},
          ],
        }),
        data: {'name': 'Ana', 'email': 'bad', 'password': '1'},
      );

      Object? captured;
      try {
        await service.register('Ana', 'bad', '1');
      } on DioException catch (e) {
        captured = e.error;
      }

      expect(captured, isA<ValidationException>());
      final ex = captured as ValidationException;
      expect(ex.errors, hasLength(2));
      expect(ex.errors.first.field, 'email');
      expect(ex.errors.last.field, 'password');
    });
  });

  group('me', () {
    test('200 OK → devuelve User mapeado del payload', () async {
      await tokenStorage.save('jwt-xyz');

      adapter.onGet(
        '/users/me',
        (req) => req.reply(200, {
          'ok': true,
          'user': {
            'id': 7,
            'name': 'Bea',
            'email': 'bea@test.com',
            'image': 'http://server/uploads/abc.jpg',
            'roles': ['admin', 'user'],
          },
        }),
      );

      final user = await service.me();

      expect(user.id, '7');
      expect(user.email, 'bea@test.com');
      expect(user.photoUrl, 'http://server/uploads/abc.jpg');
      expect(user.roles, ['admin', 'user']);
    });

    test('401 → token limpiado por el interceptor', () async {
      await tokenStorage.save('jwt-xyz');

      adapter.onGet(
        '/users/me',
        (req) => req.reply(401, {'ok': false, 'message': 'Token inválido.'}),
      );

      Object? captured;
      try {
        await service.me();
      } on DioException catch (e) {
        captured = e.error;
      }

      expect(captured, isA<UnauthorizedException>());
      expect(await tokenStorage.read(), isNull);
    });
  });
}
